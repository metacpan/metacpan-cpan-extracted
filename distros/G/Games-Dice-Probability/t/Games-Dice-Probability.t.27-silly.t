# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.21-silly.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 26 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("(2d6+2)+(1d4)-(3d3+1)");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-5);
ok($diceobj->max(),14);
ok($diceobj->bounds()->[0],-5);
ok($diceobj->bounds()->[1],14);
ok($diceobj->probability(-5),0.000257201646090535);
ok($diceobj->probability(-4),0.00154320987654321);
ok($diceobj->probability(-3),0.00540123456790123);
ok($diceobj->probability(-2),0.0136316872427984);
ok($diceobj->probability(-1),0.0275205761316872);
ok($diceobj->probability(0),0.0470679012345679);
ok($diceobj->probability(1),0.0704732510288066);
ok($diceobj->probability(2),0.0943930041152263);
ok($diceobj->probability(3),0.114197530864198);
ok($diceobj->probability(4),0.125514403292181);
ok($diceobj->probability(5),0.125514403292181);
ok($diceobj->probability(6),0.114197530864198);
ok($diceobj->probability(7),0.0943930041152263);
ok($diceobj->probability(8),0.0704732510288066);
ok($diceobj->probability(9),0.0470679012345679);
ok($diceobj->probability(10),0.0275205761316872);
ok($diceobj->probability(11),0.0136316872427984);
ok($diceobj->probability(12),0.00540123456790123);
ok($diceobj->probability(13),0.00154320987654321);
ok($diceobj->probability(14),0.000257201646090535);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

