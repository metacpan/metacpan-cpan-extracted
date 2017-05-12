#!/usr/bin/env perl
# For Emacs: -*- mode:cperl; mode:folding; -*-
#
# (c) Jiri Vaclavik
#

use strict;
use warnings;

use Data::Dumper;
use Math::Random::SkewNormal qw(generate_sn_multi);

if (!$ARGV[0]){
    die <<'EOF';
Usage:
./sn_multi.pl 100 0 0 1 0 0 1
will generate 100 realizations of SN_n ditribution, where
    delta = (0, 0)
    Omega = unit matrix
EOF
}

my $realizations = shift @ARGV;
my $n = int sqrt @ARGV;
my $delta = [];
my $A = [];

for my $d (0 .. $n-1){
    $delta->[$d] = shift @ARGV;
}

for my $row (0 .. $n-1){
    for my $col (0 .. $n-1){
        $A->[$row][$col] = shift @ARGV;
    }
}

$, = "\t";
for (1 .. $realizations){
    print @{generate_sn_multi($delta, $A)}, "\n";
}
