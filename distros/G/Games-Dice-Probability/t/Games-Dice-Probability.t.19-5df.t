# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Games-Dice-Probability.t.19-5df.t'

#########################

use strict;
use warnings;
use Test;

my $diceobj;

BEGIN { plan tests => 17 };

INIT {
    use Games::Dice::Probability;

    $diceobj = Games::Dice::Probability->new("5df");
}

# Confirm objects were created.
ok($diceobj->isa("Games::Dice::Probability"),1);

# Confirm attributes.
ok($diceobj->min(),-5);
ok($diceobj->max(),5);
ok($diceobj->bounds()->[0],-5);
ok($diceobj->bounds()->[1],5);
ok($diceobj->probability(-5),0.00411522633744856);
ok($diceobj->probability(-4),0.0205761316872428);
ok($diceobj->probability(-3),0.0617283950617284);
ok($diceobj->probability(-2),0.123456790123457);
ok($diceobj->probability(-1),0.185185185185185);
ok($diceobj->probability(0),0.209876543209877);
ok($diceobj->probability(1),0.185185185185185);
ok($diceobj->probability(2),0.123456790123457);
ok($diceobj->probability(3),0.0617283950617284);
ok($diceobj->probability(4),0.0205761316872428);
ok($diceobj->probability(5),0.00411522633744856);

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

