#!/usr/bin/perl -w

use strict;
use Math::MatrixReal;
use Benchmark;

my $diag    = [ 1 .. 20 ];
my $n = scalar @$diag;
my $matrix = Math::MatrixReal->new($n,$n);
my $iter = shift;


timethese(50000, { 

# quite a performance hit!
new_diag_each => sub { $matrix = $matrix->each_diag( sub { shift @$diag } ); },

new_diag_elem => sub { map { $matrix->[0][$_][$_] = shift @$diag } ( 0 .. $n-1); }

});
