# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.04-4d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 48 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("4d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),4);
ok($diceobj->max(),24);
ok($diceobj->bounds()->[0],4);
ok($diceobj->bounds()->[1],24);
ok($diceobj->combinations(4),1);
ok($diceobj->combinations(5),4);
ok($diceobj->combinations(6),10);
ok($diceobj->combinations(7),20);
ok($diceobj->combinations(8),35);
ok($diceobj->combinations(9),56);
ok($diceobj->combinations(10),80);
ok($diceobj->combinations(11),104);
ok($diceobj->combinations(12),125);
ok($diceobj->combinations(13),140);
ok($diceobj->combinations(14),146);
ok($diceobj->combinations(15),140);
ok($diceobj->combinations(16),125);
ok($diceobj->combinations(17),104);
ok($diceobj->combinations(18),80);
ok($diceobj->combinations(19),56);
ok($diceobj->combinations(20),35);
ok($diceobj->combinations(21),20);
ok($diceobj->combinations(22),10);
ok($diceobj->combinations(23),4);
ok($diceobj->combinations(24),1);
ok($diceobj->probability(4),0.000771604938271605);
ok($diceobj->probability(5),0.00308641975308642);
ok($diceobj->probability(6),0.00771604938271605);
ok($diceobj->probability(7),0.0154320987654321);
ok($diceobj->probability(8),0.0270061728395062);
ok($diceobj->probability(9),0.0432098765432099);
ok($diceobj->probability(10),0.0617283950617284);
ok($diceobj->probability(11),0.0802469135802469);
ok($diceobj->probability(12),0.0964506172839506);
ok($diceobj->probability(13),0.108024691358025);
ok($diceobj->probability(14),0.112654320987654);
ok($diceobj->probability(15),0.108024691358025);
ok($diceobj->probability(16),0.0964506172839506);
ok($diceobj->probability(17),0.0802469135802469);
ok($diceobj->probability(18),0.0617283950617284);
ok($diceobj->probability(19),0.0432098765432099);
ok($diceobj->probability(20),0.0270061728395062);
ok($diceobj->probability(21),0.0154320987654321);
ok($diceobj->probability(22),0.00771604938271605);
ok($diceobj->probability(23),0.00308641975308642);
ok($diceobj->probability(24),0.000771604938271605);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

