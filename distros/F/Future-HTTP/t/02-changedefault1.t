#!perl -w
use strict;
use warnings;
use Test::More tests=>1;

BEGIN {
    unshift @Future::HTTP::loops, ['Test/More.pm' => 'Config'];
}
use Future::HTTP;

is( Future::HTTP->best_implementation(), 'Config', "changed default backend (pre)");

