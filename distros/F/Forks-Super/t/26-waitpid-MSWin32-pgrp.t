use Forks::Super ':test';
use Test::More tests => 10;
use strict;
use warnings;

# emulation of process groups on MSWin32.
# for now I don't know how useful this is.

SKIP: {

    if ($^O ne 'MSWin32') {
	skip 'test only for process group emulation on MSWin32', 10;
    }

    my $pgid = $$;

    my $job1 = fork { sub => sub { sleep 1 } };
    my $pid1 = waitpid $job1+0, 0;
    ok($pid1 == $job1, "waitpid on child pid ok");

    my $job2 = fork { sub => sub { sleep 2 } };
    my $job3 = fork { sub => sub { sleep 2 } };

    my $pid2 = waitpid -$pgid, 0;
    ok($pid2 == $job2 || $pid2 == $job3, "waitpid on parent pgid $pgid ok");

    my $pid3 = waitpid -$pgid, 0;
    ok($pid3 == $job2 || $pid3 == $job3, '2nd waitpid on parent pgid ok');
    ok($pid2 != $pid3, '2nd waitpid on parent pgid returns different result');

    #######################################################

    my $job5 = fork { cmd => [ $^X, "t/external-command.pl", "-s=1" ] };
    my $job6 = fork { exec => [ $^X, "t/external-command.pl", "-e=2" ] };
    my $job7 = fork { cmd => [ $^X, "t/external-command.pl", "-e=3" ] };

    # tests 5,6,8 fail sometimes
    my $pid5 = waitpid -$pgid, 0;
    ok($pid5 == $job5 || $pid5 == $job6 || $pid5 == $job7,   ### 5 ###
       'waitpid on parent pgid for cmd => ' . $pid5 )
        or diag "expected $job5 or $job6 or $job7";

    my $pid6 = waitpid -$pgid, 0;
    ok(($pid6 == $job5 || $pid6 == $job6 || $pid6 == $job7)  ### 6 ###
       && $pid6 != $pid5,
       'waitpid on parent pgid for cmd => ' . $pid6 )
        or diag "expected $job5 or $job6 or $job7";

    my $pid7 = waitpid -1,0;
    ok(($pid7 == $job5 || $pid7 == $job6 || $pid7 == $job7)  ### 7 ###
       && $pid7 != $pid5 && $pid7 != $pid6,
       'waitpid on parent pgid for cmd => ' . $pid7 )
        or diag "expected $job5 or $job6 or $job7";

    ok($job5->{pgid} == $pgid && $job6->{pgid} == $pgid,     ### 8 ###
       "fork-to-cmd/fork-to-exec in MSWin32 keep pgid")
        or diag "expected $job5->{pgid} or $job6->{pgid} to be $pgid";

    

    my $job8 = fork { cmd => [ $^X, "t/external-command.pl", "-e=hello" ],
		      timeout => 10 };

    my $pid8 = waitpid -$pgid, 0, 5;
    my $pid9 = waitpid -$job8, 0, 5;
    my $pid10 = waitpid -$job8->{pgid}, 0, 5;

    ok($job8->{pgid} != $pgid,
       "fork-to-cmd/fork-to-exec in MSWin32 with timeout changes pgid");

    ok(!isValidPid($pid8) && !isValidPid($pid9) 
           && isValidPid($pid10) && $pid10==$job8,
       "waitpid on process group only effective for new child pgid");

    diag "waitpid result for cmd with timeout: $pid8,$pid9,$pid10";

}

waitall;
