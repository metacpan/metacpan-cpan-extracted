use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

{
    my $builder = Gnuplot::Builder::Script->new(term => 'png');
    is $builder->to_string(), "set term png\n";
}

{
    my $builder = Gnuplot::Builder::Script->new('grid');
    is $builder->to_string(), "set grid\n";
}

done_testing;
