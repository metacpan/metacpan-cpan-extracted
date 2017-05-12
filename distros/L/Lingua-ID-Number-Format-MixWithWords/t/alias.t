#!perl

use 5.010;
use strict;
use warnings;
use MixWithWords::ID qw(format_number_mix);
use Test::More 0.98;

is(format_number_mix(num=>1e7), '10 juta');

DONE_TESTING:
done_testing();
