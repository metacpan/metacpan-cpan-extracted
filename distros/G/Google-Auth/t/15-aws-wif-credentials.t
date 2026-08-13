# Copyright 2026 Google LLC and contributors
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::PP;
use MIME::Base64 qw(decode_base64);
use Digest::SHA  qw(hmac_sha256 hmac_sha256_hex sha256_hex);

# plan tests => 12; # Let done_testing handle it

BEGIN {
  use_ok('Google::Auth::ExternalAccountCredentials') || print "Bail out!\n";
}

subtest 'AWS WIF Initialization and Factory' => sub {
  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
      region_url     =>
        'http://169.254.169.254/latest/meta-data/placement/availability-zone',
      url => 'http://169.254.169.254/latest/meta-data/iam/security-credentials',
    },
  );

  ok(defined $creds, 'AWS credentials object created via factory');
  isa_ok($creds, 'Google::Auth::ExternalAccountCredentials::Aws');
};

subtest 'AWS WIF Missing All Sources throws Error' => sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_FULL_URI'};

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
    },
  );

  eval { $creds->retrieve_subject_token(); };
  like(
    $@,
qr/Unable to resolve AWS credentials from environment, container task, or EC2 metadata server/,
    'throws when no credentials could be found'
  );
};

subtest 'AWS WIF Static Environment Variables' => sub {
  local %ENV = %ENV;
  $ENV{'AWS_ACCESS_KEY_ID'}     = 'mock_access_key';
  $ENV{'AWS_SECRET_ACCESS_KEY'} = 'mock_secret_key';
  $ENV{'AWS_SESSION_TOKEN'}     = 'mock_session_token';
  $ENV{'AWS_DEFAULT_REGION'}    = 'us-east-1';

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
    },
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token, 'subject token generated successfully');

  my $decoded_json = decode_base64($subject_token);
  my $req_obj      = decode_json($decoded_json);

  is($req_obj->{'method'}, 'POST', 'request method is POST');
  is(
    $req_obj->{'url'},
'https://sts.us-east-1.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15',
    'request URL matches STS endpoint'
  );

  my $headers = $req_obj->{'headers'};
  ok(defined $headers, 'headers array is present');
  is(ref $headers, 'ARRAY', 'headers is indeed an array');

  my %header_map = map { $_->{'key'} => $_->{'value'} } @$headers;

  is($header_map{'host'}, 'sts.us-east-1.amazonaws.com', 'host header matches');
  is($header_map{'x-amz-security-token'},
    'mock_session_token', 'security token matches');
  ok(defined $header_map{'x-amz-date'},    'x-amz-date is present');
  ok(defined $header_map{'Authorization'}, 'Authorization header is present');

  # Verify AWS SigV4 signature correctness manually
  my $amz_date  = $header_map{'x-amz-date'};
  my $datestamp = substr($amz_date, 0, 8);

  my $canonical_headers =
    'host:sts.us-east-1.amazonaws.com' . "\n" .
    'x-amz-date:' .
    $amz_date . "\n" .
    'x-amz-security-token:mock_session_token' . "\n";
  my $signed_headers = 'host;x-amz-date;x-amz-security-token';
  my $payload_hash   = sha256_hex('');

  my $canonical_request = join("\n",
    'POST',             '/', 'Action=GetCallerIdentity&Version=2011-06-15',
    $canonical_headers, $signed_headers, $payload_hash);

  my $credential_scope =
    join('/', $datestamp, 'us-east-1', 'sts', 'aws4_request');
  my $string_to_sign = join("\n",
    'AWS4-HMAC-SHA256', $amz_date, $credential_scope,
    sha256_hex($canonical_request));

  my $k_date    = hmac_sha256($datestamp,     'AWS4' . 'mock_secret_key');
  my $k_region  = hmac_sha256('us-east-1',    $k_date);
  my $k_service = hmac_sha256('sts',          $k_region);
  my $k_signing = hmac_sha256('aws4_request', $k_service);

  my $expected_signature = hmac_sha256_hex($string_to_sign, $k_signing);

  my $expected_auth =
    'AWS4-HMAC-SHA256 Credential=mock_access_key/' .
    $credential_scope .
    ', SignedHeaders=' .
    $signed_headers .
    ', Signature=' .
    $expected_signature;

  is($header_map{'Authorization'},
    $expected_auth, 'Authorization signature verified successfully');
};

