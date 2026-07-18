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

BEGIN
{
    use_ok('Google::Auth::ExternalAccountCredentials') || print "Bail out!\n";
}

subtest 'Pluggable WIF Initialization and Factory' => sub {
    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            executable => {
                command => 'echo 1',
            },
        },
    );

    ok( defined $creds, 'Pluggable credentials object created via factory' );
    isa_ok( $creds, 'Google::Auth::ExternalAccountCredentials::Pluggable' );
};

subtest 'Pluggable WIF Success JSON Output' => sub {
    my $command = sprintf('"%s" -e "print q({\"my_token_field\":\"mock_pluggable_token\"})"', $^X);
    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            executable => {
                command => $command,
            },
            format => {
                type                     => 'json',
                subject_token_field_name => 'my_token_field',
            },
        },
    );

    my $token = $creds->retrieve_subject_token();
    is( $token, 'mock_pluggable_token', 'parses custom subject_token_field_name correctly' );
};

subtest 'Pluggable WIF Success Text Output' => sub {
    my $command = '"' . $^X . '" -e "print q(raw-plain-text-token)"';
    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            executable => {
                command => $command,
            },
            format => {
                type => 'text',
            },
        },
    );

    my $token = $creds->retrieve_subject_token();
    is( $token, 'raw-plain-text-token', 'returns raw output with newline stripped' );
};

subtest 'Pluggable WIF Environment Variable Injection' => sub {
    # Command that prints a JSON containing the value of the environment variable MOCK_ENV_VAR
    # We use perl to print it portably
    my $env_sigil = $^O eq 'MSWin32' ? '$' : '\$';
    my $command = '"' . $^X . '" -e "print q({) . chr(34) . q(id_token) . chr(34) . q(:) . chr(34) . ' . $env_sigil . 'ENV{MOCK_ENV_VAR} . chr(34) . q(})"';

    my $creds = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            executable => {
                command               => $command,
                environment_variables => {
                    MOCK_ENV_VAR => 'injected-env-value',
                },
            },
        },
    );

    my $token = $creds->retrieve_subject_token();
    is( $token, 'injected-env-value', 'successfully injected environment variable into command execution context' );
};

subtest 'Pluggable WIF Error Handling' => sub {
    # Command that produces invalid JSON
    my $bad_json_command = '"' . $^X . '" -e "print q({) . chr(34) . q(invalid_json:)"';
    my $creds_bad_json = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            executable => {
                command => $bad_json_command,
            },
        },
    );

    eval {
        $creds_bad_json->retrieve_subject_token();
    };
    like( $@, qr/Failed to parse JSON from pluggable command output/, 'throws when command output is invalid JSON' );

    # Command that fails to execute (invalid command name)
    my $invalid_cmd = 'non_existent_pluggable_command_12345';
    my $creds_invalid = Google::Auth::ExternalAccountCredentials->make_creds(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            executable => {
                command => $invalid_cmd,
            },
        },
    );

    eval {
        $creds_invalid->retrieve_subject_token();
    };
    ok( $@, 'throws when pluggable command fails to execute or exits with error' );
};

done_testing();
