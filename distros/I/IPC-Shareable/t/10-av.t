use warnings;
use strict;

use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

tie my @av, 'IPC::Shareable', { destroy => 1 };

my @words = qw(tic tac toe);
@av = qw(tic tac toe);

for (0 .. 2) {
    is $av[$_], $words[$_], "shared array has been populated ok: $_";
}

$#av = 5;

is scalar(@av), 6, "array count ok";

for (3 .. 5) {
    is defined $av[$_], '', "array elem $_ is present but undefined";
}

is $#av, 5, "array len ok";

@av = ();
is scalar(@av), 0, "shared array cleared ok";

@av = qw(fee fie foe fum);

my $fum = pop @av;

is $fum, 'fum', "a pop on the array is ok";
is $#av, 2, "after pop, proper amount of elements remain ok";

push @av => $fum;
is $av[3], $fum, "pushing to array ok";
is $#av, 3, "a push adds a new element ok";

# shift

my $fee = shift @av;
is $fee, 'fee', "shifting the array ok";
is $#av, 2, "after shift, proper number of elements ok";

# unshift

unshift @av => $fee;
is $fee, 'fee', "unshifting the array ok";
is $#av, 3, "after unshift, proper number of elements ok";

# splice

my(@gone) = splice @av, 1, 2, qw(i spliced);

is $av[1], 'i', "splice 1 ok";
is $av[2], 'spliced', "splice 2 ok";
is $gone[0], 'fie', "splice 3 ok";
is $gone[1], 'foe', "splice 4 ok";

done_testing();
