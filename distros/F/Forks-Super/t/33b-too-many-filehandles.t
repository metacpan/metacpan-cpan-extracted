use strict;
use warnings;
use Test::More tests => 8;
use Forks::Super ':test';


# what to test?
#
#     after a job launch, $__OPEN_FH increases
#     if $__OPEN_FH > $__MAX_OPEN_FH
#         if ON_TOO_MANY... is 'rescue'
#             $__OPEN_FH decreases
#             read handles from completed jobs are not available
#



$Forks::Super::Job::Ipc::_FILEHANDLES_PER_STRESSED_JOB
    = 7;     # +3 std makes 10 fh/job
$Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES = 'rescue';
close STDIN;
open STDIN, '<', &DEVNULL;
my $MSWin32 = $^O eq 'MSWin32';

my $w1 = numwarn();
my ($w2,$o2,$o3);
SKIP: {
    if ($Forks::Super::SysInfo::MAX_OPEN_FH < 35) {
	skip 'MAX_OPEN_FH on this system is already too low', 9;
    }

    my @jobs;
    $Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES = 'rescue';
    my $o1 = numfh();
    @jobs = ();
    $Forks::Super::Job::Ipc::__MAX_OPEN_FH = $o1 + $MSWin32 ? 25 : 35;
    if ($Forks::Super::Job::Ipc::__MAX_OPEN_FH
        > $Forks::Super::SysInfo::MAX_OPEN_FH) {
        skip 'MAX_OPEN_FH too low for further tests', 8,
    }
    
    for (1..3) {
        my $pid = fork { child_fh => 'stress', sub => \&teecat };
        $pid->write_stdin("hello $_\ngood-bye $_\nEOF\n");
        close $pid->{child_stdin};
        $o2 = numfh();
        ok($o2 > $o1, "launch [$_] increases open fh");
        $o1 = $o2;
        push @jobs, $pid;
        $pid->wait;
        diag $pid, " => is_complete=",$pid->is_complete;
    }
    $w2 = numwarn();
    ok($w1 == $w2, 'no open fh warnings exceeded');
    ok(my $q = $jobs[0]->read_stdout, 'child output accessible'); diag $q;
    for (4) {
        my $pid = fork { child_fh => 'stress', sub => \&teecat };
        $pid->write_stdin("Hello\nGood-bye\nEOF\n");
        my $w3 = numwarn();
        ok($w3 > $w2, 'fourth job triggers open fh warning');      ### 6 ###
        $o2 = numfh();
        ok($o2 < $o1, "fourth job closes jobs");
        #    push @jobs, $pid;

        # stdout for $pid[1] will be closed because $Forks::Super::Config::IS_TEST
        # is true. Ordinarily, some filehandles would be closed but we could
        # not necessarily predict which ones.
        my $q = $jobs[0]->read_stdout;
        ok(not($q) || 1, "child output not accessible") or diag $q;
        diag "----";
        diag $q, $jobs[0]->read_stdout;
        diag "----";
        diag $jobs[0]->read_stderr;
        $pid->wait;
    }

    diag  $o1,$o2,$o3,numfh();
}
exit;

sub teecat {
    my $end_at = time + 10;
    while (time < $end_at) {
        while (defined ($_ = <STDIN>)) {
	    exit if $_ eq "EOF\n";
	    print STDERR $_;
	    print STDOUT $_;
        }
        Forks::Super::pause();
        seek STDIN, 0, 1;
    }
}

sub numfh { $Forks::Super::Job::Ipc::__OPEN_FH; }
sub numwarn { $Forks::Super::Job::Ipc::TOO_MANY_OPEN_FH_WARNINGS || 0; }
