use Forks::Super ':test';
use Test::More tests => 16;
use Carp;
use strict;
use warnings;


if ($^O eq 'MSWin32') {
    Forks::Super::Config::CONFIG_module("Win32::API");
    if ($Win32::API::VERSION && $Win32::API::VERSION < 0.71) {
	warn qq[

Win32::API v$Win32::API::VERSION found. v>=0.71 may be required
to pass this test and use the features exercised by this test.

];
    }
}


# repeat test of t/40a, t/40d, and t/40g with the alternate alarm.
#
# if these tests pass but t/40a, t/40d, and t/40g fail, your system
# may benefit from using the "poor man's alarm" to timeout a long-running
# child process. You can set  $PREFER_ALTERNATE_ALARM = 1;   in
# lib/Forks/Super/SysInfo.pm  and run these tests again.
#
# If this test passes on freebsd while t/40a, 40d, 40g fail,
# then the alternate alarm can be a workaround to timeout issues
# on freebsd for Forks::Super v>=0.79
# RT#118474 - also an issue on darwin

Forks::Super::Job::Timeout::warm_up();

SKIP: {
    if ($^O eq 'MSWin32') {
        skip "No need to test alternate alarm on $^O", 3;
    }
    my $pid = fork { sub => sub { sleep 20; exit 0 }, 
		 debug => $^O =~ /freebsd|darwin/i ? 1 : 0,
                 use_alternate_alarm => 1,
		 timeout => 3 };
    my $t = Time::HiRes::time();
    my $p = wait;
    $t = Time::HiRes::time() - $t;
    ok($p == $pid, "$$\\wait successful");
    ok($? != 0, "job expired with non-zero exit STATUS");
    ok($t < 10.0, "Timed out in ${t}s, expected ~3s"); ### 3 # was 5.1 obs 5.98
                                                       ### obs 7.79
}


SKIP: {
    if ($^O eq 'MSWin32') {
        skip "No need to test alternate alarm on $^O", 3;
    }

    my $now = Time::HiRes::time();
    my $future = Time::HiRes::time() + 3;
    my $pid = fork { sub => sub { sleep 20; exit 0 },
		 debug => $^O =~ /freebsd/i ? 1 : 0,
                 use_alternate_alarm => 1,
		 expiration => $future };
    my $t = Time::HiRes::time();
    my $p = wait;
    $t = Time::HiRes::time() - $t;
    ok($p == $pid, "$$\\wait successful");
    okl($t < 9.95, "wait took ${t}s, expected ~3s");                   ### 5 ###

    ## this is an intermittent (5%?) failure point on solaris, v0.44-0.49.
    ok($? != 0, "job expired with non-zero STATUS $? should be != 0"); ### 6 ###

    #######################################################
}

SKIP: {

    if (!$Forks::Super::SysInfo::CONFIG{'getpgrp'}) {
	if (!($^O eq 'MSWin32' 
	      && Forks::Super::Config::CONFIG_module("Win32::Process"))) {

	    skip "Skipping tests about timing out grandchildren "
		. "because setpgrp() and TASKKILL are unavailable", 6;
	}
    }

    if ($^O eq 'MSWin32') {
        skip "No need to test alternate alarm on $^O", 6;
    }



    # a child process that times out should clean up after
    # itself (i.e., kill off its grandchildren).
    #
    # This is harder to do on some systems than on others.

    unlink "t/out/spawn.pids.$$";
    my $t = Time::HiRes::time();

    # set up a program to spawn many other processes and to run
    # for about 15 seconds.
    my $pid = fork { timeout => 5, 
                     cmd => [ $^X, "t/spawner-and-counter.pl",
                              "t/out/spawn.pids.$$", "3", "15" ],
                     use_alternate_alarm => 1,
    };
    my $t2 = Time::HiRes::time();

    my $p = wait;
    my $t3 = Time::HiRes::time();
    ($t,$t2) = ($t3-$t,$t3-$t2);
    my $j = Forks::Super::Job::get($pid);
    my $t4 = $j->{end} - $j->{start};
    okl($p == $pid && $t >= 4.5 && $t4 <= 10 && $t2 <= 10,  # was 8/9 obs 11.26
	"external prog took ${t}s ${t2}s ${t4}s, expected 5-7s");

    if ($t <= 14) {
	sleep 20 - $t;
    } else {
	sleep 1;
    }

    open(my $PIDS, "<", "t/out/spawn.pids.$$");
    my @pids = <$PIDS>;
    for (@pids) { s/\s+$// }
    close $PIDS;
    ok(@pids == 4, "spawned " . scalar @pids . " procs, Expected 4");
    for (my $i=0; $i<4 && $i<@pids; $i++) {
	my ($pid_i, $file_i) = split /,/, $pids[$i];
	open(my $F_I, "<", $file_i);
	my @data_i = <$F_I>;
	close $F_I;
	my @orig_data_i = @data_i;
	pop @data_i while @data_i > 0 && $data_i[-1] !~ /\S/;
	my $last_count_i = $data_i[-1] + 0;

	# failure point, Cygwin v5.6.1
	ok($last_count_i >= 5,
	   "Last count from $file_i was $last_count_i, "
	   . "Expect >= 5");   ### 9-12 ###
	if ($last_count_i < 5) {
	    print STDERR "File contents were:\n", @orig_data_i, "\n";
	}
	($file_i) = $file_i =~ /(.*)/;
	if ($last_count_i > 5) {
	    unlink $file_i;
	}
    }
    unlink "t/out/spawn.pids.$$";

    waitall;
} # end SKIP

SKIP: {

    if (!$Forks::Super::SysInfo::CONFIG{'getpgrp'}
	&& $^O ne 'MSWin32') {
	skip "setpgrp() unavailable, can't test process group manipulation", 4;
    }
    if ($^O eq 'MSWin32') {
        skip "No need to test alternate alarm on $^O", 4;
    }

    my ($job, $pgid, $ppgid);

    # job without expiration
    $ppgid = $^O eq 'MSWin32' ? $$ : getpgrp();
    my $pid = fork { sub => sub { sleep 5 } };
    $job = Forks::Super::Job::get($pid);
    $pgid = $job->{pgid};
    my $p = waitpid -$ppgid, 0;
    ok($p == $pid && $pgid == $ppgid, 
       "child pgid set to parent pgid")
	or diag("Expect waitpid output $p == pid $pid, ",
		"pgid $pgid == ppgid $ppgid");

    # job with expiration
    $pid = fork { timeout => 3,
                  sub => sub { sleep 5 }, 
                  use_alternate_alarm => 1 };
    $job = Forks::Super::Job::get($pid);
    $pgid = $job->{pgid};
    ok($pgid != $ppgid, "child pgid != parent pgid with timeout");
    $p = waitpid -$ppgid, 0;
    ok($p == -1, "waitpid on parent pgid returns -1");
    $p = waitpid -$pgid, 0;
    ok($p == $pid, "waitpid on child pgid returns child pid")
	or diag("waitpid returned $p, expected $pid");
} # end SKIP
