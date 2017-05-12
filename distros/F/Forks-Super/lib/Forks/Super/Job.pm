###############################################################################
# Forks::Super::Job - object representing a task to perform in
#                     a background process
# See the subpackages for some implementation details
#

package Forks::Super::Job;
use Forks::Super::Debug qw(debug);
use Forks::Super::Util qw(is_number qualify_sub_name shquote
                          IS_CYGWIN IS_WIN32 is_pipe);
use Forks::Super::Config qw(:all);
use Forks::Super::Job::Ipc;
use Forks::Super::Job::Timeout;
use Forks::Super::Deferred qw(queue_job);
use Forks::Super::Job::OS;
use Forks::Super::Job::Callback qw(run_callback);
use Signals::XSIG;
use Exporter;
use POSIX ':sys_wait_h';
use Carp;
use Cwd;
use IO::Handle;
use strict;
use warnings;


our @ISA = qw(Exporter);
our @EXPORT = qw(@ALL_JOBS %ALL_JOBS PREFORK POSTFORK 
                 POSTFORK_PARENT POSTFORK_CHILD);
our $VERSION = '0.89';

our (@ALL_JOBS, %ALL_JOBS, @ARCHIVED_JOBS, $WIN32_PROC, $WIN32_PROC_PID);
our $OVERLOAD_ENABLED = 0;
our $_RETRY_PAUSE;
our (@PREFORK, @POSTFORK_PARENT, @POSTFORK_CHILD);

# a reference to the Job that launched a process.
# should only by set in the _child_ process created by a Job
my $this;

my $use_overload = $ENV{FORKS_SUPER_JOB_OVERLOAD};
if (!defined($use_overload)) {
    $use_overload = 1;
}
if ($use_overload) {
    enable_overload();
} else {
    enable_overload();
    disable_overload();
}

#############################################################################
# Object methods (meant to be called as $job->method_name(@args))

sub new {
    my ($class, $opts) = @_;
    my $self = { pid => '' };
    if (ref $opts eq 'HASH') {
	foreach (keys %$opts) {
	    $self->{$_} = $opts->{$_} ;
	}
    }

    $self->{__opts__} = $opts;
    $self->{created} = Time::HiRes::time();
    $self->{state} = 'NEW';
    $self->{ppid} = $$;
    if ($^O eq 'MSWin32') {
	$self->{pgid} = $self->{ppid};
    }
    if (!defined $self->{_is_bg}) {
	$self->{_is_bg} = 0;
    }
    if (!defined $self->{debug}) {
	$self->{debug} = $Forks::Super::Debug::DEBUG;
	if (defined $self->{undebug}) {
	    $self->{debug} = 0;
	}
    }
    # 0.41: fix overload bug here by putting  bless  before  push @ALL_JOBS
    bless $self, 'Forks::Super::Job';
    push @ALL_JOBS, $self;
    if ($self->{debug}) {
	debug('New job created: ', $self->toString());
    }
    return $self;
}

sub reuse {
    my ($job, @opts) = @_;
    my $opts = @opts > 1 ? { @opts } : $opts[0];
    #if (ref $opts ne 'HASH') {
    #  $opts = { @_[1..$#_] };
    #}
    my %opts;
    if (defined $job->{__opts__}) {
	%opts = %{$job->{__opts__}};
    }
    for (keys %$opts) {
	$opts{$_} = $opts->{$_};
    }

    return Forks::Super::fork( \%opts ) ;
}

sub _check_daemon_state {
    my $job = shift;
    if ($job->{state} ne 'DAEMON-COMPLETE' &&
	!CORE::kill(0, $job->signal_pid || -1)) {

	local $?;
	$job->_mark_complete;
	$job->_mark_reaped;
	$job->{state} = 'DAEMON-COMPLETE';
    }
    return;
}

sub is_reaped {
    my $job = shift;
    my $state = $job->state;
    return defined($state) && $state eq 'REAPED';
}

sub is_complete {
    my $job = shift;
    my $state = $job->state;
    return defined($state) &&
	($state eq 'COMPLETE' || 
	 $state eq 'REAPED' || 
	 $state eq 'DAEMON-COMPLETE');
}

sub is_started {
    my $job = shift;
    return $job->is_complete || $job->is_active || 
	(defined($job->{state}) &&
	 ($job->{state} eq 'SUSPENDED' || $job->{state} eq 'DAEMON-SUSPENDED'));
}

sub is_active {
    my $job = shift;
    my $state = $job->state;
    return defined($state) && ($state eq 'ACTIVE' || $state eq 'DAEMON');
}

sub is_suspended {
    my $job = shift;
    return defined($job->{state}) && $job->{state} =~ /SUSPENDED/;
}

sub is_deferred {
    my $job = shift;
    return defined($job->{state}) && $job->{state} =~ /DEFERRED/;
}

sub is_daemon {
    my $job = shift;
    return !!$job->{daemon};
}

sub Forks::Super::Job::waitpid {
    my ($job, $flags, $timeout) = @_;
    return Forks::Super::Wait::waitpid($job->{pid}, $flags, $timeout || 0);
}

sub Forks::Super::Job::wait {
    my ($job, $timeout) = @_;
    if (defined($timeout) && $timeout == 0) {
	return Forks::Super::Wait::waitpid($job->{pid}, &WNOHANG);
    }
    return Forks::Super::Wait::waitpid($job->{pid}, 0, $timeout || 0);
}

sub Forks::Super::Job::kill {
    my ($job, $signal) = @_;
    if (!defined($signal) || $signal eq '') {
	$signal = Forks::Super::Util::signal_number('INT') || 1;
    }
    return Forks::Super::kill($signal, $job);
}

sub Forks::Super::Job::state {
    my $job = shift;
    if ($job->{daemon} && 
	$job->{state} ne 'NEW' &&
	$job->{state} ne 'DAEMON-COMPLETE') {

	# if current state is DAEMON or DAEMON-SUSPENDED,
	# inspect the process table or use SIGZERO to see
	# if the daemon is still active
	$job->_check_daemon_state;
    }
    return $job->{state};
}

sub status {
    my $job = shift;
    return $job->{status};  # may be undefined
}

sub exit_status {
    my $job = shift;
    return if !defined $job->{status};
    my $coredump = $job->{status} & 128 ? 1 : 0;
    my $signal = $job->{status} & 127;
    my $exit_status = $job->{status} >> 8;
    if (wantarray) {
	return ($exit_status, $signal, $coredump);
    } elsif ($signal || $coredump) {
	return -$signal - 128*$coredump;
    } else {
	return $exit_status;
    }
}

#
# Produces string representation of a Forks::Super::Job object.
#
sub toString {
    my $job = shift;
    my @to_display = qw(pid state create);
    push @to_display, 
  	grep { defined $job->{$_} } qw(real_pid style cmd exec sub args dir 
                                       start end reaped status closure child_fh
                                       pgid queue_priority timeout expiration
				       signal_pid remote);
    my @output = ();
    no warnings 'uninitialized';
    foreach my $attr (@to_display) {
	next if ! defined $job->{$attr};
	if (ref $job->{$attr} eq 'ARRAY') {
	    push @output, "$attr=[" . join(q{,},@{$job->{$attr}}) . ']';
        } elsif (ref($job->{attr}) eq 'HASH') {
            use Data::Dumper;
            local $Data::Dumper::Indent=0;
            push @output, "$attr=" . Dumper($job->{$attr});
	} else {
	    push @output, "$attr=" . $job->{$attr};
	}
    }
    return '{' . join ( ';' , @output), '}';
}

sub toFullString {
    my $job = shift;
    my @output = ();
    foreach my $attr (sort keys %$job) {
	next if ! defined $job->{$attr};
	if (ref $job->{$attr} eq 'ARRAY') {
	    push @output, "$attr=[" . join(',', @{$job->{$attr}}) . ']';
	} elsif (ref $job->{$attr} eq 'HASH') {
	    push @output, "$attr={", 
	    join(',', map { "$_=>$job->{$attr}{$_}"
		      } sort keys %{$job->{$attr}}), '}';
	} else {
	    push @output, "$attr=$job->{$attr}";
	}
    }
    return '{' . join(';', @output), '}';
}

sub toShortString {
    my $job = shift;
    if (defined $job->{short_string}) {
	return $job->{short_string};
    }
    my @to_display = grep { 
	defined $job->{$_} 
    }  qw(pid state cmd exec sub args closure real_pid);

    my @output;
    foreach my $attr (@to_display) {
	if (ref($job->{$attr}) eq 'ARRAY') {
	    push @output, "$attr=[" . join(',', @{$job->{$attr}}) . ']';
	} else {
	    push @output, "$attr=" . $job->{$attr};
	}
    }
    return $job->{short_string} = '{' . join(';',@output) . '}';
}

sub _mark_complete {
    my $job = shift;
    $job->{end} = Time::HiRes::time();
    $job->{state} = 'COMPLETE';
    $job->run_callback('share');
    $job->run_callback('collect');
    $job->run_callback('finish');
    return;
}

sub _mark_reaped {
    my $job = shift;
    $job->{state} = 'REAPED';
    $job->{reaped} = Time::HiRes::time();
    $job->run_callback('reaped');
    $? = defined $job->{status} ? $job->{status} : $job->{daemon} && 0;
    debug("Job $job->{pid} reaped") if $job->{debug};
    return;
}

#
# determine whether a job is eligible to start
#
sub can_launch {
    no strict 'refs';

    my $job = shift;
    $job->{last_check} = Time::HiRes::time();
    if (defined $job->{can_launch}) {
	if (ref $job->{can_launch} eq 'CODE') {
	    $job->{queue_message} = 'user can_launch function failed';
	    return $job->{can_launch}->($job);
	} elsif (ref $job->{can_launch} eq '') {
	    my $can_launch_sub = $job->{can_launch};
	    $job->{queue_message} = 'user can_launch function failed';
	    return $can_launch_sub->($job);
	}
    } else {
	$job->{queue_message} = 'default can_launch function failed';
	return $job->_can_launch;
    }
}

sub _can_launch_delayed_start_check {
    my $job = shift;
    return 1 if !defined($job->{start_after}) ||
	Time::HiRes::time() >= $job->{start_after};

    if ($job->{debug}) {
        debug('_can_launch(): start delay requested. launch fail');
    }

    # delay option should normally be associated with queue on busy behavior.
    # any reason not to make this the default ?
    #  delay + fail   is pretty dumb
    #  delay + block  is like sleep + fork

    if (! defined $job->{on_busy}) {
	$job->{_on_busy} = 'QUEUE';
    }
    $job->{queue_message} = "haven't yet reached job start_after time "
	. localtime($job->{start_after});
    return 0;
}

sub _can_launch_dependency_check {
    my $job = shift;
    my @dep_on = defined($job->{depend_on}) ? @{$job->{depend_on}} : ();
    my @dep_start = defined($job->{depend_start}) 
        ? @{$job->{depend_start}} : ();

    foreach my $dj (@dep_on) {
	my $j = $ALL_JOBS{$dj};
	if (not defined $j) {
	    carp 'Forks::Super::Job: ',
	    "dependency $dj for job $job->{pid} is invalid. Ignoring.\n";
	    next;
	}
	if (!$j->is_complete) {
	    debug('_can_launch(): ',
		  "job waiting for job $j->{pid} to finish. launch fail.")
		if $j->{debug};
	    $job->{queue_message} = "depends on job $j->{pid} to finish";
	    return 0;
	}
    }

    foreach my $dj (@dep_start) {
	my $j = $ALL_JOBS{$dj};
	if (not defined $j) {
	    carp 'Forks::Super::Job ',
		 "start dependency $dj for job $job->{pid} is invalid. ",
                 "Ignoring.\n";
	    next;
	}
	if (!$j->is_started) {
	    debug('_can_launch(): ',
		  "job waiting for job $j->{pid} to start. launch fail.")
		if $j->{debug};
	    $job->{queue_message} = "depends on job $j->{pid} to start";
	    return 0;
	}
    }
    return 1;
}

sub _can_launch_remote {
    my $job = shift;
    return 1 if !defined $job->{remote};
    my @specs = @{$job->{remote}};
    for (my $i=$#specs; $i>=1; $i--) {
        my $j = int(rand($i+1));
        @specs[$i,$j] = @specs[$j,$i];
    }

    foreach my $spec (@specs) {
        my $host = $spec->{host};
        next unless $host;
        if ($job->_can_launch_remote_check_host($host)) {
            $job->{remote} = $spec;
            return 1;
        }
    }
    if ($job->{debug}) {
        my @hosts = map { $_->{host} } @specs;
        debug("_can_launch_remote: host(s) @hosts are too busy");
    }
    return 0;
}

