#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Iterator::Breathe';

my $it = new_ok 'Iterator::Breathe' => [
#    verbose => 1,
];

#is $it->verbose, 1, 'verbose';

my $got;

for my $i ( 0 .. 99 ) {
  $got = $it->iterate;
  is $got, $i + 1, 'ith iteration up';
}

for (my $i = 99; $i >= 0; $i-- ) {
  $got = $it->iterate;
  is $got, $i, 'ith iteration down';
}

done_testing();
