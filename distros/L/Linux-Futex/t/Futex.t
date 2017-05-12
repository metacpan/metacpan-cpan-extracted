# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Futex.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Linux::Futex') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Linux::Futex;
eval { Linux::Futex::addr("  "); };
like( $@, qr/at least four/, 'get address of short mutex');
my $buf = pack("L", 26);
my $m0 = Linux::Futex::addr($buf);
ok( !defined(Linux::Futex::init($m0)), 'init test');
my $v0 = unpack("L", $buf);
is( $v0, 0, 'initialize mutex test');
ok( !defined(Linux::Futex::lock($m0)), 'lock test');
my $v1 = unpack("L", $buf);
is( $v1, 1, 'locked mutex value test');
ok( !defined(Linux::Futex::unlock($m0)), 'unlock test');
my $v2 = unpack("L", $buf);
is( $v2, 0, 'unlocked mutex value test');
