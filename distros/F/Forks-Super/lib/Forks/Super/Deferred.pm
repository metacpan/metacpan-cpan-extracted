#
# Forks::Super::Deferred - routines to manage "deferred" jobs
#

package Forks::Super::Deferred;

use Forks::Super::Config;
use Forks::Super::Debug qw(:all);
use Forks::Super::Tie::Enum;
use Forks::Super::Util qw(IS_WIN32);
use Signals::XSIG;
use Carp;
use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(queue_job);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.96';

# must sync FIRST_DEFERRED_ID with Win32 code in Forks::Super::Util::isValidPid
use constant FIRST_DEFERRED_ID => -2_100_000;
use constant QUEUE_PRIORITY_INCREMENT => 1.0E-6;
use constant DEFAULT_QUEUE_MONITOR_FREQ => 30;

our (@QUEUE, $QUEUE_MONITOR_PID, $QUEUE_MONITOR_PPID, $QUEUE_MONITOR_FREQ);
our $QUEUE_DEBUG = $ENV{FORKS_SUPER_QUEUE_DEBUG} || 0;
our $QUEUE_MONITOR_LIFESPAN = 14400;   # 14400s == 4 hours
our $DEFAULT_QUEUE_PRIORITY = 0;
our $INHIBIT_QUEUE_MONITOR = 1;
my $NEXT_DEFERRED_ID = FIRST_DEFERRED_ID;
our $OLD_QINTERRUPT_SIG;
our ($MAIN_PID,$_LOCK) = ($$,0);

# if a child process finishes while the  run_queue()  function is running,
# we will usually have to restart that function in order to make sure
# that jobs are dispatched quickly and in the correct order. The SIGCHLD
# handler sets a  $REAP  flag, and if we check that flag  run_queue()
# will do its job properly.
our $CHECK_FOR_REAP = 1;

# use var $Forks::Super::QUEUE_INTERRUPT, not lexical package var

sub get_default_priority {
    my $q = $DEFAULT_QUEUE_PRIORITY;
    $DEFAULT_QUEUE_PRIORITY -= &QUEUE_PRIORITY_INCREMENT;
    return $q;
}

sub init {
    tie $QUEUE_MONITOR_FREQ, 
        'Forks::Super::Deferred::QueueMonitorFreq', &DEFAULT_QUEUE_MONITOR_FREQ;

    tie $INHIBIT_QUEUE_MONITOR, 
        'Forks::Super::Deferred::InhibitQueueMonitor', &IS_WIN32;
    # !Forks::Super::Util::_has_POSIX_signal_framework();

    tie $Forks::Super::QUEUE_INTERRUPT, 
        'Forks::Super::Deferred::QueueInterrupt', ('', keys %SIG);
    if (grep {/USR1/} keys %SIG) {
	$Forks::Super::QUEUE_INTERRUPT = 'USR1';
    }
    return;
}

sub deinit {
    untie $QUEUE_MONITOR_FREQ;
    untie $INHIBIT_QUEUE_MONITOR;
    untie $Forks::Super::QUEUE_INTERRUPT;
}

sub init_child {
    @QUEUE = ();
    undef $QUEUE_MONITOR_PID;
    if ($Forks::Super::QUEUE_INTERRUPT
	&& $Forks::Super::SysInfo::CONFIG{SIGUSR1}) {
	$SIG{$Forks::Super::QUEUE_INTERRUPT} = 'DEFAULT';
    }
    return;
}

#
# once there are jobs in the queue, we'll need to call
# check_queue() every once in a while to make sure those
# jobs get started when they are eligible. Certain
# events (the CHLD handler being invoked, the
# waitall method) call check_queue but that still doesn't
# guarantee that it will be called frequently enough.
#
# This method sets up a background process (using
# CORE::fork -- it won't be subject to reaping by
# this module's wait/waitpid/waitall methods)
# to periodically send USR1^H^H^H^H
# $Forks::Super::QUEUE_INTERRUPT signals to this
#
sub _launch_queue_monitor {
    if (!$Forks::Super::SysInfo::CONFIG{'SIGUSR1'}) {
	debug('_lqm returning: no SIGUSR1') if $QUEUE_DEBUG;
	return;
    }
    if (defined $QUEUE_MONITOR_PID) {
	debug('_lqm returning: $QUEUE_MONITOR_PID defined') if $QUEUE_DEBUG;
	return;
    }

    if ($Forks::Super::SysInfo::CONFIG{'setitimer'}) {
	_launch_queue_monitor_setitimer();
    } else {
	_launch_queue_monitor_fork();
    }
    return;
}

