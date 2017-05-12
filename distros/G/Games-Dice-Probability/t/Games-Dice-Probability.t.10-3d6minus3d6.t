# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.10-3d6minus3d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 68 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("3d6-3d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-15);
ok($diceobj->max(),15);
ok($diceobj->bounds()->[0],-15);
ok($diceobj->bounds()->[1],15);
ok($diceobj->combinations(-15),1);
ok($diceobj->combinations(-14),6);
ok($diceobj->combinations(-13),21);
ok($diceobj->combinations(-12),56);
ok($diceobj->combinations(-11),126);
ok($diceobj->combinations(-10),252);
ok($diceobj->combinations(-9),456);
ok($diceobj->combinations(-8),756);
ok($diceobj->combinations(-7),1161);
ok($diceobj->combinations(-6),1666);
ok($diceobj->combinations(-5),2247);
ok($diceobj->combinations(-4),2856);
ok($diceobj->combinations(-3),3431);
ok($diceobj->combinations(-2),3906);
ok($diceobj->combinations(-1),4221);
ok($diceobj->combinations(0),4332);
ok($diceobj->combinations(1),4221);
ok($diceobj->combinations(2),3906);
ok($diceobj->combinations(3),3431);
ok($diceobj->combinations(4),2856);
ok($diceobj->combinations(5),2247);
ok($diceobj->combinations(6),1666);
ok($diceobj->combinations(7),1161);
ok($diceobj->combinations(8),756);
ok($diceobj->combinations(9),456);
ok($diceobj->combinations(10),252);
ok($diceobj->combinations(11),126);
ok($diceobj->combinations(12),56);
ok($diceobj->combinations(13),21);
ok($diceobj->combinations(14),6);
ok($diceobj->combinations(15),1);
ok($diceobj->probability(-15),2.14334705075446e-05);
ok($diceobj->probability(-14),0.000128600823045268);
ok($diceobj->probability(-13),0.000450102880658436);
ok($diceobj->probability(-12),0.0012002743484225);
ok($diceobj->probability(-11),0.00270061728395062);
ok($diceobj->probability(-10),0.00540123456790123);
ok($diceobj->probability(-9),0.00977366255144033);
ok($diceobj->probability(-8),0.0162037037037037);
ok($diceobj->probability(-7),0.0248842592592593);
ok($diceobj->probability(-6),0.0357081618655693);
ok($diceobj->probability(-5),0.0481610082304527);
ok($diceobj->probability(-4),0.0612139917695473);
ok($diceobj->probability(-3),0.0735382373113855);
ok($diceobj->probability(-2),0.0837191358024691);
ok($diceobj->probability(-1),0.0904706790123457);
ok($diceobj->probability(0),0.0928497942386831);
ok($diceobj->probability(1),0.0904706790123457);
ok($diceobj->probability(2),0.0837191358024691);
ok($diceobj->probability(3),0.0735382373113855);
ok($diceobj->probability(4),0.0612139917695473);
ok($diceobj->probability(5),0.0481610082304527);
ok($diceobj->probability(6),0.0357081618655693);
ok($diceobj->probability(7),0.0248842592592593);
ok($diceobj->probability(8),0.0162037037037037);
ok($diceobj->probability(9),0.00977366255144033);
ok($diceobj->probability(10),0.00540123456790123);
ok($diceobj->probability(11),0.00270061728395062);
ok($diceobj->probability(12),0.0012002743484225);
ok($diceobj->probability(13),0.000450102880658436);
ok($diceobj->probability(14),0.000128600823045268);
ok($diceobj->probability(15),2.14334705075446e-05);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

