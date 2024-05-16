#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use HashData::Test::Source::LinesInDATA;

my $t = HashData::Test::Source::LinesInDATA->new;

$t->reset_iterator;
is_deeply($t->get_next_item, [one=>"satu"]);
is_deeply($t->get_next_item, [two=>"dua"]);
is_deeply($t->get_next_item, [three=>"tiga"]);
is_deeply($t->get_next_item, [four=>"empat"]);
is_deeply($t->get_next_item, [five=>"lima"]);
dies_ok { $t->get_next_item };

$t->reset_iterator;
is_deeply($t->get_next_item, [one=>"satu"]);

ok($t->has_item_at_key("two"));
is_deeply($t->get_item_at_key("two"), "dua");
ok(!$t->has_item_at_key("six"));
dies_ok { $t->get_item_at_key("six") };

ok($t->has_item_at_pos(0));
is_deeply($t->get_item_at_pos(0), [one=>"satu"]);
ok($t->has_item_at_pos(4));
is_deeply($t->get_item_at_pos(4), [five=>"lima"]);
ok(!$t->has_item_at_pos(5));
dies_ok { $t->get_item_at_pos(5) };

$t = HashData::Test::Source::LinesInDATA->new;
is_deeply($t->get_next_item, [one=>"satu"]);

done_testing;
