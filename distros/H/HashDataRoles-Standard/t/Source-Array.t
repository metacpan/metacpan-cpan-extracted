#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use HashData::Test::Source::Array;

my $t = HashData::Test::Source::Array->new(array=>[["one","satu"], ["two","dua"], ["three","tiga"]]);

$t->reset_iterator;
ok($t->has_next_item);
is_deeply($t->get_next_item, ["one","satu"]);
is_deeply($t->get_next_item, ["two","dua"]);
is_deeply($t->get_next_item, ["three","tiga"]);
ok(!$t->has_next_item);
dies_ok { $t->get_next_item };
$t->reset_iterator;
is_deeply($t->get_next_item , ["one","satu"]);
is($t->get_item_count, 3);

ok($t->has_item_at_key("two"));
is_deeply($t->get_item_at_key("two"), "dua");
ok(!$t->has_item_at_key("four"));
dies_ok { $t->get_item_at_key("four") };

ok($t->has_item_at_pos(0));
is_deeply($t->get_item_at_pos(0), ["one","satu"]);
ok(!$t->has_item_at_pos(3));
dies_ok { $t->get_item_at_pos(3) };

done_testing;
