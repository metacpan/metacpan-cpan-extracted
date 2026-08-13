# Copyright 2026 Google LLC and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Auth::ExternalAccountCredentials::Aws;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::ExternalAccountCredentials';

use Digest::SHA qw(hmac_sha256 hmac_sha256_hex sha256_hex);
use Time::Piece;
use JSON::PP;
use MIME::Base64 qw(encode_base64);
use URI;
use HTTP::Request;
use Google::Auth::Exceptions;
use Log::Any qw($log);

sub _get_imdsv2_token {
  my ($self, $imdsv2_url) = @_;

  $imdsv2_url = 'http://169.254.169.254/latest/api/token'
    unless defined $imdsv2_url && length $imdsv2_url;
  $log->debugf('Attempting to fetch AWS IMDSv2 token from: %s', $imdsv2_url);

  my $req = HTTP::Request->new(PUT => $imdsv2_url);
  $req->header('X-aws-ec2-metadata-token-ttl-seconds' => '21600');

  my $res = $self->ua->request($req);
  if ($res->is_success) {
    my $token = $res->decoded_content;
    $token =~ s/^\s+|\s+$//g if defined $token;
    return $token            if defined $token && length $token;
  }

  $log->debugf('Could not obtain IMDSv2 token: %s', $res->status_line);
  return;
}

