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
        'useSafeJail'     => 1,
        'customFunctions' => undef
    ),
    'new jail object'
);
$jail->build_jail();

my $sub1  = "sub { return( basic('login','password') ) }";
my $basic = $jail->jail_reval($sub1);
ok( ( !defined($basic) or defined($basic) ),
    'basic extended function can be undef with recent Safe Jail' );

my $sub2          = "sub { return ( encode_base64('test') ) }";
my $encode_base64 = $jail->jail_reval($sub2);
ok(
    ( !defined($encode_base64) or defined($encode_base64) ),
    'encode_base64 function can be undef with recent Safe Jail'
);

my $sub3      = "sub { return(checkDate('20000000000000','21000000000000')) }";
my $checkDate = $jail->jail_reval($sub3);
ok( ( !defined($checkDate) or defined($checkDate) ),
    'checkDate extended function can be undef with recent Safe Jail' );

# basic and encode_base64 are not supported by safe jail, but checkDate is

ok( &$checkDate == "1", 'checkDate extended function working with Safe Jail' );
