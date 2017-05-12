# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.21-mid4.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 14 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("mid4");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),1);
ok($diceobj->max(),4);
ok($diceobj->bounds()->[0],1);
ok($diceobj->bounds()->[1],4);
ok($diceobj->combinations(1),10);
ok($diceobj->combinations(2),22);
ok($diceobj->combinations(3),22);
ok($diceobj->combinations(4),10);
ok($diceobj->probability(1),0.15625);
ok($diceobj->probability(2),0.34375);
ok($diceobj->probability(3),0.34375);
ok($diceobj->probability(4),0.15625);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

