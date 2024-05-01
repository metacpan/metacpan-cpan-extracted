use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel               => 'error',
            passwordDB             => 'Demo',
            storePassword          => 1,
            storePasswordEncrypted => 1,
            restSessionServer      => 1,
            restExportSecretKeys   => 1,
            key                    => 'secret',
            macros                 => { '_decrypted' => 'decrypt($_password)' }
        }
    }
);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# Check encrypted password in session
my $json = getSession($id)->data;
ok( $json->{_password} ne "dwho", "password encrypted in session" );
count(1);

# Check we can decrypt it
ok( $json->{_decrypted} eq "dwho", "password can be decrypted" );
count(1);

$client->logout($id);

clean_sessions();

done_testing( count() );
