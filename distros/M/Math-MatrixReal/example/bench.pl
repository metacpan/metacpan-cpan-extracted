#!/usr/bin/perl -w

use Math::MatrixReal;
use Benchmark;

my @matrices = map { Math::MatrixReal->new_random($_) } qw(5 10 15 20);

my $iter = 2000;

for my $matrix ( @matrices ) {
        my ($r,$c) = $matrix->dim;
        print "Benchmarking $r x $c matrix\n";

        timethese($iter, {
              'overload_left_multiply  '     => sub { 7*$matrix                          },
              'overload_right_multiply '     => sub { $matrix*7                          },

               # this is twice as fast, but gives you CPT
              'function_multiply       '     => sub { $matrix->multiply_scalar($matrix,7)},
        });

        timethese($iter,
            { 
              'matrix_squared     '     => sub { $matrix ** 2                       },
              'matrix_times_itself'     => sub { $matrix * $matrix                  },
              'det                '     => sub { $matrix->det                       },
              'det_LR             '     => sub { $matrix->decompose_LR->det_LR      },
              'inverse            '     => sub { $matrix->inverse()                 },
              'to_negative_one    '     => sub { $matrix ** -1                      },
              'invert_LR          '     => sub { $matrix->decompose_LR->invert_LR   },
            });



}
