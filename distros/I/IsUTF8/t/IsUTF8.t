# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IsUTF8.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2 + 2 * map { $_ } glob("t/data*");

# Test 1
BEGIN { use_ok('IsUTF8', 0.2, "isUTF8") };

# Test 2
is($IsUTF8::VERSION, 0.2, "Version");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{

    local @ARGV = glob("t/data*");
    while (<>) {
	my ($expect) = /^(\w+)/;

	my $r1 = isUTF8;
	my $r2 = isUTF8($_);
	my $r3 = defined $r1 ? $r1 ? "UTF" : "NONE" : "OTHER";

	is($r1, $r2, "comparison of results");
	is($r3, $expect, "detection of $expect");

    }
}
