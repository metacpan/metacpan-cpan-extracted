# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.13-2d6dividedby2d6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 13 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("2d6/2d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),0);
ok($diceobj->max(),6);
ok($diceobj->bounds()->[0],0);
ok($diceobj->bounds()->[1],6);
ok($diceobj->probability(0),0.443672839506173);
ok($diceobj->probability(1),0.433641975308642);
ok($diceobj->probability(2),0.0848765432098765);
ok($diceobj->probability(3),0.0246913580246914);
ok($diceobj->probability(4),0.00848765432098765);
ok($diceobj->probability(5),0.00385802469135802);
ok($diceobj->probability(6),0.000771604938271605);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

