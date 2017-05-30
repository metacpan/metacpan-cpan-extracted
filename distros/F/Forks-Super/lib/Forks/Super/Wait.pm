#
# Forks::Super::Wait - implementation of Forks::Super:: wait, waitpid,
#        and waitall methods
#

package Forks::Super::Wait;
use Forks::Super::Job;
use Forks::Super::Util qw(is_number isValidPid IS_WIN32);
use Forks::Super::Debug qw(:all);
use Forks::Super::Config;
use Forks::Super::Deferred;
use Forks::Super::SysInfo;
use Forks::Super::Tie::Enum;
use Signals::XSIG;
use POSIX ':sys_wait_h';
use Exporter;
use Carp;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(wait waitpid waitall TIMEOUT WREAP_BG_OK);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.90';

my ($productive_waitpid_code);
my $respect_SIGCHLD_ignore = 1;

tie our $WAIT_ACTION_ON_SUSPENDED_JOBS, 
    'Forks::Super::Tie::Enum', qw(wait fail resume);

sub set_productive_waitpid_code (&) {
    $productive_waitpid_code = shift;
    return;
}

use constant TIMEOUT => -1.5;
use constant ONLY_SUSPENDED_JOBS_LEFT => -1.75;
use constant WREAP_BG_OK => WNOHANG() << 1;
use constant _BRIEF_TIMEOUT => 1E-6; # seconds
use constant FOREVER => 9.0E9;       # to a first order 285 years is forever

sub Forks::Super::Wait::wait {
    my $timeout = shift || 0;
    if ($timeout < 0) {
	$timeout = _BRIEF_TIMEOUT;
    }
    debug('invoked Forks::Super::wait') if $DEBUG;
    my $x = Forks::Super::Wait::waitpid(-1, 0, $timeout);
    return $x;
}

sub _cleanse_waitpid_args {
    my ($flags, $timeout, @dummy) = @_;
    $timeout ||= 0;
    if ($timeout < 0) {
	$timeout = _BRIEF_TIMEOUT;
    }
    if (@dummy > 2) {
	carp "Forks::Super::waitpid: Too many arguments\n";
    }
    if (not defined $flags) {
	carp "Forks::Super::waitpid: Not enough arguments\n";
	$flags = 0;
    }
    return ($flags, $timeout);
}

sub Forks::Super::Wait::waitpid {
    my $target = shift;
    my ($flags, $timeout) = _cleanse_waitpid_args(@_);

    __run_productive_waitpid_code();

    # waitpid:
    #   -1:    wait on any process
    #   t>0:   wait on process #t
    #   name:  wait on any process with the name
    #    0:    wait on any process in current process group
    #   -t:    wait on any process in process group #t

    # return -1 if there are no eligible procs to wait for
    my $no_hang = ($flags & WNOHANG) != 0;
    my $reap_bg_ok = $flags == WREAP_BG_OK;

    if (is_number($target) && $target == -1) {
	debug('waitpid: dispatching _waitpid_any') if $DEBUG;
	return _waitpid_any($no_hang, $reap_bg_ok, $timeout);
    }
    if (defined $ALL_JOBS{$target}) {
	debug('waitpid: dispatching _waitpid_target') if $DEBUG;
	return _waitpid_target($no_hang, $reap_bg_ok, $target, $timeout);
    }
    if (0 < (my @wantarray = Forks::Super::Job::getByName($target))) {
	debug('waitpid: dispatching _waitpid_name') if $DEBUG;
	return _waitpid_name($no_hang, $reap_bg_ok, $target, $timeout);
    }
    if (!is_number($target)) {
	debug("waitpid: bogus target $target") if $DEBUG;
	return _bogus_waitpid_result();
    }
    if ($target > 0) {
	if ($^O eq 'MSWin32' && defined $ALL_JOBS{-$target}) {
	    debug("dispatching _waitpid_pgrp_MSWin32 on a negative pgid!")
		if $DEBUG;
	    return _waitpid_pgrp_MSWin32($no_hang, $reap_bg_ok,
					 -$target, $timeout);
	} else {
	    debug("waitpid: bogus target $target") if $DEBUG;
	    return _bogus_waitpid_result();
	}
    }

    # $target is a number <= 0
    if ($Forks::Super::SysInfo::CONFIG{'getpgrp'}) {

	debug('waitpid: dispatching _waitpid_pgrp') if $DEBUG;
	return _waitpid_pgrp($no_hang, $reap_bg_ok, $target, $timeout);
    }
    if ($^O eq 'MSWin32') {
	debug("waitpid: dispatching _waitpid_pgrp_MSWin32 on -$target")
	    if $DEBUG;
	return _waitpid_pgrp_MSWin32($no_hang,$reap_bg_ok,0-$target,$timeout);
    }

    debug('waitpid: bogus (pgid) target ', $target) if $DEBUG;
    return _bogus_waitpid_result();
}

