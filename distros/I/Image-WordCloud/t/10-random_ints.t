use strict;
use warnings;

use Test::More tests => 4;
use Image::WordCloud;

my $wc = Image::WordCloud->new();

my $lower = 1;
my $upper = 10;

my $i = $wc->_random_int_between($lower, $upper);

ok($i >= $lower, "_random_int_between lower bound obeyed");
ok($i <= $upper, "_random_int_between upper bound obeyed");

$i = $wc->_random_int_between($upper, $lower);
ok($i >= $lower && $i <= $upper, "_random_int_between reverses argument order if necessary");

$i = $wc->_random_int_between($upper, $upper);
ok($i == $upper, "_random_int_between handles same number specified twice");