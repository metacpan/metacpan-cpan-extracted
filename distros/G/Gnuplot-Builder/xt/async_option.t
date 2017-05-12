use strict;
use warnings;
use Test::More;
use lib "xt";
use testlib::XTUtil qw(check_process_finish cond_check);
use Gnuplot::Builder ();

sub process_num { Gnuplot::Builder::Process::FOR_TEST_process_num() }

{
    local $Gnuplot::Builder::Process::ASYNC = 1;
    local $Gnuplot::Builder::Process::MAX_PROCESSES = 0;
    
    my $script = Gnuplot::Builder::Script->new(
        term => "dumb"
    );
    $script->add("print 'hogehoge'");
    $script->add("pause 1");
    my $before = time();
    foreach my $i (1..3) {
        my $ret = $script->plot("sin(x)");
        is $ret, "", "plot $i: result is empty because async is ON";
    }
    is process_num(), 3, "3 async processes running";
    cmp_ok(time() - $before, "<", 0.9, "plot() returns immediately");
    Gnuplot::Builder::Process->wait_all();
    is process_num(), 0, "all completed";
}

{
    local $Gnuplot::Builder::Process::ASYNC = 1;
    local $Gnuplot::Builder::Process::MAX_PROCESSES = 0;
    
    my $script = Gnuplot::Builder::Script->new(
        term => "dumb"
    );
    foreach my $i (1..2) {
        my $ret = $script->run_with(async => 0, do => sub {
            my $writer = shift;
            $writer->("print 'hogehoge'\n");
            $writer->("pause 1\n");
            $writer->("plot sin(x)\n");
        });
        cond_check sub {
            like $ret, qr/^hogehoge/, "plot $i: got result because async is explicitly OFF";
        };
        my $before = time();
        Gnuplot::Builder::Process->wait_all();
        cmp_ok(time() - $before, "<", 0.5, "plot $i: process is basically finished already");
        is process_num(), 0, "plot $i: no process because async is explicitly OFF";
    }
}

check_process_finish;
done_testing;