sub reapall {
    my $waited_for = 0;
    foreach my $job (@Forks::Super::Job::ALL_JOBS) {
	if ($job->state eq 'COMPLETE') {
	    $job->_mark_reaped;
	    ++$waited_for;
	}
    }
    return $waited_for;
}

sub waitall {
    my $timeout = shift || &FOREVER;
    if ($timeout < 0) {
	$timeout = &_BRIEF_TIMEOUT;
    }
    my $expire = Time::HiRes::time() + $timeout ;
    debug('waitall: waiting on all procs') if $DEBUG;
    my $waited_for = reapall();

    my $pid;
    do {
	$pid = Forks::Super::Wait::wait($expire - Time::HiRes::time());
	if ($DEBUG) {
	    debug("waitall: caught pid $pid");
	}
    } while isValidPid($pid,1) 
	&& ++$waited_for 
	&& Time::HiRes::time() < $expire;

    return $waited_for;
}

# is return value from _reap/waitpid/wait a simple scalar or an
# overloaded Forks::Super::Job object?

our $OVERLOAD_RETURN;
sub _reap_return {
    my ($job) = @_;
    if (!defined $OVERLOAD_RETURN) {
	$OVERLOAD_RETURN = $Forks::Super::Job::OVERLOAD_ENABLED;
    }

    my $pid = $job->{real_pid};
    $pid = $OVERLOAD_RETURN ? Forks::Super::Job::get($pid) : $pid;
    return $pid;
}

#
# The handle_CHLD() subroutine takes care of reaping
# processes from the operating system. This method's
# part of the relay is taking the reaped process
# and updating the job's state.
#
# Optionally takes a process group ID to reap processes
# from that specific group.
#
# return the process id of the job that was reaped, or
# -1 if no eligible jobs were reaped. In wantarray mode,
# return the number of eligible processes (state == ACTIVE
# or  state == COMPLETE  or  STATE == SUSPENDED) that were
# not reaped.
#
sub _reap {
    my ($reap_bg_ok, $optional_pgid) = @_; # to reap procs from specific group
    __run_productive_waitpid_code();
    Forks::Super::Sigchld::handle_bastards();

    my @j = @ALL_JOBS;
    if (defined $optional_pgid) {
	# same code for MSWin32, Unix
	@j = grep { $_->{pgid} == $optional_pgid } @ALL_JOBS;
    }

    # see if any jobs are complete (signaled the SIGCHLD handler)
    # but have not been reaped.
    my @waiting = grep { $_->{state} eq 'COMPLETE' } @j;
    if (!$reap_bg_ok) {
	@waiting = grep { $_->{_is_bg} == 0 } @waiting;
    }
    debug('_reap(): found ', scalar @waiting,
	  ' complete & unreaped processes') if $DEBUG;

    if (@waiting > 0) {
	@waiting = sort { $a->{end} <=> $b->{end} } @waiting;
	my $job = shift @waiting;
	my $real_pid = $job->{real_pid};
	my $pid = $job->{pid};

	if ($job->{debug}) {
	    debug("_reap: reaping $pid/$real_pid.");
	}
	if (not wantarray) {
	    return _reap_return($job);
	}

	my ($nactive1, $nalive, $nactive2, $nalive2)
	    = Forks::Super::Job::count_processes($reap_bg_ok, $optional_pgid);
	debug("_reap:  $nalive remain.") if $DEBUG;
	$job->_mark_reaped;
	return (_reap_return($job), $nactive1, $nalive, $nactive2, $nalive2);
    }


    # the failure to reap active jobs may occur because the jobs are still
    # running, or it may occur because the relevant signals arrived at a
    # time when the signal handler was overwhelmed

    my ($nactive1, $nalive, $nactive2, $nalive2)
	= Forks::Super::Job::count_processes($reap_bg_ok, $optional_pgid);

    my $val = $nalive2 ? _active_waitpid_result() : _reaped_waitpid_result();
    return $val if not wantarray;

    if ($DEBUG) {
	debug("_reap(): nothing to reap now. $nactive1 remain.");
    }
    return ($val, $nactive1, $nalive, $nactive2, $nalive2);
}


