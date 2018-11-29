#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Finance::SE::IDX::Static qw(
                                   list_idx_boards
                                   list_idx_firms
                                   list_idx_sectors
                           );

my $res;

subtest list_idx_boards => sub {
    $res = list_idx_boards();
    is($res->[0], 200);
    is(scalar(@{ $res->[2] }), 2);
};

subtest list_idx_firms => sub {
    $res = list_idx_firms();
    is($res->[0], 200);
    is(scalar(@{ $res->[2] }), 615);

    $res = list_idx_firms(sector => "AGRI", board => "PENGEMBANGAN");
    is($res->[0], 200);
    is(scalar(@{ $res->[2] }), 5);
};

subtest list_idx_sectors => sub {
    $res = list_idx_sectors();
    is($res->[0], 200);
    is(scalar(@{ $res->[2] }), 9);
};

done_testing;
