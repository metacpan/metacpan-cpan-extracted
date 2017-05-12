# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.02-2d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 28 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("2d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),2);
ok($diceobj->max(),12);
ok($diceobj->bounds()->[0],2);
ok($diceobj->bounds()->[1],12);
ok($diceobj->combinations(2),1);
ok($diceobj->combinations(3),2);
ok($diceobj->combinations(4),3);
ok($diceobj->combinations(5),4);
ok($diceobj->combinations(6),5);
ok($diceobj->combinations(7),6);
ok($diceobj->combinations(8),5);
ok($diceobj->combinations(9),4);
ok($diceobj->combinations(10),3);
ok($diceobj->combinations(11),2);
ok($diceobj->combinations(12),1);
ok($diceobj->probability(2),0.0277777777777778);
ok($diceobj->probability(3),0.0555555555555556);
ok($diceobj->probability(4),0.0833333333333333);
ok($diceobj->probability(5),0.111111111111111);
ok($diceobj->probability(6),0.138888888888889);
ok($diceobj->probability(7),0.166666666666667);
ok($diceobj->probability(8),0.138888888888889);
ok($diceobj->probability(9),0.111111111111111);
ok($diceobj->probability(10),0.0833333333333333);
ok($diceobj->probability(11),0.0555555555555556);
ok($diceobj->probability(12),0.0277777777777778);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

