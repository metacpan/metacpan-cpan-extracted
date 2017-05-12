#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::Slurper qw(read_text);
use Finance::Currency::Convert::BI qw(get_jisdor_rates);
use Test::More 0.98;

my $page = "$Bin/data/jisdor-2015-10-23.html";

subtest get_jisdor_rates => sub {
    my $res = get_jisdor_rates(_page_content => scalar read_text($page));
    is($res->[0], 200, "status");
    is(scalar @{$res->[2]}, 14, "num of rates");
    is($res->[2][0]{date}, '2015-10-23', "rate[0] date");
    is($res->[2][0]{rate}, '13491', "rate[0] rate");
};

done_testing;
