# Copyright 2026 Google LLC
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

package Google::Auth::ServiceAccountCredentials;

use strict;
use warnings;

use Moo;
extends 'Google::Auth::Credentials';

use JSON::PP;
use MIME::Base64 qw(encode_base64url);
use LWP::UserAgent;
use Google::Auth;
use Google::Auth::Exceptions;
use Google::Auth::RetryHelper;
use Log::Any qw($log);

our $VERSION = '0.02';

has json_key => (
    is       => 'ro',
    required => 0,
);

has project_id => (
    is       => 'ro',
    required => 0,
);

has private_key_id => (
    is       => 'ro',
    required => 0,
);

has private_key => (
    is       => 'ro',
    required => 0,
);

has client_email => (
    is       => 'ro',
    required => 0,
);

has client_id => (
    is       => 'ro',
    required => 0,
);

has auth_uri => (
    is       => 'ro',
    required => 0,
);

has token_uri => (
    is       => 'ro',
    required => 0,
);

has auth_provider_x509_cert_url => (
    is       => 'ro',
    required => 0,
);

has client_x509_cert_url => (
    is       => 'ro',
    required => 0,
);

has scope => (
    is       => 'ro',
    required => 0,
);


has ua => (
    is      => 'ro',
    default => sub { LWP::UserAgent->new( timeout => 10 ) },
);

around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $args = $class->$orig(@args);

    if ( my $json = $args->{json_key} ) {
        $args->{project_id}                  //= $json->{project_id};
        $args->{private_key_id}              //= $json->{private_key_id};
        $args->{private_key}                 //= $json->{private_key};
        $args->{client_email}                //= $json->{client_email};
        $args->{client_id}                   //= $json->{client_id};
        $args->{auth_uri}                    //= $json->{auth_uri};
        $args->{token_uri}                   //= $json->{token_uri};
        $args->{auth_provider_x509_cert_url} //= $json->{auth_provider_x509_cert_url};
        $args->{client_x509_cert_url}        //= $json->{client_x509_cert_url};
    }

    return $args;
};

sub _encode_base64url {
    my ($data) = @_;
    my $s = MIME::Base64::encode_base64url($data);
    $s =~ s/=+$//;
    return $s;
}

sub fetch_access_token {
    my ( $self, %options ) = @_;

    my $private_key  = $self->private_key;
    my $client_email = $self->client_email;
    my $token_uri    = $self->token_uri // 'https://oauth2.googleapis.com/token';

    if ( !defined $private_key || !defined $client_email ) {
        $log->errorf('Missing private_key or client_email for ServiceAccountCredentials token exchange');
        Google::Auth::Error->throw('Missing private_key or client_email to sign and fetch token');
    }

    my $now = time();
    my $header = {
        alg => 'RS256',
        typ => 'JWT',
    };
    $header->{kid} = $self->private_key_id if defined $self->private_key_id;

    my $scope = $self->scope;
    if ( ref($scope) eq 'ARRAY' ) {
        $scope = join(' ', @$scope);
    }

    my $payload = {
        iss   => $client_email,
        sub   => $client_email,
        aud   => $token_uri,
        exp   => $now + 3600,
        iat   => $now,
    };
    $payload->{scope} = $scope if defined $scope;

    my $header_b64  = _encode_base64url(encode_json($header));
    my $payload_b64 = _encode_base64url(encode_json($payload));
    my $message     = $header_b64 . '.' . $payload_b64;

    $log->tracef('Signing JWT assertion for service account %s (key ID: %s)...', $client_email, $self->private_key_id // 'N/A');
    my $signature_raw = Google::Auth::rsa_sign_sha256($private_key, $message);
    if ( !defined $signature_raw ) {
        $log->errorf('Failed to sign JWT assertion for service account %s', $client_email);
        Google::Auth::Error->throw('Failed to sign JWT assertion using private key');
    }
    my $signature_b64 = _encode_base64url($signature_raw);
    my $assertion     = $message . '.' . $signature_b64;

    my $ua = $self->ua;
    my $post_body = {
        grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion  => $assertion,
    };

    $log->infof('Exchanging signed JWT assertion for access token at %s...', $token_uri);
    my $response = Google::Auth::RetryHelper->execute_with_retry(sub {
        my $res = $ua->post(
            $token_uri,
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content'      => $post_body
        );
        if ( !$res->is_success ) {
            $log->warnf('Service account token request failed at %s: status %s', $token_uri, $res->code);
            Google::Auth::Error->throw('HTTP request failed with status ' . $res->code . ': ' . $res->decoded_content);
        }
        return $res;
    }, %options);

    my $res_data = decode_json($response->decoded_content);
    my $token    = $res_data->{access_token};
    my $expires  = $res_data->{expires_in} // 3600;

    $self->access_token($token);
    $self->expires_at($now + $expires);

    return $token;
}

1;
