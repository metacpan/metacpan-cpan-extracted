#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Doubly;

# Test remove_from_end
ok(my $list = Doubly->new(), 'created list');

$list->add(1);
$list->add(2);
$list->add(3);

is($list->length, 3, 'length is 3');

# Remove from end
my $removed = $list->remove_from_end;
is($removed, 3, 'removed item is 3');
is($list->length, 2, 'length is now 2');

# Check remaining items
$list->start;
is($list->data, 1, 'first item is still 1');
$list->end;
is($list->data, 2, 'last item is now 2');

# Remove again
$removed = $list->remove_from_end;
is($removed, 2, 'removed item is 2');
is($list->length, 1, 'length is now 1');

# Remove last
$removed = $list->remove_from_end;
is($removed, 1, 'removed item is 1');
is($list->length, 0, 'length is now 0');

done_testing();
