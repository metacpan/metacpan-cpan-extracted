# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-SharedConf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Lemonldap::NG::Handler::Main::Jail') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(
    my $jail = Lemonldap::NG::Handler::Main::Jail->new(
        'jail'            => undef,
        'useSafeJail'     => 0,
        'customFunctions' => undef
    ),
    'new fake jail object'
);
$jail->build_jail();

my $sub1 = "sub { return( basic('login','password') ) }";
my $basic;
ok( $basic = $jail->jail_reval($sub1), 'Compilation succeed' )
  or print STDERR $jail->error . "\n";
like(
    &$basic,
    '/^Basic bG9naW46cGFzc3dvcmQ=$/',
    'basic extended function working without Safe Jail'
);

my $sub2          = "sub { return ( encode_base64('test') ) }";
my $encode_base64 = $jail->jail_reval($sub2);
like( &$encode_base64, '/^dGVzdA==$/',
    'encode_base64 extended function working without Safe Jail' );

my $sub3      = "sub { return(checkDate('20000000000000','21000000000000')) }";
my $checkDate = $jail->jail_reval($sub3);
ok( &$checkDate == "1",
    'checkDate extended function working without Safe Jail' );
