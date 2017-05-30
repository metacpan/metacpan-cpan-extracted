#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 2;

require Hash::Normalize;

my %syms = (
 normalize         => '\%;$',
 get_normalization => '\%',
);

for (sort keys %syms) {
 eval { Hash::Normalize->import($_) };
 is $@,            '',        "import $_";
 is prototype($_), $syms{$_}, "prototype $_";
}
