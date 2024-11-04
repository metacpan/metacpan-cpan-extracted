#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use HashData::Test::Source::Iterator;

my $t = HashData::Test::Source::Iterator->new(num_pairs=>3);

$t->reset_iterator;
is_deeply($t->get_next_item, [1,1]); #1
is_deeply($t->get_next_item, [2,2]); #2
is_deeply($t->get_next_item, [3,3]); #3
dies_ok { $t->get_next_item }; #4
$t->reset_iterator;
is_deeply($t->get_next_item , [1,1]); #5
is($t->get_item_count, 3); #6

ok($t->has_item_at_key(1)); #7
is_deeply($t->get_item_at_key(1), [1,1]); #8
ok($t->has_item_at_key(2)); #9
is_deeply($t->get_item_at_key(2), [2,2]); #10
ok(!$t->has_item_at_key(4)); #11
is_deeply([$t->get_item_at_key(4)], []); #12

my @keys = sort $t->get_all_keys;
is_deeply(\@keys, [1,2,3]); #13

done_testing;
