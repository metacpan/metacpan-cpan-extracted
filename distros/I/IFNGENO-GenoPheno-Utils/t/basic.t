use strict;
use warnings;
use Test::More tests => 2;

use IFNGENO::GenoPheno::Utils qw(clean normalise_raw_gt);

is(clean("  hello  "), "hello", "clean works");
is(normalise_raw_gt(" aa "), "AA", "genotype normalization works");