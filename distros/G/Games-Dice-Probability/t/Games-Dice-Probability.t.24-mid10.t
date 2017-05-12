# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.21-mid10.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 26 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("mid10");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),1);
ok($diceobj->max(),10);
ok($diceobj->bounds()->[0],1);
ok($diceobj->bounds()->[1],10);
ok($diceobj->combinations(1),28);
ok($diceobj->combinations(2),76);
ok($diceobj->combinations(3),112);
ok($diceobj->combinations(4),136);
ok($diceobj->combinations(5),148);
ok($diceobj->combinations(6),148);
ok($diceobj->combinations(7),136);
ok($diceobj->combinations(8),112);
ok($diceobj->combinations(9),76);
ok($diceobj->combinations(10),28);
ok($diceobj->probability(1),0.028);
ok($diceobj->probability(2),0.076);
ok($diceobj->probability(3),0.112);
ok($diceobj->probability(4),0.136);
ok($diceobj->probability(5),0.148);
ok($diceobj->probability(6),0.148);
ok($diceobj->probability(7),0.136);
ok($diceobj->probability(8),0.112);
ok($diceobj->probability(9),0.076);
ok($diceobj->probability(10),0.028);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

