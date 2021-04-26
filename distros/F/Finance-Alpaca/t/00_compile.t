use strict;
use Test::More 0.98;
use lib '../lib', './lib';
#
use_ok $_ for qw(
    Finance::Alpaca
);

done_testing;
1;
