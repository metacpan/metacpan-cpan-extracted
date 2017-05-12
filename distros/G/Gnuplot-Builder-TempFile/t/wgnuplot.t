use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Wgnuplot;

my $script = gscript();
isa_ok($script, "Gnuplot::Builder::Script", "Gnuplot::Builder is loaded.");

is_deeply(\@Gnuplot::Builder::Process::COMMAND,
          [qw(gnuplot_builder_tempfile_wrapper wgnuplot -persist)],
          "COMMAND is replaced OK");

done_testing;
