use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Process;
use IO::Pipe;

sub fork_mock_gnuplot {
    my $to_mock = IO::Pipe->new;
    my $from_mock = IO::Pipe->new;
    my $pid = fork;
    if(!defined $pid) {
        die "Fork failed";
    }elsif(!$pid) {
        ## child
        $to_mock->reader;
        $from_mock->writer;
        $from_mock->autoflush(1);
        Gnuplot::Builder::Process::MockTool::receive_from_builder $to_mock, $from_mock, sub {
            my ($data) = @_;
            print $from_mock $data;
        };
        exit 0;
    }
    $to_mock->writer;
    $to_mock->autoflush(1);
    $from_mock->reader;
    return ($pid, $to_mock, $from_mock);
}

{
    note("-- with end mark");
    my ($mock_pid, $to_mock, $from_mock) = fork_mock_gnuplot();
    print $to_mock "hoge\n";
    print $to_mock "foo\n";
    print $to_mock "bar\n";

    ## finish
    print $to_mock "print '-'\n";
    print $to_mock q{print '@@@@@@_END_OF_GNUPLOT_BUILDER_@@@@@@'}, "\n";
    print $to_mock "pause mouse close\n" if $Gnuplot::Builder::Process::PAUSE_FINISH;
    print $to_mock "exit\n";

    my $result = do { local $/; <$from_mock> };
    my $exp = sprintf(<<'EXP', $Gnuplot::Builder::Process::PAUSE_FINISH ? "\npause mouse close" : "");
hoge
foo
bar
print '-'
print '@@@@@@_END_OF_GNUPLOT_BUILDER_@@@@@@'
@@@@@@_END_OF_GNUPLOT_BUILDER_@@@@@@%s
exit
EXP
    is $result, $exp, "receive_from_builder ends with the END_MARK";
    waitpid $mock_pid, 0;
}

{
    note("-- without end mark, but close input");
    my ($mock_pid, $to_mock, $from_mock) = fork_mock_gnuplot();
    print $to_mock "HOGE\n";
    print $to_mock "FOO\n";
    print $to_mock "BAR\n";
    close $to_mock;
    my $result = do { local $/; <$from_mock> };
    is $result, <<'EXP', "receive_from_builder ends with EOF";
HOGE
FOO
BAR
EXP
}

done_testing;
