# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.09-2d6minus2d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 48 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("2d6-2d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-10);
ok($diceobj->max(),10);
ok($diceobj->bounds()->[0],-10);
ok($diceobj->bounds()->[1],10);
ok($diceobj->combinations(-10),1);
ok($diceobj->combinations(-9),4);
ok($diceobj->combinations(-8),10);
ok($diceobj->combinations(-7),20);
ok($diceobj->combinations(-6),35);
ok($diceobj->combinations(-5),56);
ok($diceobj->combinations(-4),80);
ok($diceobj->combinations(-3),104);
ok($diceobj->combinations(-2),125);
ok($diceobj->combinations(-1),140);
ok($diceobj->combinations(0),146);
ok($diceobj->combinations(1),140);
ok($diceobj->combinations(2),125);
ok($diceobj->combinations(3),104);
ok($diceobj->combinations(4),80);
ok($diceobj->combinations(5),56);
ok($diceobj->combinations(6),35);
ok($diceobj->combinations(7),20);
ok($diceobj->combinations(8),10);
ok($diceobj->combinations(9),4);
ok($diceobj->combinations(10),1);
ok($diceobj->probability(-10),0.000771604938271605);
ok($diceobj->probability(-9),0.00308641975308642);
ok($diceobj->probability(-8),0.00771604938271605);
ok($diceobj->probability(-7),0.0154320987654321);
ok($diceobj->probability(-6),0.0270061728395062);
ok($diceobj->probability(-5),0.0432098765432099);
ok($diceobj->probability(-4),0.0617283950617284);
ok($diceobj->probability(-3),0.0802469135802469);
ok($diceobj->probability(-2),0.0964506172839506);
ok($diceobj->probability(-1),0.108024691358025);
ok($diceobj->probability(0),0.112654320987654);
ok($diceobj->probability(1),0.108024691358025);
ok($diceobj->probability(2),0.0964506172839506);
ok($diceobj->probability(3),0.0802469135802469);
ok($diceobj->probability(4),0.0617283950617284);
ok($diceobj->probability(5),0.0432098765432099);
ok($diceobj->probability(6),0.0270061728395062);
ok($diceobj->probability(7),0.0154320987654321);
ok($diceobj->probability(8),0.00771604938271605);
ok($diceobj->probability(9),0.00308641975308642);
ok($diceobj->probability(10),0.000771604938271605);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

