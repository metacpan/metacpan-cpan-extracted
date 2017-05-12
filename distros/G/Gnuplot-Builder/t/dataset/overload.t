use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Dataset;

{
    my $builder = Gnuplot::Builder::Dataset->new_file(
        "sample.dat",
        using => "1:2:3",
    );
    $builder->setq_option(title => sub { "Sample Data" });
    is "$builder", q{'sample.dat' using 1:2:3 title 'Sample Data'}, 'stringification is overloaded by to_string()';
}

done_testing;
