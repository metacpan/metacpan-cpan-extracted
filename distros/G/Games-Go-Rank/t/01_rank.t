#!/usr/bin/env perl
use warnings;
use strict;
use Games::Go::Rank;
use Test::More tests => 87;

sub gt_ok ($$) {
    my ($rank1, $rank2) = @_;
    ok( Games::Go::Rank->new(rank => $rank1) >
          Games::Go::Rank->new(rank => $rank2),
        "both OO: $rank1 > $rank2"
    );
    ok(Games::Go::Rank->new(rank => $rank1) > $rank2,
        "lhs OO: $rank1 > $rank2");
    ok($rank1 > Games::Go::Rank->new(rank => $rank2),
        "rhs OO: $rank1 > $rank2");
    lt_ok($rank2, $rank1);
}

sub lt_ok ($$) {
    my ($rank1, $rank2) = @_;
    ok( Games::Go::Rank->new(rank => $rank1) <
          Games::Go::Rank->new(rank => $rank2),
        "both OO: $rank1 < $rank2"
    );
    ok(Games::Go::Rank->new(rank => $rank1) < $rank2,
        "lhs OO: $rank1 < $rank2");
    ok($rank1 < Games::Go::Rank->new(rank => $rank2),
        "rhs OO: $rank1 < $rank2");
}

sub value_ok ($$) {
    my ($rank, $value) = @_;
    is(Games::Go::Rank->new(rank => $rank)->as_value,
        $value, "value of $rank is $value");
    is(Games::Go::Rank->new->from_value($value)->rank,
        $rank, "rank of value $value is $rank");
}

sub normalized_value_ok ($$) {
    my ($rank, $value) = @_;
    is(Games::Go::Rank->new(rank => $rank)->as_value,
        $value, "value of $rank is $value");
}
value_ok '20k',               -19;
value_ok '2k',                -1;
value_ok '1k',                0;
value_ok '1d',                1;
value_ok '4d',                4;
value_ok '7d',                7;
value_ok '1p',                8;
value_ok '9p',                16;
normalized_value_ok '20 kyu', -19;
normalized_value_ok '1-dan',  1;
normalized_value_ok '1d?',    1;
normalized_value_ok '1d*',    1;
normalized_value_ok '9-pro',  16;
gt_ok '20k',                  '21k';
gt_ok '1k',                   '2k';
gt_ok '1d',                   '1k';
gt_ok '2d',                   '1d';
gt_ok '7d',                   '4d';
gt_ok '1p',                   '7d';
gt_ok '2p',                   '1p';
gt_ok '9p',                   '8p';
gt_ok '1p',                   '1k';
gt_ok '1-pro',                '6-dan';
gt_ok '3d?',                  '2d*'
