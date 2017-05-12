use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

my $builder = Gnuplot::Builder::Script->new(
    key => "columnheader"
);

is "$builder", "set key columnheader\n", "stringification ok";

done_testing;
