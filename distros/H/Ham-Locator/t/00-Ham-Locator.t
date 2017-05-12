# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IPTables-Log.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok('Ham::Locator') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Create new IPTables::Log object
my $l = new_ok( Ham::Locator );
# Check it's of the correct type
ok(ref($l) eq "Ham::Locator",								"Object is of type Ham::Locator");

diag("Testing methods");
can_ok($l, qw(latlng2loc loc2latlng n2l l2n));

diag("Testing loc2latlng...");
$l->set_loc("IO93lo72hn");
my @latlng = $l->loc2latlng();
like($latlng[0], qr/^53.593923/,							"Correct latitude returned");
like($latlng[1], qr/^-1.022569/,							"Correct longitude returned");

diag("Testing latlng2loc...");
$l->set_latlng((53.593923, -1.022569));
my $loc = $l->latlng2loc();
like($loc, qr/IO93lo72hn/,									"Correct locator returned");

diag("Testing precision (to 8 places)...");
$l->set_precision(8);
$loc = $l->latlng2loc();
like($loc, qr/IO93lo72/,									"Correct locator returned (to 6 places)");

diag("Testing precision (to 6 places)...");
$l->set_precision(6);
$loc = $l->latlng2loc();
like($loc, qr/IO93lo/,										"Correct locator returned (to 6 places)");

diag("Testing precision (to 4 places)...");
$l->set_precision(4);
$loc = $l->latlng2loc();
like($loc, qr/IO93/,										"Correct locator returned (to 4 places)");

diag("Testing precision (to 2 places)...");
$l->set_precision(2);
$loc = $l->latlng2loc();
like($loc, qr/IO/,											"Correct locator returned (to 4 places)");

