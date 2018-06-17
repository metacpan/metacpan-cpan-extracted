#
# Forks::Super::Job::Timeout
# implementation of
#     fork { timeout => ... }
#     fork { expiration => ... }
#

package Forks::Super::Job::Timeout;
use Forks::Super::Config;
use Forks::Super::Debug qw(:all);
use Forks::Super::Util qw(IS_WIN32);
use Signals::XSIG;
use POSIX;
use Carp;
use strict;
use warnings;

use constant FOREVER => 9E9;
use constant LONG_TIME => 9E8;

our $VERSION = '0.94';

our $MAIN_PID = $$;
our $DISABLE_INT = 0;
our $TIMEDOUT = 0;
my $EXPIRATION;
our ($ORIG_PGRP, $NEW_PGRP, $NEW_SETSID, $NEWNEW_PGRP);

# Signal to help terminate grandchildren on a timeout, for systems that
# let you set process group ID. After a lot of replications I find that
#   - SIGQUIT is not appropriate on Cygwin 5.10 (_cygtls exception msgs)
#   - SIGINT,QUIT not appropriate on Cygwin 5.6.1 (t/40g#3-6 fail)
#   - linux 5.6.2 intermittent problems with any signals
our $TIMEOUT_SIG = $ENV{FORKS_SUPER_TIMEOUT_SIG} || (&IS_WIN32?'QUIT':'HUP');

sub Forks::Super::Job::_config_timeout_parent {
    my $job = shift;
    return;
}

#
# If desired, set an alarm and alarm signal handler on a child process
# to kill the child.
# Should only run from a child process immediately after the fork.
#
sub Forks::Super::Job::_config_timeout_child {
    my $job = shift;
    my $timeout = &FOREVER;

    if (exists $SIG{$TIMEOUT_SIG}) {
	$SIG{$TIMEOUT_SIG} = 'DEFAULT';
    }

    if (defined $job->{timeout}) {
	$timeout = _time_from_natural_language($job->{timeout}, 1);
    }
    if (defined $job->{expiration}) {
	$job->{expiration} = _time_from_natural_language($job->{expiration}, 0);
	if ($job->{expiration} - Time::HiRes::time() < $timeout) {
	    $timeout = $job->{expiration} - Time::HiRes::time();
	}
    }
    if ($timeout > &LONG_TIME) {
	return;
    }
    $job->{_timeout} = $timeout;
    $job->{_expiration} = $timeout + Time::HiRes::time();

    # Un*x systems - try to establish a new process group for
    # this child. If this process times out, we want to have
    # an easy way to kill off all the grandchildren.
    #
    # On Windows, if a child (i.e., a psuedo-process) launches
    # a REAL process (with system, exec, Win32::Process::Create, etc.)
    # then the only reliable way I've found to take it out is
    # with the system command TASKKILL.
    #
    # see the END{} block that covers child cleanup below
    #
    if ($Forks::Super::SysInfo::CONFIG{'getpgrp'}) {
	_change_process_group_child($job);
    } elsif ($^O eq 'MSWin32') {
	$job->{pgid} = $$;
	if ($job->{style} ne 'exec' && $job->{style} ne 'cmd') {
	    $job->set_signal_pid($$);
	}
    }

    if ($timeout < 1) {
	croak 'Forks::Super::Job::_config_timeout_child(): quick timeout';
    }

    if ($job->{style} eq 'exec') {
	# v0.55: workaround to exec/timeout incompatibility
	if ($^O ne 'MSWin32') {
	    Forks::Super::Job::OS::poor_mans_alarm($$, $timeout);
	} else {
	    # for $^O==MSWin32, run monitor after process launches ...
	    $job->{_post_exec_timeout} = $timeout;
	}
	return;
    }

    # XXX - are there systems that are inexplicably incompatible with alarm?
    # I thought  freebsd  was like that some times (when CPAN tests would
    # abort after 2-4 hours), but I haven't seen this problem in a while
    # (since v0.56?)

    no warnings 'once';
    if ($Forks::Super::SysInfo::SLEEP_ALARM_COMPATIBLE <= 0
	|| !$Forks::Super::SysInfo::CONFIG{'alarm'}
        || $Forks::Super::SysInfo::PREFER_ALTERNATE_ALARM
	|| $job->{use_alternate_alarm}) {

	# can't/shouldn't use alarm for timeout. 
	# use process monitor workaround
	Forks::Super::Job::OS::poor_mans_alarm($$, $timeout);
	return;
    }

    $XSIG{ALRM}[1] = \&_child_timeout;

    $EXPIRATION = Time::HiRes::time() + $timeout - 1.0;
    $Forks::Super::Job::Timeout::USE_ITIMER = 0;
    alarm $timeout;

    debug('_config_timeout_child(): ',
	  "alarm set for ${timeout}s in child process $$")
	if $job->{debug};
    return;
}

sub _change_process_group_child {
    my ($job) = @_;
    if (eval { $ORIG_PGRP = getpgrp(0);1 }) {
	setpgrp(0, $$);
	$NEW_PGRP = $job->{pgid} = getpgrp(0);
	$NEW_SETSID = 0;
	if ($NEW_PGRP ne $ORIG_PGRP) {
	    if ($job->{debug}) {
		debug('_config_timeout_child: ',
		      "Child process group changed to $job->{pgid}");
	    }
	} else {
	    # setpgrp didn't work, try POSIX::setsid
	    $NEW_SETSID = POSIX::setsid();
	    $job->{pgid} = $NEW_PGRP = getpgrp(0);
	    if ($job->{debug}) {
		debug('_config_timeout_child: ',
		      "Child process started new session $NEW_SETSID, ",
		      "process group $NEW_PGRP");
	    }
	}
    } else {
	$Forks::Super::SysInfo::CONFIG{'getpgrp'} = 0;
    }
    return;
}


# to be run in a child if that child times out
sub _child_timeout {

    # the SIGALRM handler in the child might be used for
    # several purposes, so the fact that this function is
    # called does not necessarily mean it is time for the
    # child to exit.
    if ($Forks::Super::SysInfo::CONFIG{'setitimer'}
	&& $Forks::Super::Job::Timeout::USE_ITIMER
	&& Time::HiRes::time() 
		< $EXPIRATION - $Forks::Super::SysInfo::TIME_HIRES_TOL) {
	if ($DEBUG) {
	    debug('SIGALRM caught in child, but expiration time ',
		  $EXPIRATION, ' not reached yet (', Time::HiRes::time(), ')');
	}
	return;
    }

    if ($DEBUG) {
        debug "Forks::Super: child process timeout\n";
    } else {
        warn "Forks::Super: child process timeout\n";
    }
    $TIMEDOUT = 1;

    my $job = Forks::Super::Job->this;
    if ($job->{_sync}) {
	$job->{_sync}->remove;
    }

    # we wish to kill not only this child process,
    # but any other active processes that it has spawned.
    # There are several ways to do this.
    if ($Forks::Super::SysInfo::PROC_PROCESSTABLE_OK &&
        Forks::Super::Config::CONFIG('Proc::ProcessTable')) {
	my @to_kill = 
	    _child_timeout_read_procs_to_kill_from_Proc_ProcessTable();
	if (defined $Forks::Super::Job::CHILD_EXEC_PID) {
	    push @to_kill, $Forks::Super::Job::CHILD_EXEC_PID;
	}
	if (@to_kill > 0) {
            if ($DEBUG) {
                debug("to kill[$TIMEOUT_SIG]: @to_kill");
            }
	    Forks::Super::kill($TIMEOUT_SIG, @to_kill);
	}
    } elsif (_child_timeout_has_new_process_group()) {

	if ($DEBUG) {
	    debug("sending SIG$TIMEOUT_SIG to process group");
	}
	local $SIG{$TIMEOUT_SIG} = 'IGNORE';
	$DISABLE_INT = 1;
	my $SIG = $Forks::Super::Config::SIGNO{$TIMEOUT_SIG} || 15;
	CORE::kill -$SIG, getpgrp(0);
	$DISABLE_INT = 0;

    } elsif (&IS_WIN32) {
	if ($DEBUG) {
	    debug("using child_timeout_Win32 to end process");
	}
	_child_timeout_Win32();
    }
    if ($DEBUG) {
        debug("_child_timeout: end reached");
    }
    exit 255;
}

sub _child_timeout_has_new_process_group {
    if ($Forks::Super::SysInfo::CONFIG{'getpgrp'}) {
	if ($NEW_SETSID || ($ORIG_PGRP ne $NEW_PGRP)) {
	    return 1;
	}
    }
    return 0;
}

