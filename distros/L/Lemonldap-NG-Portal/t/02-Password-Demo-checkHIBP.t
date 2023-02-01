use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_PP_PASSWORD_TOO_SHORT PE_PP_INSUFFICIENT_PASSWORD_QUALITY
  PE_PP_NOT_ALLOWED_CHARACTER PE_PP_NOT_ALLOWED_CHARACTERS
);

require 't/test-lib.pm';

my ( $res, $json );

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            passwordDB                  => 'Demo',
            passwordPolicy              => 1,
            portalRequireOldPassword    => 0,
            passwordPolicyMinSize       => 6,
            passwordPolicyMinLower      => 0,
            passwordPolicyMinUpper      => 0,
            passwordPolicyMinDigit      => 0,
            passwordPolicyMinSpeChar    => 0,
            passwordPolicySpecialChar   => '[ }\ }',
            portalDisplayPasswordPolicy => 1,
            checkHIBP                   => 1,
            checkHIBPURL                => 'https://api.pwnedpasswords.com/range/',
            checkHIBPRequired           => 1,
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

# Test HIBP API
# -------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=secret&confirmpassword=secret'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 58
    ),
    'Simple password found in HIBP database'
);
expectBadRequest($res);

ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
    'Response is PE_PP_INSUFFICIENT_PASSWORD_QUALITY'
) or explain( $json, "error => 28" );
count(3);

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
'oldpassword=dwho&newpassword=T ESTis0k\}&confirmpassword=T ESTis0k\}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Complex password not found in HIBP database'
);
expectOK($res);
count(1);

# Test $client->logout
$client->logout($id);

clean_sessions();

done_testing( count() );