sub _get_aws_security_credentials {
  my ($self) = @_;

  # 1. Check static environment variables
  my $access_key    = $ENV{AWS_ACCESS_KEY_ID};
  my $secret_key    = $ENV{AWS_SECRET_ACCESS_KEY};
  my $session_token = $ENV{AWS_SESSION_TOKEN};

  if ( defined $access_key
    && defined $secret_key
    && length($access_key)
    && length($secret_key))
  {
    $log->tracef('Using AWS static environment credentials with access key: %s',
      $access_key);
    return ($access_key, $secret_key, $session_token);
  }

  # 2. Check AWS ECS / EKS Container task credentials
  my $container_uri;
  my $rel_uri  = $ENV{AWS_CONTAINER_CREDENTIALS_RELATIVE_URI};
  my $full_uri = $ENV{AWS_CONTAINER_CREDENTIALS_FULL_URI};

  if (defined $rel_uri && length $rel_uri) {
    # Defense-in-depth: Validate relative URI starts with single slash and contains no userinfo '@', double slashes, or path traversal
    unless ($rel_uri =~ m{^/[^@]+$} && $rel_uri !~ m{//|\.\.}) {
      $log->errorf(
'Security violation: Invalid AWS_CONTAINER_CREDENTIALS_RELATIVE_URI format: %s',
        $rel_uri
      );
      Google::Auth::Error->throw(
        "Invalid AWS_CONTAINER_CREDENTIALS_RELATIVE_URI format: $rel_uri");
    }
    $container_uri = 'http://169.254.170.2' . $rel_uri;
  } elsif (defined $full_uri && length $full_uri) {
    my $uri_obj = URI->new($full_uri);
    my $scheme  = lc($uri_obj->scheme // '');
    my $host    = lc($uri_obj->host   // '');

    $log->debugf("Validating FULL_URI: %s (Scheme: %s, Host: %s)",
      $full_uri, $scheme, $host);

    # Enforce allowed schemes
    unless ($scheme eq 'http' || $scheme eq 'https') {
      $log->errorf(
'Security violation: AWS_CONTAINER_CREDENTIALS_FULL_URI scheme %s is not permitted',
        $scheme
      );
      Google::Auth::Error->throw(
"AWS_CONTAINER_CREDENTIALS_FULL_URI scheme $scheme carries security violation"
      );
    }

    # Enforce allowed loopback / link-local container host allowlist per AWS SDK specifications
    $host =~ s/^[\[\s]+|[\]\s]+$//g;    # Trim brackets and spaces

    unless ($host eq '127.0.0.1'
      || $host eq 'localhost'
      || $host eq '::1'
      || $host eq '169.254.170.2')
    {
      $log->errorf(
'Security violation: AWS_CONTAINER_CREDENTIALS_FULL_URI host %s is not permitted',
        $host
      );
      Google::Auth::Error->throw(
"AWS_CONTAINER_CREDENTIALS_FULL_URI host $host carries security violation"
      );
    }
    $container_uri = $full_uri;
  }

  if ($container_uri) {
    $log->debugf('Fetching AWS container task credentials from: %s',
      $container_uri);
    my $req        = HTTP::Request->new(GET => $container_uri);
    my $auth_token = $ENV{AWS_CONTAINER_AUTHORIZATION_TOKEN};
    if (defined $auth_token && length $auth_token) {
      $req->header(Authorization => $auth_token);
    }

    my $res = $self->ua->request($req);
    if ($res->is_success) {
      my $data = eval { decode_json($res->decoded_content) };
      if ( ref $data eq 'HASH'
        && $data->{AccessKeyId}
        && $data->{SecretAccessKey})
      {
        $log->tracef('Successfully resolved AWS container credentials: %s',
          $data->{AccessKeyId});
        return ($data->{AccessKeyId}, $data->{SecretAccessKey}, $data->{Token});
      }
    }
    $log->warnf('Failed to retrieve AWS container credentials from %s: %s',
      $container_uri, $res->status_line);
  }

  # 3. Check EC2 IMDSv2 Metadata Server
  my $source  = $self->credential_source // {};
  my $sec_url = $source->{url};

  if ($sec_url) {
    $log->debugf('Fetching AWS EC2 metadata credentials from: %s', $sec_url);
    my $imdsv2_token =
      $self->_get_imdsv2_token($source->{imdsv2_session_token_url});

    # Query attached role name
    my $role_req = HTTP::Request->new(GET => $sec_url);
    $role_req->header('X-aws-ec2-metadata-token' => $imdsv2_token)
      if defined $imdsv2_token;

    my $role_res = $self->ua->request($role_req);
    if ($role_res->is_success) {
      my $role_name = (split /\r?\n/, $role_res->decoded_content)[0];
      $role_name =~ s/^\s+|\s+$//g if defined $role_name;

      if (defined $role_name && length $role_name) {
        my $cred_url = $sec_url;
        $cred_url .= '/' unless $cred_url =~ m{/$};
        $cred_url .= $role_name;

        my $cred_req = HTTP::Request->new(GET => $cred_url);
        $cred_req->header('X-aws-ec2-metadata-token' => $imdsv2_token)
          if defined $imdsv2_token;

        my $cred_res = $self->ua->request($cred_req);
        if ($cred_res->is_success) {
          my $data = eval { decode_json($cred_res->decoded_content) };
          if ( ref $data eq 'HASH'
            && $data->{AccessKeyId}
            && $data->{SecretAccessKey})
          {
            $log->tracef(
'Successfully resolved AWS EC2 metadata credentials for role %s: %s',
              $role_name, $data->{AccessKeyId});
            return ($data->{AccessKeyId}, $data->{SecretAccessKey},
              $data->{Token});
          }
        }
      }
    }
    $log->warnf('Failed to retrieve AWS EC2 metadata credentials: %s',
      $role_res->status_line);
  }

  $log->errorf(
'Unable to resolve AWS credentials from environment, container task, or EC2 metadata server'
  );
  Google::Auth::Error->throw(
'Unable to resolve AWS credentials from environment, container task, or EC2 metadata server'
  );
}

sub _get_aws_region {
  my ($self) = @_;

  my $region;
  if (defined $ENV{AWS_REGION} && length $ENV{AWS_REGION}) {
    $region = $ENV{AWS_REGION};
  } elsif (defined $ENV{AWS_DEFAULT_REGION} && length $ENV{AWS_DEFAULT_REGION})
  {
    $region = $ENV{AWS_DEFAULT_REGION};
  }
  if (defined $region && length $region) {
    return $region;
  }

  my $source     = $self->credential_source // {};
  my $region_url = $source->{region_url};

  if ($region_url) {
    $log->debugf('Fetching AWS region from metadata: %s', $region_url);
    my $imdsv2_token =
      $self->_get_imdsv2_token($source->{imdsv2_session_token_url});

    my $req = HTTP::Request->new(GET => $region_url);
    $req->header('X-aws-ec2-metadata-token' => $imdsv2_token)
      if defined $imdsv2_token;

    my $res = $self->ua->request($req);
    if ($res->is_success) {
      my $az = $res->decoded_content;
      $az =~ s/^\s+|\s+$//g if defined $az;
      if (defined $az && length($az) > 1) {
        # Strip trailing availability zone character (e.g. us-west-2a -> us-west-2)
        my $derived_region = substr($az, 0, -1);
        if ($derived_region =~ m{^[a-z]{2,4}-[a-z]+-\d+$}) {
          $log->tracef('Derived AWS region from AZ (%s): %s',
            $az, $derived_region);
          return $derived_region;
        } else {
          $log->warnf(
'Metadata AZ response (%s) produced invalid region format (%s), falling back to us-east-1',
            $az, $derived_region
          );
        }
      }
    }
  }

  return 'us-east-1';
}

sub retrieve_subject_token {
  my ($self) = @_;

  my ($access_key, $secret_key, $session_token) =
    $self->_get_aws_security_credentials();
  my $region = $self->_get_aws_region();

  my $source  = $self->credential_source // {};
  my $raw_url = $source->{regional_cred_verification_url}
    // 'https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15';

  $raw_url =~ s/\{region\}/$region/g;

  my $uri_obj = URI->new($raw_url);
  my $host    = $uri_obj->host;
  my $method  = 'POST';
  my $uri     = $uri_obj->path || '/';
  my $query = $uri_obj->query // 'Action=GetCallerIdentity&Version=2011-06-15';

  my $t         = gmtime();
  my $amz_date  = $t->strftime('%Y%m%dT%H%M%SZ');
  my $datestamp = $t->strftime('%Y%m%d');

  my %headers = (
    'host'       => $host,
    'x-amz-date' => $amz_date,
  );
  $headers{'x-amz-security-token'} = $session_token
    if defined $session_token && length $session_token;

  my @sorted_header_names = sort keys %headers;
  my $canonical_headers =
    join('', map { $_ . ':' . $headers{$_} . "\n" } @sorted_header_names);
  my $signed_headers = join(';', @sorted_header_names);

  my $payload_hash = sha256_hex('');

  my $canonical_request = join("\n",
    $method, $uri, $query, $canonical_headers, $signed_headers, $payload_hash);

  my $algorithm        = 'AWS4-HMAC-SHA256';
  my $credential_scope = join('/', $datestamp, $region, 'sts', 'aws4_request');
  my $string_to_sign   = join("\n",
    $algorithm, $amz_date, $credential_scope, sha256_hex($canonical_request));

  my $k_date    = hmac_sha256($datestamp,     'AWS4' . $secret_key);
  my $k_region  = hmac_sha256($region,        $k_date);
  my $k_service = hmac_sha256('sts',          $k_region);
  my $k_signing = hmac_sha256('aws4_request', $k_service);

  my $signature = hmac_sha256_hex($string_to_sign, $k_signing);

  my $auth_header =
"$algorithm Credential=$access_key/$credential_scope, SignedHeaders=$signed_headers, Signature=$signature";
  $headers{Authorization} = $auth_header;

  my @header_array;
  foreach my $k (sort keys %headers) {
    push @header_array, {key => $k, value => $headers{$k}};
  }

  my $request_obj = {
    url     => $raw_url,
    headers => \@header_array,
    method  => $method,
  };

  my $subject_token = encode_base64(encode_json($request_obj), '');
  $subject_token =~ s/\s+//g;
  return $subject_token;
}

1;
