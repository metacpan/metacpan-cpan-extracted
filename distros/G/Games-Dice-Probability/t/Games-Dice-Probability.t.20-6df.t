# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.20-6df.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 19 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("6df");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-6);
ok($diceobj->max(),6);
ok($diceobj->bounds()->[0],-6);
ok($diceobj->bounds()->[1],6);
ok($diceobj->probability(-6),0.00137174211248285);
ok($diceobj->probability(-5),0.00823045267489712);
ok($diceobj->probability(-4),0.0288065843621399);
ok($diceobj->probability(-3),0.0685871056241427);
ok($diceobj->probability(-2),0.123456790123457);
ok($diceobj->probability(-1),0.172839506172839);
ok($diceobj->probability(0),0.193415637860082);
ok($diceobj->probability(1),0.172839506172839);
ok($diceobj->probability(2),0.123456790123457);
ok($diceobj->probability(3),0.0685871056241427);
ok($diceobj->probability(4),0.0288065843621399);
ok($diceobj->probability(5),0.00823045267489712);
ok($diceobj->probability(6),0.00137174211248285);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

