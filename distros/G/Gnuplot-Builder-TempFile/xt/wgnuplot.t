use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Wgnuplot;
use Time::HiRes qw(time);

{
    my $script = gscript;
    isa_ok($script, "Gnuplot::Builder::Script");
    
    my $before = time;
    $script->plot("sin(x)/x");
    cmp_ok(time - $before, "<", 1, "plot() returns immediately");
    diag("it shows plot window, right?");
}

done_testing;
