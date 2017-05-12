use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;

note("-- synopsis example");

my $result = "";
Gnuplot::Builder::Script->new->run_with(
    writer => sub { $result .= shift },
    do => sub {
        ## SYNOPSIS

        my $builder = Gnuplot::Builder::Script->new();
        $builder->set(
            terminal => 'png size 500,500 enhanced',
            grid     => 'x y',
            xrange   => '[-10:10]',
            yrange   => '[-1:1]',
            xlabel   => '"x" offset 0,1',
            ylabel   => '"y" offset 1,0',
        );
        $builder->setq(output => 'sin_wave.png');
        $builder->unset("key");
        $builder->define('f(x)' => 'sin(pi * x)');
        $builder->plot("f(x)"); ## output sin_wave.png
    
        my $child = $builder->new_child;
        $child->define('f(x)' => 'cos(pi * x)'); ## override parent's setting
        $child->setq(output => 'cos_wave.png');  ## override parent's setting
        $child->plot("f(x)");                    ## output cos_wave.png
        
    }
);

is $result, <<'EXP', "script result OK";
set terminal png size 500,500 enhanced
set grid x y
set xrange [-10:10]
set yrange [-1:1]
set xlabel "x" offset 0,1
set ylabel "y" offset 1,0
set output 'sin_wave.png'
unset key
f(x) = sin(pi * x)
plot f(x)
set terminal png size 500,500 enhanced
set grid x y
set xrange [-10:10]
set yrange [-1:1]
set xlabel "x" offset 0,1
set ylabel "y" offset 1,0
set output 'cos_wave.png'
unset key
f(x) = cos(pi * x)
plot f(x)
EXP

done_testing;