sub _child_timeout_read_procs_to_kill_from_Proc_ProcessTable {
    my $ps = eval { Proc::ProcessTable->new() } || return;
    my (%ppid, @to_kill) = ();
    foreach my $p (@{$ps->table}) {
      $ppid{$p->pid} = $p->ppid;
    }
    foreach my $opid (keys %ppid) {
      my $pid = $ppid{$opid};
      while (defined $pid) {
	if ($pid == $$) {
	  push @to_kill, $opid;
	  last;
	}
	$pid = $ppid{$pid};
      }
    }
    return @to_kill;
}

sub _child_timeout_Win32 {
    my $pid = Forks::Super::Job::get_win32_proc_pid();
    my $job = Forks::Super::Job->this;
    my $signo = Forks::Super::Util::signal_number('ALRM') || 14;

    if ($job->{signal_pid}) {
	my $p = $job->{signal_pid};
	my $c1 = Forks::Super::Job::OS::Win32::terminate_process_tree(
	    $p, $signo);
	$job->{debug} && debug("killed process tree for signal pid $p: $c1");
    }
    if ($pid && $pid > 0 && $pid != $job->{signal_pid}) {
	my $c2 = Forks::Super::Job::OS::Win32::terminate_process_tree(
	    $pid, $signo);
	$job->{debug} && debug("killed process tree for system1 pid $pid: $c2");
    }
    return;
}

sub _cleanup_child {
    # typically called from an END { } block when a child
    # with a timeout is exiting.

    if (defined $Forks::Super::Config::CONFIG{'alarm'}
	&& $Forks::Super::SysInfo::CONFIG{'alarm'}) {

	alarm 0;
    }
    return if !$TIMEDOUT;

    if ($DISABLE_INT) {
	# our child process received its own SIGINT that got sent out
	# to its children/process group. We intended the exit status
	# here to be as if it had die'd.

	$? = 255;
    }

    if ($Forks::Super::SysInfo::CONFIG{'getpgrp'}) {
	# try to kill off any grandchildren
	if ($ORIG_PGRP == $NEW_PGRP) {
	    carp 'Forks::Super::child_exit: original setpgrp call failed, ',
			"child-of-child process might not be terminated.\n";
	} else {
	    setpgrp(0, $ORIG_PGRP);
	    $NEWNEW_PGRP = getpgrp(0);
	    if ($NEWNEW_PGRP eq $NEW_PGRP) {
		carp 'Forks::Super::child_exit: ',
		    	'final setpgrp call failed, ',
		    	"[$ORIG_PGRP/$NEW_PGRP/$NEWNEW_PGRP] ",
		    	"child-of-child processes might not be terminated.\n";
	    } else {
		local $SIG{INT} = 'IGNORE';
		my $num_killed = CORE::kill 'INT', -$NEW_PGRP; 
		# kill -PID === kill PGID. Not portable
		if ($num_killed && $NEW_PGRP && $DEBUG) {
		    debug('child_exit: ',
			  "sent SIGINT to $num_killed grandchildren");
		}
	    }
	}
    }
    return 1; # done
}

sub warm_up {

    # force loading of some modules in the parent process
    # so that fast fail (see t/40-timeout.t, tests #8,17)
    # aren't slowed down when they encounter the croak call.

    eval { croak "preload.\n" } or do {};
    return $@;
}

sub _time_from_natural_language {
    my ($time,$isInterval) = @_;
    if ($time !~ /[A-Za-z]/) {
	return $time;
    }

    if (Forks::Super::Config::CONFIG('DateTime::Format::Natural')) {
	my $now = DateTime->now;
	my $dt_nl_parser = DateTime::Format::Natural->new(datetime => $now,
						   lang => 'en',
						   prefer_future => 1);
	if ($isInterval) {
	    my ($dt) = $dt_nl_parser->parse_datetime_duration($time);
	    return $dt->epoch - $now->epoch;
	} else {
	    my $dt = $dt_nl_parser->parse_datetime($time);
	    return $dt->epoch;
	}
    } else{
	carp 'Forks::Super::Job::Timeout: ',
		"time spec $time may contain natural language. ",
		'Install the  DateTime::Format::Natural  module ',
		"to use this feature.\n";
	return $time;
    }
}

1;
