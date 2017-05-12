# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.08-3d6plus3d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 68 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("3d6+3d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),6);
ok($diceobj->max(),36);
ok($diceobj->bounds()->[0],6);
ok($diceobj->bounds()->[1],36);
ok($diceobj->combinations(6),1);
ok($diceobj->combinations(7),6);
ok($diceobj->combinations(8),21);
ok($diceobj->combinations(9),56);
ok($diceobj->combinations(10),126);
ok($diceobj->combinations(11),252);
ok($diceobj->combinations(12),456);
ok($diceobj->combinations(13),756);
ok($diceobj->combinations(14),1161);
ok($diceobj->combinations(15),1666);
ok($diceobj->combinations(16),2247);
ok($diceobj->combinations(17),2856);
ok($diceobj->combinations(18),3431);
ok($diceobj->combinations(19),3906);
ok($diceobj->combinations(20),4221);
ok($diceobj->combinations(21),4332);
ok($diceobj->combinations(22),4221);
ok($diceobj->combinations(23),3906);
ok($diceobj->combinations(24),3431);
ok($diceobj->combinations(25),2856);
ok($diceobj->combinations(26),2247);
ok($diceobj->combinations(27),1666);
ok($diceobj->combinations(28),1161);
ok($diceobj->combinations(29),756);
ok($diceobj->combinations(30),456);
ok($diceobj->combinations(31),252);
ok($diceobj->combinations(32),126);
ok($diceobj->combinations(33),56);
ok($diceobj->combinations(34),21);
ok($diceobj->combinations(35),6);
ok($diceobj->combinations(36),1);
ok($diceobj->probability(6),2.14334705075446e-05);
ok($diceobj->probability(7),0.000128600823045268);
ok($diceobj->probability(8),0.000450102880658436);
ok($diceobj->probability(9),0.0012002743484225);
ok($diceobj->probability(10),0.00270061728395062);
ok($diceobj->probability(11),0.00540123456790123);
ok($diceobj->probability(12),0.00977366255144033);
ok($diceobj->probability(13),0.0162037037037037);
ok($diceobj->probability(14),0.0248842592592593);
ok($diceobj->probability(15),0.0357081618655693);
ok($diceobj->probability(16),0.0481610082304527);
ok($diceobj->probability(17),0.0612139917695473);
ok($diceobj->probability(18),0.0735382373113855);
ok($diceobj->probability(19),0.0837191358024691);
ok($diceobj->probability(20),0.0904706790123457);
ok($diceobj->probability(21),0.0928497942386831);
ok($diceobj->probability(22),0.0904706790123457);
ok($diceobj->probability(23),0.0837191358024691);
ok($diceobj->probability(24),0.0735382373113855);
ok($diceobj->probability(25),0.0612139917695473);
ok($diceobj->probability(26),0.0481610082304527);
ok($diceobj->probability(27),0.0357081618655693);
ok($diceobj->probability(28),0.0248842592592593);
ok($diceobj->probability(29),0.0162037037037037);
ok($diceobj->probability(30),0.00977366255144033);
ok($diceobj->probability(31),0.00540123456790123);
ok($diceobj->probability(32),0.00270061728395062);
ok($diceobj->probability(33),0.0012002743484225);
ok($diceobj->probability(34),0.000450102880658436);
ok($diceobj->probability(35),0.000128600823045268);
ok($diceobj->probability(36),2.14334705075446e-05);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

