#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Doubly;

# Stress test with large list

my $list = Doubly->new();

# Add 100,000 items
$list->bulk_add(1..100000);

is($list->data, 1, 'first item after bulk_add');

is($list->length, 100000, 'length is 100000');

ok($list = $list->end, 'navigate to end');

is($list->data, 100000, 'last item is 100000');

is($list->prev->data, 99999, 'prev from end is 99999');

# Navigate to middle
$list->start;
for (1..50000) {
    $list->next;
}
is($list->data, 50001, 'middle element is 50001');

$list->destroy();

is($list->data, undef, 'data is undef after destroy');

done_testing();
