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
            portalRequireOldPassword    => 1,
            passwordPolicyMinSize       => 6,
            passwordPolicyMinLower      => 3,
            passwordPolicyMinUpper      => 3,
            passwordPolicyMinDigit      => 1,
            passwordPolicyMinSpeChar    => 2,
            passwordPolicySpecialChar   => '   [  } \   ',
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

# Test min size
# -------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=test&confirmpassword=test'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 54
    ),
    'Password min size not respected'
);
expectBadRequest($res);

ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_PASSWORD_TOO_SHORT,
    'Response is PE_PP_PASSWORD_TOO_SHORT'
) or explain( $json, "error => 29" );
count(3);

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=TESTis0k\}&confirmpassword=TESTis0k\}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 66
    ),
    'Password min size respected'
);
expectOK($res);
count(1);

# Test min lower
# --------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=TESTLOWer&confirmpassword=TESTLOWer'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 64
    ),
    'Password min lower not respected'
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
'oldpassword=dwho&newpassword=TESTl0wer\}&confirmpassword=TESTl0wer\}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Password min lower respected'
);
expectOK($res);
count(1);

# Test min upper
# --------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=testUPper&confirmpassword=testUPper'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 64
    ),
    'Password min upper not respected'
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
'oldpassword=dwho&newpassword=t3stUPPER\}&confirmpassword=t3stUPPER\}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Password min upper respected'
);
expectOK($res);
count(1);

# Test min digit
# --------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=testDIGIT&confirmpassword=testDIGIT'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 64
    ),
    'Password min digit not respected'
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
'oldpassword=dwho&newpassword=t3stDIGIT\}&confirmpassword=t3stDIGIT\}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Password min digit respected'
);
expectOK($res);
count(1);

# Test min special char
# ---------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=t3stDIGIT}&confirmpassword=t3stDIGIT}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 66
    ),
    'Password min special char not respected'
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
'oldpassword=dwho&newpassword=t3stDIGIT}@&confirmpassword=t3stDIGIT}@'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Password min special char not respected'
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
'oldpassword=dwho&newpassword=t3stDIGIT}@}&confirmpassword=t3stDIGIT}@}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 70
    ),
    'Password special char not allowed'
);
expectBadRequest($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_NOT_ALLOWED_CHARACTER,
    'Response is PE_PP_NOT_ALLOWED_CHARACTER'
) or explain( $json, "error => 100" );
count(3);

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
'oldpassword=dwho&newpassword=t3stDIGIT}@#}&confirmpassword=t3stDIGIT}@#}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 72
    ),
    'Password special chars not allowed'
);
expectBadRequest($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_NOT_ALLOWED_CHARACTERS,
    'Response is PE_PP_NOT_ALLOWED_CHARACTERS'
) or explain( $json, "error => 100" );
count(3);

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
'oldpassword=dwho&newpassword=t3stDIGIT\}&confirmpassword=t3stDIGIT\}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Password min special char respected'
);
expectOK($res);
count(1);

ok(
    $res =
      $client->_get( '/', cookie => "lemonldap=$id", accept => 'text/html' ),
    'Get Menu'
);
ok(
    $res->[2]->[0] =~
      m%<span trspan="passwordPolicyMinSize">Minimal size:</span> 6%,
    ' passwordPolicyMinSize'
) or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSize' );
ok(
    $res->[2]->[0] =~
m%<span trspan="passwordPolicyMinLower">Minimal lower characters:</span> 3%,
    ' passwordPolicyMinLower'
) or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinLower' );
ok(
    $res->[2]->[0] =~
m%<span trspan="passwordPolicyMinUpper">Minimal upper characters:</span> 3%,
    ' passwordPolicyMinUpper'
) or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinUpper' );
ok(
    $res->[2]->[0] =~
m%<span trspan="passwordPolicyMinDigit">Minimal digit characters:</span> 1%,
    ' passwordPolicyMinDigit'
) or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinDigit' );
ok(
    $res->[2]->[0] =~
m%<span trspan="passwordPolicyMinSpeChar">Minimal special characters:</span> 2%,
    ' passwordPolicyMinSpeChar'
) or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSpeChar' );
ok(
    $res->[2]->[0] =~
m%\Q<span trspan="passwordPolicySpecialChar">Allowed special characters:</span> [ } \E%,
    ' passwordPolicySpecialChar'
) or print STDERR Dumper( $res->[2]->[0], 'passwordPolicySpecialChar' );
ok( $res->[2]->[0] !~ m%class="fa fa-eye-slash toggle-password">%,
    ' no toggle icon found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(8);

# Test $client->logout
$client->logout($id);

clean_sessions();

done_testing( count() );
