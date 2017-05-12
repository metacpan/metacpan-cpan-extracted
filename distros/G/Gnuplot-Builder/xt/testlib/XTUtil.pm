package testlib::XTUtil;
use strict;
use warnings;
use Test::More;
use Test::Builder;
use Exporter qw(import);
use Gnuplot::Builder::Process;

$Gnuplot::Builder::Process::ASYNC = 0;

our @EXPORT_OK = qw(if_no_file check_process_finish cond_check);

sub if_no_file {
    my ($filename, $code) = @_;
  SKIP: {
        if(-e $filename) {
            skip "File $filename exists. Remove it first.", 1;
        }
        note("--- output $filename");
        $code->($filename);
    }
}

sub check_process_finish {
    note("wait for all managed sub-processes to finish");
    Gnuplot::Builder::Process->wait_all();
    note("Gnuplot::Builder params:");
    note("  COMMAND: " . (join " ", @Gnuplot::Builder::Process::COMMAND));
    note("  PAUSE_FINISH: $Gnuplot::Builder::Process::PAUSE_FINISH");
    my $ps = `ps aux | grep gnuplot | grep -v 'grep gnuplot'`;
    my $status = ($? >> 8);
    if($!) {
        note("ps returned error: $!");
    }else {
        note("result of ps:");
        note($ps);
    }
}

sub cond_check {
    my ($check_sub) = @_;
    if($^O eq 'MSWin32') {
        note("Check is skipped in Windows");
        return;
    }
    $check_sub->();
}

1;

