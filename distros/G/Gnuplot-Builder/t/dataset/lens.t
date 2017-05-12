use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Dataset;
use lib "t";
use testlib::LensUtil qw(test_lens_options);

test_lens_options("Dataset", sub { Gnuplot::Builder::Dataset->new });


done_testing;
