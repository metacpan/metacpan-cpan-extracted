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

use strict;
use warnings;

use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::PP;
use File::Temp qw(tempfile);

BEGIN
{
    use_ok('Google::Auth::ExternalAccountCredentials') || print "Bail out!\n";
}

subtest 'Subject Token from File and STS Exchange' => sub {
    my $mock_ua = Test::LWP::UserAgent->new();

    my ($fh, $temp_filename) = tempfile( UNLINK => 1 );
    print $fh 'my-file-subject-token';
    close($fh);

    my $creds = Google::Auth::ExternalAccountCredentials->new(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            file => $temp_filename,
        },
        ua => $mock_ua,
    );

    ok( defined $creds, 'credentials object created' );

    $mock_ua->map_response(
        sub {
            my ($request) = @_;
            return $request->url eq 'https://sts.googleapis.com/v1/token'
               && $request->content =~ /subject_token=my-file-subject-token/
               && $request->content =~ /audience=.*my-provider/;
        },
        HTTP::Response->new(
            200, 'OK',
            [ 'Content-Type' => 'application/json' ],
            encode_json({
                access_token => 'mock-sts-google-token',
                issued_token_type => 'urn:ietf:params:oauth:token-type:access_token',
                token_type => 'Bearer',
                expires_in => 3600
            })
        )
    );

    my $token = $creds->fetch_access_token();
    is( $token, 'mock-sts-google-token', 'STS exchanged token matches' );
    is( $creds->access_token, 'mock-sts-google-token', 'cached token matches' );
    ok( defined $creds->expires_at, 'expiration calculated' );
};

subtest 'Subject Token from URL and Impersonated Exchange' => sub {
    my $mock_ua = Test::LWP::UserAgent->new();

    my $creds = Google::Auth::ExternalAccountCredentials->new(
        audience                          => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type                => 'urn:ietf:params:oauth:token-type:jwt',
        token_url                         => 'https://sts.googleapis.com/v1/token',
        credential_source                 => {
            url     => 'http://169.254.169.254/metadata/identity/oauth2/token',
            headers => {
                Metadata => 'true',
            },
            format => {
                type                     => 'json',
                subject_token_field_name => 'id_token'
            }
        },
        service_account_impersonation_url => 'https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/target-sa@google.com:generateAccessToken',
        ua                                => $mock_ua,
    );

    $mock_ua->map_response(
        sub {
            my ($request) = @_;
            return $request->url eq 'http://169.254.169.254/metadata/identity/oauth2/token'
               && $request->header('Metadata') eq 'true';
        },
        HTTP::Response->new(
            200, 'OK',
            [ 'Content-Type' => 'application/json' ],
            encode_json({
                id_token => 'url-subject-token'
            })
        )
    );

    $mock_ua->map_response(
        sub {
            my ($request) = @_;
            return $request->url eq 'https://sts.googleapis.com/v1/token'
               && $request->content =~ /subject_token=url-subject-token/;
        },
        HTTP::Response->new(
            200, 'OK',
            [ 'Content-Type' => 'application/json' ],
            encode_json({
                access_token => 'mock-sts-google-token',
                expires_in => 3600
            })
        )
    );

    $mock_ua->map_response(
        sub {
            my ($request) = @_;
            return $request->url eq 'https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/target-sa@google.com:generateAccessToken'
               && $request->header('Authorization') eq 'Bearer mock-sts-google-token';
        },
        HTTP::Response->new(
            200, 'OK',
            [ 'Content-Type' => 'application/json' ],
            encode_json({
                accessToken => 'mock-final-impersonated-token',
                expireTime  => '2026-06-02T09:30:00Z'
            })
        )
    );

    my $token = $creds->fetch_access_token();
    is( $token, 'mock-final-impersonated-token', 'impersonated final token matches' );
    is( $creds->access_token, 'mock-final-impersonated-token', 'cached token matches' );
    is( $creds->expires_at, '2026-06-02T09:30:00Z', 'expiration matches' );
};

