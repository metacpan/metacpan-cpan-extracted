# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.21-mid12.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 30 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("mid12");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),1);
ok($diceobj->max(),12);
ok($diceobj->bounds()->[0],1);
ok($diceobj->bounds()->[1],12);
ok($diceobj->combinations(1),34);
ok($diceobj->combinations(2),94);
ok($diceobj->combinations(3),142);
ok($diceobj->combinations(4),178);
ok($diceobj->combinations(5),202);
ok($diceobj->combinations(6),214);
ok($diceobj->combinations(7),214);
ok($diceobj->combinations(8),202);
ok($diceobj->combinations(9),178);
ok($diceobj->combinations(10),142);
ok($diceobj->combinations(11),94);
ok($diceobj->combinations(12),34);
ok($diceobj->probability(1),0.0196759259259259);
ok($diceobj->probability(2),0.0543981481481481);
ok($diceobj->probability(3),0.0821759259259259);
ok($diceobj->probability(4),0.103009259259259);
ok($diceobj->probability(5),0.116898148148148);
ok($diceobj->probability(6),0.123842592592593);
ok($diceobj->probability(7),0.123842592592593);
ok($diceobj->probability(8),0.116898148148148);
ok($diceobj->probability(9),0.103009259259259);
ok($diceobj->probability(10),0.0821759259259259);
ok($diceobj->probability(11),0.0543981481481481);
ok($diceobj->probability(12),0.0196759259259259);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

