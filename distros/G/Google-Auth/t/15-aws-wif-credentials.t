# Copyright 2026 Google LLC
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
use Digest::SHA qw(hmac_sha256 hmac_sha256_hex sha256_hex);

BEGIN
{
    use_ok('Google::Auth::ExternalAccountCredentials') || print "Bail out!\n";
}

subtest 'AWS WIF Initialization and Factory' => sub {
    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            environment_id => 'aws1',
            region_url     => 'http://169.254.169.254/latest/meta-data/placement/availability-zone',
            url            => 'http://169.254.169.254/latest/meta-data/iam/security-credentials',
        },
    );

    ok( defined $creds, 'AWS credentials object created via factory' );
    isa_ok( $creds, 'Google::Auth::ExternalAccountCredentials::Aws' );
};

subtest 'AWS WIF Missing Environment Variables' => sub {
    local %ENV = %ENV;
    delete $ENV{'AWS_ACCESS_KEY_ID'};
    delete $ENV{'AWS_SECRET_ACCESS_KEY'};

    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            environment_id => 'aws1',
        },
    );

    eval {
        $creds->retrieve_subject_token();
    };
    like( $@, qr/Missing AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY in environment/, 'throws on missing AWS credentials' );
};

subtest 'AWS WIF Subject Token Generation and Signature Verification' => sub {
    local %ENV = %ENV;
    $ENV{'AWS_ACCESS_KEY_ID'}     = 'mock_access_key';
    $ENV{'AWS_SECRET_ACCESS_KEY'} = 'mock_secret_key';
    $ENV{'AWS_SESSION_TOKEN'}     = 'mock_session_token';
    $ENV{'AWS_DEFAULT_REGION'}    = 'us-east-1';

    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:aws:token-type:aws4_request',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            environment_id => 'aws1',
        },
    );

    my $subject_token = $creds->retrieve_subject_token();
    ok( defined $subject_token, 'subject token generated successfully' );

    my $decoded_json = decode_base64($subject_token);
    my $req_obj = decode_json($decoded_json);

    is( $req_obj->{'method'}, 'POST', 'request method is POST' );
    is( $req_obj->{'url'}, 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15', 'request URL matches STS endpoint' );

    my $headers = $req_obj->{'headers'};
    ok( defined $headers, 'headers array is present' );
    is( ref $headers, 'ARRAY', 'headers is indeed an array' );

    my %header_map = map { $_->{'key'} => $_->{'value'} } @$headers;

    is( $header_map{'host'}, 'sts.amazonaws.com', 'host header matches' );
    is( $header_map{'x-amz-security-token'}, 'mock_session_token', 'security token matches' );
    ok( defined $header_map{'x-amz-date'}, 'x-amz-date is present' );
    ok( defined $header_map{'Authorization'}, 'Authorization header is present' );

    # Verify AWS SigV4 signature correctness manually using the date from headers
    my $amz_date = $header_map{'x-amz-date'};
    my $datestamp = substr($amz_date, 0, 8);

    my $canonical_headers = 'host:sts.amazonaws.com' . "\n"
                          . 'x-amz-date:' . $amz_date . "\n"
                          . 'x-amz-security-token:mock_session_token' . "\n";
    my $signed_headers = 'host;x-amz-date;x-amz-security-token';
    my $payload_hash = sha256_hex('');

    my $canonical_request = join("\n",
        'POST',
        '/',
        'Action=GetCallerIdentity&Version=2011-06-15',
        $canonical_headers,
        $signed_headers,
        $payload_hash
    );

    my $credential_scope = join('/', $datestamp, 'us-east-1', 'sts', 'aws4_request');
    my $string_to_sign = join("\n",
        'AWS4-HMAC-SHA256',
        $amz_date,
        $credential_scope,
        sha256_hex($canonical_request)
    );

    my $k_date    = hmac_sha256($datestamp, 'AWS4' . 'mock_secret_key');
    my $k_region  = hmac_sha256('us-east-1', $k_date);
    my $k_service = hmac_sha256('sts', $k_region);
    my $k_signing = hmac_sha256('aws4_request', $k_service);

    my $expected_signature = hmac_sha256_hex($string_to_sign, $k_signing);

    my $expected_auth = 'AWS4-HMAC-SHA256 Credential=mock_access_key/' . $credential_scope . ', SignedHeaders=' . $signed_headers . ', Signature=' . $expected_signature;

    is( $header_map{'Authorization'}, $expected_auth, 'Authorization signature verified successfully' );
};

done_testing();
