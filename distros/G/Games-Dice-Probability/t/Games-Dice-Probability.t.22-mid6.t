# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.21-mid6.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 18 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("mid6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),1);
ok($diceobj->max(),6);
ok($diceobj->bounds()->[0],1);
ok($diceobj->bounds()->[1],6);
ok($diceobj->combinations(1),16);
ok($diceobj->combinations(2),40);
ok($diceobj->combinations(3),52);
ok($diceobj->combinations(4),52);
ok($diceobj->combinations(5),40);
ok($diceobj->combinations(6),16);
ok($diceobj->probability(1),0.0740740740740741);
ok($diceobj->probability(2),0.185185185185185);
ok($diceobj->probability(3),0.240740740740741);
ok($diceobj->probability(4),0.240740740740741);
ok($diceobj->probability(5),0.185185185185185);
ok($diceobj->probability(6),0.0740740740740741);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

