# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.11-2d6times2d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 59 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("2d6*2d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),4);
ok($diceobj->max(),144);
ok($diceobj->bounds()->[0],4);
ok($diceobj->bounds()->[1],144);
ok($diceobj->probability(4),0.000771604938271605);
ok($diceobj->probability(6),0.00308641975308642);
ok($diceobj->probability(8),0.00462962962962963);
ok($diceobj->probability(9),0.00308641975308642);
ok($diceobj->probability(10),0.00617283950617284);
ok($diceobj->probability(12),0.0169753086419753);
ok($diceobj->probability(14),0.00925925925925926);
ok($diceobj->probability(15),0.0123456790123457);
ok($diceobj->probability(16),0.0146604938271605);
ok($diceobj->probability(18),0.0216049382716049);
ok($diceobj->probability(20),0.0231481481481481);
ok($diceobj->probability(21),0.0185185185185185);
ok($diceobj->probability(22),0.00308641975308642);
ok($diceobj->probability(24),0.0401234567901235);
ok($diceobj->probability(25),0.0123456790123457);
ok($diceobj->probability(27),0.0123456790123457);
ok($diceobj->probability(28),0.0277777777777778);
ok($diceobj->probability(30),0.0401234567901235);
ok($diceobj->probability(32),0.0231481481481481);
ok($diceobj->probability(33),0.00617283950617284);
ok($diceobj->probability(35),0.037037037037037);
ok($diceobj->probability(36),0.0408950617283951);
ok($diceobj->probability(40),0.0447530864197531);
ok($diceobj->probability(42),0.0462962962962963);
ok($diceobj->probability(44),0.00925925925925926);
ok($diceobj->probability(45),0.0246913580246914);
ok($diceobj->probability(48),0.0432098765432099);
ok($diceobj->probability(49),0.0277777777777778);
ok($diceobj->probability(50),0.0185185185185185);
ok($diceobj->probability(54),0.0308641975308642);
ok($diceobj->probability(55),0.0123456790123457);
ok($diceobj->probability(56),0.0462962962962963);
ok($diceobj->probability(60),0.029320987654321);
ok($diceobj->probability(63),0.037037037037037);
ok($diceobj->probability(64),0.0192901234567901);
ok($diceobj->probability(66),0.0154320987654321);
ok($diceobj->probability(70),0.0277777777777778);
ok($diceobj->probability(72),0.0385802469135802);
ok($diceobj->probability(77),0.0185185185185185);
ok($diceobj->probability(80),0.0231481481481481);
ok($diceobj->probability(81),0.0123456790123457);
ok($diceobj->probability(84),0.00925925925925926);
ok($diceobj->probability(88),0.0154320987654321);
ok($diceobj->probability(90),0.0185185185185185);
ok($diceobj->probability(96),0.00771604938271605);
ok($diceobj->probability(99),0.0123456790123457);
ok($diceobj->probability(100),0.00694444444444444);
ok($diceobj->probability(108),0.00617283950617284);
ok($diceobj->probability(110),0.00925925925925926);
ok($diceobj->probability(120),0.00462962962962963);
ok($diceobj->probability(121),0.00308641975308642);
ok($diceobj->probability(132),0.00308641975308642);
ok($diceobj->probability(144),0.000771604938271605);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

