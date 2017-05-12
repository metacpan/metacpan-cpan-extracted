use strict;
use warnings;
use Test::More tests => 8;
use Forks::Super ':test';


# what to test?
#
#     after a job launch, $__OPEN_FH increases
#     if $__OPEN_FH > $__MAX_OPEN_FH
#         if ON_TOO_MANY... is 'fail'
#             $__OPEN_FH keeps increasing
#             read handles from completed jobs are still available
#



$Forks::Super::Job::Ipc::__MAX_OPEN_FH = 35;
$Forks::Super::Job::Ipc::_FILEHANDLES_PER_STRESSED_JOB
    = 7;     # +3 std makes 10 fh/job
$Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES = 'fail';
close STDIN;
open STDIN,'<',&DEVNULL;

sub teecat {
    my $end_at = time + 5;
    while (time < $end_at) {
        while (defined ($_ = <STDIN>)) {
            if ($_ eq "EOF\n") {
                exit;
            }
	    print STDERR $_;
	    print STDOUT $_;
        }
        Forks::Super::pause();
        seek STDIN, 0, 1;
    }
}

sub numfh { $Forks::Super::Job::Ipc::__OPEN_FH; }
sub numwarn { $Forks::Super::Job::Ipc::TOO_MANY_OPEN_FH_WARNINGS; }

SKIP: {
    if ($Forks::Super::SysInfo::MAX_OPEN_FH < 35) {
	skip 'MAX_OPEN_FH on this system is already too low', 7;
    }

    my $o1 = numfh();
    my $pid = fork { child_fh => 'stress', sub => \&teecat };
    $pid->write_stdin("hello\nEOF\n");
    my $o2 = numfh();

    ok($o2 > $o1, 'launching job increases open fh');
    $pid->close_fh('stress');
    $pid->wait;
    my $o3 = numfh();
    ok($o3 < $o2, 'closing job decreases open fh');

############################################

    $o1 = numfh();
    for (1..5) {
        if ($Forks::Super::SysInfo::MAX_OPEN_FH < 10 * $_) {
            # my devio.us account says MAX_OPEN_FH = 46, so yeah, this happens
            ok(1, "skip: child $_ to stress open filehandles");
            $Forks::Super::Job::Ipc::__MAX_OPEN_FH -= 10;
            next;
        }
	
        my $pid = fork { child_fh => 'stress', sub => \&teecat };
        $pid->write_stdin("hello\nEOF\n");
        $o2 = numfh();
        ok($o2 > $o1, "launch [$_] increases open fh");
        $o1 = $o2;
        $pid->wait;
    }
    my $w1 = numwarn();
    ok( $w1 > 0, 'fail mode: exceeding max open triggered warnings' );
    waitall;
}

###############################################
