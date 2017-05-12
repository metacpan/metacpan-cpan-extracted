use strict;
use warnings FATAL => "all";
use Test::More;

note("--- synopsis");

use Gnuplot::Builder::Dataset;
use Gnuplot::Builder::Template qw(gusing gevery);
    
my $dataset = Gnuplot::Builder::Dataset->new_file("sample.dat");
$dataset->set(
    using => gusing(
        -x => 1, -xlow => 2, -xhigh => 3,
        -y => 4, -ylow => 5, -yhigh => 6
    ),
    every => gevery(
        -start_point => 1, -end_point => 50
    ),
    with => "xyerrorbars",
);
is "$dataset", q{'sample.dat' using 1:4:2:3:5:6 every 1::1::50 with xyerrorbars};

is $dataset->get_option("using")->get("-xlow"), 2;
is $dataset->get_option("every")->get("-start_point"), 1;

done_testing;
