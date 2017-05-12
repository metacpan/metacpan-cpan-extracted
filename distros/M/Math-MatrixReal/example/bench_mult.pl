#!/usr/bin/perl -w

use Math::MatrixReal;
use Benchmark;

my @matrices = map { Math::MatrixReal->new_random($_) } qw(10 20 50 100 200 300);

my $iter = 2000;

for my $matrix ( @matrices ) {
        my ($r,$c) = $matrix->dim;
        my $b = $matrix->new_random($r);

        print "Benchmarking $r x $c matrix\n";

        timethese($iter, {
              '*       '         => sub { $matrix*$b },
              'multiply'         => sub { $matrix->multiply($b) },
        });

        timethese($iter,
            { 
              'matrix_squared        '     => sub { $matrix ** 2                       },
              'matrix_times_itself   '     => sub { $matrix * $matrix                  },
              'matrix_multiply_itself'     => sub { $matrix->multiply($matrix)         },
            }
        )
}