subtest 'AWS WIF Container Task Credentials (ECS Relative URI)' => sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'} = '/v2/credentials/task-123';
  $ENV{'AWS_DEFAULT_REGION'}                     = 'us-west-2';

  my $mock_ua = Test::LWP::UserAgent->new();
  $mock_ua->map_response(
    qr{http://169\.254\.170\.2/v2/credentials/task-123},
    HTTP::Response->new(
      200, 'OK',
      ['Content-Type' => 'application/json'],
      encode_json({
          AccessKeyId     => 'ecs_mock_key',
          SecretAccessKey => 'ecs_mock_secret',
          Token           => 'ecs_mock_token',
        })));

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
    },
    ua => $mock_ua,
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token,
    'subject token generated from ECS container credentials');

  my $decoded_json = decode_base64($subject_token);
  my $req_obj      = decode_json($decoded_json);
  my %header_map =
    map { $_->{'key'} => $_->{'value'} } @{$req_obj->{'headers'}};

  is($header_map{'x-amz-security-token'},
    'ecs_mock_token', 'ECS security token is set');
  like($header_map{'Authorization'},
    qr/Credential=ecs_mock_key/, 'Authorization contains ECS key');
  like($header_map{'Authorization'},
    qr/us-west-2/, 'Authorization scope contains us-west-2');
};

subtest
  'AWS WIF Container Task Credentials (Full URI with Authorization Token)' =>
  sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'};
  $ENV{'AWS_CONTAINER_CREDENTIALS_FULL_URI'} =
    'http://localhost:8080/credentials';
  $ENV{'AWS_CONTAINER_AUTHORIZATION_TOKEN'} = 'auth-bearer-token';
  $ENV{'AWS_DEFAULT_REGION'}                = 'eu-west-1';

  my $mock_ua = Test::LWP::UserAgent->new();
  $mock_ua->map_response(
    sub {
      my ($request) = @_;
      return 0 unless $request->uri eq 'http://localhost:8080/credentials';
      return 0
        unless ($request->header('Authorization') // '') eq 'auth-bearer-token';
      return 1;
    },
    HTTP::Response->new(
      200, 'OK',
      ['Content-Type' => 'application/json'],
      encode_json({
          AccessKeyId     => 'full_uri_key',
          SecretAccessKey => 'full_uri_secret',
          Token           => 'full_uri_token',
        })));

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
    },
    ua => $mock_ua,
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token,
    'subject token generated from Full URI container credentials');

  my $decoded_json = decode_base64($subject_token);
  my $req_obj      = decode_json($decoded_json);
  my %header_map =
    map { $_->{'key'} => $_->{'value'} } @{$req_obj->{'headers'}};

  like($header_map{'Authorization'},
    qr/Credential=full_uri_key/, 'Authorization contains full URI key');
  };

subtest 'AWS WIF EC2 IMDSv2 Metadata Resolution' => sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_FULL_URI'};
  $ENV{'AWS_REGION'} = 'ap-southeast-1';

  my $mock_ua = Test::LWP::UserAgent->new();
  # 1. IMDSv2 Token PUT
  $mock_ua->map_response(
    sub {
      my ($request) = @_;
      return $request->method eq 'PUT'
        && $request->uri eq 'http://169.254.169.254/latest/api/token';
    },
    HTTP::Response->new(200, 'OK', [], 'mock-imdsv2-session-token'));

  # 2. Role name GET
  $mock_ua->map_response(
    sub {
      my ($request) = @_;
      return 0 unless $request->method eq 'GET';
      return 0
        unless $request->uri eq
        'http://169.254.169.254/latest/meta-data/iam/security-credentials';
      return ($request->header('X-aws-ec2-metadata-token') // '') eq
        'mock-imdsv2-session-token';
    },
    HTTP::Response->new(200, 'OK', [], "my-ec2-iam-role\n"));

  # 3. Security Credentials GET
  $mock_ua->map_response(
    sub {
      my ($request) = @_;
      return 0 unless $request->method eq 'GET';
      return 0
        unless $request->uri eq
'http://169.254.169.254/latest/meta-data/iam/security-credentials/my-ec2-iam-role';
      return ($request->header('X-aws-ec2-metadata-token') // '') eq
        'mock-imdsv2-session-token';
    },
    HTTP::Response->new(
      200, 'OK',
      ['Content-Type' => 'application/json'],
      encode_json({
          AccessKeyId     => 'imds_mock_key',
          SecretAccessKey => 'imds_mock_secret',
          Token           => 'imds_mock_token',
        })));

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
      url => 'http://169.254.169.254/latest/meta-data/iam/security-credentials',
      imdsv2_session_token_url => 'http://169.254.169.254/latest/api/token',
    },
    ua => $mock_ua,
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token, 'subject token generated from IMDSv2 metadata');

  my $decoded_json = decode_base64($subject_token);
  my $req_obj      = decode_json($decoded_json);
  my %header_map =
    map { $_->{'key'} => $_->{'value'} } @{$req_obj->{'headers'}};

  is($header_map{'x-amz-security-token'},
    'imds_mock_token', 'IMDS security token is set');
  like($header_map{'Authorization'},
    qr/Credential=imds_mock_key/, 'Authorization contains IMDS key');
  like($header_map{'Authorization'},
    qr/ap-southeast-1/, 'Authorization scope contains ap-southeast-1');
};

