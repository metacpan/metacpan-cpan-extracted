use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder;

{
    note("--- synopsis example");
    my $script = gscript(grid => "y", mxtics => 5, mytics => 5);
    $script->setq(
        xlabel => 'x values',
        ylabel => 'y values',
        title  => 'my plot'
    );
    $script->define('f(x)' => 'sin(x) / x');

    ## well, that's not exactly same as the synopsis...
    my $result = "";
    $script->plot_with(
        dataset => [
            gfile('result.dat',
                  using => '1:2:3', title => "'Measured'", with => "yerrorbars"),
            gfunc('f(x)', title => "'Theoretical'", with => "lines")
        ],
        writer => sub { $result .= shift },
    );
    is $result, <<EXP, "build script OK";
set grid y
set mxtics 5
set mytics 5
set xlabel 'x values'
set ylabel 'y values'
set title 'my plot'
f(x) = sin(x) / x
plot 'result.dat' using 1:2:3 title 'Measured' with yerrorbars,f(x) title 'Theoretical' with lines
EXP
}

done_testing;
