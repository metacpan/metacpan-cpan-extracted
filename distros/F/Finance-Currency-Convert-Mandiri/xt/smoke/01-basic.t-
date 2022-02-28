#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Perinci::Import 'Finance::Currency::Convert::Mandiri',
    get_currencies => {exit_on_error=>1};

my $res = get_currencies();
is($res->[0], 200, "get_currencies() succeeds")
    or diag explain $res;

done_testing;