subtest 'Load from JSON configuration' => sub {
    my $json_config = {
        type                              => 'external_account',
        audience                          => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type                => 'urn:ietf:params:oauth:token-type:jwt',
        token_url                         => 'https://sts.googleapis.com/v1/token',
        credential_source                 => {
            file => '/var/run/secrets/token',
        },
        service_account_impersonation_url => 'https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/target-sa@google.com:generateAccessToken',
    };

    require Google::Auth::DefaultCredentials;
    my $creds = Google::Auth::DefaultCredentials->make_creds(
        json_key => $json_config,
    );

    ok( defined $creds, 'loaded credentials successfully' );
    isa_ok( $creds, 'Google::Auth::ExternalAccountCredentials' );
    is( $creds->audience, '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider', 'audience matches' );
    is( $creds->credential_source->{file}, '/var/run/secrets/token', 'file source matches' );
    is( $creds->service_account_impersonation_url, 'https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/target-sa@google.com:generateAccessToken', 'impersonation url matches' );
};

subtest 'Initialization and Validation Errors' => sub {
    my $base_opts = {
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
    };

    # 1. Missing credential_source
    eval {
        Google::Auth::ExternalAccountCredentials->new(
            %$base_opts,
        );
    };
    like( $@, qr/Missing required arguments: credential_source/, 'throws error on missing credential_source' );

    # 2. Invalid options environment_id
    eval {
        Google::Auth::ExternalAccountCredentials->new(
            %$base_opts,
            credential_source => {
                url            => 'http://dummyurl.com',
                environment_id => 'aws1'
            }
        );
    };
    like( $@, qr/Invalid Identity Pool credential_source field 'environment_id'/, 'throws error on environment_id' );

    # 3. Ambiguous credential source (file and url conflict)
    eval {
        Google::Auth::ExternalAccountCredentials->new(
            %$base_opts,
            credential_source => {
                file => '/tmp/token',
                url  => 'http://dummyurl.com'
            }
        );
    };
    like( $@, qr/Ambiguous credential_source. 'file' is mutually exclusive with 'url'/, 'throws error on file/url conflict' );

    # 4. Missing both file and url in credential_source
    eval {
        Google::Auth::ExternalAccountCredentials->new(
            %$base_opts,
            credential_source => {}
        );
    };
    like( $@, qr/Missing credential_source. A 'file' or 'url' must be provided./, 'throws error on empty credential_source' );

    # 5. Invalid credential source format format type
    eval {
        Google::Auth::ExternalAccountCredentials->new(
            %$base_opts,
            credential_source => {
                url    => 'http://dummyurl.com',
                format => { type => 'invalid_format' }
            }
        );
    };
    like( $@, qr/Invalid credential_source format invalid_format/, 'throws error on invalid format' );

    # 6. Missing field name for JSON format
    eval {
        Google::Auth::ExternalAccountCredentials->new(
            %$base_opts,
            credential_source => {
                url    => 'http://dummyurl.com',
                format => { type => 'json' }
            }
        );
    };
    like( $@, qr/Missing subject_token_field_name for JSON credential_source format/, 'throws error on missing json field name' );
};

subtest 'STS Exchange Failure' => sub {
    my $mock_ua = Test::LWP::UserAgent->new();
    my ($fh, $temp_filename) = tempfile( UNLINK => 1 );
    print $fh 'my-file-subject-token';
    close($fh);

    my $creds = Google::Auth::ExternalAccountCredentials->new(
        audience           => '//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/my-pool/providers/my-provider',
        subject_token_type => 'urn:ietf:params:oauth:token-type:jwt',
        token_url          => 'https://sts.googleapis.com/v1/token',
        credential_source  => {
            file => $temp_filename,
        },
        ua => $mock_ua,
    );

    $mock_ua->map_response(
        sub {
            my ($request) = @_;
            return $request->url eq 'https://sts.googleapis.com/v1/token';
        },
        HTTP::Response->new(
            400, 'Bad Request',
            [ 'Content-Type' => 'application/json' ],
            encode_json({
                error             => 'invalid_grant',
                error_description => 'The subject token is invalid or expired'
            })
        )
    );

    eval {
        $creds->fetch_access_token();
    };
    like( $@, qr/Token exchange failed with status 400/, 'throws detailed error on STS failure' );
};

done_testing();
