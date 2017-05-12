# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.14-3d6dividedby3d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 13 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("3d6/3d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),0);
ok($diceobj->max(),6);
ok($diceobj->bounds()->[0],0);
ok($diceobj->bounds()->[1],6);
ok($diceobj->probability(0),0.453575102880658);
ok($diceobj->probability(1),0.479359567901235);
ok($diceobj->probability(2),0.0556412894375857);
ok($diceobj->probability(3),0.00904492455418381);
ok($diceobj->probability(4),0.00195044581618656);
ok($diceobj->probability(5),0.000407235939643347);
ok($diceobj->probability(6),2.14334705075446e-05);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

