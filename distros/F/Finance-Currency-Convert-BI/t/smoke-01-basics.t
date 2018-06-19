#!perl

BEGIN {
  unless ($ENV{AUTOMATED_TESTING}) {
    print qq{1..0 # SKIP these tests are for "smoke bot" testing\n};
    exit
  }
}


use 5.010;
use strict;
use warnings;
use Test::More 0.98;
use Test::Warnings;

use Perinci::Import 'Finance::Currency::Convert::BI',
    get_jisdor_rates => {exit_on_error=>1},
    get_currencies   => {exit_on_error=>1};

my $res;

$res = get_jisdor_rates();
is($res->[0], 200, "get_jisdor_rates() succeeds")
    or diag explain $res;

$res = get_currencies();
is($res->[0], 200, "get_currencies() succeeds")
    or diag explain $res;

done_testing;
