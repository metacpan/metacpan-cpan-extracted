#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Doubly;

# Test 1: Create empty list
ok(my $list = Doubly->new(), 'created empty list');

# Test 2: Empty list data is undef
is($list->data, undef, 'empty list data is undef');

# Test 3: Set data
ok($list->data(1), 'set data to 1');

# Test 4: Get data
is($list->data, 1, 'data is 1');

# Test 5: Set data to string
ok($list->data("hello"), 'set data to string');
is($list->data, "hello", 'data is hello');

# Test 6: Set data to float
ok($list->data(3.14), 'set data to float');
is($list->data, 3.14, 'data is 3.14');

# Test 7: Create list with initial value
ok(my $list2 = Doubly->new(100), 'created list with initial value');
is($list2->data, 100, 'initial data is 100');

# Test 8: Create list with string initial value
ok(my $list3 = Doubly->new("test"), 'created list with string initial');
is($list3->data, "test", 'initial data is test');

# Test 9: Hash reference
ok(my $list4 = Doubly->new(), 'created list for hash test');
$list4->add({a => 1, b => 2});
$list4->start;
is(ref($list4->data), 'HASH', 'data is a HASH ref');
is($list4->data->{a}, 1, 'hash key a is 1');
is($list4->data->{b}, 2, 'hash key b is 2');

# Test 10: Array reference
ok(my $list5 = Doubly->new(), 'created list for array test');
$list5->add([1, 2, 3]);
$list5->start;
is(ref($list5->data), 'ARRAY', 'data is an ARRAY ref');
is_deeply($list5->data, [1, 2, 3], 'array contains correct values');

# Test 11: Nested structure
ok(my $list6 = Doubly->new(), 'created list for nested test');
$list6->add({nested => {deep => [1, 2, 3]}});
$list6->start;
is(ref($list6->data), 'HASH', 'outer is HASH');
is(ref($list6->data->{nested}), 'HASH', 'nested is HASH');
is_deeply($list6->data->{nested}{deep}, [1, 2, 3], 'deep array correct');

# Test 12: Modifying shared ref affects stored data
ok(my $list7 = Doubly->new(), 'created list for modify test');
$list7->add({counter => 0});
$list7->start;
my $ref = $list7->data;
$ref->{counter}++;
is($list7->data->{counter}, 1, 'modification persists in stored data');
 
# Test 13: Set data to hash via data() method
ok(my $list8 = Doubly->new(), 'created list for data() set test');
$list8->add("placeholder");
$list8->start;
$list8->data({x => 10});
is(ref($list8->data), 'HASH', 'data() can set hash ref');
is($list8->data->{x}, 10, 'hash set via data() has correct value');

done_testing();
