use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_PP_PASSWORD_TOO_LONG
  PE_PP_PASSWORD_TOO_SHORT
  PE_PP_NOT_ALLOWED_CHARACTER
  PE_PP_NOT_ALLOWED_CHARACTERS
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY
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
            passwordPolicyMaxSize       => 14,
            passwordPolicyMinLower      => 3,
            passwordPolicyMinUpper      => 3,
            passwordPolicyMinDigit      => 1,
            passwordPolicyMinSpeChar    => 2,
            passwordPolicySpecialChar   => '[ }\ }',
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
my $query = 'oldpassword=dwho&newpassword=test&confirmpassword=test';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

# Test max size
# -------------
$query =
'oldpassword=dwho&newpassword=testtesttesttest&confirmpassword=testtesttesttest';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
    ),
    'Password max size not respected'
);
expectBadRequest($res);

ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_PASSWORD_TOO_LONG,
    'Response is PE_PP_PASSWORD_TOO_LONG'
) or explain( $json, "error => 111" );
count(3);

$query = 'oldpassword=dwho&newpassword=T ESTis0k\}&confirmpassword=T ESTis0k\}';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
    ),
    'Password min size respected'
);
expectOK($res);
count(1);

# Test min lower
# --------------
$query = 'oldpassword=dwho&newpassword=TESTLOWer&confirmpassword=TESTLOWer';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

$query = 'oldpassword=dwho&newpassword=TESTl0wer\}&confirmpassword=TESTl0wer\}';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
    ),
    'Password min lower respected'
);
expectOK($res);
count(1);

# Test min upper
# --------------
$query = 'oldpassword=dwho&newpassword=testUPper&confirmpassword=testUPper';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

$query = 'oldpassword=dwho&newpassword=t3stUPPER\}&confirmpassword=t3stUPPER\}';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
    ),
    'Password min upper respected'
);
expectOK($res);
count(1);

# Test min digit
# --------------
$query = 'oldpassword=dwho&newpassword=testDIGIT&confirmpassword=testDIGIT';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

$query = 'oldpassword=dwho&newpassword=t3stDIGIT\}&confirmpassword=t3stDIGIT\}';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
    ),
    'Password min digit respected'
);
expectOK($res);
count(1);

# Test min special char
# ---------------------
$query = 'oldpassword=dwho&newpassword=t3stDIGIT}&confirmpassword=t3stDIGIT}';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

$query = 'oldpassword=dwho&newpassword=t3stDIGIT}@&confirmpassword=t3stDIGIT}@';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

$query =
  'oldpassword=dwho&newpassword=t3stDIGIT}@}&confirmpassword=t3stDIGIT}@}';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

$query =
  'oldpassword=dwho&newpassword=t3stDIGIT}@#}&confirmpassword=t3stDIGIT}@#}';
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            $query

        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => length($query)
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

$query = 'oldpassword=dwho&newpassword=t3stDIGIT\}&confirmpassword=t3stDIGIT\}';
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

ok(
    $res =
      $client->_get( '/', cookie => "lemonldap=$id", accept => 'text/html' ),
    'Get Menu'
);
ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinSize"></span> 6%,
    ' passwordPolicyMinSize' )
  or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSize' );
ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinLower"></span> 3%,
    ' passwordPolicyMinLower' )
  or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinLower' );
ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinUpper"></span> 3%,
    ' passwordPolicyMinUpper' )
  or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinUpper' );
ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinDigit"></span> 1%,
    ' passwordPolicyMinDigit' )
  or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinDigit' );
ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinSpeChar"></span> 2%,
    ' passwordPolicyMinSpeChar' )
  or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSpeChar' );
ok(
    $res->[2]->[0] =~
      m%\Q<span trspan="passwordPolicySpecialChar"></span> &lt;space&gt; [ \ }%,
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
