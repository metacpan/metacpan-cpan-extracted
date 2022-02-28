#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use Test::More 0.98;

use File::Slurper qw(read_text);
use Finance::Currency::Convert::BI qw(get_jisdor_rates get_currencies);

subtest get_jisdor_rates => sub {
    my $page = "$Bin/data/jisdor-2022-02-25.html";
    my $res = get_jisdor_rates(_page_content => scalar read_text($page));
    is($res->[0], 200, "status");
    is(scalar @{$res->[2]}, 10, "num of rates");
    is($res->[2][0]{date}, '2022-02-24', "rate[0] date");
    is($res->[2][0]{rate}, '14371', "rate[0] rate");
};

subtest get_currencies => sub {
    my $page = "$Bin/data/kurs-transaksi-bi-2022-02-25.html";
    my $res = get_currencies(_page_content => scalar read_text($page));
    is($res->[0], 200, "status") or diag explain $res;
    is(scalar keys %{$res->[2]{currencies}}, 24, "num of rates");
    is($res->[2]{currencies}{SGD}{buy}, '10574.73', "SGD buy rate");
};

done_testing;
