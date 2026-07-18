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

# 1. Load Log::Any::Test FIRST
use Log::Any::Test;

# 2. Load Log::Any
use Log::Any qw($log);

# 3. Load the Adapter
use Log::Any::Adapter;

# 4. Set the Test adapter before loading the modules under test
Log::Any::Adapter->set('Test', min_level => 'trace');

# 5. Load modules under test
use Google::Auth;
use Google::Auth::ServiceAccountCredentials;
use Google::Auth::ExternalAccountCredentials;
use Google::Auth::RetryHelper;

subtest 'ServiceAccountCredentials Logging' => sub {
    my $mock_ua = Test::LWP::UserAgent->new();

    my $keypair = Google::Auth::generate_self_signed_cert();
    my $valid_pkey = $keypair->{key};

    my $creds = Google::Auth::ServiceAccountCredentials->new(
        project_id    => 'my-project',
        private_key   => $valid_pkey,
        client_email  => 'test-sa@google.com',
        private_key_id => 'key-12345',
        token_uri     => 'https://oauth2.googleapis.com/token',
        ua            => $mock_ua,
    );

    $mock_ua->map_response(
        qr/oauth2.googleapis.com\/token/,
        HTTP::Response->new(
            200, 'OK',
            [ 'Content-Type' => 'application/json' ],
            encode_json({
                access_token => 'mock-gcp-token',
                expires_in   => 3600
            })
        )
    );

    $log->clear();

    my $token = $creds->get_token();
    is( $token, 'mock-gcp-token', 'fetched token successfully' );

    # Verify captured logs
    $log->contains_ok(qr/Access token is missing or expired for Google::Auth::ServiceAccountCredentials/, 'info log for missing token check is present');
    $log->contains_ok(qr/Signing JWT assertion for service account test-sa\@google.com/, 'trace log for JWT signing is present');
    $log->contains_ok(qr/Exchanging signed JWT assertion for access token at/, 'info log for exchange start is present');
    $log->contains_ok(qr/Successfully refreshed access token for Google::Auth::ServiceAccountCredentials/, 'info log for exchange completion is present');
};

subtest 'RetryHelper and Error Logging' => sub {
    my $mock_ua = Test::LWP::UserAgent->new();

    my $keypair = Google::Auth::generate_self_signed_cert();
    my $valid_pkey = $keypair->{key};

    my $creds = Google::Auth::ServiceAccountCredentials->new(
        project_id    => 'my-project',
        private_key   => $valid_pkey,
        client_email  => 'test-sa@google.com',
        token_uri     => 'https://oauth2.googleapis.com/token',
        ua            => $mock_ua,
    );

    $mock_ua->map_response(
        qr/oauth2.googleapis.com\/token/,
        HTTP::Response->new(
            503, 'Service Unavailable',
            [ 'Content-Type' => 'text/plain' ],
            'Transient Outage'
        )
    );

    $log->clear();

    eval {
        $creds->get_token( max_retries => 2, initial_delay => 0.01, backoff_factor => 1.0 );
    };
    ok( $@, 'throws error on repeated HTTP 503 failures' );

    # Verify warnings and errors are captured in the log stream
    $log->contains_ok(qr/Transient error on attempt 1\/2/, 'warn log for transient retry is present');
    $log->contains_ok(qr/Max retry attempts \(2\/2\) reached/, 'error log for max retries failure is present');
};

subtest 'Pluggable credentials WIF Logging' => sub {
    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            executable => {
                command => sprintf('"%s" -e "print q({\"id_token\":\"mock_pluggable_token\"})"', $^X),
            },
        },
    );

    $log->clear();

    my $token = $creds->retrieve_subject_token();
    is( $token, 'mock_pluggable_token', 'retrieved token successfully' );

    $log->contains_ok(qr/Executing Pluggable credential command/, 'info log for executable command start is present');
    $log->contains_ok(qr/Parsing JSON output from Pluggable command/, 'trace log for JSON parsing is present');
    $log->contains_ok(qr/Pluggable subject token retrieved successfully/, 'trace log for retrieval completion is present');
};

done_testing();
