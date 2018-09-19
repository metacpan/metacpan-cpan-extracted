#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Finance::SE::Catalog;

my $cat = Finance::SE::Catalog->new;

subtest "by_code" => sub {
    my $res;

    ok($res = $cat->by_code("idx"));
    is($res->{code}, "IDX");

    ok($res = $cat->by_code("BEI"));
    is($res->{code}, "IDX");

    ok($res = $cat->by_code("bej"));
    is($res->{code}, "IDX");

    dies_ok { $res = $cat->by_code("xxx") };
};

subtest "by_name" => sub {
    my $res;

    ok($res = $cat->by_name("new york stock exchange"));
    ok($res->{code}, "IDX");

    ok($res = $cat->by_name("Bursa Efek Indonesia"));
    ok($res->{code}, "IDX");

    dies_ok { $cat->by_name("foo bar") };
};

subtest "all_codes" => sub {
    my @codes = $cat->all_codes;
    ok(@codes);
};

subtest "all_data" => sub {
    my @all_data = $cat->all_data;
    ok(@all_data);
};

DONE_TESTING:
done_testing;