# wait on any process
sub _waitpid_any {
    my ($no_hang,$reap_bg_ok,$timeout) = @_;
    my $expire = Time::HiRes::time() + ($timeout || &FOREVER);
    my ($pid, $nactive2, $nalive, $nactive, $nalive2) = _reap($reap_bg_ok);
    if ($no_hang == 0) {
	while (!isValidPid($pid,1) && $nalive > 0) {
	    if (Time::HiRes::time() >= $expire) {
		# XXX - reset $? ?
		return TIMEOUT;
	    }
	    if ($nactive == 0) {

		if ($WAIT_ACTION_ON_SUSPENDED_JOBS eq 'fail') {
		    # XXX - reset $? ?
		    return ONLY_SUSPENDED_JOBS_LEFT;
		} elsif ($WAIT_ACTION_ON_SUSPENDED_JOBS eq 'resume') {
		    _activate_one_suspended_job($reap_bg_ok);
		}
	    }
	    __run_productive_waitpid_code();

	    # XXX - $DEFAULT_PAUSE here? 
	    # Pause time should not be greater than the timeout.
	    Forks::Super::Util::pause();
	    ($pid, $nactive2, $nalive, $nactive, $nalive2) = _reap($reap_bg_ok);
	}
    }
    if (defined $ALL_JOBS{$pid}) {
	my $job = Forks::Super::Job::get($ALL_JOBS{$pid});
	while (not defined $job->{status}) {
	    Forks::Super::Util::pause();
	}
	$? = $job->{status};
    }
    return __waitpid_result($pid);
}

sub __waitpid_result {
    my $pid = shift;
    if ($respect_SIGCHLD_ignore &&
	$Signals::XSIG{CHLD} &&
	ref($Signals::XSIG{CHLD}) eq 'ARRAY' &&
	'IGNORE' eq ($Signals::XSIG::XSIG{CHLD}[0] || '') &&
	defined $Forks::Super::SysInfo::IGNORE_WAITPID_RESULT) {


	$? = $Forks::Super::SysInfo::IGNORE_WAITPID_STATUS;
	$pid = $Forks::Super::SysInfo::IGNORE_WAITPID_RESULT;
    }
    return $pid;
}

sub _activate_one_suspended_job {
    my @suspended =
        grep { $_->{state} eq 'SUSPENDED' } @Forks::Super::ALL_JOBS;
    if (@suspended == 0) {
	@suspended = grep { 
	    $_->{state} =~ /SUSPENDED/
	} @Forks::Super::ALL_JOBS;
    }
    @suspended = sort { 
	$b->{queue_priority} <=> $a->{queue_priority} } @suspended;
    if (@suspended == 0) {
	warn 'Forks::Super::_activate_one_suspended_job(): ',
	" can't find an appropriate suspended job to resume\n";
	return;
    }

    my $j1 = $suspended[0];
    $j1->{queue_priority} -= 1E-4;
    $j1->resume;
    return;
}