sub _check_queue {
    # check_queue call triggered by a SIGALRM. 
    # XXX - we can do logging or other special handling here ...
    check_queue();
    return;
}

sub _launch_queue_monitor_setitimer {

    $QUEUE_MONITOR_PPID = $$;
    $QUEUE_MONITOR_PID = 'setitimer';
    $XSIG{ALRM}[2] = \&_check_queue;

    Time::HiRes::setitimer(
	&Time::HiRes::ITIMER_REAL, $QUEUE_MONITOR_FREQ, $QUEUE_MONITOR_FREQ);
    return;
}

sub _launch_queue_monitor_fork {

    if (!$Forks::Super::QUEUE_INTERRUPT) {
	debug('_lqm returning: $Forks::Super::QUEUE_INTERRUPT not set')
	    if $QUEUE_DEBUG;
	return;
    }

    $OLD_QINTERRUPT_SIG = $SIG{$Forks::Super::QUEUE_INTERRUPT};
#   $SIG{$Forks::Super::QUEUE_INTERRUPT} = \&Forks::Super::Deferred::check_queue;
    $SIG{$Forks::Super::QUEUE_INTERRUPT} = \&check_queue;
    $QUEUE_MONITOR_PPID = $$;
    $QUEUE_MONITOR_PID = CORE::fork();
    if (not defined $QUEUE_MONITOR_PID) {
	warn 'Forks::Super: ',
		"queue monitoring sub process could not be launched: $!\n";
	undef $QUEUE_MONITOR_PPID;
	return;
    }
    if ($QUEUE_MONITOR_PID == 0) {

	_launch_queue_monitor_fork_child();
	exit 0;

    }
    return;
}

sub _launch_queue_monitor_fork_child {
    # a detached child 
    $0 = "QMon:$QUEUE_MONITOR_PPID";
    if ($DEBUG || $QUEUE_DEBUG) {
	debug("Launching queue monitor process $$ ",
	      "SIG $Forks::Super::QUEUE_INTERRUPT ",
	      "PPID $QUEUE_MONITOR_PPID ",
	      "FREQ $QUEUE_MONITOR_FREQ ");
    }

    if (defined &Forks::Super::init_child) {
	Forks::Super::init_child();
    } else {
	init_child();
    }

    close STDIN;
    open STDIN, '<', Forks::Super::Util::DEVNULL();
    close STDOUT;
    open STDOUT, '>', Forks::Super::Util::DEVNULL();
    if (!$DEBUG && !$QUEUE_DEBUG) {
        close STDERR;
        open STDERR, '>', Forks::Super::Util::DEVNULL();
    }
    # XXX - closed fd's 4 ... 2999?
    umask 0;
    chdir '/';
    $SIG{'TERM'} = 'DEFAULT';

    # three (normal) ways the queue monitor can die:
    #  1. (preferred) killed by the calling process (_kill_queue_monitor)
    #  2. fails to signal calling process 10 consecutive times
    #  3. exit after $QUEUE_MONITOR_LIFESPAN seconds

    my $expire = time + $QUEUE_MONITOR_LIFESPAN;
    my $consecutive_failures = 0;
    while (time < $expire && $consecutive_failures < 10) {
	CORE::sleep $QUEUE_MONITOR_FREQ;

	if ($DEBUG || $QUEUE_DEBUG) {
	    debug("queue monitor $$ passing signal to $QUEUE_MONITOR_PPID");
	}
	if (CORE::kill $Forks::Super::QUEUE_INTERRUPT, $QUEUE_MONITOR_PPID) {
	    $consecutive_failures = 0;
	} else {
	    $consecutive_failures++;
	}
	last if time > $expire;
    }
    return;
}

sub _kill_queue_monitor {
    if (defined($QUEUE_MONITOR_PPID) && $$ == $QUEUE_MONITOR_PPID) {
	if (defined $QUEUE_MONITOR_PID) {
	    if ($DEBUG || $QUEUE_DEBUG) {
		debug("killing queue monitor $QUEUE_MONITOR_PID");
	    }

	    if ($QUEUE_MONITOR_PID eq 'setitimer') {

		$XSIG{ALRM}[1] = undef;
		$XSIG{ALRM}[2] = undef;
		Time::HiRes::setitimer(&Time::HiRes::ITIMER_REAL, 0);
		undef $QUEUE_MONITOR_PID;
		undef $QUEUE_MONITOR_PPID;

	    } elsif ($QUEUE_MONITOR_PID > 0) {
		CORE::kill 'TERM', $QUEUE_MONITOR_PID;

		my $z = CORE::waitpid $QUEUE_MONITOR_PID, 0;
		if ($DEBUG || $QUEUE_DEBUG) {
		    debug("kill queue monitor result: $z");
		}

		undef $QUEUE_MONITOR_PID;
		undef $QUEUE_MONITOR_PPID;
		if (defined $OLD_QINTERRUPT_SIG) {
		    $SIG{$Forks::Super::QUEUE_INTERRUPT} = $OLD_QINTERRUPT_SIG;
		}
	    }
	}
    }
    return;
}


sub _cleanup {
    _kill_queue_monitor();
    return;
}

#
# add a new job to the queue.
# may run with no arg to populate queue from existing
# deferred jobs
#
sub queue_job {
    my $job = shift;
    if (&Forks::Super::Job::_INSIDE_END_QUEUE) {
	return;
    }
    if (defined $job) {
	$job->{state} = 'DEFERRED';
	$job->{queued} ||= Time::HiRes::time();
	$job->{pid} = $NEXT_DEFERRED_ID--;
	$Forks::Super::ALL_JOBS{$job->{pid}} = $job;
	if ($job->{debug} || $QUEUE_DEBUG) {
	    debug('queueing job ', $job->toString());
	}
    }

    my @q = grep { $_->{state} eq 'DEFERRED' } @Forks::Super::ALL_JOBS;
    @QUEUE = @q;
    if (@QUEUE > 0 && !$QUEUE_MONITOR_PID && !$INHIBIT_QUEUE_MONITOR) {
	_launch_queue_monitor();
    } elsif (@QUEUE == 0 && defined($QUEUE_MONITOR_PID)) {
	_kill_queue_monitor();
    }
    return;
}

sub _check_for_reap {
    if ($CHECK_FOR_REAP && $Forks::Super::Sigchld::REAP > 0) {
	if ($DEBUG || $QUEUE_DEBUG) {
	    debug('reap during queue examination -- restart');
	}
	return 1;
    }
    return;
}

#
# attempt to launch all jobs that are currently in the
# DEFFERED state.
#
sub run_queue {
    my ($ignore) = @_;
    if (@QUEUE <= 0) {
	return;
    }
    if (&Forks::Super::Job::_INSIDE_END_QUEUE) {
	return;
    }

    {
	no warnings 'once';
	return if $Forks::Super::CHILD_FORK_OK <= 0
	    && $$ != ($Forks::Super::MAIN_PID || $MAIN_PID);
    }
    queue_job();

    return if @QUEUE <= 0;

    if ($_LOCK++ > 0) {
	$_LOCK--;
	return;
    }

    # tasks for run_queue:
    #   assemble all DEFERRED jobs
    #   order by priority
    #   go through the list and attempt to launch each job in order.

    debug('run_queue(): examining deferred jobs') if $DEBUG || $QUEUE_DEBUG;
    while (_attempt_to_launch_deferred_jobs()) { 1 }
    $_LOCK--;
    return;
}

sub _get_deferred_jobs {
    my @deferred_jobs = grep { 
	defined($_->{state}) && $_->{state} eq 'DEFERRED' 
    } @Forks::Super::ALL_JOBS;
    @deferred_jobs = sort { 
	($b->{queue_priority}||0) <=> ($a->{queue_priority}||0)
    } @deferred_jobs;
    return @deferred_jobs;
}

