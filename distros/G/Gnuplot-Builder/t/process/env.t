use strict;
use warnings;
use Test::More;
BEGIN {
    $ENV{PERL_GNUPLOT_BUILDER_PROCESS_COMMAND} = "./hoge/gnuplot --persist";
    $ENV{PERL_GNUPLOT_BUILDER_PROCESS_MAX_PROCESSES} = 99999;
    $ENV{PERL_GNUPLOT_BUILDER_PROCESS_PAUSE_FINISH} = 100;
    $ENV{PERL_GNUPLOT_BUILDER_PROCESS_ENCODING} = "shift_jis";
    $ENV{PERL_GNUPLOT_BUILDER_PROCESS_NO_STDERR} = 38;
}
use Gnuplot::Builder::Process;

is_deeply
    \@Gnuplot::Builder::Process::COMMAND,
    ["./hoge/gnuplot --persist"],
    "COMMAND is custormized via env";

is $Gnuplot::Builder::Process::MAX_PROCESSES,
    99999,
    "MAX_PROCESSES is customized via env";

is $Gnuplot::Builder::Process::PAUSE_FINISH,
    100,
    "PAUSE_FINISH is customized via env";

is $Gnuplot::Builder::Process::ENCODING,
    "shift_jis",
    "ENCODING is customized via env";

is $Gnuplot::Builder::Process::NO_STDERR,
    38,
    "NO_STDERR is customized via env";
    
done_testing;
