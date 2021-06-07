#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use HashData::Test::Spec::Basic;

my $hd = HashData::Test::Spec::Basic->new;

subtest "has_next_item, get_next_item, reset_iterator" => sub {
    #$hd->reset_iterator;
    ok($hd->has_next_item);
    is_deeply($hd->get_next_item, [five=>"lima"]);
    is_deeply($hd->get_next_item, [four=>"empat"]);
    $hd->reset_iterator;
    is_deeply($hd->get_next_item, [five=>"lima"]);
    is_deeply($hd->get_next_item, [four=>"empat"]);
    is_deeply($hd->get_next_item, [one=>"satu"]);
    is_deeply($hd->get_next_item, [three=>"tiga"]);
    is_deeply($hd->get_next_item, [two=>"dua"]);
    ok(!$hd->has_next_item);
    dies_ok { $hd->get_next_item };
};

subtest "get_item_count, get_iterator_pos" => sub {
    $hd->reset_iterator;
    is($hd->get_iterator_pos, 0);
    is($hd->get_item_count, 5);
};

subtest get_all_items => sub {
    is_deeply([$hd->get_all_items], [
        [five  => "lima"],
        [four  => "empat"],
        [one   => "satu"],
        [three => "tiga"],
        [two   => "dua"],
    ]);
};

subtest each_item => sub {
    my $row;
    $hd->each_item(sub { $row //= $_[0] });
    is_deeply($row, [five=>"lima"]);
};

subtest "get_item_at_key, has_item_at_key, get_all_keys" => sub {
    is_deeply($hd->get_item_at_key("three"), "tiga");
    ok($hd->has_item_at_key("three"));

    dies_ok { $hd->get_item_at_key("six") };
    ok(!$hd->has_item_at_key("six"));

    is_deeply($hd->get_all_keys, [qw/five four one three two/]);
};

done_testing;
