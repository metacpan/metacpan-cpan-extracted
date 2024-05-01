use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';
require 't/smtp.pm';

my $res;

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel                 => 'error',
            passwordDB               => 'Demo',
            portalRequireOldPassword => 1,
            storePassword            => 1,
            restSessionServer        => 1,
            restExportSecretKeys     => 1,
            mailOnPasswordChange     => 1,
        }
    }
);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
count(1);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho*&password=dwho'),
        accept => 'text/html',
        length => 24
    ),
    'Auth query'
);
count(1);

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

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=test&confirmpassword=test'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 54
    ),
    'Correct password'
);
count(1);

# Check updated password in session
is( getSession($id)->data->{_password}, "test", "password updated in session" );
count(1);

# Check mail is sent
like( mail(), qr#<span>Hello</span>#, "Found english greeting" );
count(1);

# Test $client->logout
$client->logout($id);

clean_sessions();

done_testing( count() );