sub _attempt_to_launch_deferred_jobs {
    $Forks::Super::Sigchld::REAP = 0;
    foreach my $job (_get_deferred_jobs()) {
	if ($job->can_launch) {
	    if ($job->{debug}) {
		debug("Launching deferred job $job->{pid}")
	    }
	    $job->{state} = 'LAUNCHING';

	    # if this loop gets interrupted to handle a child,
	    # we might be launching jobs in the wrong order.
	    # If we detect that an interruption has happened,
	    # abort and restart the loop.
	    #
	    # To disable this check, set 
	    # $Forks::Super::Deferred::CHECK_FOR_REAP = 0

	    if (_check_for_reap()) {
		$job->{state} = 'DEFERRED';
		return 1;
	    }
	    my $pid = $job->launch();
	    if ($pid == 0) {
		if (defined($job->{sub}) || defined($job->{cmd})
		    || defined($job->{exec})) {
		    $_LOCK--;
		    croak 'Forks::Super::run_queue(): ',
		        'fork on deferred job unexpectedly returned ',
		        "a process id of 0!\n";
		}
		$_LOCK--;
		croak 'Forks::Super::run_queue(): ',
		    'deferred job must have a ',
		    "'sub', 'cmd', or 'exec' option!\n";
	    }
	    return 1;
	} elsif ($job->{debug}) {
	    debug('Still must wait to launch job ', $job->toShortString());
	}
    }        # next deferred job
    return 0;
}

sub suspend_resume_jobs {
    my @jobs = grep {
	defined($_->{suspend}) &&
	    ($_->{state} eq 'ACTIVE' || $_->{state} eq 'SUSPENDED')
    } @Forks::Super::ALL_JOBS;
    return if @jobs <= 0;

    if ($_LOCK++ > 0) {
	$_LOCK--;
	return;
    }

    debug('suspend_resume_jobs(): examining jobs') if $DEBUG || $QUEUE_DEBUG;

    foreach my $job (@jobs) {
	no strict 'refs';
	my $job_is_suspended = $job->{state} =~ /SUSPEND/;
	my $action = $job->{suspend}->();
	if ($action < 0 && ! $job_is_suspended) {
	    $job->suspend;
	    debug("suspend_resume_jobs: suspend callback value $action for ",
		  'job ', $job->{pid}, ' ... suspending') if $job->{debug};
	} elsif ($action > 0 && $job_is_suspended) {
	    $job->resume;
	    debug("suspend_resume_jobs: suspend callback value $action for ",
		  'job ', $job->{pid}, ' ... resuming') if $job->{debug};
	}
    }

    $_LOCK--;
    return;
}

#
# SIGUSR1 handler. A background process will send periodic USR1^H^H^H^H
# $Forks::Super::QUEUE_INTERRUPT signals back to this process. On
# receipt of these signals, this process should examine the queue.
# This will keep us from ignoring the queue for too long.
#
# Note this automatic housecleaning is not available on some OS's
# like Windows. Those users may need to call  Forks::Super::Deferred::check_queue
# or  Forks::Super::run_queue  manually from time to time.
#
sub check_queue {
    run_queue() if !$_LOCK;
    suspend_resume_jobs() if !$_LOCK;
    return;
}

#############################################################################

# when $Forks::Super::Deferred::QUEUE_MONITOR_FREQ is updated,
# we should restart the queue monitor.

sub Forks::Super::Deferred::QueueMonitorFreq::TIESCALAR {
    my ($class,$value) = @_;
    $value = int $value;
    if ($value == 0) {
	$value = 1;
    } elsif ($value < 0) {
	$value = &DEFAULT_QUEUE_MONITOR_FREQ; # 30 seconds
    }
    debug('new F::S::D::QueueMonitorFreq obj') if $QUEUE_DEBUG;
    return bless \$value, $class;
}

sub Forks::Super::Deferred::QueueMonitorFreq::FETCH {
    my $self = shift;
    debug("F::S::D::QueueMonitorFreq::FETCH: $$self") if $QUEUE_DEBUG;
    return $$self;
}

sub Forks::Super::Deferred::QueueMonitorFreq::STORE {
    my ($self,$new_value) = @_;
    $new_value = int($new_value) || 1;
    if ($new_value < 0) {
	$new_value = &DEFAULT_QUEUE_MONITOR_FREQ;
    }
    if ($new_value == $$self) {
	debug("F::S::D::QueueMonitorFreq::STORE noop $$self") if $QUEUE_DEBUG;
	return $$self;
    }
    if ($QUEUE_DEBUG) {
	debug("F::S::D::QueueMonitorFreq::STORE $$self <== $new_value");
    }
    $$self = $new_value;
    _kill_queue_monitor();
    check_queue();
    if (@QUEUE > 0) {
	_launch_queue_monitor();
    }
    return;
}

#############################################################################

# When $Forks::Super::Deferred::INHIBIT_QUEUE_MONITOR is changed to non-zero,
# always call _kill_queue_monitor.

sub Forks::Super::Deferred::InhibitQueueMonitor::TIESCALAR {
    my ($class,$value) = @_;
    $value = 0+!!$value;
    return bless \$value, $class;
}

sub Forks::Super::Deferred::InhibitQueueMonitor::FETCH {
    my $self = shift;
    return $$self;
}

sub Forks::Super::Deferred::InhibitQueueMonitor::STORE {
    my ($self, $new_value) = @_;
    $new_value = 0+!!$new_value;
    if ($$self != $new_value) {
	if ($new_value) {
	    _kill_queue_monitor();
	} else {
	    queue_job();
	}
    }
    $$self = $new_value;
    return $$self;
}

#############################################################################

# Restart queue monitor if value for $QUEUE_INTERRUPT is changed.

{
    no warnings 'once';

    *Forks::Super::Deferred::QueueInterrupt::TIESCALAR
	= \&Forks::Super::Tie::Enum::TIESCALAR;

    *Forks::Super::Deferred::QueueInterrupt::FETCH
	= \&Forks::Super::Tie::Enum::FETCH;
}

sub Forks::Super::Deferred::QueueInterrupt::STORE {
    my ($self, $new_value) = @_;
    if (uc $new_value eq uc Forks::Super::Tie::Enum::get_value($self)) {
	return; # no change
    }
    if (!Forks::Super::Tie::Enum::has_attr($self,$new_value)) {
	return; # invalid assignment
    }
    _kill_queue_monitor();
    $Forks::Super::Tie::Enum::VALUE{$self} = $new_value;
    if (@QUEUE > 0) {
	_launch_queue_monitor();
    }
    return;
}

#############################################################################

1;

=head1 NAME

Forks::Super::Deferred - manage queue of background tasks to perform

=head1 VERSION

0.96

=head1 DESCRIPTION

C<Forks::Super::Deferred> is part of the L<Forks::Super|Forks::Super> 
distribution.
The function and variables in this module manage the queue
of L<"deferred processes"|Forks::Super/"Deferred processes"> --
background tasks that have been specified but that can not or 
should not be run until some time in the future.

There should not be much reason for a L<Forks::Super|Forks::Super> user to
call functions or manipulate variables in this module directly.

This package used to be called C<Forks::Super::Queue>, but that
name is being made available for an object/task queue implementation
that can work across parent-child process boundaries.

=head1 FUNCTIONS

=over 4

=item Forks::Super::Deferred::check_queue

Examines the queue of background tasks. Launches the tasks that
are eligible to start.

This function is called automatically from your program during
C<wait> and C<waitpid> calls, when the C<SIGCHLD> handler runs, 
or during any "productive pause" (see L<Forks::Super::Util/"pause">)
in your code.

=back

=head1 VARIABLES

=over 4

=item $Forks::Super::Deferred::QUEUE_MONITOR_FREQ

When jobs are in the queue, a separate thread will signal the
program and cause the queue to be examined every C<$QUEUE_MONITOR_FREQ>
seconds. 

For programs with lots of quick jobs, this variable can be set to a
small value to make sure the queue is examined frequently.

For programs with CPU-intensive, long running jobs, this variable
can be set to a large value so that not too many processing resources
are wasted examining the queue.

=back

=over 4

=item $Forks::Super::Deferred::QUEUE_DEBUG

If set to a true value, the C<Forks::Super::Deferred> module will publish
additional messages to the debugging output handle (see 
L<Forks::Super::Debug/"$DEBUG_FH">) about what the module is doing.
These messages may or may not be interesting.

This variable will be set at run-time if the environment variable
C<FORKS_SUPER_QUEUE_DEBUG> is set.

=back

=cut 

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2018, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
