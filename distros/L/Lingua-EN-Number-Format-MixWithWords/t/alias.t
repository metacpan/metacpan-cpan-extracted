#!perl

use 5.010;
use strict;
use warnings;
use MixWithWords::EN qw(format_number_mix);
use Test::More 0.96;

is(format_number_mix(num=>1e7, scale=>'short'), '10 million');

DONE_TESTING:
done_testing();