sub _bogus_waitpid_result {
    if (defined $Forks::Super::SysInfo::BOGUS_WAITPID_STATUS) {
	$? = $Forks::Super::SysInfo::BOGUS_WAITPID_STATUS;
    }
    return $Forks::Super::SysInfo::BOGUS_WAITPID_RESULT;
}

sub _active_waitpid_result {
    if (defined $Forks::Super::SysInfo::ACTIVE_WAITPID_STATUS) {
	$? = $Forks::Super::SysInfo::ACTIVE_WAITPID_STATUS;
    }
    return $Forks::Super::SysInfo::ACTIVE_WAITPID_RESULT;
}

sub _reaped_waitpid_result {
    if (defined $Forks::Super::SysInfo::REAPED_WAITPID_STATUS) {
	$? = $Forks::Super::SysInfo::REAPED_WAITPID_STATUS;
    }
    return $Forks::Super::SysInfo::REAPED_WAITPID_RESULT;
}

# wait on a specific process
sub _waitpid_target {
    my ($no_hang, $reap_bg_ok, $target, $timeout) = @_;
    my $expire = Time::HiRes::time() + ($timeout || &FOREVER);

    my $job = $ALL_JOBS{$target};

    if (not defined $job) {
	debug('_waitpid_target: bogus target') if $job->{debug} & 2;
	return _bogus_waitpid_result();
    } 

    if ($job->{state} eq 'COMPLETE') {
	debug("_waitpid_target: job $job is complete, reaping ...")
	    if $job->{debug} & 2;
	$job->_mark_reaped;
	return __waitpid_result(_reap_return($job));
    }

    if ($job->{daemon}) {
	debug("_waitpid_target: job $job is a daemon, returning bogus result")
	    if $job->{debug} & 2;
	return _bogus_waitpid_result();
    }

    if ($job->{state} eq 'REAPED') {
	debug("_waitpid_target: job $job is already reaped ...") 
	    if $job->{debug} & 2;
	return _reaped_waitpid_result();
    }

    if ($no_hang) {
	debug("_waitpid_target: job $job is still $job->{state}")
	    if $job->{debug} & 2;
	return _active_waitpid_result();
    }

    # block until job is complete.
    debug("_waitpid_target: blocking until $job is complete")
	    if $job->{debug} & 2;

    my $block = _block_until_job_completes($job, $expire);
    return TIMEOUT if $block == TIMEOUT;

    debug("_waitpid_target: job $job is complete now, reaping ...")
	if $job->{debug} & 2;
    $job->_mark_reaped;
    return __waitpid_result(_reap_return($job));
}

sub _block_until_job_completes {
    my ($job, $expire) = @_;
    while ($job->{state} ne 'COMPLETE' && $job->{state} ne 'REAPED') {
	return TIMEOUT if Time::HiRes::time() >= $expire;
	__run_productive_waitpid_code();
	Forks::Super::Util::pause();
	if ($job->{state} =~ /DEFER|SUSPEND/) {
	    Forks::Super::Deferred::check_queue();
	}
        if ($job->{debug} > 1) {
            debug("    blocking on $job state is $job->{state}");
        }
    }
    return 0;
}

