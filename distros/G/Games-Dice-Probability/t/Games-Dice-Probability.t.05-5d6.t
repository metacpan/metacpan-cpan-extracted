# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.05-5d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 58 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("5d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),5);
ok($diceobj->max(),30);
ok($diceobj->bounds()->[0],5);
ok($diceobj->bounds()->[1],30);
ok($diceobj->combinations(5),1);
ok($diceobj->combinations(6),5);
ok($diceobj->combinations(7),15);
ok($diceobj->combinations(8),35);
ok($diceobj->combinations(9),70);
ok($diceobj->combinations(10),126);
ok($diceobj->combinations(11),205);
ok($diceobj->combinations(12),305);
ok($diceobj->combinations(13),420);
ok($diceobj->combinations(14),540);
ok($diceobj->combinations(15),651);
ok($diceobj->combinations(16),735);
ok($diceobj->combinations(17),780);
ok($diceobj->combinations(18),780);
ok($diceobj->combinations(19),735);
ok($diceobj->combinations(20),651);
ok($diceobj->combinations(21),540);
ok($diceobj->combinations(22),420);
ok($diceobj->combinations(23),305);
ok($diceobj->combinations(24),205);
ok($diceobj->combinations(25),126);
ok($diceobj->combinations(26),70);
ok($diceobj->combinations(27),35);
ok($diceobj->combinations(28),15);
ok($diceobj->combinations(29),5);
ok($diceobj->combinations(30),1);
ok($diceobj->probability(5),0.000128600823045268);
ok($diceobj->probability(6),0.000643004115226337);
ok($diceobj->probability(7),0.00192901234567901);
ok($diceobj->probability(8),0.00450102880658436);
ok($diceobj->probability(9),0.00900205761316872);
ok($diceobj->probability(10),0.0162037037037037);
ok($diceobj->probability(11),0.0263631687242798);
ok($diceobj->probability(12),0.0392232510288066);
ok($diceobj->probability(13),0.0540123456790123);
ok($diceobj->probability(14),0.0694444444444444);
ok($diceobj->probability(15),0.0837191358024691);
ok($diceobj->probability(16),0.0945216049382716);
ok($diceobj->probability(17),0.100308641975309);
ok($diceobj->probability(18),0.100308641975309);
ok($diceobj->probability(19),0.0945216049382716);
ok($diceobj->probability(20),0.0837191358024691);
ok($diceobj->probability(21),0.0694444444444444);
ok($diceobj->probability(22),0.0540123456790123);
ok($diceobj->probability(23),0.0392232510288066);
ok($diceobj->probability(24),0.0263631687242798);
ok($diceobj->probability(25),0.0162037037037037);
ok($diceobj->probability(26),0.00900205761316872);
ok($diceobj->probability(27),0.00450102880658436);
ok($diceobj->probability(28),0.00192901234567901);
ok($diceobj->probability(29),0.000643004115226337);
ok($diceobj->probability(30),0.000128600823045268);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

