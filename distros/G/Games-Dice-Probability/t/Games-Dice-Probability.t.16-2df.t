# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.16-2df.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 11 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("2df");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-2);
ok($diceobj->max(),2);
ok($diceobj->bounds()->[0],-2);
ok($diceobj->bounds()->[1],2);
ok($diceobj->probability(-2),0.111111111111111);
ok($diceobj->probability(-1),0.222222222222222);
ok($diceobj->probability(0),0.333333333333333);
ok($diceobj->probability(1),0.222222222222222);
ok($diceobj->probability(2),0.111111111111111);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

