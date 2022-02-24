# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-SharedConf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
require 't/test.pm';
BEGIN { use_ok('Lemonldap::NG::Handler::Main::Jail') }

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(
    my $jail = Lemonldap::NG::Handler::Main::Jail->new(
        'jail'                 => undef,
        'useSafeJail'          => 0,
        'customFunctions'      => undef,
        'multiValuesSeparator' => '; ',
    ),
    'new fake jail object'
);
$jail->build_jail('Lemonldap::NG::Handler::Test');

my $sub1  = "sub { return( basic('login','password') ) }";
my $basic = $jail->jail_reval($sub1);
like(
    &$basic,
    '/^Basic bG9naW46cGFzc3dvcmQ=$/',
    'basic extended function working without Safe Jail'
);

my $sub2          = "sub { return ( encode_base64('test') ) }";
my $encode_base64 = $jail->jail_reval($sub2);
like( &$encode_base64, '/^dGVzdA==$/',
    'encode_base64 extended function working without Safe Jail' );

my $sub3      = "sub { return(checkDate('20000101000000','21000101000000')) }";
my $checkDate = $jail->jail_reval($sub3);
ok( &$checkDate == "1",
    'checkDate extended function working without Safe Jail' );

my $sub4 =
  "sub { return(checkDate('20000101000000+0100','21000101000000+0100')) }";
$checkDate = $jail->jail_reval($sub4);
ok( &$checkDate == "1",
    'checkDate extended function working without Safe Jail' );

my $sub5      = "sub { return ( listMatch('ABC; DEF; GHI','abc', 1) ) }";
my $listMatch = $jail->jail_reval($sub5);
ok( ( defined($listMatch) and ref($listMatch) eq 'CODE' ),
    'listMatch function is defined' );
ok( &$listMatch eq '1', 'Get good result' );

my $sub6 = "sub { return ( listMatch('ABC; DEF; GHI','ab', 1) ) }";
$listMatch = $jail->jail_reval($sub6);
ok( ( defined($listMatch) and ref($listMatch) eq 'CODE' ),
    'listMatch function is defined' );
ok( &$listMatch eq '0', 'Get good result' );

# Test has2f method
my $sub7  = "sub { return(has2f_internal(\$_[0],\$_[1])) }";
my $has2f = $jail->jail_reval($sub7);
ok(
    ( defined($has2f) and ref($has2f) eq 'CODE' ),
    'checkDate extended function is defined'
);
is(
    $has2f->( {
            _2fDevices =>
"[{\"name\":\"MyTOTP\",\"_secret\":\"g5fsxwf4d34biemlojsbbvhgtskrssos\",\"epoch\":1602173208,\"type\":\"TOTP\"}]"
        },
        "TOTP"
    ),
    1,
    "Function works"
);
is(
    $has2f->( {
            _2fDevices =>
"[{\"name\":\"MyTOTP\",\"_secret\":\"g5fsxwf4d34biemlojsbbvhgtskrssos\",\"epoch\":1602173208,\"type\":\"TOTP\"}]"
        },
    ),
    1,
    "Function works"
);
is(
    $has2f->( {
            _2fDevices =>
"[{\"name\":\"MyTOTP\",\"_secret\":\"g5fsxwf4d34biemlojsbbvhgtskrssos\",\"epoch\":1602173208,\"type\":\"TOTP\"}]"
        },
        "UBK"
    ),
    0,
    "Function works"
);

$sub  = "sub { return(";
$code = $jail->jail_reval($sub);
ok( ( not defined($code) ), 'Syntax error yields undef result' );
like(
    $jail->error,
    qr/Missing right curly or square bracket/,
    'Found correct error message'
);
