# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.18-4df.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 15 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("4df");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-4);
ok($diceobj->max(),4);
ok($diceobj->bounds()->[0],-4);
ok($diceobj->bounds()->[1],4);
ok($diceobj->probability(-4),0.0123456790123457);
ok($diceobj->probability(-3),0.0493827160493827);
ok($diceobj->probability(-2),0.123456790123457);
ok($diceobj->probability(-1),0.197530864197531);
ok($diceobj->probability(0),0.234567901234568);
ok($diceobj->probability(1),0.197530864197531);
ok($diceobj->probability(2),0.123456790123457);
ok($diceobj->probability(3),0.0493827160493827);
ok($diceobj->probability(4),0.0123456790123457);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

