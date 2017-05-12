# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.12-3d6times3d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 113 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("3d6*3d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),9);
ok($diceobj->max(),324);
ok($diceobj->bounds()->[0],9);
ok($diceobj->bounds()->[1],324);
ok($diceobj->probability(9),2.14334705075446e-05);
ok($diceobj->probability(12),0.000128600823045268);
ok($diceobj->probability(15),0.000257201646090535);
ok($diceobj->probability(16),0.000192901234567901);
ok($diceobj->probability(18),0.000428669410150892);
ok($diceobj->probability(20),0.000771604938271605);
ok($diceobj->probability(21),0.000643004115226337);
ok($diceobj->probability(24),0.00218621399176955);
ok($diceobj->probability(25),0.000771604938271605);
ok($diceobj->probability(27),0.00107167352537723);
ok($diceobj->probability(28),0.00192901234567901);
ok($diceobj->probability(30),0.00372942386831276);
ok($diceobj->probability(32),0.00270061728395062);
ok($diceobj->probability(33),0.00115740740740741);
ok($diceobj->probability(35),0.00385802469135802);
ok($diceobj->probability(36),0.00643004115226337);
ok($diceobj->probability(39),0.000900205761316872);
ok($diceobj->probability(40),0.00887345679012346);
ok($diceobj->probability(42),0.00707304526748971);
ok($diceobj->probability(44),0.00347222222222222);
ok($diceobj->probability(45),0.00685871056241427);
ok($diceobj->probability(48),0.0124742798353909);
ok($diceobj->probability(49),0.00482253086419753);
ok($diceobj->probability(50),0.00694444444444444);
ok($diceobj->probability(51),0.000128600823045268);
ok($diceobj->probability(52),0.00270061728395062);
ok($diceobj->probability(54),0.0107596021947874);
ok($diceobj->probability(55),0.00694444444444444);
ok($diceobj->probability(56),0.0154320987654321);
ok($diceobj->probability(60),0.0192901234567901);
ok($diceobj->probability(63),0.0160751028806584);
ok($diceobj->probability(64),0.0102237654320988);
ok($diceobj->probability(65),0.00540123456790123);
ok($diceobj->probability(66),0.0115740740740741);
ok($diceobj->probability(68),0.000385802469135802);
ok($diceobj->probability(70),0.0212191358024691);
ok($diceobj->probability(72),0.0333504801097394);
ok($diceobj->probability(75),0.00257201646090535);
ok($diceobj->probability(77),0.0173611111111111);
ok($diceobj->probability(78),0.00900205761316872);
ok($diceobj->probability(80),0.0258487654320988);
ok($diceobj->probability(81),0.0133959190672154);
ok($diceobj->probability(84),0.0225051440329218);
ok($diceobj->probability(85),0.000771604938271605);
ok($diceobj->probability(88),0.0243055555555556);
ok($diceobj->probability(90),0.0334790809327846);
ok($diceobj->probability(91),0.0135030864197531);
ok($diceobj->probability(96),0.0250771604938272);
ok($diceobj->probability(98),0.00964506172839506);
ok($diceobj->probability(99),0.0289351851851852);
ok($diceobj->probability(100),0.015625);
ok($diceobj->probability(102),0.00128600823045267);
ok($diceobj->probability(104),0.0189043209876543);
ok($diceobj->probability(105),0.00643004115226337);
ok($diceobj->probability(108),0.0272205075445816);
ok($diceobj->probability(110),0.03125);
ok($diceobj->probability(112),0.0173611111111111);
ok($diceobj->probability(117),0.0225051440329218);
ok($diceobj->probability(119),0.00192901234567901);
ok($diceobj->probability(120),0.0379372427983539);
ok($diceobj->probability(121),0.015625);
ok($diceobj->probability(126),0.0167181069958848);
ok($diceobj->probability(128),0.00540123456790123);
ok($diceobj->probability(130),0.0243055555555556);
ok($diceobj->probability(132),0.0289351851851852);
ok($diceobj->probability(135),0.0107167352537723);
ok($diceobj->probability(136),0.00270061728395062);
ok($diceobj->probability(140),0.0173611111111111);
ok($diceobj->probability(143),0.0243055555555556);
ok($diceobj->probability(144),0.0207261659807956);
ok($diceobj->probability(150),0.0115740740740741);
ok($diceobj->probability(153),0.00321502057613169);
ok($diceobj->probability(154),0.0173611111111111);
ok($diceobj->probability(156),0.0225051440329218);
ok($diceobj->probability(160),0.00694444444444444);
ok($diceobj->probability(162),0.00107167352537723);
ok($diceobj->probability(165),0.0115740740740741);
ok($diceobj->probability(168),0.0160751028806584);
ok($diceobj->probability(169),0.00945216049382716);
ok($diceobj->probability(170),0.00347222222222222);
ok($diceobj->probability(176),0.00694444444444444);
ok($diceobj->probability(180),0.0118741426611797);
ok($diceobj->probability(182),0.0135030864197531);
ok($diceobj->probability(187),0.00347222222222222);
ok($diceobj->probability(192),0.00643004115226337);
ok($diceobj->probability(195),0.00900205761316872);
ok($diceobj->probability(196),0.00482253086419753);
ok($diceobj->probability(198),0.00115740740740741);
ok($diceobj->probability(204),0.00321502057613169);
ok($diceobj->probability(208),0.00540123456790123);
ok($diceobj->probability(210),0.00643004115226337);
ok($diceobj->probability(216),0.00107167352537723);
ok($diceobj->probability(221),0.00270061728395062);
ok($diceobj->probability(224),0.00385802469135802);
ok($diceobj->probability(225),0.00214334705075446);
ok($diceobj->probability(234),0.000900205761316872);
ok($diceobj->probability(238),0.00192901234567901);
ok($diceobj->probability(240),0.00257201646090535);
ok($diceobj->probability(252),0.000643004115226337);
ok($diceobj->probability(255),0.00128600823045267);
ok($diceobj->probability(256),0.000771604938271605);
ok($diceobj->probability(270),0.000428669410150892);
ok($diceobj->probability(272),0.000771604938271605);
ok($diceobj->probability(288),0.000257201646090535);
ok($diceobj->probability(289),0.000192901234567901);
ok($diceobj->probability(306),0.000128600823045268);
ok($diceobj->probability(324),2.14334705075446e-05);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

