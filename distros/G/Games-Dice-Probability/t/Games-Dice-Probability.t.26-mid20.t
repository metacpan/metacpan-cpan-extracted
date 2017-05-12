# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.21-mid20.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 46 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("mid20");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),1);
ok($diceobj->max(),20);
ok($diceobj->bounds()->[0],1);
ok($diceobj->bounds()->[1],20);
ok($diceobj->combinations(1),58);
ok($diceobj->combinations(2),166);
ok($diceobj->combinations(3),262);
ok($diceobj->combinations(4),346);
ok($diceobj->combinations(5),418);
ok($diceobj->combinations(6),478);
ok($diceobj->combinations(7),526);
ok($diceobj->combinations(8),562);
ok($diceobj->combinations(9),586);
ok($diceobj->combinations(10),598);
ok($diceobj->combinations(11),598);
ok($diceobj->combinations(12),586);
ok($diceobj->combinations(13),562);
ok($diceobj->combinations(14),526);
ok($diceobj->combinations(15),478);
ok($diceobj->combinations(16),418);
ok($diceobj->combinations(17),346);
ok($diceobj->combinations(18),262);
ok($diceobj->combinations(19),166);
ok($diceobj->combinations(20),58);
ok($diceobj->probability(1),0.00725);
ok($diceobj->probability(2),0.02075);
ok($diceobj->probability(3),0.03275);
ok($diceobj->probability(4),0.04325);
ok($diceobj->probability(5),0.05225);
ok($diceobj->probability(6),0.05975);
ok($diceobj->probability(7),0.06575);
ok($diceobj->probability(8),0.07025);
ok($diceobj->probability(9),0.07325);
ok($diceobj->probability(10),0.07475);
ok($diceobj->probability(11),0.07475);
ok($diceobj->probability(12),0.07325);
ok($diceobj->probability(13),0.07025);
ok($diceobj->probability(14),0.06575);
ok($diceobj->probability(15),0.05975);
ok($diceobj->probability(16),0.05225);
ok($diceobj->probability(17),0.04325);
ok($diceobj->probability(18),0.03275);
ok($diceobj->probability(19),0.02075);
ok($diceobj->probability(20),0.00725);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

