use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants
  qw(PE_BADOLDPASSWORD PE_PASSWORD_MISMATCH PE_PP_MUST_SUPPLY_OLD_PASSWORD);

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                 => 'error',
            passwordDB               => 'Demo',
            portalRequireOldPassword => 1,
            customPlugins            => 't::PasswordHookPlugin',
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
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# Test bad new password
my $s = buildForm( {
        oldpassword     => "dwho",
        newpassword     => "12345",
        confirmpassword => "12345",
    }
);
ok(
    $res = $client->_post(
        '/',
        IO::String->new($s),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($s),
    ),
    'Bad new password'
);
count(1);
expectReject( $res, 400, 28 );

# Test good new password
$s = buildForm( {
        oldpassword     => "dwho",
        newpassword     => "12346",
        confirmpassword => "12346",
    }
);
ok(
    $res = $client->_post(
        '/',
        IO::String->new($s),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($s),
    ),
    'Correct new password'
);
count(1);

expectReject( $res, 200, 35, "Expect PE_PASSWORD_OK" );
my $pdata = expectPdata($res);
is( $pdata->{afterHook}, "dwho-dwho-12346",
    "passwordAfterChange hook worked as expected" );
count(1);

# Test $client->logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );
