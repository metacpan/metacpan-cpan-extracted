use strict;
use warnings;
use Test::More;

BEGIN { delete $ENV{PERL_GNUPLOT_BUILDER_PROCESS_MAX_PROCESSES}; }

use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;
use Time::HiRes qw(time);
use lib "xt";
use testlib::XTUtil qw(check_process_finish cond_check);

sub plot_time {
    my $builder = shift;
    my $before = time;
    my $ret = $builder->plot_with(dataset => "sin(x)", async => 1);
    cond_check sub {
        is $ret, "", "async plot always returns an empty string";
    };
    return time() - $before;
}

sub process_num { Gnuplot::Builder::Process::FOR_TEST_process_num }

is $Gnuplot::Builder::Process::MAX_PROCESSES, 2, "by default, max is 2";

{
    note("--- limit max processes");
    local $Gnuplot::Builder::Process::MAX_PROCESSES = 3;
    my $builder = Gnuplot::Builder::Script->new(
        term => "postscript eps",
    );
    $builder->add("pause 3");

    cmp_ok plot_time($builder), "<", 1, "1st plot: no time";
    cmp_ok plot_time($builder), "<", 1, "2st plot: no time";
    cmp_ok plot_time($builder), "<", 1, "3st plot: no time";
    is process_num(), 3, "3 processes running";
    cmp_ok plot_time($builder), ">", 2, "4th plot: wait until one of the previous ones";
}

sleep 4;

{
    note("--- no limit");
    local $Gnuplot::Builder::Process::MAX_PROCESSES = 0;
    my $builder = Gnuplot::Builder::Script->new(
        term => "postscript eps"
    );
    $builder->add("pause 1");
    foreach my $round (1..10) {
        cmp_ok plot_time($builder), "<", 1, "round $round: no time";
    }
    is process_num(), 10, "10 processes running";
    sleep 2;
    cmp_ok plot_time($builder), "<", 1, "last round: no time";
    is process_num(), 1, "1 process running";
}

check_process_finish;

done_testing;