sub _waitpid_name {
    my ($no_hang, $reap_bg_ok, $target, $timeout) = @_;
    my $expire = Time::HiRes::time() + ($timeout || &FOREVER);
    my @jobs = Forks::Super::Job::getByName($target);
    if (@jobs == 0) {
	return _bogus_waitpid_result();
    }
    my @jobs_to_wait_for = ();
    foreach my $job (@jobs) {
	if ($job->{state} eq 'COMPLETE') {
	    $job->_mark_reaped;
	    return __waitpid_result(_reap_return($job));
	} elsif ($job->{state} ne 'REAPED' 
		 && $job->{state} ne 'DEFERRED'
		 && !$job->{daemon}) {
	    push @jobs_to_wait_for, $job;
	}
    }
    if (@jobs_to_wait_for == 0) {
	return _reaped_waitpid_result();
    } elsif ($no_hang) {
	return _active_waitpid_result();
    }

    # otherwise block until a job is complete
    @jobs = grep {
	$_->{state} eq 'COMPLETE' || $_->{state} eq 'REAPED'
    } @jobs_to_wait_for;
    while (@jobs == 0) {
	if (Time::HiRes::time() >= $expire) {
	    # XXX - update $? ?
	    return TIMEOUT;
	}
	__run_productive_waitpid_code();
	Forks::Super::Util::pause();
	if (grep {$_->{state} eq 'DEFERRED'} @jobs_to_wait_for) {
	    Forks::Super::Deferred::run_queue();
	}
	@jobs = grep { $_->{state} eq 'COMPLETE' 
			   || $_->{state} eq 'REAPED'} @jobs_to_wait_for;
    }
    $jobs[0]->_mark_reaped;
    return __waitpid_result(_reap_return($jobs[0]));
}

# wait on any process from a specific process group
sub _waitpid_pgrp {
    my ($no_hang, $reap_bg_ok, $target, $timeout) = @_;

    if ($target == 0) {
	if (! eval { $target = getpgrp(0) } ) {
	    $target = $$;
	}
    } elsif ($target < 0) {
	$target = -$target;
    }

    my $expire = Time::HiRes::time() + ($timeout || &FOREVER);
    my ($pid, $nactive) = _reap($reap_bg_ok,$target);
    if (! $no_hang) {
	while (!isValidPid($pid,1) && $nactive > 0) {
	    if (Time::HiRes::time() >= $expire) {
		# XXX - update $? ?
		return TIMEOUT;
	    }
	    __run_productive_waitpid_code();
	    Forks::Super::Util::pause();
	    ($pid, $nactive) = _reap($reap_bg_ok,$target);
	}
    }
    if (defined $ALL_JOBS{$pid}) {
	$? = $ALL_JOBS{$pid}{status};
    }
    return __waitpid_result($pid);
}

sub _waitpid_pgrp_MSWin32 {
    my ($no_hang, $reap_bg_ok, $target, $timeout) = @_;

    if ($target == 0) {
	$target = $$;
    } elsif ($target < 0) {
	# ok for emulated MSWin32 process group to be negative
	# $target = -$target;
    }

    my $expire = Time::HiRes::time() + ($timeout || &FOREVER);
    my ($pid, $nactive) = _reap($reap_bg_ok,$target);

    if (! $no_hang) {
	while (!isValidPid($pid,1) && $nactive > 0) {
	    if (Time::HiRes::time() >= $expire) {
		# XXX - update $? ?
		return TIMEOUT;
	    }
	    __run_productive_waitpid_code();
	    Forks::Super::Util::pause();
	    ($pid, $nactive) = _reap($reap_bg_ok,$target);
	}
    }
    if (defined $ALL_JOBS{$pid}) {
	$? = $ALL_JOBS{$pid}{status};
    }
    return __waitpid_result($pid);
}

sub __run_productive_waitpid_code {
    if ($productive_waitpid_code) {
	$productive_waitpid_code->();
    }
    return;
}

1;


=head1 NAME

Forks::Super::Wait

=head1 VERSION

0.90

=head1 DESCRIPTION

C<Forks::Super::Wait> is part of the L<Forks::Super|Forks::Super> distribution.
The function and variables in this module manage the background processes
at the end of their life cycle.

There should not be much reason for a L<Forks::Super|Forks::Super> user to
call functions or manipulate variables in this module directly.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