sub _can_launch_remote_check_host {
    my ($job, $h) = @_;
    my $max_proc = $job->max_proc($h);
    if ($max_proc < 1) {
        debug("_can_launch_remote: no restriction on host $h")
            if $job->{debug};
        return 1;
    }
    my $num_active = count_active_processes_on_host($h);
    if ($num_active >= $max_proc) {
        debug('_can_launch_remote(): ',
              "host $h too busy. ($num_active >= $max_proc)") if $job->{debug};
    } else {
        debug('_can_launch_remote(): ',
              "host $h not busy. ($num_active < $max_proc) ",
              " launch ok") if $job->{debug};
        return 1;
    } 
}

sub max_proc {
    my $val;
    if (@_ > 0 && ref($_[0]) eq 'Forks::Super::Job'
        && (defined($_[0]->{max_proc}) || defined($_[0]->{max_fork}))) {
        $val = $_[0]->{max_proc} || $_[0]->{max_fork};
    } else {
        $val = $Forks::Super::MAX_PROC;
        my $host = shift;
        if (ref($host) && ref($host) eq 'Forks::Super::Job') {
            $host = shift;
        }
        if (defined($host)) {
            if (defined($Forks::Super::MAX_PROC{$host})) {
                $val = $Forks::Super::MAX_PROC{$host};
            } elsif (defined($Forks::Super::MAX_PROC{DEFAULT})) {
                $val = $Forks::Super::MAX_PROC{DEFAULT};
            }
        }
    }
    return ref($val) eq 'CODE' ? $val->() : $val;
}

sub _max_proc { # used in test suite but not in this distro itself
    my $j = shift;
    $j->{max_proc} ||= $j->{max_fork};
    return defined($j->{max_proc}) ? $j->{max_proc} : max_proc();
}

sub _max_load { # used in test suite but not in this distro itself
    my $j = shift;
    return defined($j->{max_load}) ? $j->{max_load} : $Forks::Super::MAX_LOAD;
}

#
# default function for determining whether the system
# is too busy to create a new child process or not
#
sub _can_launch {
    no warnings qw(once);

    my $job = shift;
    if ($job->{force}) {
	debug('_can_launch(): force attr set. launch ok')
	    if $job->{debug};
	return 1;
    }

    return 0 if not $job->_can_launch_delayed_start_check;
    return 0 if not $job->_can_launch_dependency_check;
    if ($job->{remote}) {
        if ($job->_can_launch_remote) {
            debug('_can_launch_remote(): system not busy. launch ok.')
                if $job->{debug};
            return 1;
        } else {
            return 0;
        }
    }

    my $max_proc = $job->max_proc();
    my $max_load = defined($job->{max_load})
	? $job->{max_load} : $Forks::Super::MAX_LOAD;
    if ($max_proc > 0) {
	my $num_active = count_active_processes();
	if ($num_active >= $max_proc) {
	    debug('_can_launch(): ',
		  "active jobs $num_active exceeds limit $max_proc. ",
		  'launch fail.') if $job->{debug};
	    $job->{queue_message} =
		"active jobs $num_active exceeds limit $max_proc";
	    return 0;
	}
    }

    if ($max_load > 0) {
	my $load = get_cpu_load();
	if ($load > $max_load) {
	    debug('_can_launch(): ',
		  "cpu load $load exceeds limit $max_load. launch fail.")
		if $job->{debug};
	    $job->{queue_message} = 
		"cpu load $load exceeds limit $max_load";
	    return 0;
	}
    }
    debug('_can_launch(): system not busy. launch ok.')
	if $job->{debug};
    return 1;
}

# Perl system fork() call. Encapsulated here so it can be overridden 
# and mocked for testing. See t/17-retries.t
sub _CORE_fork { return CORE::fork }

#
# make a system fork call and configure the job object
# in the parent and the child processes
#
sub launch {
    my $job = shift;
    if ($job->is_started) {
	Carp::confess 'Forks::Super::Job::launch() ',
	    "called on a job in state $job->{state}!\n";
    }

    if ($$ != $Forks::Super::MAIN_PID && $Forks::Super::CHILD_FORK_OK > 0) {
	$Forks::Super::MAIN_PID = $$;
	$Forks::Super::CHILD_FORK_OK--;
    }

    if ($$ != $Forks::Super::MAIN_PID && $Forks::Super::CHILD_FORK_OK <= 0) {
	return _launch_from_child($job);
    }
    $job->_preconfig_fh;
    $job->_preconfig2;
    $job->{cwd} = &Cwd::getcwd;


    $_->() for @PREFORK;

    if ($job->{emulate} ||
        ($Forks::Super::EMULATION_MODE && !defined $job->{emulate})) {
        debug("emulating child process in main process") if $job->{debug};
        return $job->_emulate;
    }

    my $pid = _robust_fork($job);
    if (!defined $pid) {
	debug('launch(): CORE::fork() returned undefined!')
	    if $job->{debug};
	return;
    }

    if ($job->{_sync}) {
	$job->{_sync}->releaseAfterFork($pid || $$);
    }


    if (Forks::Super::Util::isValidPid($pid)) {

        $_->() for @POSTFORK_PARENT;

	# parent
	_postlaunch_parent1($pid, $job);
        return $job->_postlaunch_parent2;

    } 
    if ($pid == 0) {

        $_->() for @POSTFORK_CHILD;

	$job->{real_pid} = $job->{pid} = "$$ child";
	$job->{is_child} = 1;

	if ($job->{daemon}) {
	    if (&IS_WIN32) {
		$job->_postlaunch_daemon_child_Win32;
		return 0;
	    }
	    $job->_postlaunch_daemon_child;
	}
	_postlaunch_child($job);
	return 0;

    }  

    Carp::confess 'Forks::Super::launch(): ',
	"Somehow we got invalid pid=$pid from fork call.";
    return;
}

sub _robust_fork {
    my $job = shift;
    my $retries = $job->{retries} || 0;

    # the other 18,000 lines in this distro
    # are just a wrapper around this line:

    my $pid = _CORE_fork();


    while (!defined($pid) && $retries-- > 0) {
	warn 'Forks::Super::launch: ',
	    "system fork call returned undef. Retrying ...\n";
	$_RETRY_PAUSE ||= 1.0;
	my $delay = 1.0 + $_RETRY_PAUSE * (($job->{retries} || 1) - $retries);
	Forks::Super::Util::pause($delay);
	$pid = _CORE_fork();
    }
    return $pid;
}

sub _emulate {
    my $job = shift;
    require Forks::Super::Job::Emulate;
    bless $job, 'Forks::Super::Job::Emulate';
    return $job->emulate;
}

sub _postlaunch_parent1 {
    my ($pid, $job) = @_;

    $ALL_JOBS{$pid} = $job;
    if (defined($job->{state}) &&
	$job->{state} ne 'NEW' &&
	$job->{state} ne 'LAUNCHING' &&
	$job->{state} ne 'DEFERRED') {
	warn 'Forks::Super::Job::launch(): ',
	     "job $pid already has state: $job->{state}\n";
    } else {
	$job->{state} = 'ACTIVE';

	#
	# it is possible that this child exited quickly and has already
	# been reaped in the SIGCHLD handler. In that case, the signal
	# handler should have made an entry in 
	# %Forks::Super::Sigchld::BASTARD_DATA  for this process.
	#
	Forks::Super::Sigchld::handle_bastards($pid);
    }
    if ($job->{signal_ipc_pipe}) {
        close $job->{signal_ipc_pipe}[1];
    }
    if ($job->{daemon_ipc_pipe}) {
        close $job->{daemon_ipc_pipe}[1];
    }
    if ($job->{daemon}) {
	$pid = $job->_postlaunch_daemon_parent($pid);
    }
    $job->{real_pid} = $pid;
    $job->{pid} ||= $pid;
    $job->{start} = Time::HiRes::time();

    $job->_config_parent(1);
    return;
}

sub _postlaunch_parent2 {
    my $job = shift;
    $job->_config_parent(2);
    $job->run_callback('start');
    Forks::Super::handle_CHLD(-1);
    if ($$ != $Forks::Super::MAIN_PID) {
	# Forks::Super::fork call from a child.
	$XSIG{CHLD}[-1] ||= \&Forks::Super::handle_CHLD;
    }
    $job->_read_signal_pid;
    return $OVERLOAD_ENABLED ? $job : $job->{pid};
}

sub _postlaunch_daemon_parent {
    my ($job, $pid) = @_;

    # set the pid to the daemon (grandchild) process's id,
    # not the intermediate (child) process
    $job->{state} = 'DAEMON';
    my $new_pid;
    my $_t = Time::HiRes::time();

    if (defined $job->{daemon_ipc_pipe}) {
        $new_pid = __read_from_pipe( $job->{daemon_ipc_pipe}[0] );
        close $job->{daemon_ipc_pipe}[0];
        close $job->{daemon_ipc_pipe}[1];
    } else {
        for (my $try=1; defined($job->{daemon_ipc}) && $try<=50; $try++) {
            if (-f $job->{daemon_ipc} . '.ready') {
                if (open my $fh, '<', $job->{daemon_ipc}) {
                    $new_pid = <$fh>;
                    close $fh;
                    unlink $job->{daemon_ipc}, $job->{daemon_ipc} . '.ready';
                } else {
                    carp "Forks::Super: could not receive daemon pid: $!";
                    Forks::Super::Util::pause(0.002*$try*$try*$try,$try<3);
                    next;
                }

                if ($job->{debug}) {
                    debug("daemon job pid is $new_pid (try=$try) ",
                          't=',Time::HiRes::time()-$_t,'s');
                }

                ($new_pid) = $new_pid =~ /([-\d]*)/;
                if ($try >= 10) {
                    carp 'Forks::Super::fork: ',
                        'managed to communicate with the daemon process ',
                        "on the $try-th try ...";
                }
                last;
            } elsif ($try == 50) {
                carp 'Forks::Super::fork: ',
                    'failed to communicate with new daemon process';
            } else {
                Forks::Super::Util::pause(0.002*$try*$try*$try,$try<3);
            }
        }
    }
    if ($new_pid) {
	$job->{intermediate_pid} = $pid;
	delete $ALL_JOBS{$pid};
	$ALL_JOBS{$new_pid} = $job;
	$pid = $new_pid;
    } elsif (!defined $new_pid) {
	carp 'Forks::Super::fork: ',
	      'unable to get process ID for new daemon process. ',
	      'It is possible the daemon fork failed. ',
	      'Signalling and other IPC with this process may be unreliable.';
    }
    return $pid;
}

sub _postlaunch_daemon_child_Win32 {
    my $job = shift;

    # maybe we can just do  Win32::Process::Create
    # with the  DETACHED_PROCESS  flag ?

    if ($job->{style} ne 'cmd' && $job->{style} ne 'exec') {
	carp "Forks::Super::fork: 'daemon' option on MSWin32 ",
	    "must also use 'cmd' or 'exec' option";
	return;
    }

    if (!Forks::Super::Config::CONFIG('Win32::Process')) {
	carp 'Forks::Super::daemon: ',
	     'need Win32::Process to launch daemon in MSWin32';
	return;
    }

    if (defined &Forks::Super::init_child) {
	Forks::Super::init_child();
    }
    $job->_config_child;
    local $ENV{_FORK_PPID} = $$;
    local $ENV{_FORK_PID} = $$;

    # XXX - can we handle the usual suite of options with daemon+Win32?
    #       os_priority, cpu_affinity  are set in  _config_child? (need test)
    #       share? of course not (need to doc)

    my $procObj;
    my @cmd = $job->{style} eq 'exec' ? @{$job->{exec}} : @{$job->{cmd}};

    my $result = Win32::Process::Create(
	$procObj, $cmd[0],  join (' ',@cmd),  0,
	&Win32::Process::DETACHED_PROCESS,
	defined $job->{dir} ? $job->{dir} : '/');

    if (!$result) {
	croak 'Forks::Super: failed to launch a detached Windows process: ',
		Win32::Process::ErrorReport();
    }
    my $p2 = $procObj->GetProcessID();
    $job->set_signal_pid($p2);

    if (defined $job->{_timeout}) {
	if ($job->{_timeout} > 0) {
	    Forks::Super::Job::OS::poor_mans_alarm($p2,$job->{_timeout});
	} else {
	    croak "Forks::Super: quick timeout (daemon)";
	}
    }

    if ($job->{daemon_ipc_pipe}) {
        syswrite $job->{daemon_ipc_pipe}[1], "$p2\n";
        close $job->{daemon_ipc_pipe}[1];
    } else {
	my $f = $job->{daemon_ipc};
	if (open my $fh, '>', "$f.tmp") {
	    print $fh $p2;
	    close $fh;
	    rename "$f.tmp", $f;
	    if (open my $ready, '>>', "$f.ready") {
		close $ready;
	    }
	} else {
	    croak "Forks::Super::fork: daemon failed to communicate its PID $!";
	}
    }
    exit;
}

