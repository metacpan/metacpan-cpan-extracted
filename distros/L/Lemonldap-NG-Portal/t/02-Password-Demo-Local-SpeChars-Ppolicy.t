use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants
  'PE_PP_INSUFFICIENT_PASSWORD_QUALITY';

require 't/test-lib.pm';

my ( $res, $json );

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            passwordDB                  => 'Demo',
            portalRequireOldPassword    => 1,
            passwordPolicyMinSize       => 0,
            passwordPolicyMinLower      => 0,
            passwordPolicyMinUpper      => 0,
            passwordPolicyMinDigit      => 0,
            passwordPolicyMinSpeChar    => 2,
            passwordPolicySpecialChar   => '__ALL__',
            portalDisplayPasswordPolicy => 1
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

ok(
    $res =
      $client->_get( '/', cookie => "lemonldap=$id", accept => 'text/html' ),
    'Get Menu'
);
ok( $res->[2]->[0] =~ m%<input id="oldpassword" name="oldpassword"%,
    ' Old password input' )
  or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
m%<span trspan="passwordPolicyMinSpeChar">Minimal special characters:</span> 2%,
    ' passwordPolicyMinSpeChar'
) or print STDERR Dumper( $res->[2]->[0] );
count(3);

my $query = 'oldpassword=dwho&newpassword=@test&confirmpassword=@test';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
    ),
    'Password min special char policy not respected'
);
expectBadRequest($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
    'Response is PE_PP_INSUFFICIENT_PASSWORD_QUALITY'
) or explain( $json, "error => 28" );
count(3);

$query = 'oldpassword=dwho&newpassword=@%&confirmpassword=@%';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
    ),
    'Password min special char respected'
);
expectOK($res);
count(1);

# Test $client->logout
$client->logout($id);

clean_sessions();

done_testing( count() );
