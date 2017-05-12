use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

{
    no warnings "once";
    $Gnuplot::Buidler::Process::NO_STDERR = 0;
    $Gnuplot::Buidler::Process::ASYNC = 0;
    $Gnuplot::Builder::Process::MAX_PROCESSES = 1;
}

{
    note('no_stderr');
    my $s = Gnuplot::Builder::Script->new->set_plot(
        no_stderr => 1
    )->add(<<SCRIPT);
set print
print "STDERR!"
set print "-"
print "STDOUT!"
SCRIPT

    is $s->run, "STDOUT!\n", "STDERR should be suppressed by no_stderr option";
}

{
    note('output and writer');
    my $buf = "";
    my $s = Gnuplot::Builder::Script->new->set_plot(output => "hoge.png", writer => sub { $buf .= $_[0] });
    $s->plot_with(dataset => 'sin(x)');
    like $buf, qr/set output 'hoge.png'/, 'output and writer are effective';
}

{
    note('async');
    my $s = Gnuplot::Builder::Script->new->set_plot(async => 1);
    my $before = time();
    $s->run('pause 3');
    is Gnuplot::Builder::Process::FOR_TEST_process_num(), 1;
    cmp_ok(time() - $before, "<", 2, 'run() returns immediately because async is effective');
    Gnuplot::Builder::Process->wait_all;
}


done_testing;
