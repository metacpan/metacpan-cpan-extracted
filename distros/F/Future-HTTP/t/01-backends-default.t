#!perl -w
use strict;
use warnings;
use Test::More;

use Future::HTTP;

is( Future::HTTP->best_implementation(), 'Future::HTTP::Tiny', "The default backend is HTTP::Tiny");

done_testing();