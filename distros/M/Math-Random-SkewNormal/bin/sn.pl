#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; -*-
#
# (c) Jiri Vaclavik
#

use strict;
use warnings;

use Math::Random::SkewNormal qw(generate_sn);

if (!$ARGV[0]){
    die <<'EOF';
Usage:
./sn.pl 1 5
where 1st param is skewness
      2nd parameter is count of realizations
EOF
}

my $param = $ARGV[0];
my $realizations = $ARGV[1];

for (1 .. $realizations){
    printf("%.15f\n", generate_sn($param));
}
