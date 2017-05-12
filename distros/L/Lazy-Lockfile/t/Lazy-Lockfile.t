# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lazy-Lockfile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Lazy::Lockfile') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $lock = Lazy::Lockfile->new();
ok( $lock );

my $lock2 = Lazy::Lockfile->new();
ok( !defined $lock2 );

ok( $lock->unlock() );

$lock2 = Lazy::Lockfile->new();
ok( $lock2 );

