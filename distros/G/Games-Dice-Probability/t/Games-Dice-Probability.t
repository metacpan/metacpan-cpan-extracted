# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 9 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("1d6");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->can('debug') && 1 || 0,1);
ok($diceobj->can('combinations') && 1 || 0,1);
ok($diceobj->can('distribution') && 1 || 0,1);
ok($diceobj->can('probability') && 1 || 0,1);
ok($diceobj->can('bounds') && 1 || 0,1);
ok($diceobj->can('min') && 1 || 0,1);
ok($diceobj->can('max') && 1 || 0,1);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

