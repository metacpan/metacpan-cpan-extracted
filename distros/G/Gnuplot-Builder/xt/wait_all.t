use strict;
use warnings;
use Test::More;
use Gnuplot::Builder qw(gwait);
use lib "xt";
use testlib::XTUtil;

{
    my $before = time();
    Gnuplot::Builder::Process->wait_all();
    cmp_ok(time() - $before, "<", 1, "finish immediately");
}

{
    Gnuplot::Builder::Script->new->add("pause 1")->run_with(async => 1);
    is Gnuplot::Builder::Process::FOR_TEST_process_num(), 1, "1 process running";
    gwait();
    is Gnuplot::Builder::Process::FOR_TEST_process_num(), 0, "process complete";
}

done_testing;
