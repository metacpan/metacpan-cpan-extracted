#!perl -w
use strict;
use warnings;
use Test::More tests=>1;

use Future::HTTP;
BEGIN {
    unshift @Future::HTTP::loops, ['Test/More.pm' => 'Config'];
}

is( Future::HTTP->best_implementation(), 'Config', "changed default backend (post)");

