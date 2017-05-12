use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Process;
use Gnuplot::Builder::Script;
use Time::HiRes qw(time);

my $REAL_GNUPLOT = $ENV{REAL_GNUPLOT} || "gnuplot";
my $start_time = time;

@Gnuplot::Builder::Process::COMMAND =
    ("gnuplot_builder_tempfile_wrapper", $REAL_GNUPLOT, "--persist");

note("REAL_GNUPLOT = $REAL_GNUPLOT");
note("command: " . join(" ", @Gnuplot::Builder::Process::COMMAND));

my $script = Gnuplot::Builder::Script->new;
$script->plot("sin(x)");
cmp_ok(time - $start_time, "<", 1, "plot() method returns immediately");

diag("it shows a plot window, right?");

done_testing;