sub _postlaunch_daemon_child {
    my $job = shift;
    debug("child $$ forking again to create daemon process")
	if $job->{debug};



    # following Proc::Daemon's lead:
    # 1. The script forks a child (already done)
    # 2. The child changes the current working directory.
    $job->_chdir_for_daemon;

    # 3. The child clears the file creation mask
    # if $job->{umask} is set, umask will be reset in _config_child
    umask 0;

    # 4. The child becomes a session leader
    my $sid = eval { POSIX::setsid() };
    if ($sid < 0) {
	croak 'Forks::Super: failed to create daemon process ',
		'because it could not make the new child process ',
		"a session leader: $!";
    }

    # local $SIG{'HUP'} = 'IGNORE';

    # 5. Fork another child process (the daemon process) to prevent
    #    the potential of acquiring a controlling terminal.
    my $p1 = $$;
    my $p2 = _CORE_fork();
    if ($p1 != $$) {
	# the second child (daemon) (6., 7., & 8.)
	return $job->_postlaunch_daemon_grandchild;
    }

    if (!defined($p2)) {
	croak 'Forks::Super::fork: ',
		'Unable to create daemon process because secondary fork failed';
    }

    # 9. transfer pid of second child from first child to parent
    if ($job->{daemon_ipc_pipe}) {
        syswrite $job->{daemon_ipc_pipe}[1], "$p2\n";
        close $job->{daemon_ipc_pipe}[1];
    } else
    {
	my $f = $job->{daemon_ipc};
	if (open my $fh, '>', "$f.tmp") {
	    print $fh $p2;
	    close $fh;
	    rename "$f.tmp", $f;
	    if (open my $ready, '>>', "$f.ready") {
		close $ready;
	    }
	} else {
	    croak 'Forks::Super::fork: ',
	    	"daemon failed to communicate its PID: $!";
	}
    }
    exit;
}

sub _postlaunch_daemon_grandchild {
    # config for the actual daemon process

    my $job = shift;
    if (&IS_CYGWIN) {
	$job->__adjust_cygwin_daemon_job;
    }

    # 6. close all open file descriptors
    close STDIN;
    open STDIN, '<', Forks::Super::Util::DEVNULL();
    close STDOUT;
    open STDOUT, '>', Forks::Super::Util::DEVNULL();
    if (! defined $job->{'_daemon_dont_close_2'}) {
        close STDERR;
        open STDERR, '>', Forks::Super::Util::DEVNULL();
    }
    my $max_fh = $Forks::Super::SysInfo::MAX_OPEN_FH;
    if ($max_fh < 256) {
	$max_fh = 256;
    }
    for (3..$max_fh) {
	POSIX::close $_ if ! defined $job->{"_daemon_dont_close_$_"};
    }

    # 7. open STDIN,STDOUT,STDERR to desired locations
    # 8. return to calling script
    #    --- this is handled in _postlaunch_child

    if ($job->{name}) {
	$0 = $job->{name};
    }
    return;
}

sub _chdir_for_daemon {
    my ($job) = @_;
    my $dir = $job->{dir};
    if (!defined($dir)) {
        chdir '/';
    } elsif (!chdir $dir) {
        carp '"Forks::Super::Job: failed to change daemon process ',
	        "directory to \"$dir\":", $!;
	chdir '/';
    }
    return;
}

sub __adjust_cygwin_daemon_job {
    my ($job) = @_;

    if (&IS_CYGWIN && defined($job->{cmd}) && !defined($job->{exec})) {
	if (!defined($job->{timeout}) && !defined($job->{expiration})) {
	    $job->{exec} = delete $job->{cmd};
	    $job->{style} = 'exec';
	} elsif (0) {
	    carp 'Forks::Super::fork: ',
		    'warning: on Cygwin the combination of daemon, cmd, ',
		    'and timeout options are probably incompatible with ',
		    'the Forks::Super::Job::suspend, resume, ',
		    'and terminate functions.';
	}
    }
    return;
}


sub _postlaunch_child {
    my $job = shift;
    Forks::Super::init_child() unless $job->{is_emulation};
    $job->_config_child;

    local $ENV{_FORK_PPID} = $$;
    local $ENV{_FORK_PID} = $$;

    if ($job->{style} eq 'cmd' || $job->{style} eq 'exec') {

        if ($job->{style} eq 'cmd' && $job->{remote}) {

            $job->_postlaunch_child_to_remote_cmd;

        } elsif (defined($job->{fh_config}{stdin})
	    && defined($job->{fh_config}{sockets})) {

	    $job->_postlaunch_child_to_proc;

	} elsif ($job->{style} eq 'cmd') {

	    $job->_postlaunch_child_to_cmd;

	} else {

	    $job->_postlaunch_child_to_exec;

	}

    } elsif ($job->{style} eq 'sub') {

	$job->_postlaunch_child_to_sub;

    } elsif ($job->{style} eq 'natural') {

        $job->_postlaunch_to_natural_child;

    }
    return 0;
}

sub _postlaunch_child_to_exec {
    my $job = shift;
    debug("Exec'ing [ @{$job->{exec}} ]") if $job->{debug};

    if (!&IS_WIN32) {
	exec( @{$job->{exec}} )
	    or croak 'exec failed for ', $job->toString(), 
	        ' command ',@{$job->{exec}};
    }

    # Windows needs special handling. An  exec  call from a Windows child
    # process will actually spawn a new process (a real process, not a
    # pseudo-process) and its process id will be unavailable to both
    # the child and the parent process.
    #
    # Furthermore, the  exec  is not a "true" exec. The old process will
    # hang around and wait for the new process to finish, and then run
    # the END{} blocks and exit with the 
    #
    # system 1, ...  is a decent workaround
    # 
    $WIN32_PROC_PID = system 1, @{$job->{exec}};

    if ($job->{_post_exec_timeout}) {
	Forks::Super::Job::OS::poor_mans_alarm(
	    $WIN32_PROC_PID, $job->{_post_exec_timeout});
    }


    $job->set_signal_pid($WIN32_PROC_PID);
    my $z = CORE::waitpid $WIN32_PROC_PID, 0;
    my $c1 = $?;
    if ($job->{debug}) {
	debug("waitpid $WIN32_PROC_PID ==> $z");
    }
    deinit_child() unless $job->{is_emulation};
    exit $c1 >> 8;
}

sub _postlaunch_child_to_proc {
    my $job = shift;
    my $proch = Forks::Super::Job::Ipc::_gensym();
    $job->{cmd} ||= $job->{exec};
    my $p1 = open $proch, '|-', @{$job->{cmd}};
    print $proch $job->{fh_config}{stdin};
    close $proch;
    my $c1 = $?;
    debug("Exit code of $$ was $c1 ", $c1>>8) if $job->{debug};
    deinit_child() unless $job->{is_emulation};
    exit $c1 >> 8;
}

sub _postlaunch_child_to_cmd {
    my $job = shift;
    debug("Executing command [ @{$job->{cmd}} ]") if $job->{debug};

    my $c1;
    if (&IS_WIN32) {

	$c1 = Forks::Super::Job::OS::Win32::system1_win32_process(
	                      $job, @{$job->{cmd}});

    } else {

	my $this_pid = $$;
        my $retries = $job->{retries} || 0;
	my $exec_pid = _CORE_fork();
	while (!defined $exec_pid && $retries-- > 0) {
            warn "Forks::Super::Job::_postlaunch_child_to_cmd: ",
                "system fork call returned undef. Retrying ...\n";
            Forks::Super::Util::pause(1.0);
            $exec_pid = _CORE_fork();
        }
        if (!defined $exec_pid) {
            croak "Forks::Super::Job::_postlaunch_child_to_cmd: ",
                "Child process unable to create new fork to run cmd";
        }
        if ($exec_pid == 0) {
	    exec( @{$job->{cmd}} ) or
                Carp::confess 'exec for cmd-style fork failed ';
	}
        $job->{debug} && debug("  exec pid is $exec_pid");
	$job->set_signal_pid($exec_pid);
	$job->{exec_pid} = $exec_pid;

	$Forks::Super::Job::CHILD_EXEC_PID = $exec_pid; 
	# XXX - do something with this in _cleanup_child

	my $z = CORE::waitpid $exec_pid, 0;
	$c1 = $?;
	debug("waitpid returned $z, exit code of $$ was $c1 ", $c1>>8)
	    if $job->{debug};
    }
    if ($job->{is_emulation}) {
        Forks::Super::Job::Ipc::_close_child_fh($job);
        Forks::Super::Sigchld::_preliminary_reap($job,$c1);
    } else {
        deinit_child();
        exit $c1 >> 8;
    }
}

sub _postlaunch_child_to_remote_cmd {
    my $job = shift;
    my $remote = $job->{remote};
    my @cmd = @{$job->{cmd}};
    debug("Executing command [ @cmd ] on "
          . $remote->{host}) if $job->{debug};

    my $retries = $job->{retries} || 0;
    my $this_pid = $$;

    if (ref($remote) eq 'ARRAY') {
        $remote = $remote->[0];
    }

    if (!defined($remote->{proto}) || $remote->{proto} eq 'ssh') {
        my (%opts,%runopts);

        my $host = $remote->{host};

        my $stdin;
        if ($job->{stdin}) {
            if ('ARRAY' eq ref $job->{stdin}) {
                $stdin = join '', $job->{stdin}; # or join "\n",... ?
            } else {
                $stdin = $job->{stdin};
            }
        } elsif ($job->{fh_config}{in}) {
            $stdin = join '', <STDIN>;
        }

        untie *STDIN;
        open STDIN,"<",&Forks::Super::Util::DEVNULL;

        if (CONFIG_module('Net::OpenSSH')) {
            foreach my $remoteopt (grep exists $remote->{$_},
                                   qw(key_path user password passphrase
                                      gateway ssh_cmd ctl_dir remote_shell
                                      timeout strict_mode kill_ssh_on_timeout
                                      async default_ssh_opts forward_agent
                                      forward_X11 port)) {
                $opts{$remoteopt} = $remote->{$remoteopt};
            }

            my $ssh = Net::OpenSSH->new($host,%opts);
            croak $ssh->error if $ssh->error;
            $job->set_signal_pid($ssh->get_master_pid);

            if (defined $stdin) {
                $runopts{stdin_data} = $stdin;
            } else {
                $runopts{stdin_discard} = 1;
            }

            my ($output,$errput) = $ssh->capture2(\%runopts, @cmd);
            my $rc = $?;
            print STDOUT $output;
            print STDERR $errput;
            $ssh->disconnect;
            deinit_child();
            exit $rc >> 8;
        } elsif (Forks::Super::Config::CONFIG_external_program("ssh")) {
            # poor man's ssh. Not really recommended if
            # Net::OpenSSH is available.
            if ($remote->{password}) {
                deinit_child();
                die "passphrase with ssh not supported with Net::OpenSSH!";
            }
            my $cmd = __build_ssh_command($host, $remote, $job);
            my $sshpid = CORE::fork();
            if ($sshpid == 0) {
                exec($cmd);
            }
            $job->set_signal_pid($$);
            my $waitpid = CORE::waitpid $sshpid,0;
            my $rc = $?;
            deinit_child();
            exit $rc >> 8;
        } else {
            deinit_child();
            carp "Alternate ssh support for remote option not implemented";
            exit 66;
        }
        deinit_child();
        exit $? >> 8;
    } else {
        croak "Forks::Super: Only 'ssh' protocol supported for remote";
    }
}

sub shquote2 {
    my $input = shift;
    return shquote(shquote($input));
}

