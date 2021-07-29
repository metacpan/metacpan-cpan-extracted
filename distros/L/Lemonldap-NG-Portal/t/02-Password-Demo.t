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
            showLanguages            => 0,
            storePassword            => 1,
            restSessionServer        => 1,
            restExportSecretKeys     => 1,
            error_de_85              => 'From lemonlap-ng.ini',
        }
    }
);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
ok( $res->[2]->[0] !~ m%<span id="languages"></span>%,
    ' No language icon found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%"trOver"%, ' trOver found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%"all":\{\}%, ' all found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%"PE85":"From lemonlap-ng.ini"%, ' PE85 found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(5);

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
ok( $res->[2]->[0] =~ m%<span trmsg="40"></span>%, ' PE40 found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

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

# Test mismatch pwd
ok(
    $res = $client->_post(
        '/',
        IO::String->new('oldpassword=dwho&newpassword=test&confirmpassword=t'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 51
    ),
    'Password mismatch'
);
expectBadRequest($res);
my $json;
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_PASSWORD_MISMATCH, 'Response is PE_PASSWORD_MISMATCH' )
  or explain( $json, "error => 34" );
count(3);

# Test missing old pwd
ok(
    $res = $client->_post(
        '/',
        IO::String->new('newpassword=test&confirmpassword=test'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 37
    ),
    'Missing old password'
);
expectBadRequest($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_MUST_SUPPLY_OLD_PASSWORD,
    'Response is PE_PP_MUST_SUPPLY_OLD_PASSWORD'
) or explain( $json, "error => 27" );
count(3);

# Test bad old pwd
ok(
    $res = $client->_post(
        '/',
        IO::String->new('oldpassword=dd&newpassword=test&confirmpassword=test'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 52
    ),
    'Bad old password'
);
expectBadRequest($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_BADOLDPASSWORD, 'Response is PE_BADOLDPASSWORD' )
  or explain( $json, "error => 27" );
count(3);

# Test good password
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

expectReject( $res, 200, 35, "Expect PE_PASSWORD_OK" );

# Check updated password in session (#2430)
$json =
  expectJSON( $client->_get("/sessions/global/$id"), 'Get session content' );
is( $json->{_password}, "test", "password updated in session" );
count(1);

# Test $client->logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );
