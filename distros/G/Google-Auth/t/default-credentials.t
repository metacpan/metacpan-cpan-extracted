#!/perl -T
# Copyright 2022 Google LLC
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
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);
use JSON::PP;

use Google::Auth;
use Google::Auth::DefaultCredentials;

# Clean up the environment first to ensure test isolation
delete $ENV{GOOGLE_APPLICATION_CREDENTIALS};
delete $ENV{GOOGLE_CLOUD_PROJECT};
delete $ENV{GOOGLE_PRIVATE_KEY};
delete $ENV{GOOGLE_CLIENT_EMAIL};
$ENV{HOME}        = '/nonexistent/home';
$ENV{APPDATA}     = '/nonexistent/appdata';
delete $ENV{ProgramData};
delete $ENV{CLOUDSDK_CONFIG};



subtest 'from_env loading valid service account credentials' => sub {
    my $sa_data = {
        type                        => 'service_account',
        project_id                  => 'test-project-123',
        private_key_id              => 'abcd1234efgh5678',
        private_key                 => '-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----',
        client_email                => 'test-sa@test-project-123.iam.gserviceaccount.com',
        client_id                   => '1234567890',
        auth_uri                    => 'https://accounts.google.com/o/oauth2/auth',
        token_uri                   => 'https://oauth2.googleapis.com/token',
        auth_provider_x509_cert_url => 'https://www.googleapis.com/oauth2/v1/certs',
        client_x509_cert_url        => 'https://www.googleapis.com/robot/v1/metadata/x509/test-sa%40test-project-123.iam.gserviceaccount.com',
    };
    my $sa_json = encode_json($sa_data);

    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    print $fh $sa_json;
    close($fh);

    $ENV{GOOGLE_APPLICATION_CREDENTIALS} = $filename;

    my $creds = eval { Google::Auth->default() };
    is( $@, '', 'no exception thrown' );
    ok( defined $creds, 'credentials returned' );
    isa_ok( $creds, 'Google::Auth::ServiceAccountCredentials' );

    is( $creds->project_id, 'test-project-123', 'project_id matches' );
    is( $creds->client_email, 'test-sa@test-project-123.iam.gserviceaccount.com', 'client_email matches' );
    is( $creds->private_key_id, 'abcd1234efgh5678', 'private_key_id matches' );

    delete $ENV{GOOGLE_APPLICATION_CREDENTIALS};
};

subtest 'from_env loading invalid JSON' => sub {
    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    print $fh 'not a valid json string';
    close($fh);

    $ENV{GOOGLE_APPLICATION_CREDENTIALS} = $filename;

    throws_ok { Google::Auth->default() } qr/JSON|decode/, 'throws JSON decode exception';

    delete $ENV{GOOGLE_APPLICATION_CREDENTIALS};
};

subtest 'from_env loading JSON missing type' => sub {
    my $sa_data = {
        project_id   => 'test-project-123',
        client_email => 'test-sa@test-project-123.iam.gserviceaccount.com',
    };
    my $sa_json = encode_json($sa_data);

    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    print $fh $sa_json;
    close($fh);

    $ENV{GOOGLE_APPLICATION_CREDENTIALS} = $filename;

    throws_ok { Google::Auth->default() } qr/missing the type field/, 'throws type field exception';

    delete $ENV{GOOGLE_APPLICATION_CREDENTIALS};
};

subtest 'from_env with non-existent file' => sub {
    $ENV{GOOGLE_APPLICATION_CREDENTIALS} = '/nonexistent/file/path.json';

    throws_ok { Google::Auth->default() } qr/Your credentials were not found|does not exist/, 'throws error on non-existent credentials file';

    delete $ENV{GOOGLE_APPLICATION_CREDENTIALS};
};

done_testing();