subtest 'AWS WIF Dynamic Region Resolution from Availability Zone' => sub {
  local %ENV = %ENV;
  $ENV{'AWS_ACCESS_KEY_ID'}     = 'reg_access_key';
  $ENV{'AWS_SECRET_ACCESS_KEY'} = 'reg_secret_key';
  delete $ENV{'AWS_REGION'};
  delete $ENV{'AWS_DEFAULT_REGION'};

  my $mock_ua = Test::LWP::UserAgent->new();
  $mock_ua->map_response(
    qr{http://169\.254\.169\.254/latest/meta-data/placement/availability-zone},
    HTTP::Response->new(200, 'OK', [], 'us-west-2b'));

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
      region_url     =>
        'http://169.254.169.254/latest/meta-data/placement/availability-zone',
      regional_cred_verification_url =>
'https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15',
    },
    ua => $mock_ua,
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token, 'subject token generated with dynamic region');

  my $decoded_json = decode_base64($subject_token);
  my $req_obj      = decode_json($decoded_json);

  is(
    $req_obj->{'url'},
'https://sts.us-west-2.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15',
    'regional STS endpoint interpolated'
  );
  my %header_map =
    map { $_->{'key'} => $_->{'value'} } @{$req_obj->{'headers'}};
  is($header_map{'host'}, 'sts.us-west-2.amazonaws.com',
    'host header matches regional host');
  like($header_map{'Authorization'},
    qr/us-west-2/, 'Authorization scope contains derived region');
};

subtest 'AWS WIF Negative Security Tests - Relative URI User-Info Injection' =>
  sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'} = '@attacker.com/steal';

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {environment_id => 'aws1'},
  );

  eval { $creds->retrieve_subject_token(); };
  like(
    $@,
    qr/Invalid AWS_CONTAINER_CREDENTIALS_RELATIVE_URI format/,
    'throws security exception on relative URI User-Info injection'
  );
  };

subtest
  'AWS WIF Negative Security Tests - Disallowed Host in Container Task Full URI'
  => sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'};
  $ENV{'AWS_CONTAINER_CREDENTIALS_FULL_URI'} =
    'http://untrusted-host.com/creds';

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {environment_id => 'aws1'},
  );

  eval { $creds->retrieve_subject_token(); };
  like(
    $@,
    qr/carries security violation/,
    'throws security exception on non-loopback host in Full URI'
  );
  };

subtest
'AWS WIF Negative Security Tests - Disallowed Scheme in Container Task Full URI'
  => sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'};
  $ENV{'AWS_CONTAINER_CREDENTIALS_FULL_URI'} = 'file://localhost/etc/passwd';

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {environment_id => 'aws1'},
  );

  my $result = eval { $creds->retrieve_subject_token(); };
  my $err    = $@;
  like(
    $err,
    qr/carries security violation/,
    'throws security exception on non-http scheme in Full URI'
  );
  };

