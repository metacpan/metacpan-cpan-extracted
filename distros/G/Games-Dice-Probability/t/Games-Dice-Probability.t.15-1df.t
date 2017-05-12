# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.15-1df.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 9 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("1df");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-1);
ok($diceobj->max(),1);
ok($diceobj->bounds()->[0],-1);
ok($diceobj->bounds()->[1],1);
ok($diceobj->probability(-1),0.333333333333333);
ok($diceobj->probability(0),0.333333333333333);
ok($diceobj->probability(1),0.333333333333333);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

