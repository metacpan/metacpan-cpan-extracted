# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.21-mid8.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 22 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("mid8");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),1);
ok($diceobj->max(),8);
ok($diceobj->bounds()->[0],1);
ok($diceobj->bounds()->[1],8);
ok($diceobj->combinations(1),22);
ok($diceobj->combinations(2),58);
ok($diceobj->combinations(3),82);
ok($diceobj->combinations(4),94);
ok($diceobj->combinations(5),94);
ok($diceobj->combinations(6),82);
ok($diceobj->combinations(7),58);
ok($diceobj->combinations(8),22);
ok($diceobj->probability(1),0.04296875);
ok($diceobj->probability(2),0.11328125);
ok($diceobj->probability(3),0.16015625);
ok($diceobj->probability(4),0.18359375);
ok($diceobj->probability(5),0.18359375);
ok($diceobj->probability(6),0.16015625);
ok($diceobj->probability(7),0.11328125);
ok($diceobj->probability(8),0.04296875);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

