use Test::More;
use strict;
use IO::String;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_PP_PASSWORD_TOO_SHORT PE_PP_INSUFFICIENT_PASSWORD_QUALITY
  PE_PP_NOT_ALLOWED_CHARACTER PE_PP_NOT_ALLOWED_CHARACTERS
);

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            passwordDB                  => 'Demo',
            portalRequireOldPassword    => 1,
            passwordPolicyMinSize       => 0,
            passwordPolicyMinLower      => 0,
            passwordPolicyMinUpper      => 0,
            passwordPolicyMinDigit      => 0,
            passwordPolicyMinSpeChar    => 0,
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
ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyNone">%,
    ' passwordPolicyNone' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

# Test $client->logout
$client->logout($id);

clean_sessions();

done_testing( count() );
