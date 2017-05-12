use Forks::Super ':test';
use Test::More tests => 18;
use strict;
use warnings;

# spoof that we are in a child process
my $actual_pid = $$;
my $spoof_main_pid = CORE::fork();
exit if $spoof_main_pid == 0;
$Forks::Super::MAIN_PID = $spoof_main_pid;


##### 0: no child fork allowed

$Forks::Super::CHILD_FORK_OK = 0;
my $pid = fork;
ok(!defined($pid), "fork fails for CHILD_FORK_OK==0");


##### -1: child uses CORE::fork

$Forks::Super::MAIN_PID = $spoof_main_pid;
$Forks::Super::CHILD_FORK_OK = -1;
$pid = fork;
exit if $$ != $actual_pid;
ok(defined($pid), "fork ok for CHILD_FORK_OK==-1");
ok(ref($pid) eq '', "CORE fork used for CHILD_FORK_OK<0");


##### +1: child uses F::S::fork, grandchild fork not allowed

$Forks::Super::MAIN_PID = $spoof_main_pid;
$Forks::Super::CHILD_FORK_OK = 1;
$pid = fork;
if ($$ != $actual_pid) {
   my $child_pid = $$;
   my $pid2 = fork;
   exit 17 if $$ != $child_pid;
   if (!defined $pid2) {
      exit 10;
   } elsif (!ref($pid2)) {
      exit 11;
   } else {
      exit 12;
   }
}
ok(defined($pid), "fork ok for CHILD_FORK_OK==1");
ok(ref($pid) eq 'Forks::Super::Job', "F::S::fork used for CHILD_FORK_OK>0");
$pid->wait;
ok($pid->exit_status == 10, "grandchild fork failed for CHILD_FORK_OK==1");


##### +0.5: child uses F::S::fork, grandchild can use CORE::fork

$Forks::Super::MAIN_PID = $spoof_main_pid;
$Forks::Super::CHILD_FORK_OK = 0.5;
$pid = fork;
if ($$ != $actual_pid) {
   my $child_pid = $$;
   my $pid2 = fork;
   exit 17 if $$ != $child_pid;
   if (!defined $pid2) {     # fork failed
      exit 10;
   } elsif (ref($pid2) ne 'Forks::Super::Job') {    # CORE fork
      exit 11;
   } else {                  # F::S::fork
      exit 12;
   }
}
ok(defined($pid), "fork ok for CHILD_FORK_OK>0");
ok(ref($pid) eq 'Forks::Super::Job', "F::S::fork used for CHILD_FORK_OK>0");
$pid->wait;
ok($pid->exit_status == 11, "grandchild CORE::fork for 0<CHILD_FORK_OK<1")
		  or diag($?);


##### +2: child and grandchild can F::S::fork, greatgrandchild no fork

$Forks::Super::MAIN_PID = $spoof_main_pid;
$Forks::Super::CHILD_FORK_OK = 2;
$pid = fork;
if ($$ != $actual_pid) {
    my $child_pid = $$;
    my $pid2 = fork;
    if ($$ != $child_pid) {
	my $gchild_pid = $$;
	my $pid3 = fork;
	exit 27 if $$ != $gchild_pid;
	if (!defined $pid3) {
	    exit 20;
	} elsif (ref($pid3) ne 'Forks::Super::Job') {
	    exit 21;
	} else {
	    exit 22;
	}
    }
    wait;
    my $status = $? >> 8;
    if ($status == 20) {
	exit 10;
    } elsif ($status == 21) {
	exit 11;
    } elsif ($status == 22) {
	exit 12;
    } else {
	exit 18;
    }
}
ok(defined($pid), "fork ok for CHILD_FORK_OK=2");
ok(ref($pid) eq 'Forks::Super::Job', "F::S::fork used for CHILD_FORK_OK>0");
$pid->wait;
ok($pid->exit_status == 10, "fork failed for greatgrandchild CF_OK==2")
    or diag($?);


##### +1.5: child and grandchild can F::S::fork, greatgrandchild CORE fork

$Forks::Super::MAIN_PID = $spoof_main_pid;
$Forks::Super::CHILD_FORK_OK = 1.9;
$pid = fork;
if ($$ != $actual_pid) {
    my $child_pid = $$;
    my $pid2 = fork;
    if ($$ != $child_pid) {
	my $gchild_pid = $$;
	my $pid3 = fork;
	exit 27 if $$ != $gchild_pid;
	if (!defined $pid3) {
	    exit 20;
	} elsif (ref($pid3) ne 'Forks::Super::Job') {
	    exit 21;
	} else {
	    exit 22;
	}
    }
    wait;
    my $status = $? >> 8;
    if ($status == 20) {
	exit 10;
    } elsif ($status == 21) {
	exit 11;
    } elsif ($status == 22) {
	exit 12;
    } else {
	exit 18;
    }
}
ok(defined($pid), "fork ok for CHILD_FORK_OK=2");
ok(ref($pid) eq 'Forks::Super::Job', "F::S::fork used for CHILD_FORK_OK>0");
$pid->wait;
ok($pid->exit_status == 11, "CORE fork used for greatgrandchild 1<CF_OK<2")
    or diag($?);




##### +3: child and grandchild can F::S::fork, greatgrandchild can too

$Forks::Super::MAIN_PID = $spoof_main_pid;
$Forks::Super::CHILD_FORK_OK = 2.1;
$pid = fork;
if ($$ != $actual_pid) {
    my $child_pid = $$;
    my $pid2 = fork;
    if ($$ != $child_pid) {
	my $gchild_pid = $$;
	my $pid3 = fork;
	exit 27 if $$ != $gchild_pid;
	if (!defined $pid3) {
	    exit 20;
	} elsif (ref($pid3) ne 'Forks::Super::Job') {
	    exit 21;
	} else {
	    exit 22;
	}
    }
    wait;
    my $status = $? >> 8;
    if ($status == 20) {
	exit 10;
    } elsif ($status == 21) {
	exit 11;
    } elsif ($status == 22) {
	exit 12;
    } else {
	exit 18;
    }
}
ok(defined($pid), "fork ok for CHILD_FORK_OK=2");
ok(ref($pid) eq 'Forks::Super::Job', "F::S::fork used for CHILD_FORK_OK>0");
$pid->wait;
ok($pid->exit_status == 12, "F::S::fork for greatgrandchild CF_OK>2")
    or diag($?);


