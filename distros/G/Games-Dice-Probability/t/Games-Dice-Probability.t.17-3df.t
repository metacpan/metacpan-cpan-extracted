# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.17-3df.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 13 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("3df");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-3);
ok($diceobj->max(),3);
ok($diceobj->bounds()->[0],-3);
ok($diceobj->bounds()->[1],3);
ok($diceobj->probability(-3),0.037037037037037);
ok($diceobj->probability(-2),0.111111111111111);
ok($diceobj->probability(-1),0.222222222222222);
ok($diceobj->probability(0),0.259259259259259);
ok($diceobj->probability(1),0.222222222222222);
ok($diceobj->probability(2),0.111111111111111);
ok($diceobj->probability(3),0.037037037037037);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

