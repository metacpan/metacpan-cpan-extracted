# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.03-3d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 38 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("3d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),3);
ok($diceobj->max(),18);
ok($diceobj->bounds()->[0],3);
ok($diceobj->bounds()->[1],18);
ok($diceobj->combinations(3),1);
ok($diceobj->combinations(4),3);
ok($diceobj->combinations(5),6);
ok($diceobj->combinations(6),10);
ok($diceobj->combinations(7),15);
ok($diceobj->combinations(8),21);
ok($diceobj->combinations(9),25);
ok($diceobj->combinations(10),27);
ok($diceobj->combinations(11),27);
ok($diceobj->combinations(12),25);
ok($diceobj->combinations(13),21);
ok($diceobj->combinations(14),15);
ok($diceobj->combinations(15),10);
ok($diceobj->combinations(16),6);
ok($diceobj->combinations(17),3);
ok($diceobj->combinations(18),1);
ok($diceobj->probability(3),0.00462962962962963);
ok($diceobj->probability(4),0.0138888888888889);
ok($diceobj->probability(5),0.0277777777777778);
ok($diceobj->probability(6),0.0462962962962963);
ok($diceobj->probability(7),0.0694444444444444);
ok($diceobj->probability(8),0.0972222222222222);
ok($diceobj->probability(9),0.115740740740741);
ok($diceobj->probability(10),0.125);
ok($diceobj->probability(11),0.125);
ok($diceobj->probability(12),0.115740740740741);
ok($diceobj->probability(13),0.0972222222222222);
ok($diceobj->probability(14),0.0694444444444444);
ok($diceobj->probability(15),0.0462962962962963);
ok($diceobj->probability(16),0.0277777777777778);
ok($diceobj->probability(17),0.0138888888888889);
ok($diceobj->probability(18),0.00462962962962963);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

