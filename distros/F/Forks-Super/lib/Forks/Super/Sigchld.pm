#
# Forks::Super::Sigchld - SIGCHLD handler for Forks::Super module
#

package Forks::Super::Sigchld;
use Forks::Super::Debug qw(:all);
use Forks::Super::Util qw(:all);
use Signals::XSIG;
use POSIX ':sys_wait_h';
# use Time::HiRes;  # not installed on ActiveState 5.6 :-(
use strict;
use warnings;

our ($_SIGCHLD, $_SIGCHLD_CNT, $REAP) = (0,0,0);
our (@CHLD_HANDLE_HISTORY, @SIGCHLD_CAUGHT) = (0);
our $SIG_DEBUG = $ENV{SIG_DEBUG};
our $VERSION = '0.89';
my %bastards;

#
# default SIGCHLD handler to reap completed child
# processes for Forks::Super
#
# may also be invoked synchronously with argument -1
# if we are worried that some previous CHLD signals
# were not handled correctly.
#
sub handle_CHLD {
    local $! = 0;
    $SIGCHLD_CAUGHT[0]++;
    my $sig = shift;
    $_SIGCHLD_CNT++;

    # poor man's synchronization
    $_SIGCHLD++;
    if ($_SIGCHLD > 1) {
	if ($SIG_DEBUG) {
	    my $z = Time::HiRes::time() - $^T;
	    push @CHLD_HANDLE_HISTORY,
	            "synch $$ $_SIGCHLD $_SIGCHLD_CNT $sig $z\n";
	}
	$_SIGCHLD--;
	return;
    }

    if ($SIG_DEBUG) {
	my $z = Time::HiRes::time() - $^T;
	push @CHLD_HANDLE_HISTORY, "start $$ $_SIGCHLD $_SIGCHLD_CNT $sig $z\n";
    }
    if ($sig ne '-1' && $DEBUG) {
	debug("handle_CHLD(): $sig received");
    }

    my $nhandled = 0;

    while (1) {
	my $pid = -1;
	my $status = $?;
	for my $tries (1 .. 3) {
	    local $?;
	    $pid = CORE::waitpid -1, WNOHANG;
	    $status = $?;
	    last if isValidPid($pid);
	}
	last if !isValidPid($pid);

	$nhandled++;

        if ($Forks::Super::Job::Emulate::EMULATE_PID{$pid}) {
            my $job = $Forks::Super::Job::Emulate::EMULATE_PID{$pid};
            _preliminary_reap($job,$status);
            Forks::Super::Job::IPC::_close_child($job);
        } elsif (defined $Forks::Super::ALL_JOBS{$pid}) {
	    _preliminary_reap($pid, $status);
	} else {
	    # There are (at least) two reasons we reach this code branch:
	    #
	    # 1. A child process completes so quickly that it is reaped in 
	    #    this subroutine *before* the parent process has finished 
	    #    initializing its state.
	    #    Treat this as a bastard pid. We'll check later if the 
	    #    parent process knows about this process.
	    # 2. This is a child process with $CHILD_FORK_OK>0, reaping process
	    #    started with a system fork (system or exec or maybe even qx?),
	    #    not a F::S::fork call from within the child process.

	    debug('handle_CHLD(): got CHLD signal ',
		  "but can't find child to reap; pid=$pid") if $DEBUG;

	    $bastards{$pid} = [ scalar Time::HiRes::time(), $status ];
	}
	$REAP = 1;
    }
    if ($SIG_DEBUG) {
	my $z = Time::HiRes::time() - $^T;
	push @CHLD_HANDLE_HISTORY, "end $$ $_SIGCHLD $_SIGCHLD_CNT $sig $z\n";
    }
    $_SIGCHLD--;
    if ($nhandled > 0) {
	Forks::Super::Deferred::check_queue();
    }
    return;
}

sub _preliminary_reap {
    my ($pid,$status) = @_;
    my $j = $Forks::Super::ALL_JOBS{$pid};
    $REAP = 1;
    if ($j->{debug}) {
	debug('handle_CHLD(): preliminary reap for ',
	      "$pid status=$status");
    }
    if ($SIG_DEBUG) {
	my $z = Time::HiRes::time() - $^T;
	push @CHLD_HANDLE_HISTORY,
		"reap $$ $_SIGCHLD $_SIGCHLD_CNT <$pid> $status $z\n";
    }

    $REAP = 1;
    if (!$j->{daemon}) {
	$j->{status} = $status;
	$j->_mark_complete;
    }
    return;
}


#
# bastards arise when a child finishes quickly and has been
# reaped in the SIGCHLD handler before the parent has finished
# initializing the job's state. See  Forks::Super::Sigchld::handle_CHLD() .
#
sub handle_bastards {
    my @pids = @_;
    if (@pids == 0) {
	@pids = keys %bastards;
    }
    foreach my $pid (@pids) {
	my $job = $Forks::Super::ALL_JOBS{$pid};
	if (defined $job && defined $bastards{$pid}) {
	    warn 'Forks::Super: ',
	        "Job $pid reaped before parent initialization.\n";
	    if ($job->{daemon}) {
		delete $bastards{$pid};
	    } else {
		$job->_mark_complete;
		($job->{end}, $job->{status})
		    = @{delete $bastards{$pid}};
	    }
	}
    }
    return;
}

1;

__END__


Signal handling, since v0.40

Where available, signals are used throughout Forks::Super.
Where they are not available (MSWin32), we still try to run
the "signal handlers" every once in a while.

Parent SIGCHLD handler:

    Indicates that a child process is finished. 
    Call CORE::waitpid and do an "internal reap"

Child SIGALRM handler:

    Indicates that a child has "timed out" or expired.
    Should cause a kill signal (HUP? TERM? QUIT? INT?) to be
    sent to any grandchild processes.

Parent SIGHUP|SIGINT|SIGTERM|SIGQUIT|SIGPIPE handlers

    If parent process is interrupted, we still want the parent
    to run "clean up" code, especially if IPC files 
    were used.

Parent periodic tasks [SIGUSR1 | SIGALRM]

    Parent processes have some periodic tasks that they
    should perform from time to time:
      - Examine the job queue and dispatch jobs
      - Clean the pipes -- do non-blocking read on any
        open pipe/sockethandles and buffer the input
      - Call SIGCHLD handler to reap jobs where we might
        have missed a SIGCHLD

Child periodic tasks

    Periodic tasks in the child
      - Clean pipes
      - Check if command has timed out yet.
      - See if a user's alarm has gone off

We want a framework where we can add and remove jobs
for the signal handlers to do at will. If end user
also wishes to add a signal handler, the framework
should be able to accomodate that, too. And transparently.
