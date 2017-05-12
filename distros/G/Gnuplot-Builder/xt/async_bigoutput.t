use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;
use lib "xt";
use testlib::XTUtil qw(check_process_finish);

{
    my $script = Gnuplot::Builder::Script->new(
        samples => 10000,
        term => "postscript",
        xrange => "[-100:100]",
    );
    $script->plot_with(dataset => "sin(x)", async => 1);
    sleep 1;
    Gnuplot::Builder::Process->FOR_TEST_clear_zombies;
    is(Gnuplot::Builder::Process->FOR_TEST_process_num, 0, "all processes finished.");
}

check_process_finish;

done_testing;
