# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.01-1d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 18 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("1d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),1);
ok($diceobj->max(),6);
ok($diceobj->bounds()->[0],1);
ok($diceobj->bounds()->[1],6);
ok($diceobj->combinations(1),1);
ok($diceobj->combinations(2),1);
ok($diceobj->combinations(3),1);
ok($diceobj->combinations(4),1);
ok($diceobj->combinations(5),1);
ok($diceobj->combinations(6),1);
ok($diceobj->probability(1),0.166666666666667);
ok($diceobj->probability(2),0.166666666666667);
ok($diceobj->probability(3),0.166666666666667);
ok($diceobj->probability(4),0.166666666666667);
ok($diceobj->probability(5),0.166666666666667);
ok($diceobj->probability(6),0.166666666666667);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