sub __build_ssh_command {
    # poor man's ssh command. Build command line instruction to
    # run ssh command and capture output. Not the way to do it
    # if there is any other way to do it.
    #
    # we ass-u-me that local host and remote host are POSIX-y,
    # and that shquote should be applied for both purposes
    # (so it is applied twice for the actual remote command and
    # its arguments).
    
    my ($host, $remote, $job) = @_;

    my @cmd = (shquote(Forks::Super::Config::CONFIG_external_program("ssh")));

    if ($remote->{debug}) {
        push @cmd, "-v";
    }

    my $id = $remote->{identity_file} || $remote->{identity}
                                      || $remote->{key_path};
    if ($id && ref($id) eq '') {
        $id = [ $id ];
    }
    if ($id) {
        push @cmd, "-i", shquote($_) for @$id;
    }

    if ($remote->{port}) {
        push @cmd, "-p", shquote($remote->{port});
    }

    if ($remote->{user}) {
        my $user = $remote->{user};
        if ($remote->{password}) {
            # I don't think this will work ...
            $user .= ":" . $remote->{password};
        }
        push @cmd, "-l", shquote($user);
    }

    if ($remote->{options}) {
        my $options = $remote->{options};
        if (ref($options) eq '') {
            $options = [ $options ];
        }
        push @cmd, "-o", shquote($_) for @$options;
    }

    push @cmd, shquote($host);

    # command must immediately follow $host
    # command to remote host must be shell quoted twice!
    # once for the local shell running ssh, and
    # once for the remote shell interpreting the command

    if (@{$job->{cmd}} <= 1) {
        push @cmd, map { shquote($_) } @{$job->{cmd}};
    } else {
        push @cmd, map { shquote2($_) } @{$job->{cmd}};
    }

    my $stdin;
    if ($job->{stdin}) {
        if ('ARRAY' eq ref $job->{stdin}) {
            $stdin = join '', $job->{stdin}; # or join "\n",... ?
        } else {
            $stdin = $job->{stdin};
        }
    } elsif ($job->{fh_config}{in}) {
        $stdin = join '', <STDIN>;
    }
    if (defined($stdin)) {
        open my $fh,'>',$job->{fh_config}{f_in};
        print $fh $stdin;
        close $fh;
        close STDIN;
        push @cmd, "<" . shquote($job->{fh_config}{f_in});
    } else {
        push @cmd, '</dev/null';
    }

    if ($job->{fh_config}{out}) {
        if ($job->{fh_config}{f_out} eq '__socket__') {
        } else {
            close STDOUT;
            push @cmd, ">" . shquote($job->{fh_config}{f_out});
        }
    } else {
        push @cmd, ">/dev/null";
    }
    if ($job->{fh_config}{join}) {
        close STDERR;
        push @cmd, "2>&1";
    } elsif ($job->{fh_config}{err}) {
        close STDERR;
        push @cmd, "2>" . shquote($job->{fh_config}{f_err});
    } else {
        push @cmd, "2>/dev/null";
    }

#    push @cmd, '>/tmp/ssh.stdout';
#    push @cmd, '2>/tmp/ssh.stderr';

    return "@cmd";
}

sub _postlaunch_child_to_sub {
    my $job = shift;
    my $sub = $job->{sub};
    my @args = @{$job->{args} || []};

    my $error;
    eval {
	no strict 'refs';
        if (!$job->{is_emulation}) {
            $job->{_cleanup_code} = \&deinit_child;
        }
	$sub->(@args);
	delete $job->{_cleanup_code};
	1;
    } or do {
	$error = $@;
    };

    if ($job->{debug}) {
	if ($error) {
	    debug("JOB $$ SUBROUTINE CALL HAD AN ERROR: $error");
	}
	debug("Job $$ subroutine call has completed");
    }
    if ($job->{is_emulation}) {
        Forks::Super::Job::Ipc::_child_share($job);
        my $status = 0;
        if ($error) {
            $job->{error} = $error;
            $status = 255 << 8;
        }
        return Forks::Super::Sigchld::_preliminary_reap($job,$status);
    }
    deinit_child();
    if ($error) {
        die $error,"\n";
    }
    exit 0;
}

sub _postlaunch_to_natural_child {
    # no chance to run  deinit_child  on a natural fork except inside
    # an END block. This function adds an END block at run time that
    # won't be seen by any other processes.
    use B;
    unshift @{B::end_av->object_2svref}, \&deinit_child;
}

sub _launch_from_child {
    my $job = shift;
    if ($Forks::Super::CHILD_FORK_OK == 0) {
	carp "Forks::Super::fork() not allowed in child process $$ ",
	        "while \$Forks::Super::CHILD_FORK_OK is not set!";
	return;
    } elsif ($Forks::Super::CHILD_FORK_OK < 0) {
	carp "Forks::Super::fork() call not allowed in child process $$ ",
		"while \$Forks::Super::CHILD_FORK_OK <= 0.\n",
		"Will use CORE::fork() to create child of child.";

	my $pid = _CORE_fork();
	if (defined($pid) && $pid == 0) {
	    # child of child
	    if (defined &Forks::Super::init_child) {
		Forks::Super::init_child();
	    } else {
		init_child();
	    }
	    # return $pid;
	}
	return $pid;
    }
    return;
}

sub set_signal_pid {
    # called from child. signal_pid will be called from the parent
    my ($job, $signal_pid) = @_;
    $job->{signal_pid} = $signal_pid;

    if (defined $job->{signal_ipc}) {
	if (open my $fh, '>', $job->{signal_ipc} . '.tmp') {
	    print $fh $signal_pid;
	    close $fh;
	    rename $job->{signal_ipc} . '.tmp', $job->{signal_ipc};
	    if ($job->{debug}) {
		debug("Signal pid for $$ is $signal_pid");
	    }
	} else {
	    carp 'Forks::Super::set_signal_pid: ',
	        "child was unable to communicate its other PID to parent: $!";
	}
    } elsif (defined $job->{signal_ipc_pipe}) {
        syswrite $job->{signal_ipc_pipe}[1], $signal_pid . "\n";
        close $job->{signal_ipc_pipe}[1];
    } elsif (0) {
	no warnings 'uninitialized';
	carp 'Forks::Super::set_signal_pid: signal IPC file not specified ',
	    "for job $job->{pid} to deliver signal pid $signal_pid ",
	    'to its parent';
    }
    return;
}

sub signal_pids {
    # if a background job has spawned yet another process,
    # then sometimes we want to send a signal to both of those processes ...

    my $job = shift;
    my $signal_pid = $job->signal_pid;

    if (defined $job->{real_pid} && $job->{real_pid} != $signal_pid) {
	if ($job->{debug}) {
	    debug("signal pids for $job are $signal_pid,", $job->{real_pid});
	}

	# XXX - do we just want to signal one pid ???
	#return ($signal_pid, $job->{real_pid});
	return ($signal_pid);
    } else {
	if ($job->{debug}) {
	    debug("signal pids for $job is $signal_pid");
	}
	return ($signal_pid);
    }
}

sub signal_pid {
    my $job = shift;

    if (($job->{signal_ipc} || $job->{signal_ipc_pipe}) &&
        !defined $job->{signal_pid}) {
	$job->_read_signal_pid;
    }
    if ($job->{debug} && defined $job->{signal_pid}) {
	debug("job $job will send signal to ", $job->{signal_pid});
    }
    return $job->{signal_pid} || $job->{real_pid};
}

sub __read_from_pipe {
    my $pipe = shift;
    my ($rin,$ein,$rout,$eout) = ('');
    vec($rin, fileno($pipe), 1) = 1;
    $ein = $rin;
    my ($nfound,$timeleft);
    for my $try (1 .. 5) {
        my $timeout = 0.002 * $try * $try * $try;
        ($nfound, $timeleft) = select($rout=$rin, undef, $eout=$ein, $timeout);
        if ($nfound) {
            my $line = '';
            my $ch;
            for (;;) {
                $ch = getc($pipe);
                if (!defined($ch) || $ch eq "\n") {
                    return $line;
                }
                $line .= $ch;
            }
        }
    }
    return;
}

sub _read_signal_pid {
    my $job = shift;

    if (defined $job->{signal_ipc_pipe}) {
        my $pid = __read_from_pipe( $job->{signal_ipc_pipe}[0] );
        if ($pid) {
            $job->{signal_pid} = $pid;
            if ($^O eq 'MSWin32') {
                $job->{pgid} = $job->{signal_pid};
            }
            close $job->{signal_ipc_pipe}[0];
            close $job->{signal_ipc_pipe}[1];
            if ($job->{debug}) {
                debug('parent forwarding signals for ', 
                      $job->{real_pid}, ' to ', $job->{signal_pid});
            }
            delete $job->{signal_ipc_pipe};
            return;
        } elsif ($job->{debug}) {
            debug('no signal pid read from signal ipc pipe ...');
        }
        return;
    }

    if (!defined $job->{signal_pid} && $job->{signal_ipc}) {
        for my $try (1 .. 5) {
            last if -f $job->{signal_ipc};
            Forks::Super::Util::pause(0.002*$try*$try*$try, $try<3);
        }
    }
    if ($job->{signal_ipc} && -f $job->{signal_ipc}) {
	for my $try (1..2) {
	    if (open my $fh, '<', $job->{signal_ipc}) {
		my $signal_pid = <$fh>;
		close $fh;
		unlink $job->{signal_ipc} or
		    warn 'parent did not remove IPC signal file ',
		         $job->{signal_ipc}, "! $!";
		($job->{signal_pid}) = $signal_pid =~ /([-\d]*)/;
		if ($^O eq 'MSWin32') {
		    $job->{pgid} = $job->{signal_pid};
		}
		if ($job->{debug}) {
		    debug('parent forwarding signals for ', 
			  $job->{real_pid}, ' to ', $job->{signal_pid});
		}
                delete $job->{signal_ipc};
		last;
	    } else {
		Forks::Super::pause(1.0);
	    }
	}
    } elsif ($job->{debug}) {
	debug('no ', $job->{signal_ipc}, ' signal ipc file ...');
    }
    return;
}

sub suspend {
    my $j = shift;
    $j = Forks::Super::Job::get($j);
    if ($j->{state} eq 'ACTIVE') {
	return $j->_suspend_active;
    }

    if ($j->{state} =~ /DAEMON/ && $j->{state} ne 'DAEMON-COMPLETE') {

	return $j->_suspend_daemon;

    }

    if ($j->{state} eq 'DEFERRED') {
	$j->{state} = 'SUSPENDED-DEFERRED';
	return -1;
    }

    if ($j->is_complete) {
	carp 'Forks::Super::Job::suspend(): called on completed job ', 
		$j->{pid}, "\n";
	return;
    }
    if ($j->{state} eq 'SUSPENDED') {
	carp 'Forks::Super::Job: suspend called on suspended job ', $j->{pid};
	return;
    }
    carp 'Forks::Super::Job: suspend called on job ', $j->toString(), "\n";
    return;
}

sub _suspend_active {
    my $j = shift;

    local $! = 0;
    my $kill_result = 0;
    if (&IS_CYGWIN) {
	require Forks::Super::Job::OS::Cygwin;
	my @pids = $j->signal_pids;
	foreach my $pid (@pids) {
	    $kill_result += !!Forks::Super::Job::OS::Cygwin::suspend($pid);
	}
    } else {
	$kill_result = Forks::Super::kill('STOP', $j);
    }
    if ($kill_result > 0) {
	$j->{state} = 'SUSPENDED';
	return 1;
    }
    # carp "'STOP' signal not received by job ", $j->toString(), "\n";
    return;
}

sub _suspend_daemon {
    my $j = shift;

    local $! = 0;
    my $kill_result = 0;
    if (&IS_CYGWIN) {
	require Forks::Super::Job::OS::Cygwin;
	my @pids = $j->signal_pids;
	foreach my $pid (@pids) {
	    $kill_result += !!Forks::Super::Job::OS::Cygwin::suspend($pid);
	}
    } else {
	$kill_result = Forks::Super::kill('STOP', $j);
    }
    if ($kill_result) {
	$j->{state} = 'SUSPENDED-DAEMON';
    }
    return $kill_result;
}

sub resume {
    my $j = shift;
    $j = Forks::Super::Job::get($j);
    if ($j->{state} eq 'SUSPENDED') {

	return $j->_resume_active;

    }
    if ($j->{state} eq 'SUSPENDED-DEFERRED') {
	$j->{state} = 'DEFERRED';
	return -1;
    }
    if ($j->is_complete) {
	carp 'Forks::Super::Job::resume(): called on a completed job ', 
		$j->{pid}, "\n";
	return;
    }
    if ($j->{daemon} && $j->{state} !~ /COMPLETE/) {

	return $j->_resume_daemon;

    }
    carp 'Forks::Super::Job::resume(): called on job in state ', 
    	$j->{state}, "\n";
    return;
}

sub _resume_active {
    my $j = shift;

    local $! = 0;
    my $kill_result = 0;
    if (&IS_CYGWIN) {
	require Forks::Super::Job::OS::Cygwin;
	for my $pid ($j->signal_pids) {
	    $kill_result += !!Forks::Super::Job::OS::Cygwin::resume($pid);
	}
    } else {
	$kill_result = Forks::Super::kill('CONT', $j);
    }
    if ($kill_result > 0) {
	$j->{state} = 'ACTIVE';
	return 1;
    }
    carp "'CONT' signal not received by job ", $j->toString(), "\n";
    return;
}

sub _resume_daemon {
    my $j = shift;

    my $kill_result = 0;
    if (&IS_CYGWIN) {
	require Forks::Super::Job::OS::Cygwin;
	foreach my $pid ($j->signal_pids) {
	    $kill_result += !!Forks::Super::Job::OS::Cygwin::resume($pid);
	}
    } else {
	$kill_result = Forks::Super::kill('CONT', $j);
    }
    if ($kill_result) {
	$j->{state} = 'DAEMON';
    }
    return $kill_result;
}

sub terminate {
    my $j = shift;
    if (!ref($j) || !$j->isa('Forks::Super::Job')) {
	$j = Forks::Super::Job::get($j);
    }
    if (&IS_CYGWIN) {
	require Forks::Super::Job::OS::Cygwin;
	for my $pid ($j->signal_pids) {
	    Forks::Super::Job::OS::Cygwin::terminate($pid);
	}
    } else {
	Forks::Super::kill('KILL', $j);
    }
    return;
}

#
# do further initialization of a Forks::Super::Job object,
# mainly setting derived fields
#
sub _preconfig {
    my $job = shift;
    $job->_preconfig_style;
    $job->_preconfig_dir;
    $job->_preconfig_busy_action;
    $job->_preconfig_start_time;
    $job->_preconfig_dependencies;
    $job->_preconfig_share;
    $job->_preconfig_remote;
    Forks::Super::Job::Callback::_preconfig_callbacks($job);
    Forks::Super::Job::OS::_preconfig_os($job);
    return;
}

# some final initialization just before launch
sub _preconfig2 {
    my $job = shift;
    if (!defined $job->{debug}) {
	$job->{debug} = $Forks::Super::Debug::DEBUG;
    }
    if ($job->{daemon}) {
        # we avoid pipes on Windows because they have tiny capacity
        # and prone to deadlock. Those concerns are not so big for
        # communicating the daemon pid ... do we want to
        # try using pipes for this on Windows?
        if (!&IS_WIN32) {
            pipe my $p1, my $p2;
            $p2->autoflush(1);
            $job->{daemon_ipc_pipe} = [ $p1, $p2 ];
            if ($job->{debug}) {
                debug('Job will use pipe to get daemon pid');
            }
        } else {
            $job->{daemon_ipc} =
                Forks::Super::Job::Ipc::_choose_fh_filename(
                    '.daemon', purpose => 'daemon ipc');
            if ($job->{debug}) {
                debug('Job will use ', $job->{daemon_ipc},
                      ' to get daemon pid.');
            }
        }
    }
    if ($job->{style} eq 'cmd'
		|| (&IS_WIN32 && $job->{style} eq 'exec')
		|| (&IS_WIN32 && ($job->{timeout} || $job->{expiration}))) {


        if ($Forks::Super::SIGNAL_IPC_FILE 

            # we avoid pipes on Windows because they have tiny capacity
            # and prone to deadlock, but those are not large concerns
            # for a low volume, single purpose communication channel
            # like communicating the signal pid
#           || &IS_WIN32
            
            || $job->{daemon}) {
            $job->{signal_ipc} =
                Forks::Super::Job::Ipc::_choose_fh_filename(
                    '.signal', purpose => 'signal ipc', job => $job);
            if ($job->{debug}) {
                debug('Job will use ', $job->{signal_ipc},
                      ' to get signal pid.');
            }
        } else {
            pipe my $p1, my $p2;
            $p2->autoflush(1);
            $job->{signal_ipc_pipe} = [ $p1, $p2 ];
            if ($job->{debug}) {
                debug('Job will use pipe to get signal pid.');
            }
        }
    }

    if ($Forks::Super::Debug::DUMPSIG) {
	if ($job->{style} eq 'natural' || $job->{style} eq 'sub') {
	    $job->{_enable_dump} =
		Forks::Super::Job::Ipc::_choose_fh_filename(
		    '.dump', purpose => 'stack trace ipc', job => $job);
	}
    }
    if ($job->{sync}) {
	require Forks::Super::Sync;
	my ($count, @initial);
	if (ref $job->{sync} eq 'ARRAY') {
	    $count = @initial = @{$job->{sync}};
	} elsif ($job->{sync} !~ /\D/) {
	    $count = $job->{sync};
	    @initial = ('N') x $count;
	} else {
	    $count = @initial = split //, $job->{sync};
	}

	if ($job->{sync_impl}) {
	    $job->{_sync} = Forks::Super::Sync->new( 
	        implementation => $job->{sync_impl},
		count => $count,
		initial => \@initial );
	    $job->{_sync}{_job} = $job;
	} else {
	    $job->{_sync} = Forks::Super::Sync->new( 
#	    implementation => 'Semaphlock',
		count => $count,
		initial => \@initial );
	    $job->{_sync}{_job} = $job;
	}
    }
    return;
}

sub _preconfig_style {
    my $job = shift;

    ###################
    # set up style.
    #

    if (0 && defined $job->{run}) {   # not enabled
	$job->_preconfig_style_run;
    }

    if (defined $job->{cmd}) {
	if (ref $job->{cmd} ne 'ARRAY') {
	    $job->{cmd} = [ $job->{cmd} ];
	}
	$job->{style} = 'cmd';
    } elsif (defined $job->{exec}) {
	if (ref $job->{exec} ne 'ARRAY') {
	    $job->{exec} = [ $job->{exec} ];
	}
	$job->{style} = 'exec';
    } elsif (defined $job->{sub}) {
	$job->{style} = 'sub';
	$job->{sub} = qualify_sub_name $job->{sub};
	if (defined $job->{args}) {
	    if (ref $job->{args} ne 'ARRAY') {
		$job->{args} = [ $job->{args} ];
	    }
	} else {
	    $job->{args} = [];
	}
    } else {
	$job->{style} = 'natural';
    }
    return;
}

sub _preconfig_style_run {    ### for future use
    my $job = shift;
    if (ref $job->{run} ne 'ARRAY') {
	$job->{run} = [ $job->{run} ];
    }

    return;

    # How will we use or emulate the rich functionality
    # of IPC::Run?
    #
    # inputs are a "harness specification"
    # build a harness
    # on "launch", call $harness->start
    # when the job is reaped, call $harness->finish

    # one feature of IPC::Run harnesses is that they
    # may be reused!

}

sub _preconfig_dir {
    my $job = shift;
    if (defined $job->{chdir}) {
	$job->{dir} ||= $job->{chdir};
    }
    if (defined $job->{dir}) {
	$job->{dir} = Forks::Super::Util::abs_path($job->{dir});
    }
    return;
}

sub _preconfig_busy_action {
    my $job = shift;

    ######################
    # what will we do if the job cannot launch?
    #
    if (defined $job->{on_busy}) {
	$job->{_on_busy} = $job->{on_busy};
    } else {
	no warnings 'once';
	$job->{_on_busy} = $Forks::Super::ON_BUSY || 'block';

	# may be overridden to 'queue' if  depend_on  or
	# depend_start  is set. See  _preconfig_dependencies

    }
    $job->{_on_busy} = uc $job->{_on_busy};

    ########################
    # make a queue priority available if needed
    #
    if (not defined $job->{queue_priority}) {
	$job->{queue_priority} = Forks::Super::Deferred::get_default_priority();
    }
    return;
}

sub _preconfig_start_time {
    my $job = shift;

    ###########################
    # configure a future start time
    my $start_after = 0;
    if (defined $job->{delay}) {
	$start_after
	    = Time::HiRes::time() 
	    + Forks::Super::Job::Timeout::_time_from_natural_language(
	            $job->{delay}, 1);
    }
    if (defined $job->{start_after}) {
	my $start_after2 =
            Forks::Super::Job::Timeout::_time_from_natural_language(
                $job->{start_after}, 0);
	if ($start_after < $start_after2) {
	    $start_after = $start_after2 
	}
    }
    if ($start_after) {
	$job->{start_after} = $start_after;
	delete $job->{delay};
	debug('_can_launch(): start delay until ' 
              . localtime($job->{start_after}) . ' requested.')
	    if $job->{debug};
    }
    return;
}

sub _preconfig_dependencies {
    my $job = shift;

    ##########################
    # assert dependencies are expressed as array refs
    # expand job names to pids
    #
    if (defined $job->{depend_on}) {
	if (ref $job->{depend_on} ne 'ARRAY') {
	    $job->{depend_on} = [ $job->{depend_on} ];
	}
	$job->{depend_on} = _resolve_names($job, $job->{depend_on});
	$job->{_on_busy} = 'QUEUE' unless $job->{on_busy};
    }
    if (defined $job->{depend_start}) {
	if (ref $job->{depend_start} ne 'ARRAY') {
	    $job->{depend_start} = [ $job->{depend_start} ];
	}
	$job->{depend_start} = _resolve_names($job, $job->{depend_start});
	$job->{_on_busy} = 'QUEUE' unless $job->{on_busy};
    }
    return;
}

sub _preconfig_remote {
    my $job = shift;
    return if !defined $job->{remote};
    my $remote = $job->{remote};
    if (!$job->{cmd}) {
        if ($job->{exec}) {
            $job->{cmd} = $job->{exec};
        } else {
            carp "fork: remote => ... specified without  cmd => ... ! ",
            "remote spec will be ignored";
            $job->{remote_disabled} = delete $job->{remote};
            return;
        }
    }

    if ('ARRAY' ne ref $job->{remote}) {
        # prior to launch, ensure that $job->{remote} is an array reference
        # of allowable remote specs.
        #
        # after launch, $job->{remote} will point to the actual remote spec
        # that was used to launch the job (see _can_launch_remote)
        $job->{remote} = [ $job->{remote} ];
    }
    $job->{remote} = [
        map {
            if (!ref($_)) {
                { host => $_ };
            } elsif (!defined($_->{host})) {
                ()
            } elsif (defined($_->{proto}) && $_->{proto} ne 'ssh') {
                carp "Forks::Super: Only 'ssh' protocol supported in remote";
                ()
            } elsif (ref($_->{host}) eq 'ARRAY') {
                # not documented, but  remote => { host=>[host1,host2],user=>... }
                # is supported
                my $spec = $_;
                map {
                    my $spec2 = { %$spec };
                    $spec2->{host} = $_;
                    $spec2;
                } @{$_->{host}};
            } else {
                $_
            }
        } @{$job->{remote}}
        ];
    if (@{$job->{remote}} == 0) {
        $job->{__error} = "No valid remote specs in remote param $remote";
        return;
    }
    foreach my $spec (@{$job->{remote}}) {
        my $host = $spec->{host};
        my ($up,$hp) = split /(?<!\\)@/, $host, 2;
        if ($up && $hp) {
            my ($u,$p) = split /(?<!\\):/, $up, 2;
            if ($u && $p) {
                $spec->{user} ||= $u;
                $spec->{password} ||= $p;
            } else {
                $spec->{user} ||= $up;
            }
            $host = $hp;
        }
        my ($h,$p) = split /(?<!\\):/, $host, 2;
        if ($h && $p) {
            $spec->{host} = $h;
            $spec->{port} ||= $p;
        }
    }
    return;
}

# convert job names in an array to job ids, if necessary
sub _resolve_names {
    my ($job, $id_list) = @_;
    my @out = ();
    foreach my $id (@{$id_list}) {
	if (ref($id) && $id->isa('Forks::Super::Job')) {
	    push @out, $id;
	} elsif (is_number($id) && defined($ALL_JOBS{$id})) {
	    push @out, $id;
	} else {
	    my @j = Forks::Super::Job::getByName($id);
	    if (@j > 0) {
		foreach my $j (@j) {
		    next if \$j eq \$job; 
		    # $j eq $job was not sufficient when $job is overloaded
		    # and $job->{pid} has not been set.

		    push @out, $j->{pid};
		}
	    } else {
		carp 'Forks::Super: Job ',
		    "dependency identifier \"$id\" is invaild. Ignoring\n";
	    }
	}
    }
    return \@out;
}

#
# set some additional attributes of a Forks::Super::Job after the
# child is successfully launched.
#
sub _config_parent {
    my ($job,$step) = @_;
    $step = $step || 1;
    $job->_config_fh_parent($step);
    $job->_config_timeout_parent($step);
    if ($step < 2 && $Forks::Super::SysInfo::CONFIG{'getpgrp'}) {
	# when  timeout =>   or   expiration =>  is used,
	# PGID of child will be set to child PID
	if (defined($job->{timeout}) || defined($job->{expiration})) {
	    $job->{pgid} = $job->{real_pid};
	} else {
	    if (not eval { $job->{pgid} = getpgrp($job->{real_pid}) }) {
		$Forks::Super::SysInfo::CONFIG{'getpgrp'} = 0;
		$job->{pgid} = $job->{real_pid};
	    }
	}
    }
    return;
}

# only meaningful from a child process
sub this {
    return $this;
}

sub _config_child {
    my $job = shift;

    {
        no warnings 'once';
        # $Forks::Super::Job::self  is deprecated
        $Forks::Super::Job::self = $job;
    }
    $this = $job;

    $job->_config_env_child;
    $job->_config_callback_child;
    $job->_config_debug_child;
    $job->_config_timeout_child;
    $job->_config_os_child;
    $job->_config_fh_child;
    $job->_config_dir;
    return;
}

sub _config_env_child {
    my $job = shift;
    if ($job->{env} && ref($job->{env}) eq 'HASH') {
	foreach my $key (keys %{$job->{env}}) {
	    $ENV{$key} = $job->{env}{$key};
	}
    }
    return;
}

sub _config_debug_child {
    my $job = shift;
    if ($job->{undebug}) {
	if ($Forks::Super::Config::IS_TEST) {
	    debug("Disabling debugging in child $$");
	}
	$Forks::Super::Debug::DEBUG = 0;
	$Forks::Super::DEBUG = 0;
	$job->{debug} = 0;
    }
    if ($job->{_enable_dump}) {
	if ($job->{style} eq 'natural' || $job->{style} eq 'sub') {
	    $SIG{ $Forks::Super::Debug::DUMPSIG } =
		\&Forks::Super::Debug::child_dump;
	} else {
	    $SIG{ $Forks::Super::Debug::DUMPSIG } = 'IGNORE';
	}
    }
    return;
}

sub _config_dir {
    my $job = shift;
    $job->{dir} ||= $job->{chdir};
    if (defined $job->{dir}) {
	if (!chdir $job->{dir}) {
	    croak 'Forks::Super::Job::launch(): ',
	        "Invalid \"dir\" option: \"$job->{dir}\" $!\n";
	}
    }
    return;
}

sub acquire {
    my ($job, $n, $timeout) = @_;
    $job = &this if $job eq __PACKAGE__;
    if ($job->{_sync}) {
	return $job->{_sync}->acquire($n, $timeout);
    }
    return;
}

sub release {
    my ($job, $n) = @_;
    $job = &this if $job eq __PACKAGE__;
    if ($job->{_sync}) {
	return $job->{_sync}->release($n);
    }
    return;
}

sub acquireAndRelease {
    my ($job, $n, $timeout) = @_;
    return $job->acquire($n,$timeout) && $job->release($n);
}

######################################################################

# Global destruction handling. There is a lot of cleanup in this
# distribution and a lot of functions need to know if they are
# being called during global destruction.

BEGIN {
    if (defined ${^GLOBAL_PHASE}) {  # Perl v>=5.14.0
        eval 'sub _INSIDE_END_QUEUE () {
                  ${^GLOBAL_PHASE} eq q{DESTRUCT} &&  __END() }; 1';
    } else {
        require B;
        eval 'sub _INSIDE_END_QUEUE () { ${B::main_cv()} == 0 && __END() }; 1';
    }
}

END { &__END }

sub __END {
    no warnings 'internal', 'redefine';
    *_INSIDE_END_QUEUE = sub () { 1 };

    if ($$ == ($Forks::Super::MAIN_PID ||= $$)) {

	# disable SIGCHLD handler during cleanup. Hopefully this will fix
	# intermittent test failures where all subtests pass but the
	# test exits with non-zero exit status (e.g., t/42d-filehandles.t)

	untie %SIG;
	eval {
	    no warnings;                    ## no critic (NoWarnings)
	    $SIG{CHLD} = undef; 1;
	} or do {
	    $SIG{CHLD} = 'IGNORE';
	};
	Forks::Super::Deferred::_cleanup();
	Forks::Super::Job::Ipc::_cleanup();
    } else {
        if (defined($this) && defined($this->{_cleanup_code})) {
            no strict 'refs';
            $this->{_cleanup_code}->();
        }
	Forks::Super::Job::Timeout::_cleanup_child();
    }
    1;
}

#############################################################################
# Package methods (meant to be called as Forks::Super::Job::xxx(@args))

sub enable_overload {
    if (!$OVERLOAD_ENABLED) {
	$OVERLOAD_ENABLED = 1;

	if (!eval  q!
	    # in most contexts a Forks::Super::Job obj acts like its process id
	    use overload
		'""' => sub { $_[0]->{pid} },
		'+' => sub { $_[0]->{pid} + $_[1] },
		'*' => sub { $_[0]->{pid} * $_[1] },
		'&' => sub { $_[0]->{pid} & $_[1] },
		'|' => sub { $_[0]->{pid} | $_[1] },
		'^' => sub { $_[0]->{pid} ^ $_[1] },
		'~' => sub { ~$_[0]->{pid} },         # since 0.37
		'<=>' => sub { $_[2] ? $_[1] <=> $_[0]->{pid} 
			       : $_[0]->{pid} <=> $_[1] },
	        'cmp' => sub { $_[2] ? $_[1] cmp $_[0]->{pid} 
			       : $_[0]->{pid} cmp $_[1] },
	        '-'   => sub { $_[2] ? $_[1]  -  $_[0]->{pid} 
			       : $_[0]->{pid}  -  $_[1] },
	        '/'   => sub { $_[2] ? $_[1]  /  $_[0]->{pid} 
			       : $_[0]->{pid}  /  $_[1] },
	        '%'   => sub { $_[2] ? $_[1]  %  $_[0]->{pid} 
			       : $_[0]->{pid}  %  $_[1] },
	        '**'  => sub { $_[2] ? $_[1]  ** $_[0]->{pid} 
			       : $_[0]->{pid}  ** $_[1] },
	        '<<'  => sub { $_[2] ? $_[1]  << $_[0]->{pid} 
			       : $_[0]->{pid}  << $_[1] },
	        '>>'  => sub { $_[2] ? $_[1]  >> $_[0]->{pid} 
			       : $_[0]->{pid}  >> $_[1] },
	        'x'   => sub { $_[2] ? $_[1]  x  $_[0]->{pid} 
			       : $_[0]->{pid}  x  $_[1] },
	        'cos'  => sub { cos $_[0]->{pid} },
	        'sin'  => sub { sin $_[0]->{pid} },
	        'exp'  => sub { exp $_[0]->{pid} },
	        'log'  => sub { log $_[0]->{pid} },
	        'sqrt' => sub { sqrt $_[0]->{pid} },
	        'int'  => sub { int $_[0]->{pid} },
	        'abs'  => sub { abs $_[0]->{pid} },
	        'atan2' => sub { $_[2] ? atan2($_[1],$_[0]->{pid}) 
				     : atan2($_[0]->{pid},$_[1]) },
		 # '<>' => sub { $_[0]->read_stdout() },  # doesn't work
		'fallback' => 1,
		    ;

	    # '<>' => sub { ... }
	    # doesn't work -- it gives us "Not a GLOB reference ..."
	    # errors when we try to use it. XXX - Why?
	    #
	    # Here's the workaround:

	    no strict 'refs';
	    *{__PACKAGE__ . '::(<>'} = sub { $_[0]->read_stdout() };


	    1 !            # end eval 'use overload ...'
	    ) {
	    carp 'Error enabling overloading on ',
	    	"Forks::Super::Job objects: $@\n";
	} elsif ($Forks::Super::Debug::DEBUG) {
	    debug('Enabled overloading on Forks::Super::Job objects');
	}
    }
    return;
}

sub disable_overload {
    if ($OVERLOAD_ENABLED) {
	$OVERLOAD_ENABLED = 0;

	# XXX - the use of  overload::unimport  at run-time is "questionable"
	#       and of dubious value
	eval {
	    my @ops = grep {
	        $_ ne '""' && $_ ne 'fallback'
	    } map { split } values %overload::ops;
	    overload->unimport( @ops );
	    1
	} or Forks::Super::Debug::carp_once 'Forks::Super::Job ',
	        "disable overload failed: $@";

    }
    return;
}

# returns a Forks::Super::Job object with the given identifier
sub get {
    my $id = shift;
    if (!defined $id) {
	Carp::cluck 'undef value passed to Forks::Super::Job::get()';
    }
    if (ref($id) && $id->isa('Forks::Super::Job')) {
	return $id;
    }
    if (defined $ALL_JOBS{$id}) {
	return $ALL_JOBS{$id};
    }
    return getByPid($id) || getByName($id);
}

sub getByPid {
    my $id = shift;
    if (is_number($id)) {
	my @j = grep { ($_->{pid} && ($_->{pid} == $id)) ||
                       ($_->{real_pid} && ($_->{real_pid} == $id))
		 } @ALL_JOBS;
	return $j[0] if @j > 0;
    }
    return;
}

sub getByName {
    my $id = shift;
    my @j = grep { defined($_->{name}) && $_->{name} eq $id } @ALL_JOBS;
    if (@j > 0) {
	return wantarray ? @j : $j[0];
    }
    return;
}

sub getOrMock {
    my $id = shift;
    return get($id) ||
	$Forks::Super::Job::Foreign::FOREIGN_JOBS{$id} ||
        Forks::Super::Job::Foreign->new($id);
}

{
    # bare bones partial emulation of Forks::Super::Job to represent
    # processes that were not initiated by Forks::Super. 
    # Used in Forks::Super::kill.

    # XXX - best practice to move this block to its own file
    package Forks::Super::Job::Foreign;          ## yes critic
    our %FOREIGN_JOBS = ();
    sub new {
	my ($class,$id) = @_;
	my $self = { pid => $id, real_pid => $id, state => 'FOREIGN' };
	$FOREIGN_JOBS{$id} = $self;
	return bless $self, $class;
    }
    sub is_deferred { return 0 }
    sub is_complete { return 0 }
    sub signal_pids { my $self = shift; return $self->{pid} }
}

# retrieve a job object for a pid or job name, if necessary
sub _resolve {
    if (!ref($_[0]) || !$_[0]->isa('Forks::Super::Job')) {
	my $job = get($_[0]);
	if (defined $job) {
	    return $_[0] = $job;
	}
	return $job;
    }
    return $_[0];
}

#
# count the number of active processes
#
sub count_active_processes {
    my $optional_pgid = shift;
    if (defined $optional_pgid) {
	return scalar grep {
	    $_->{state} eq 'ACTIVE'
		and $_->{pgid} == $optional_pgid } @ALL_JOBS;
    }
    return scalar grep { defined($_->{state})
			     && $_->{state} eq 'ACTIVE' } @ALL_JOBS;
}

sub count_alive_processes {
    my ($count_bg, $optional_pgid) = @_;
    my @alive = grep { $_->{state} eq 'ACTIVE' ||
			   $_->{state} eq 'COMPLETE' ||
			   $_->{state} eq 'DEFERRED' ||
			   $_->{state} eq 'LAUNCHING' || # rare
			   $_->{state} eq 'SUSPENDED' ||
			   $_->{state} eq 'SUSPENDED-DEFERRED' 
		   } @ALL_JOBS;
    if (!$count_bg) {
	@alive = grep { $_->{_is_bg} == 0 } @alive;
    }
    if (defined $optional_pgid) {
	@alive = grep { $_->{pgid} == $optional_pgid } @alive;
    }
    return scalar @alive;
}

sub count_queued_processes {
    my ($count_bg,$optional_pgid) = @_;
    my @deferred = grep { $_->{state} eq 'DEFERRED' ||
                          $_->{state} eq 'SUSPENDED-DEFERRED' } @ALL_JOBS;
    if (!$count_bg) {
        @deferred = grep { $_->{_is_bg} == 0 } @deferred;
    }
    if (defined $optional_pgid) {
        @deferred = grep { $_->{pgid} == $optional_pgid } @deferred;
    }
    return scalar @deferred;
}

#
# _reap should distinguish:
#
#    all alive jobs (ACTIVE+COMPLETE+SUSPENDED+DEFERRED+SUSPENDED-DEFERRED)
#    all active jobs (ACTIVE + COMPLETE + DEFERRED)
#    filtered alive jobs (by optional pgid)
#    filtered ACTIVE + COMPLETE + DEFERRED jobs
#
#    if  all_active==0  and  all_alive>0,  
#    then see Wait::WAIT_ACTION_ON_SUSPENDED_JOBS
#
sub count_processes {
    my ($count_bg, $optional_pgid) = @_;
    my @alive = grep { 
	$_->{state} ne 'REAPED' && 
	  $_->{state} ne 'NEW' &&
	  !$_->{daemon}
    } @ALL_JOBS;
    if (!$count_bg) {
	@alive = grep { $_->{_is_bg} == 0 } @alive;
    }
    my @active = grep { $_->{state} !~ /SUSPENDED/ } @alive;
    my @filtered_active = @active;
    my @filtered_alive = @alive;
    if (defined $optional_pgid) {
	@filtered_active = grep $_->{pgid} == $optional_pgid, @filtered_active;
	@filtered_alive = grep $_->{pgid} == $optional_pgid, @filtered_alive;
    }

    my @n = (scalar(@filtered_active), scalar(@alive), 
	     scalar(@active), scalar(@filtered_alive));

    if ($Forks::Super::Debug::DEBUG) {
	debug("count_processes(): @n");
        if ($n[0]) {
            debug('count_processes(): Filtered active: ',
                  $filtered_active[0]->toString());
        }
        if ($n[1]) {
            debug('count_processes(): Alive: ', $alive[0]->toShortString());
        }
        if ($n[2]) {
            debug("count_processes(): Active: @active");
        }
    }

    return @n;
}

sub count_active_processes_on_host {
    my $host = shift;
    my $n = scalar grep {
        $_->{remote} &&
            defined($_->{state}) &&
            $_->{state} eq 'ACTIVE' &&
            $_->{remote}{host} &&
            $_->{remote}{host} eq $host
    } @ALL_JOBS;
    return $n;
}

sub init_child {
    Forks::Super::Job::Ipc::init_child();
    return;
}

sub deinit_child {

    # global destruction does not always release any sync objects held
    # by the child. this is especially true on MSWin32.
    my $job = Forks::Super::Job->this;
    if ($job->{_sync}) {
      $job->{_sync}->releaseAll;
    }

    Forks::Super::Job::Ipc::deinit_child();

    return;
}

#
# get the current CPU load. May not be possible
# to do on all operating systems.
#
sub get_cpu_load {
    return Forks::Super::Job::OS::get_cpu_load();
}

sub dispose {
    my @jobs = @_;
    foreach my $job (@jobs) {

	my $pid = $job->{pid};
	my $real_pid = $job->{real_pid} || $pid;

	$job->close_fh('all');
	delete $Forks::Super::CHILD_STDIN{$pid};
	delete $Forks::Super::CHILD_STDIN{$real_pid};
	delete $Forks::Super::CHILD_STDOUT{$pid};
	delete $Forks::Super::CHILD_STDOUT{$real_pid};
	delete $Forks::Super::CHILD_STDERR{$pid};
	delete $Forks::Super::CHILD_STDERR{$real_pid};

	my @fattr = qw(f_in f_out f_err);
	if ($job->{fh_config}{stress}) {
	    push @fattr, "f_stress_$_" 
		for 1..$Forks::Super::Job::Ipc::_FILEHANDLES_PER_STRESSED_JOB;
	}

	foreach my $attr (@fattr) {
	    my $file = $job->{fh_config} && $job->{fh_config}{$attr};
	    if (defined($file) && -f $file) {
		$! = 0;
		if (unlink $file) {
		    delete $Forks::Super::Job::Ipc::IPC_FILES{$file};
		} elsif (&_INSIDE_END_QUEUE) {
		    warn "unlink failed for \"$file\": $! $^E\n";
		    warn "@{$Forks::Super::Job::Ipc::IPC_FILES{$file}}\n";
		}
	    }
	}

	my @k = grep { $ALL_JOBS{$_} eq $job } keys %ALL_JOBS;
	for my $j (@k) {
	    delete $ALL_JOBS{$j};
	}
	$job->{disposed} ||= time;

	# disposed jobs go to ARCHIVED_JOBS
	push @ARCHIVED_JOBS, $job;
    }
    @ALL_JOBS = grep { !$_->{disposed} } @ALL_JOBS;
    return;
}

sub PREFORK (&) {
    push @PREFORK, $_[0];
}

sub POSTFORK (&) {
    unshift @POSTFORK_PARENT, $_[0];
    unshift @POSTFORK_CHILD, $_[0];
}

sub POSTFORK_CHILD (&) {
    unshift @POSTFORK_CHILD, $_[0];
}

sub POSTFORK_PARENT (&) {
    unshift @POSTFORK_PARENT, $_[0];
}

#
# Print information about all known jobs to currently selected filehandle.
#
sub printAll {
    print "ALL JOBS\n";
    print "--------\n";
    foreach my $job
	(sort {$a->{pid} <=> $b->{pid} ||
		   $a->{created} <=> $b->{created}} @ALL_JOBS) {
	    
	    print $job->toString(), "\n";
	    print "----------------------------\n";
    }
    return;
}

sub get_win32_proc { return $WIN32_PROC; }
sub get_win32_proc_pid { return $WIN32_PROC_PID; }

1;

__END__

=head1 NAME

Forks::Super::Job - object representing a background task

=head1 VERSION

0.89

=head1 SYNOPSIS

    use Forks::Super;

    $pid = Forks::Super::fork( \%options );  # see Forks::Super
    $job = Forks::Super::Job::get($pid);
    $job = Forks::Super::Job::getByName($name);

    print "Process id of new job is $job\n";
    print "Current state is ", $job->state, "\n";
    waitpid $job, 0;
    print "Exit status was ", $job->status, "\n";

=head1 DESCRIPTION

Calls to C<Forks::Super::fork()> that successfully spawn a child process or
create a deferred job (see L<Forks::Super/"Deferred processes">) will cause 
a C<Forks::Super::Job> instance to be created to track the job's state. 
For many uses of C<fork()>, it will not be necessary to query the state of 
a background job. But access to these objects is provided for users who 
want to exercise even greater control over their use of background
processes.

Calls to C<Forks::Super::fork()> that fail (return C<undef> or small negative
numbers) generally do not cause a new C<Forks::Super::Job> instance
to be created.

=head1 ATTRIBUTES

Use the C<Forks::Super::Job::get> or C<Forks::Super::Job::getByName>
methods to obtain a Forks::Super::Job object for
examination. The C<Forks::Super::Job::get> method takes a process ID or
job ID as an input (a value that may have been returned from a previous
call to C<Forks::Super::fork()> and returns a reference to a 
C<Forks::Super::Job> object, or C<undef> if the process ID or job ID 
was not associated with any known Job object. The 
C<Forks::Super::Job::getByName> looks up job objects by the 
C<name> parameter that may have been passed
in the C<Forks::Super::fork()> call.

A C<Forks::Super::Job> object has many attributes, some of which may
be of interest to an end-user. Most of these should not be overwritten.

=over 4

=item pid

Process ID or job ID. For deferred processes, this will be a
unique large negative number (a job ID). For processes that
were not deferred, this valud is the process ID of the
child process that performed this job's task.

=item real_pid

The process ID of the child process that performed this job's
task. For deferred processes, this value is undefined until
the job is launched and the child process is spawned.

=item pgid

The process group ID of the child process. For deferred processes,
this value is undefined until the child process is spawned. It is
also undefined for systems that do not implement
L<getpgrp|perlfunc/"getpgrp">.

=item created

The time (since the epoch) at which the instance was created.

=item start

The time at which a child process was created for the job. This
value will be undefined until the child process is spawned.

=item end

The time at which the child process completed and the parent
process received a C<SIGCHLD> signal for the end of this process.
This value will be undefined until the child process is complete.

=item reaped

The time at which a job was reaped via a call to
C<Forks::Super::wait>, C<Forks::Super::waitpid>, 
or C<Forks::Super::waitall>. Will be undefined until 
the job is reaped.

=item state

A string value indicating the current state of the job.
Current allowable values are

=over 4

=item C<DEFERRED>

For jobs that are on the job queue and have not started yet.

=item C<ACTIVE>

For jobs that have started in a child process and are,
to the knowledge of the parent process, still running.

=item C<COMPLETE>

For jobs that have completed and caused the parent process to
receive a C<SIGCHLD> signal, but have not been reaped.

The difference between a C<COMPLETE> job and a C<REAPED> job
is whether the job's process identifier has been returned in
a call to C<Forks::Super::wait> or C<Forks::Super::waitpid>
(or implicitly returned in a call to C<Forks::Super::waitall>).
When the process gets reaped, the global variable C<$?>
(see L<perlvar/"$CHILD_ERROR">) will contain the exit status
of the process, until the next time a process is reaped.

=item C<REAPED>

For jobs that have been reaped by a call to C<Forks::Super::wait>,
C<Forks::Super::waitpid>, or C<Forks::Super::waitall>.

=item C<SUSPENDED>

The job has started but it has been suspended (with a C<SIGSTOP>
or other appropriate mechanism for your operating system) and
is not currently running. A suspended job will not consume CPU
resources but my tie up memory resources.

=item C<SUSPENDED-DEFERRED>

Job is in the job queue and has not started yet, and also
the job has been suspended. A job in the C<SUSPENDED-DEFERRED>
state can only move out of this state to the C<SUSPENDED> state
(with a C<SIGCONT> or a L<"resume"|resume> call).

=back

=item status

The exit status of a job. See L<CHILD_ERROR|perlvar/"CHILD_ERROR"> in
C<perlvar>. Will be undefined until the job is complete.

=item style

One of the strings C<natural>, C<cmd>, or C<sub>, indicating
whether the initial C<fork> call returned from the child process or whether
the child process was going to run a shell command or invoke a Perl
subroutine and then exit.

=item cmd

The shell command to run that was supplied in the C<fork> call.

=item sub

=item args

The name of or reference to CODE to run and the subroutine
arguments that were supplied in the C<fork> call.

=item _on_busy

The behavior of this job in the event that the system was
too "busy" to enable the job to launch. Will have one of
the string values C<block>, C<fail>, or C<queue>.

=item queue_priority

If this job was deferred, the relative priority of this
job.

=item can_launch

By default undefined, but could be a CODE reference
supplied in the C<fork()> call. If defined, it is the
code that runs when a job is ready to start to determine
whether the system is too busy or not.

=item depend_on

If defined, contains a list of process IDs and job IDs that
must B<complete> before this job will be allowed to start.

=item depend_start

If defined, contains a list of process IDs and job IDs that
must B<start> before this job will be allowed to start.

=item start_after

Indicates the earliest time (since the epoch) at
which this job may start.

=item expiration

Indicates the latest time that this job may be allowed to
run. Jobs that run past their expiration parameter will
be killed.

=item os_priority

Value supplied to the C<fork> call about desired
operating system priority for the job.

=item cpu_affinity

Value supplied to the C<fork> call about desired
CPU's for this process to prefer.

=item child_stdin

=item child_stdout

=item child_stderr

If the job has been configured for interprocess communication,
these attributes correspond to the handles for passing
standard input to the child process, and reading standard 
output and standard error from the child process, respectively.

Note that the standard read/write operations on these filehandles
can also be accomplished through the C<write_stdin>, C<read_stdout>,
and C<read_stderr> methods of this class. Since these methods
can adjust their behavior based on the type of IPC channel
(file, socket, or pipe) or other idiosyncracies of your operating
system (#@$%^&*! Windows), B<using these methods is preferred
to using the filehandles directly>.

The package level variables 
C<< L<$Forks::Super::CHILD_STDIN{$job}, $Forks::Super::CHILD_STDOUT{$job},
$Forks::Super::CHILD_STDERR{$job}|Forks::Super/"%25CHILD_STDxxx"> >>
are equivalent to these instance variables.

=back

=cut

=head1 FUNCTIONS

=head3 get

=over 4

=item C< $job = Forks::Super::Job::get($pidOrName) >

Looks up a C<Forks::Super::Job> object by a process ID/job ID
or L<name|Forks::Super/"name"> attribute and returns the
job object. Returns C<undef> for an unrecognized pid or
job name.

=back

=head3 getByName

=over 4

=item C< $job = Forks::Super::Job::getByName($name) >

=item C< @jobs = Forks::Super::Job::getByName($name) >

Looks up one or more C<Forks::Super::Job> objects by the
or L<name|Forks::Super/"name"> attribute. In list context,
returns all known jobs that have the given name. In scalar
context, returns a single job object or C<undef> if no job
has the specified name.

=back

=head3 count_active_processes

=over 4

=item C< $n = Forks::Super::Job::count_active_processes() >

Returns the current number of active background processes.
This includes only

=over 4

=item 1. First generation processes. Not the children and
grandchildren of child processes.

=item 2. Processes spawned by the C<Forks::Super> module,
and not processes that may have been created outside the
C<Forks::Super> framework, say, by an explicit call to
C<CORE::fork()>, a call like C<system("./myTask.sh &")>,
or a form of Perl's C<open> function that launches an
external command.

=back

=back

=head3 count_queued_processes

=over 4

=item C< $n = Forks::Super::Job::count_queued_processes() >

Returns the current number of inactive tasks in the job queue.

=back

=head1 METHODS

A C<Forks::Super::Job> object recognizes the following methods.
In general, these methods should only be used from the foreground
process (the process that spawned the background job).

=head3 waitpid

=over 4

=item C<< $job->wait( [$timeout] ) >>

=item C<< $job->waitpid( $flags [,$timeout] ) >>

Convenience method to wait until or test whether the specified
job has completed. See L<Forks::Super::waitpid|Forks::Super/"waitpid">.

The calls C<< $job->wait >> and C<< $job->wait() >> will block until a 
job has completed. But C<< $job->wait(0) >> will call C<wait> with
a timeout of zero seconds, so it will be equivalent to a call of
C<< waitpid $job, &WNOHANG >>.

=back

=head3 kill

=over 4

=item C<< $job->kill($signal) >>

Convenience method to send a signal to a background job.
See L<Forks::Super::kill|Forks::Super/"kill">.

=back

=head3 suspend

=over 4

=item C<< $job->suspend >>

When called on an active job, suspends the background process with 
C<SIGSTOP> or other mechanism appropriate for the operating system.
Returns a true value if it thinks it succeeded. Unlike a C<SIGSTOP>
signal, also operates on deferred jobs.

=back

=head3 resume

=over 4

=item C<< $job->resume >>

When called on a suspended job (see L<< suspend|"$job->suspend" >>,
above), resumes the background process with C<SIGCONT> or other mechanism 
appropriate for the operating system. Returns a true value if it thinks
it succeeded. Unlike a C<SIGCONT>, also operates on deferred jobs.

=back

=head3 terminate

=over 4

=item C<< $job->terminate >>

Terminates the job with signals or other mechanism appropriate
for the operating system. This method does not return a value.

=back

=head3 is_E<lt>stateE<gt>

=over 4

=item C<< $job->is_complete >>

Indicates whether the job is in the C<COMPLETE> or C<REAPED> state.
This method may not return accurate results for L<daemon|Forks::Super/daemon>
processes.

=item C<< $job->is_started >>

Indicates whether the job has started in a background process.
While return a false value while the job is still in a deferred state.
This method may not return accurate results for L<daemon|Forks::Super/daemon>
processes.

=item C<< $job->is_active >>

Indicates whether the specified job is currently running in
a background process.
This method may not return accurate results for L<daemon|Forks::Super/daemon>
processes.

=item C<< $job->is_suspended >>

Indicates whether the specified job has started but is currently
in a suspended state.
This method may not return accurate results for L<daemon|Forks::Super/daemon>
processes.

=back

=head3 write_stdin

=over 4

=item C<< $job->write_stdin(@msg) >>

Writes the specified message to the child process's standard input
stream, if the child process has been configured to receive
input from interprocess communication. Writing to a closed 
handle or writing to a process that is not configured for IPC
will result in a warning.

Using this method may be preferrable to calling C<print> with the
process's C<child_stdin> attribute, as the C<write_stdin> method
will take into account the type of IPC channel (file, socket, or
pipe) and may alter its behavior because of it. In a near future
release, it is hoped that the simple C<print> to the child stdin
filehandle will do the right thing, using tied filehandles and
other Perl magic.

=back

=head3 read_stdout

=head3 read_stderr

=over 4

=item C<< $line = $job->read_stdout() >>

=item C<< @lines = $job->read_stdout() >>

=item C<< $line = $job->read_stderr() >>

=item C<< @lines = $job->read_stderr() >>

In scalar context, attempts to read a single line, and in list
context, attempts to read all available lines from a child
process's standard output or standard error stream. 

If there is no available input, and if the C<Forks::Super> module
detects that the background job has completed (such that no more
input will be created), then the file handle will automatically be
closed. In scalar context, these methods will return C<undef>
if there is no input currently available on an inactive process,
and C<""> (empty string) if there is no input available on
an active process.

Reading from a closed handle, or calling these methods on a
process that has not been configured for interprocess
communication will result in a warning.

=back

=head3 getc_stdout

=head3 getc_stderr

=over 4

=item C<< $char = $job->getc_stdout() >>

=item C<< $char = $job->getc_stderr() >>

Attempts to read a single character from a child process's standard
output or standard error stream. See also L<"read_stdout"> and
L<"read_stderr">.

=back

=head3 close_fh

=over 4

=item C<< $job->close_fh([@handle_id]) >>

Closes IPC filehandles for the specified job. Optional input
is one or more values from the set C<stdin>, C<stdout>, C<stderr>,
and C<all> to specify which filehandles to close. If no
parameters are provided, the default behavior is to close all
configured file handles.

The C<close_fh> method may perform certain cleanup operations
that are specific to the type and settings of the specified
handle, so using this method is preferred to:

    # not as good as:  $job->close_fh('stdin','stderr')
    close $job->{child_stdin};
    close $Forks::Super::CHILD_STDERR{$job};

On most systems, open filehandles are a scarce resource and it
is a very good practice to close filehandles when the jobs that
created them are finished running and you are finished processing
input and output on those filehandles.

=back

=head3 state

=over 4

=item C<< $state = $job->state >>

Method to access the job's current state. See L</ATTRIBUTES>.

=back

=head3 status, exit_status

=over 4

=item C<< $status = $job->status >>

=item C<< $short_status = $job->exit_status >>

=item C<< ($exit_code,$signal,$coredump) = $job->exit_status >>

For completed jobs, the C<<status>> method returns the job's
exit status. See L</ATTRIBUTES>.

C<<exit_status>> is a convenience method for retrieving the
more intuitive exit value of a background task.

In scalar context,
it returns the exit status of the program (as returned by the
L<wait|perlfunc/wait> call), but I<shifted right by eight bits>,
so that a program that ends by calling C<exit(7)> will have an
C<exit_status> of 7, not 7 * 256. If the background process
exited on a signal and/or with a core dump, the result of this
function is a negative number that indicates the signal that
caused the background process failure.

In list context, C<<exit_status>> returns a three element array
of the exit value, the signal number, and an indicator of
whether the process dumped core.

C<<exit_status>> returns nothing if called on a job that has
not completed.

=back

=head3 toString

=over 4

=item C<< $job->toString() >>

=item C<< $job->toShortString() >>

Outputs a string description of the important features of the job.

=back

=head3 acquire

=over 4

=item C<< $success = $job->acquire($n) >>

=item C<< $success = $job->acquire($n, $timeout) >>

=item C<< $success = Forks::Super::Job->acquire($n) >>

=item C<< $success = Forks::Super::Job->acquire($n, $timeout) >>

Attempts to obtain access to a synchronization resource, for jobs
that were launched with the C<< L<"sync"|Forks::Super/"sync"> >> 
option. On success, including the case where the process is already
in possession of the specified resource, this method returns true.
It returns false if the resource cannot be acquired.

C<$n> must be nonnegative and less than the number of synchronization
objects created in the original C<< fork { sync => ... } >> call. 
If a C<$timeout> argument is included, the method will return false
if the synchronization resource cannot be obtained in the specified
number of seconds. If the C<$timeout> is not specified, the method
will block until the resource can be acquried.

The instance method syntax (C<< $job->acquire(...) >>)
is for use by a parent process, coordinating with the child process
(represented by C<< $job >>). The package indirect syntax
(C<< Forks::Super::Job->acquire(...) >>) is for use by the child process.

The C<acquire> and L<"release"> interface is portable, though
the underlying synchronization implementation may be very different
on different platforms.

=back

=head3 release

=over 4

=item C<< $success = $job->release($n) >>

=item C<< $success = Forks::Super::Job->release($n) >>

Releases a synchronization object, allowing another process
to acquire it (see L<"acquire">).
Returns true on success, false on failure (for example,
if the calling process did not already possess the specified resource).

Parent processes should use the instance method syntax
(C<< $job->release(...) >>) with the job object for the child process
it is trying to coordinate with. The package indirect syntax
(C<< Forks::Super::Job->release(...) >>) is for use by the child process.

=back

=head3 acquireAndRelease

=over 4

=item C<< $success = $job->acquireAndRelease($n) >>

=item C<< $success = $job->acquireAndRelease($n, $timeout) >>

=item C<< $success = Forks::Super::Job->acquireAndRelease($n) >>

=item C<< $success = Forks::Super::Job->acquireAndRelease($n, $timeout) >>

Roughly equivalent to

    $success = $job->acquire($n) && $job->release($n)

although it may be performed atomically, depending on the implementation.

=back

=head3 reuse

=over 4

=item C<< $pid = $job->reuse( \%new_opts ) >>

Creates a new background process by calling C<Forks::Super::fork>,
using all of the existing settings of the current C<Forks::Super::Job>
object. Additional options may be provided which will override
the original settings.

Use this method to launch multiple instances of identical or
similar jobs.

    $job = fork { child_fh => "all",
              callback => { start => sub { print "I started!" },
                            finish => sub { print "I finished!" } },
              sub => sub {
                 do_something();
                 do_something_else();
                 ...   # do 100 other things.
              },
              args => [ @the_args ], timeout => 15
    };

    # Crikey, I'm not typing all that in again.
    $job2 = $job->reuse { args => [ @new_args ], timeout => 30 };

=back

=head3 dispose

=over 4

=item C<< $job->dispose() >>

=item C<< Forks::Super::Job::dispose( @jobs ) >>

Called on one or more job objects to free up any resources used
by a job object. You may call this method on any job where you 
have finished extracting all of the information that you need
from the job. Or to put it another way, you should not call this
method on a job if you still wish to access any information 
about the job. After this method is invoked on a job, any
information such as run times, status, and unread input from 
interprocess communication handles will be lost.

This method will

=over 4

=item * close any open filehandles associated with the job

=item * attempt to remove temporary files used for interprocess
communication with the job

=item * erase all information about the job

=item * remove the job object from the C<@ALL_JOBS> and C<%ALL_JOBS> variables.

=back

=back

=cut

_head3 this

_over 4

Within a child process created by L<Forks::Super|Forks::Super>, 
the method C<< Forks::Super::Job->this >> or C<< Forks::Super::Job::this >>
will return the C<Forks::Super::Job> object that was used to create
the child process.

_back

=head1 VARIABLES

=head2 @ALL_JOBS, %ALL_JOBS

Any job object created by this module will be added to the list
C<@Forks::Super::Job::ALL_JOBS> and to the lookup table
C<%Forks::Super::Job::ALL_JOBS>. Within C<%ALL_JOBS>, a specific
job object can be accessed by its job id (the numerical value returned
from C<Forks::Super::fork()>), its real process id (once the
job has started), or its C<name> attribute, if one was passed to
the C<Forks::Super::fork()> call. This may be helpful for iterating
through all of the jobs your program has created.

    my ($longest_job, $longest_time) = (-1, -1);
    foreach $job (@Forks::Super::ALL_JOBS) {
        if ($job->is_complete) {
            $job_time = $job->{end} - $job->{start};
            if ($job_time > $longest_time) {
                ($longest_job, $longest_time) = ($job, $job_time);
            }
        }
    }
    print STDERR "The job that took the longest was $job: ${job_time}s\n";

Jobs that have been passed to the L<"dispose"> method are removed
from C<@ALL_JOBS> and C<%ALL_JOBS>.

=head1 OVERLOADING

A feature of the L<Forks::Super|Forks::Super> module is to make it
more convenient to access information about a background process by
returning a C<Forks::Super::Job> object instead of a simple
numerical process id. A C<Forks::Super::Job> object is 
L<overloaded|overload> to look and behave like a process ID (or job ID)
in any numerical context. It can be passed to functions like C<kill>
and C<waitpid> (even C<CORE::kill> and C<CORE::waitpid>) that
expect to receive a process ID.

    if ($job_or_pid != $another_pid) { ... }
    kill 'TERM', $job_or_pid;

But you can also access the attributes and methods of the
C<Forks::Super::Job> object.

    $job_or_pid->{real_pid}
    $job_or_pid->suspend

Since v0.51, the C<< <> >> iteration operator has been overloaded
for the C<Forks::Super::Job> package. It can be used to read
one line of output from a background job's standard output,
and to allow you to treat the background job object
syntactically like a readable filehandle.

    my $job = fork { cmd => $command };
    while (<$job>) {
        print "Output from $job: $_\n";
    }

Since v0.41, this feature is enabled by default.

Even when overloading is enabled, C<Forks::Super::fork()> 
still returns a simple scalar value of 0 to the child process
(when a value is returned).

=head1 SEE ALSO

L<Forks::Super|Forks::Super>.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