subtest 'AWS WIF Container Task Credentials (IPv6 and Case Insensitivity)' =>
  sub {
  local %ENV = %ENV;
  delete $ENV{'AWS_ACCESS_KEY_ID'};
  delete $ENV{'AWS_SECRET_ACCESS_KEY'};
  delete $ENV{'AWS_SESSION_TOKEN'};
  delete $ENV{'AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'};

  # Test IPv6
  $ENV{'AWS_CONTAINER_CREDENTIALS_FULL_URI'} = 'http://[::1]:8080/credentials';

  my $mock_ua = Test::LWP::UserAgent->new();
  $mock_ua->map_response(
    sub {
      my ($request) = @_;
      return $request->uri eq 'http://[::1]:8080/credentials';
    },
    HTTP::Response->new(
      200, 'OK',
      ['Content-Type' => 'application/json'],
      encode_json({
          AccessKeyId     => 'ipv6_key',
          SecretAccessKey => 'ipv6_secret',
          Token           => 'ipv6_token',
        })));

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience           => '//iam.googleapis.com/foo',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {environment_id => 'aws1'},
    ua                 => $mock_ua,
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token, 'subject token generated from IPv6 Full URI');

  # Test Case Insensitivity
  $ENV{'AWS_CONTAINER_CREDENTIALS_FULL_URI'} =
    'http://LocalHost:8080/credentials';
  $mock_ua->map_response(
    qr{http://LocalHost:8080/credentials}i,    # Case insensitive regex for mock
    HTTP::Response->new(
      200, 'OK',
      ['Content-Type' => 'application/json'],
      encode_json({
          AccessKeyId     => 'case_key',
          SecretAccessKey => 'case_secret',
          Token           => 'case_token',
        })));

  $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token,
    'subject token generated from mixed-case Full URI');
  };

subtest
  'AWS WIF Edge-Case Tests - Invalid Derived AZ Region Format Fallback' => sub {
  local %ENV = %ENV;
  $ENV{'AWS_ACCESS_KEY_ID'}     = 'reg_key';
  $ENV{'AWS_SECRET_ACCESS_KEY'} = 'reg_sec';
  delete $ENV{'AWS_REGION'};
  delete $ENV{'AWS_DEFAULT_REGION'};

  my $mock_ua = Test::LWP::UserAgent->new();
  $mock_ua->map_response(
    qr{http://169\.254\.169\.254/latest/meta-data/placement/availability-zone},
    HTTP::Response->new(200, 'OK', [], '<html>Error 500</html>'));

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {
      environment_id => 'aws1',
      region_url     =>
        'http://169.254.169.254/latest/meta-data/placement/availability-zone',
    },
    ua => $mock_ua,
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token,
    'subject token generated with fallback us-east-1 region');

  my $decoded_json = decode_base64($subject_token);
  my $req_obj      = decode_json($decoded_json);
  my %header_map =
    map { $_->{'key'} => $_->{'value'} } @{$req_obj->{'headers'}};

  like($header_map{'Authorization'},
    qr/us-east-1/,
    'Authorization falls back to us-east-1 on malformed AZ string');
  };

subtest
'AWS WIF Edge-Case Tests - Empty AWS_REGION Env Var Fallback to AWS_DEFAULT_REGION'
  => sub {
  local %ENV = %ENV;
  $ENV{'AWS_ACCESS_KEY_ID'}     = 'reg_key';
  $ENV{'AWS_SECRET_ACCESS_KEY'} = 'reg_sec';
  $ENV{'AWS_REGION'}            = '';
  $ENV{'AWS_DEFAULT_REGION'}    = 'eu-central-1';

  my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
    audience =>
'//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
    subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
    token_url          => 'https://sts.googleapis.com/v1/token',
    credential_source  => {environment_id => 'aws1'},
  );

  my $subject_token = $creds->retrieve_subject_token();
  ok(defined $subject_token, 'subject token generated successfully');

  my $decoded_json = decode_base64($subject_token);
  my $req_obj      = decode_json($decoded_json);
  my %header_map =
    map { $_->{'key'} => $_->{'value'} } @{$req_obj->{'headers'}};

  like($header_map{'Authorization'},
    qr/eu-central-1/,
    'Empty AWS_REGION correctly falls back to AWS_DEFAULT_REGION');
  };

done_testing();
