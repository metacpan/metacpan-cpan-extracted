use strict;
use warnings;
use Gnuplot::Builder;

my $filename = shift @ARGV;
die "filename is not specified" if !$filename;
gscript(
    term => "png size 500,500",
    xrange => "[-5:5]",
)->setq(
    title => "plotter.pl",
    xlabel => "plotter x",
    ylabel => "plotter y"
)->plot_with(
    output => $filename,
    dataset => "x * x"
);
