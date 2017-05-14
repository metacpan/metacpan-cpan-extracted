use strict;
use warnings;
use Test::More tests => 4;
use List::MapBruteBatch 'map_brute_batch';

my @a = ("a".."z", 0..9);
my $num_do_work = 0;
my $num_do_work_items = 0;
my $num_success = 0;
my $num_failure = 0;
my @res = map_brute_batch(
    sub {
        $num_do_work++;
        $num_do_work_items += @{$_[0]};

        # Simulate random failure. Any item has a ~25% chance of
        # failing.
        for (@{$_[0]}) { return if rand() < .25 }

        return 1;
    },
    \@a,
    sub { $num_success += @{$_[0]}; map { ["OK",   $_] } @{$_[0]} },
    sub { $num_failure += @{$_[0]}; map { ["FAIL", $_] } @{$_[0]} },
);

cmp_ok(scalar(@res), '==', scalar(@a), "We got as many OK/FAIL items back as items");
cmp_ok($num_do_work, '>=', 1, "We did at least 1 work batch, but probably more");
cmp_ok($num_do_work_items, '>=', scalar(@a), "We did at least " . @a . " work items (but maybe more!)");
cmp_ok(($num_success + $num_failure), '==', scalar(@a), "Our successes & failures are the same as the total number of items");
