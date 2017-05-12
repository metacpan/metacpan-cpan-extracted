use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

{
    note("--- example in POD");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(
        terminal => 'png size 500,500',
        xrange => '[100:200]',
        output => '"foo.png"',
    );
    is $builder->to_string(), <<EXP;
set terminal png size 500,500
set xrange [100:200]
set output "foo.png"
EXP

    $builder->set(
        terminal => 'postscript eps size 5.0,5.0',
        output => '"foo.eps"'
    );
    is $builder->to_string(), <<EXP;
set terminal postscript eps size 5.0,5.0
set xrange [100:200]
set output "foo.eps"
EXP
}

done_testing;
