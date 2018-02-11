package Forks::Super;

#                 "safe" signals ($] >= 5.7.3) are strongly recommended ...
# use 5.007003;   ... but no longer required

use Forks::Super::SysInfo;
use Forks::Super::Job;
use Forks::Super::Debug qw(:all);
use Forks::Super::Util qw(:all);
use Forks::Super::Config qw(:all);
use Forks::Super::Deferred qw(:all);
use Forks::Super::Wait qw(:all);
use Forks::Super::Tie::Enum;
use Forks::Super::Sigchld;
use Forks::Super::LazyEval;
use Signals::XSIG;
use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);

use POSIX ':sys_wait_h';
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
$| = 1;

our @EXPORT = qw(fork wait waitall waitpid BG_QX BG_EVAL
                 PREFORK POSTFORK POSTFORK_CHILD POSTFORK_PARENT);
my @export_ok_func = qw(isValidPid pause Time read_stdout read_stderr
			getc_stdout getc_stderr
                        bg_eval bg_qx  open2 open3);
my @export_ok_vars = qw(%CHILD_STDOUT %CHILD_STDERR %CHILD_STDIN);
our @EXPORT_OK = (@export_ok_func, @export_ok_vars);
our %EXPORT_TAGS =
    ( 'test'         => [ qw(isValidPid Time bg_eval bg_qx), @EXPORT ],
      'test_config'  => [ qw(isValidPid Time bg_eval bg_qx), @EXPORT ],
      'test_CA'      => [ qw(isValidPid Time bg_eval bg_qx), @EXPORT ],
      'test_emulate' => [ qw(isValidPid Time bg_eval bg_qx), @EXPORT ],
      'filehandles'  => [ @export_ok_vars, @EXPORT ],
      'vars'         => [ @export_ok_vars, @EXPORT ],
      'all'          => [ @EXPORT_OK, @EXPORT ] );
our $VERSION = '0.93';

our $SOCKET_READ_TIMEOUT = 0.05;  # seconds
our $MAIN_PID;
our $ON_BUSY;
our $MAX_PROC;
our $MAX_LOAD;
our $DEFAULT_MAX_PROC;
our $IPC_DIR;
our $DONT_CLEANUP;
our $CHILD_FORK_OK;
our $QUEUE_INTERRUPT;
our $PKG_INITIALIZED;
our $LAST_JOB;
our $LAST_JOB_ID;
our $ON_TOO_MANY_OPEN_FILEHANDLES;

{
    no warnings 'once';
    push @Devel::DumpTrace::EXCLUDE_PATTERN, '^Signals::XSIG';
}

sub import {
    my ($class,@args) = @_;
    my @tags;
    init_pkg();
    my $ipc_dir = '';
    for (my $i=0; $i<@args; $i++) {
	if (_import_common_vars($args[$i], $args[$i+1])) {
	    ++$i;
	} elsif ($args[$i] eq 'FH_DIR'
		 || $args[$i] eq 'IPC_DIR'
		 || uc $args[$i] eq 'CLEANSE') {

	    if ($args[$i] && uc $args[$i] eq 'CLEANSE') {
		Forks::Super::Job::Ipc::enable_cleanse_mode();
	    }
	    $ipc_dir = $args[++$i] || '';

	} else {
	    push @tags, $args[$i];
	    if ($args[$i] =~ /^:test/) {
		no warnings 'redefine';
                if (${^TAINT}) {
                    $ENV{PATH} = "";
                    delete $ENV{ENV};
                    use Config;
                    push @INC, ".";
                    $^X = $Config::Config{perlpath};

                    # since v0.53 (daemon code) we call Cwd::abs_path or 
                    # Cwd::getcwd and the default IPC directory is tainted
                    my $ipc_dir =
                        Forks::Super::Job::Ipc::_choose_dedicated_dirname();
                    if (! eval {$ipc_dir = Cwd::abs_path($ipc_dir)}) {
                        $ipc_dir = Cwd::getcwd() . "/" . $ipc_dir;
                    }
                    $ipc_dir =~ s{(.*)/.*$}{$1};
                    ($ipc_dir) = $ipc_dir =~ /(.*)/;
                    Forks::Super::Job::Ipc::set_ipc_dir($ipc_dir);
                }
		*Forks::Super::Job::carp = *Forks::Super::carp
		    = *Forks::Super::Job::Timeout::carp
		    = *Forks::Super::Job::Ipc::carp
		    = *Forks::Super::Tie::Enum::carp = sub { warn @_,"\n" };
		$Forks::Super::Config::IS_TEST = 1;
		if ($args[$i] =~ /config/) {
		    $Forks::Super::Config::IS_TEST_CONFIG = 1
		}
		if ($^O =~ /(open|net)bsd/
		    && Forks::Super::Job::OS::get_number_of_processors() == 1) {

		    # OpenBSD is not (as far as I can tell) very good at
		    # swapping processes in and out of its cores. When it
		    # needs to do it a lot, there is a lot of latency that
		    # buggers a lot of timing tests.
                    #
                    # v0.86: netbsd, too, has the troubles.
		    $ENV{TEST_LENIENT} = 1;
		}
		if ($args[$i] =~ /CA/) {
		    Forks::Super::Debug::use_Carp_Always();
		}
                if ($args[$i] =~ /emulate/) {
                    $Forks::Super::EMULATION_MODE = 1;
                }
		Forks::Super::Util->export_to_level(
		    1, 'Forks::Super::Util', 'okl');
		Forks::Super::Util->export_to_level(
		    1, 'Forks::Super::Util', 'DEVNULL');
	    }
	}
    }
    if (!$Forks::Super::Config::CONFIG_FILE && $ENV{FORKS_SUPER_CONFIG}) {
	_import_common_vars('CONFIG_FILE', $ENV{FORKS_SUPER_CONFIG});
    }

    Forks::Super->export_to_level(1, 'Forks::Super', @tags ? @tags : @EXPORT);

    _import_init_ipc_dir($ipc_dir);
    return;
}

sub _import_common_vars {
    my ($arg,$val) = @_;
    foreach my $pair ( [MAX_PROC => \$MAX_PROC],
		       [MAX_LOAD => \$MAX_LOAD],
		       [DEBUG    => \$DEBUG],
		       [ON_BUSY  => \$ON_BUSY],
		       [CHILD_FORK_OK => \$CHILD_FORK_OK],
		       [QUEUE_MONITOR_FREQ
			=> \$Forks::Super::Deferred::QUEUE_MONITOR_FREQ],
		       [QUEUE_INTERRUPT => \$QUEUE_INTERRUPT],
		       [ON_TOO_MANY_OPEN_FILEHANDLES
		        => \$ON_TOO_MANY_OPEN_FILEHANDLES] ) {

	if ($arg eq $pair->[0]) {
	    ${$pair->[1]} = $val;
	    return 1;
	}
    }
    if (uc $arg eq 'OVERLOAD') {
	_init_overload($val);
	return 1;
    }
    if (uc $arg eq 'ENABLE_DUMP') {
	Forks::Super::Debug::enable_dump($val);
	return 1;
    }
    if (uc($arg) eq 'CONFIG' || uc($arg) eq 'CONFIG_FILE') {
	Forks::Super::Config::load_config_file($val);
	return 1;
    }
    return;
}

sub _init_overload {
    my ($arg) = @_;
    if (defined $arg && $arg =~ /^\d+$/ && $arg == 0) {
	Forks::Super::Job::disable_overload();
    } else {
	Forks::Super::Job::enable_overload();
    }
    return;
}

sub _import_init_ipc_dir {
    my ($ipc_dir) = @_;
    if ($ENV{FH_DIR} || $ENV{IPC_DIR} || $ipc_dir) {
	# deprecated warning if  FH_DIR  is set but not  IPC_DIR
	if ($ENV{FH_DIR} && !$ENV{IPC_DIR}) {
	    carp "Environment variable 'FH_DIR' is deprecated. Use 'IPC_DIR'\n";
	}
	Forks::Super::Job::Ipc::set_ipc_dir($ENV{IPC_DIR}, 1)
	    || Forks::Super::Job::Ipc::set_ipc_dir($ENV{FH_DIR}, 1)
	    || Forks::Super::Job::Ipc::set_ipc_dir($ipc_dir, 1);
    }

    if (Forks::Super::Job::Ipc::is_cleanse_mode()) {
	Forks::Super::Job::Ipc::cleanse($ipc_dir || $IPC_DIR);
	exit;
    }
    return;
}

sub init_pkg {
    return if $PKG_INITIALIZED;
    $PKG_INITIALIZED++;

    Forks::Super::Debug::init();
    Forks::Super::Config::init();

    # $Forks::Super::SysInfo::MAX_FORK is the point at which your program
    # might crash from having too many forks.
    #
    # Another reasonable default when there are moderately CPU-intensive
    # background tasks is  ~2*$Forks::Super::SysInfo::NUM_PROCESSORS.

    # Default value for $MAX_PROC should be tied to system properties
    $DEFAULT_MAX_PROC = $Forks::Super::SysInfo::MAX_FORK - 1;
    if ($] < 5.007003) {
	$DEFAULT_MAX_PROC = $Forks::Super::SysInfo::NUM_PROCESSORS;
    }

    $MAX_PROC = $DEFAULT_MAX_PROC;
    $MAX_LOAD = -1;

    # OK for child process to call Forks::Super::fork()? Could be a bad idea
    $CHILD_FORK_OK = 0;

    # Disable cleanup of IPC files? Sometimes helpful for debugging.
    $DONT_CLEANUP = $ENV{FORKS_DONT_CLEANUP} || 0;

    # choose of $Forks::Super::Util::DEFAULT_PAUSE is a tradeoff between
    # accuracy/responsiveness and performance.
    #
    # Low values will make pause/waitpid calls very busy, consuming cpu cycles
    #
    # High values increase the average delay between the time one job
    # finishes and the next waiting job starts.
    $Forks::Super::Util::DEFAULT_PAUSE = 0.10; # seconds
    $Forks::Super::Util::DEFAULT_PAUSE_IO = 0.05;


    *handle_CHLD = *Forks::Super::Sigchld::handle_CHLD;

    Forks::Super::Util::set_productive_pause_code {
	Forks::Super::Deferred::check_queue();
	handle_CHLD(-1);
    };

    Forks::Super::Wait::set_productive_waitpid_code {
	if (&IS_WIN32) {
	    handle_CHLD(-1);
	}
    };

    tie $ON_BUSY, 'Forks::Super::Tie::Enum', qw(block fail queue);
    $ON_BUSY = 'block';

    tie $ON_TOO_MANY_OPEN_FILEHANDLES,
        'Forks::Super::Tie::Enum', qw(fail rescue);

    #$ON_TOO_MANY_OPEN_FILEHANDLES = 'fail';
    $ON_TOO_MANY_OPEN_FILEHANDLES = 'rescue'; # enabled v0.85

    tie $IPC_DIR, 'Forks::Super::Job::Ipc::Tie';

    Forks::Super::Deferred::init();
    $XSIG{CHLD}[-1] = \&Forks::Super::handle_CHLD;

    no warnings 'redefine','prototype';
    *Forks::Super::Impl::fork = \&Forks::Super::Impl::_fork;
    *Forks::Super::Impl::wait = \&Forks::Super::Wait::wait;
    *Forks::Super::Impl::waitpid = \&Forks::Super::Wait::waitpid;
    *Forks::Super::Impl::kill = \&Forks::Super::Impl::_kill;
    return;
}

# RT#124316: SIGCHLD handler has unexpected side-effects. When your program
# no longer needs to fork, you can call  Forks::Super->deinit_pkg
# to remove those side-effects.
sub deinit_pkg {
    untie $ON_BUSY;
    untie $ON_TOO_MANY_OPEN_FILEHANDLES;
    untie $IPC_DIR;
    Forks::Super::Deferred::deinit();
    &Forks::Super::Util::set_productive_pause_code(undef);
    &Forks::Super::Wait::set_productive_waitpid_code(undef);
    undef $XSIG{CHLD}[-1];
    if ($] < 5.016000) {
        no warnings 'redefine','prototype';
        *Forks::Super::Impl::fork = sub { CORE::fork };
        *Forks::Super::Impl::wait = sub { CORE::wait };
        *Forks::Super::Impl::waitpid = sub { CORE::waitpid($_[0],$_[1]) };
        *Forks::Super::Impl::kill = sub { CORE::kill(@_) };
    } else {
        no warnings 'redefine','prototype';
        *Forks::Super::Impl::fork = \&CORE::fork;
        *Forks::Super::Impl::wait = \&CORE::wait;
        *Forks::Super::Impl::waitpid = \&CORE::waitpid;
        *Forks::Super::Impl::kill = \&CORE::kill;
    }
    $PKG_INITIALIZED = 0;
    return;
}

sub Forks::Super::Impl::_fork {
    my @fork_args = @_;

    my %fork_argsx;

    my $opts;
    if (ref $fork_args[0] eq 'CODE') {
	$fork_argsx{"sub"} = shift @fork_args;
    } elsif (ref $fork_args[0] eq 'ARRAY') {
	$fork_argsx{"cmd"} = shift @fork_args;
        if (@{$fork_argsx{"cmd"}} == 1) {
            $fork_argsx{"cmd"} = $fork_argsx{"cmd"}[0];
        }
    }

    if (ref $fork_args[0] ne 'HASH') {
	$opts = { @fork_args, %fork_argsx };
    } else {
	$opts = $fork_args[0];
	$opts->{$_} = $fork_argsx{$_} for keys %fork_argsx;
    }

    $MAIN_PID ||= $$;                         # initialize on first use
    my $job = Forks::Super::Job->new($opts);

    $job->_preconfig;

    if (defined $job->{__test}) {
	return $job->{__test};
    }
    if (defined $job->{__error}) {
        carp $job->{__error};
        return undef;
    }

    if ($job->{debug}) {
	debug('fork(): ', $job->toString(), ' initialized.');
    }
    handle_CHLD(-1);   # <-- benefits  MSWin32

    while (!$job->can_launch) {
	if ($job->{debug}) {
	    debug("fork(): job can not launch. Behavior=$job->{_on_busy}");
	}

	if ($job->{_on_busy} eq 'FAIL') {
	    $job->run_callback('fail');
	    $job->{end} = Time::HiRes::time();
	    $job->{status} = -1;
	    $job->_mark_reaped;
	    # -1: failure: system is too busy to create a new job
	    # in $Forks::Super::ON_BUSY documentation
	    # XXX - document this better?
	    return -1;
	} elsif ($job->{_on_busy} eq 'QUEUE') {
	    $job->run_callback('queue');
	    $job->queue_job;
	    if ($Forks::Super::Job::OVERLOAD_ENABLED) {
		return $job;
	    } else {
		return $job->{pid};
	    }
	} else {
	    pause();
	}
    }

    if ($job->{debug}) {
	debug('fork: launch approved for job');
    }

    # on most systems, $SIG{CHLD}=undef means that the SIGCHLD handler
    # we have set up (see Forks::Super::Sigchld) will not get called
    # when this child exits. That would be bad, so check for that
    # just in case the caller said 'delete $SIG{CHLD}' out of ignorance
    # or malice.

    if (!defined $SIG{CHLD}) {
	# $SIG{CHLD}="\n" warns in openbsd:'SIGCHLD handler "\n" not defined'
	$SIG{CHLD} = sub {};
	# $SIG{CHLD} = 'IGNORE'; ?
    }
    return $job->launch;
}

# called from a child process immediately after it
# is created. Mostly this subroutine is about DE-initializing
# the child; removing all the global state that only the
# parent process needs to know about.
sub init_child {
    my $is_emulation = shift;

    if ($$ == $MAIN_PID && !$is_emulation) {
	carp 'Forks::Super::init_child() ',
	    "method called from main process!\n";
	return;
    }
    Forks::Super::Deferred::init_child();

    if (!$is_emulation) {
        @ALL_JOBS = ();

        # XXX - if $F::S::CHILD_FORK_OK > 0, when do we reset $XSIG{CHLD} ?
        $XSIG{CHLD} = [];
        $SIG{CHLD} = 'DEFAULT';

        Forks::Super::Config::init_child();
    }
    Forks::Super::Job::init_child();
    return;
}

#
# returns the exit status of the given process ID or job ID.
# return undef if we don't think the process is complete yet.
#
sub status {
    my $job = shift;
    if (!ref($job) || !$job->isa('Forks::Super::Job')) {
	$job = Forks::Super::Job::get($job) || return;
    }
    return $job->{status}; # might be undef
}

sub Forks::Super::state {
    my $job = shift;
    if (!ref($job) || !$job->isa('Forks::Super::Job')) {
	$job = Forks::Super::Job::get($job) || return;
    }
    return $job->{state};
}

sub write_stdin {
    my ($job, @msg) = @_;
    return Forks::Super::Job::write_stdin($job, @msg);
}

#
# called from the parent process,
# attempts to read a line from standard output file handle
# of the specified child.
#
# returns "" if the process is running but there is no
# output waiting on the file handle
#
# returns undef if the process has completed and there is
# no output waiting on the file handle
#
# performs trivial seek on file handle before reading.
# this will reduce performance but will always clear
# error condition and eof condition on handle
#
sub read_stdout {
    goto &Forks::Super::Job::read_stdout;
#    return Forks::Super::Job::read_stdout(@_);
}

#
# like read_stdout() but for stderr.
#
sub read_stderr {
    goto &Forks::Super::Job::read_stderr;
#   return Forks::Super::Job::read_stderr(@_);
}

sub getc_stdout {
    goto &Forks::Super::Job::getc_stdout;
#    return Forks::Super::Job::getc_stdout(@_);
}

sub getc_stderr {
    goto &Forks::Super::Job::getc_stderr;
#    return Forks::Super::Job::getc_stderr(@_);
}

sub close_fh {
    goto &Forks::Super::Job::close_fh;
#    return Forks::Super::Job::close_fh(@_);
}

######################################################################

sub kill_all {
    my ($signal) = @_;
    my @all_jobs;
    if ($signal eq 'CONT') {
	@all_jobs = grep { $_->is_suspended } @Forks::Super::ALL_JOBS;
    } elsif ($signal eq 'STOP') {
	@all_jobs = grep { $_->is_active || $_->{state} eq 'DEFERRED' }
	@Forks::Super::ALL_JOBS;
    } else {
	@all_jobs = grep { $_->is_active } @Forks::Super::ALL_JOBS;

	if (@all_jobs == 0) {
	    carp 'kill_all: no active jobs';
	    if ($DEBUG) {
		debug('all jobs:');
		for my $job (@Forks::Super::ALL_JOBS) {
		    debug('   ', $job->toShortString());
		}
	    }
	    return;
	}
    }
    if ($DEBUG) {
	debug("kill_all sending signal $signal to @all_jobs");
    }
    return Forks::Super::kill ($signal, @all_jobs);
}

sub Forks::Super::Impl::_kill {
    my ($signal, @jobs) = @_;
    my $kill_proc_group = $signal =~ s/^-//;

    my (@signalled, @terminated) = ();
    my $run_queue_needed = 0;

    # convert to canonical signal name.
    $signal = Forks::Super::Util::signal_name($signal);
    if ($signal eq '') {
	carp "Forks::Super::kill: invalid signal spec $_[0]\n";
	return;
    }

    if ($kill_proc_group) {
	@jobs = _get_killable_jobs_in_process_groups(@jobs);
	if (@jobs == 0) {
	    # XXX
	    return CORE::kill '-' . $signal, @_[1..$#_];
	}
    } else {
	@jobs = _get_killable_jobs(@jobs);
    }
    my @deferred_jobs = Forks::Super::Util::filter { $_->is_deferred } @jobs;
    if (@deferred_jobs > 0) {
	push @signalled, _signal_deferred_jobs($signal, @deferred_jobs);
    }

    my @pids = map { $_->signal_pids } @jobs;

    if (&IS_WIN32) {
	# Perl's  kill  doesn't always work or doesn't always DWIM
	# on Windows. It is usually better to signal MSWin32 processes
	# and pseudo-processes with Win32 API calls.

	my ($signalled, $termref)
	    = Forks::Super::Job::OS::Win32::signal_procs(
			$signal, $kill_proc_group, @pids);
	push @signalled, @$signalled;
	push @terminated, @$termref;
    } else {
	if ($DEBUG && @pids > 0) {
	    debug("Sending signal $signal to pids: ", join(' ',@pids));
	}
	if ($signal eq 'ZERO') {
	    $signal = 0;      # for Perl 5.6 compatibility
	}
	my $is_kill = Forks::Super::Util::is_kill_signal($signal);
	foreach my $pid (@pids) {
	    local $! = 0;
	    if (CORE::kill $signal, $pid) {
		push @signalled, $pid;
		push @terminated, $pid if $is_kill;
	    }
	    if ($!) {
		carp "Forks::Super::kill: $! $pid";
	    }
	}
    }

    _unreap(@terminated);
    if ($run_queue_needed) {
	Forks::Super::Deferred::check_queue();
    }
    if ($DEBUG) {
	local $" = ',';
	debug("kill: sent SIG$signal to {@signalled} from input {@jobs}");
    }
    return wantarray ? @signalled : scalar @signalled;
}

# v0.93: put another level of indirection between the entry points to
# the main functions and their implementations so that they may be
# reverted back to CORE:: if desired (see &deinit_pkg).
sub Forks::Super::fork { goto &Forks::Super::Impl::fork }
sub Forks::Super::kill { goto &Forks::Super::Impl::kill }
sub Forks::Super::wait { goto &Forks::Super::Impl::wait };
sub Forks::Super::waitpid { goto &Forks::Super::Impl::waitpid };

sub _get_killable_jobs {
    my (@jobs) = @_;
    # may be process ids or Forks::Super::Job objects

    # coerce to Forks::Super::Job
    @jobs = map {
	ref($_) && $_->isa('Forks::Super::Job')
	    ? $_ : Forks::Super::Job::getOrMock($_)
    } @jobs;

    return grep {
	!$_->is_complete &&
	    $_->{state} ne 'NEW' &&
	    $_->{state} ne 'LAUNCHING'
    } @jobs;
}

sub _get_killable_jobs_in_process_groups {
    my (@pgids) = @_;
    my @jobs = map {
	my $pgid = $_;
	grep { $_->{pgid} == $pgid } @Forks::Super::ALL_JOBS
    } @pgids;
    return _get_killable_jobs(@jobs);
}

sub _signal_deferred_jobs {
    my ($signal, @jobs) = @_;
    my @signalled = ();

    if (Forks::Super::Util::is_stop_signal($signal)) {
	$signal = 'STOP';
    } elsif ($signal eq 'THAW') {
	$signal = 'CONT';
    } elsif ($signal =~ /(CHLD|CLD|JVM|LWP|URG|WINCH)/) {
	$signal = 'ZERO';
    }

    foreach my $j (@jobs) {
	if (Forks::Super::Util::is_kill_signal($signal)) {
	    $j->_mark_complete;
	    $j->{status} = Forks::Super::Util::signal_number($signal) || -1;
	    $j->_mark_reaped;
	    push @signalled, $j;
	} elsif ($signal eq 'STOP' || $signal eq 'CONT' || $signal eq 'ZERO') {
	    push @signalled, $j;
	    if ($signal eq 'STOP') {
		$j->{state} = 'SUSPENDED-DEFERRED';
	    } elsif ($signal eq 'CONT') {
		$j->{state} = 'DEFERRED';
	    }
	} else {
	    carp_once [$signal],
	        "Received signal '$signal' on deferred job(s),",
	        " Ignoring.\n";
	}
    }
    return @signalled;
}

sub _unreap {
    my (@pids) = @_;
    my $old_status = $?;
    foreach my $pid (@pids) {
	if ($pid == Forks::Super::Wait::waitpid $pid, 0, 1.0) {
	    my $j = Forks::Super::Job::get($pid);
	    $j->{state} = 'COMPLETE';
	    if (delete $j->{reaped}) {
		if ($DEBUG) {
		    debug("_unreap: unreaped $pid");
		}
	    }
	    $? = $old_status;
	}
    }
    return;
}

#############################################################################

# convenience methods

sub open2 {
    my (@cmd) = @_;
    my $options = {};
    if (ref $cmd[-1] eq 'HASH') {
	$options = pop @cmd;
    }
    $options->{'cmd'} = @cmd > 1 ? \@cmd : $cmd[0];
    $options->{'child_fh'} = 'in,out';

    my $pid = Forks::Super::fork( $options );
    if (!defined $pid) {
	return;
    }
    my $job = Forks::Super::Job::get($pid);

    return ($job->{child_stdin},
	    $job->{child_stdout},
	    $pid, $job);
}

sub open3 {
    my (@cmd) = @_;
    my $options = {};
    if (ref $cmd[-1] eq 'HASH') {
	$options = pop @cmd;
    }
    $options->{'cmd'} = @cmd > 1 ? \@cmd : $cmd[0];
    $options->{'child_fh'} = 'in,out,err';

    my $pid = Forks::Super::fork( $options );
    if (!defined $pid) {
	return;
    }

    my $job = Forks::Super::Job::get($pid);
    return ($job->{child_stdin},
	    $job->{child_stdout},
	    $job->{child_stderr},
	    $pid, $job);
}

###################################################################

1;

__END__

------------------------------------------------------------------------------

=head1 NAME

Forks::Super - extensions and convenience methods to manage background processes

=head1 VERSION

Version 0.93

=head1 SYNOPSIS

    use Forks::Super;
    use Forks::Super MAX_PROC => 5, DEBUG => 1;

    # --- familiar use - parent returns PID>0, child returns zero
    $pid = fork();
    die "fork failed" unless defined $pid;
    if ($pid > 0) {
        # parent code
    } else {
        # child code
    }

    # --- wait for a child process to finish
    $w = wait;                    # blocking wait on any child, child exit status in $?
    $w = waitpid $pid,0;          # blocking wait on specific child
    $w = waitpid $pid,WNOHANG;    # non-blocking, use with POSIX ':sys_wait_h'
    $w = waitpid 0,$flag;         # wait on any process in current process group
    waitall;                      # block until all children are finished

    # -------------- helpful extensions ---------------------
    # fork directly to a shell command. Child doesn't return.
    $pid = fork { cmd => "./myScript 17 24 $n" };
    $pid = fork { exec => [ "/bin/prog" , $file, "-x", 13 ] };
    $pid = fork [ "./myScript", 17, 24, $n ];    # new syntax in v0.72

    # --- fork directly to a Perl subroutine. Child doesn't return.
    $pid = fork { sub => $methodNameOrRef , args => [ @methodArguments ] };
    $pid = fork { sub => \&subroutine, args => [ @args ] };
    $pid = fork { sub => sub { "anonymous sub" }, args => [ @args ] );
    $pid = fork sub { CODE }, %other_options;    # new syntax in v0.72

    # --- impose a time limit on the child process
    $pid = fork { cmd => $cmd, timeout => 30 };  # kill child if not done in 30s
    $pid = fork { sub => $subRef , args => [ @args ],
                  expiration => 1260000000 };    # complete 8am Dec 5, 2009 UTC
    # --- wait and waitpid support timeouts, too
    $pid = wait 3.0;
    print "No child reaped in 5s"
            if waitpid 0, 0, 5.0 == &Forks::Super::Wait::TIMEOUT;

    # --- run a child process starting from a different directory
    $pid = fork { dir => "some/other/directory",
                  cmd => ["command", "--that", "--runs=somewhere", "else"] };

    # --- obtain standard file handles for the child process
    $pid = fork { child_fh => "in,out,err,:utf8" };
    if ($pid == 0) {      # child process
       sleep 1;
       $x = <STDIN>; # read from parent's $pid->{child_stdin} (output handle)
       print rand() > 0.5 ? "Yes\n" : "No\n" if $x eq "Clean your room\n";
       sleep 2;
       $i_can_haz_ice_cream = <STDIN>;
       if ($i_can_haz_ice_cream !~ /you can have ice cream/ && rand() < 0.5) {
          print STDERR '@#$&#$*&#$*&',"\n";
       }
       exit 0;
    } # else parent process
    $child_stdin = $pid->{child_stdin};
    $child_stdin = $Forks::Super::CHILD_STDIN{$pid}; # alternate, deprecated
    print $child_stdin "Clean your room\n";
    sleep 2;
    $child_stdout = $pid->{child_stdout};
    # -or- $child_stdout = $Forks::Super::CHILD_STDOUT{$pid}; # deprecated
    $child_response = <$child_stdout>; # -or-: Forks::Super::read_stdout($pid);
    if ($child_response eq "Yes\n") {
       print $child_stdin "Good boy. You can have ice cream.\n";
    } else {
       print $child_stdin "Bad boy. No ice cream for you.\n";
       sleep 2;
       $child_err = Forks::Super::read_stderr($pid);
       # -or-  $child_err = $pid->read_stderr();
       # -or-  $child_err = readline($pid->{child_stderr});
       print $child_stdin "And no back talking!\n" if $child_err;
    }

    # --- retrieve variable values from a child process
    $pid1 = fork { share => [ \$scalar, \@list ], sub => \&method };
    $pid2 = fork { share => [ \@list, \%hash ], sub => \&someOtherMethod };
    waitpid $pid1, 0;
    waitpid $pid2, 0;
    # now $scalar is set to value in 1st job, @list has values from both jobs,
    # and %hash has values from 2nd job

    # ---------- manage jobs and system resources ---------------
    # --- run 100 tasks but fork blocks while there are already 5 active jobs
    $Forks::Super::MAX_PROC = 5;
    $Forks::Super::ON_BUSY = 'block';
    for ($i=0; $i<100; $i++) {
       $pid = fork { cmd => $task[$i] };
    }

    # --- jobs fail (without blocking) if the system is too busy
    $Forks::Super::MAX_LOAD = 2.0;
    $Forks::Super::ON_BUSY = 'fail';
    $pid = fork { cmd => $task };
    if    ($pid > 0) { print "'$task' is running\n" }
    elsif ($pid < 0) { print "current CPU load > 2.0: didn't start '$task'\n" }

    # $Forks::Super::MAX_PROC setting can be overridden.
    # Start job immediately if < 3 jobs running
    $pid = fork { sub => 'MyModule::MyMethod', args => [ @b ], max_proc => 3 };

    # --- try to fork no matter how busy the system is
    $pid = fork { sub => \&MyMethod, force => 1 }

    # when system is busy, queue jobs. When system is not busy,
    #     some jobs on the queue will start.
    # if job is queued, return value from fork() is a very negative number
    $Forks::Super::ON_BUSY = 'queue';
    $pid = fork { cmd => $command };
    $pid = fork { cmd => $useless_command, queue_priority => -5 };
    $pid = fork { cmd => $important_command, queue_priority => 5 };
    $pid = fork { cmd => $future_job, delay => 20 };  # queue job for at least 20s

    # --- assign descriptive names to tasks
    $pid1 = fork { cmd => $command, name => "my task" };
    $pid2 = waitpid "my task", 0;
    $num_signalled = Forks::Super::kill 'TERM', "my task";

    $pid1 = fork { cmd => $command1, name => 'task 1' };
    $pid2 = fork { cmd => $command2, name => 'task 2' };
    $pid = waitpid -1, 0;
    print "Task that just finished was $pid->{name}\n"; # task 1 or task 2

    # --- run callbacks at various points of job life-cycle
    $pid = fork { cmd => $command, callback => \&on_complete };
    $pid = fork { sub => $sub, args => [ @args ],
                  callback => { start => 'on_start', finish => \&on_complete,
                                queue => sub { print "Job $_[1] queued\n" } } };

    # --- set up dependency relationships
    $pid1 = fork { cmd => $job1 };
    $pid2 = fork { depend_on => $pid1,
                   cmd => $job2 };          # queue until job 1 is complete
    $pid3 = fork { ... };
    $pid4 = fork { depend_start => [$pid2,$pid3],
                   cmd => $job4 };          # queue until jobs 2,3 have started
    $pid5 = fork { cmd => $job5, name => "group C" };
    $pid6 = fork { cmd => $job6, name => "group C" };
    $pid7 = fork { depend_on => "group C",
                   cmd => $job7 };          # wait for jobs 5 & 6 to complete

    # --- manage OS settings on jobs -- may not be available on all systems
    $pid1 = fork { os_priority => 10 };   # like nice(1) on Un*x
    $pid2 = fork { cpu_affinity => 0x5 }; # background task to prefer CPUs #0,2

    # --- job information
    $state = Forks::Super::state($pid);   # ACTIVE | DEFERRED | COMPLETE | REAPED
    $status = Forks::Super::status($pid); # exit status ($?) for completed jobs

    # --- return value from fork is object that just looks like a process id
    # --- see Forks::Super::Job
    $job = fork { ... };
    $state = $job->{state};
    if ($job->is_complete) {
        $status = $job->{status};
    }

    # --- evaluate long running expressions in the background
    $result = bg_eval { a_long_running_calculation() };
    # sometime later ...
    print "Result was $result\n";

    $result = bg_qx( "./long_running_command" );
    # ... do something else for a while and when you need the output ...
    print "output of long running command was: $result\n";

    # if you need bg_eval or bg_qx functionality in list context ...
    tie %result, BG_EVAL, sub { long_running_calc_that_returns_hash() };
    tie @output, BG_QX, "./long_running_cmd";


    # --- convenience methods, compare to IPC::Open2, IPC::Open3
    my ($fh_in, $fh_out, $pid, $job) = Forks::Super::open2(@command);
    my ($fh_in, $fh_out, $fh_err, $pid, $job)
            = Forks::Super::open3(@command, { timeout => 60 });

    # --- run a background process as a *daemon*
    $job = fork { cmd => $cmd, daemon => 1 };

=head1 DESCRIPTION

This package provides new definitions for the Perl functions
L<fork|perlfunc/"fork">, L<wait|perlfunc/"wait">, and
L<waitpid|perlfunc/"waitpid"> with richer functionality.
The new features are designed to make it more convenient to
spawn background processes and more convenient to manage them
to get the most out of your system's resources.

=head1 fork

=head1 C<$pid = fork( \%options )>

Attempts to spawn a new process. On success, it returns a
L<Forks::Super::Job|Forks::Super::Job> object with information
about the background
task to the calling process. This object is overloaded so that
in any numeric or string context, it will behave like the process
id of the new process, and let's C<Forks::Super::fork> be used
as a drop-in replacement for the builtin Perl C<fork> call.

With no arguments, it behaves the same as the Perl
L<< fork()|perlfunc/"fork" >> system call:

=over 4

=item *

creating a new process running the same program at the same execution point

=item *

returning to the parent an object which behaves like the
process id (PID) of the child process in any boolean, numeric,
or string context (On Windows, this is a I<pseudo-process ID>).

=item *

returning 0 to the child process

=item *

returning C<undef> if the fork call was unsuccessful

=back

=head2 Options for instructing the child process

The C<fork> call supports three options, L<"cmd">, L<"exec">,
and L<"sub"> (or C<sub>/C<args>)
that will instruct the child process to carry out a specific task.
Using any of these options causes the child process not to
return from the C<fork> call.

=head3 cmd

=over 4

=item C<< $child_pid = fork { cmd => $shell_command } >>

=item C<< $child_pid = fork { cmd => \@shell_command } >>

On successful launch of the child process, runs the specified
shell command in the child process with the Perl
L<system()|perlfunc/"system_LIST__"> function. When the system call
is complete, the child process exits with the same exit status
that was returned by the system call.

Returns the PID of the child process to
the parent process. Does not return from the child process, so you
do not need to check the fork() return value to determine whether
code is executing in the parent or child process.

See L<"Alternate fork syntax">, below, for an alternate way of
specifying a command to run in a background process.

=back

=head3 exec

=over 4

=item C<< $child_pid = fork { exec => $shell_command } >>

=item C<< $child_pid = fork { exec => \@shell_command } >>

Like the L<"cmd"> option, but the background process launches the
shell command with L<exec|perlfunc/"exec"> instead of with
L<system|perlfunc/"system_LIST__">.

Using C<exec> instead of C<cmd> will usually spawn one fewer process.
Prior to v0.55, the L<"timeout"> and L<"expiration"> options
(see L<"Options for simple job management">) could not be used
with the C<exec> option, but that incompatibility has been fixed.

=back

=head3 sub

=over 4

=item C<< $child_pid = fork { sub => $subroutineName [, args => \@args ] } >>

=item C<< $child_pid = fork { sub => \&subroutineReference [, args => \@args ] } >>

=item C<< $child_pid = fork { sub => sub { ... code ... } [, args => \@args ] } >>

On successful launch of the child process, C<fork> invokes the
specified Perl subroutine with the specified set of method arguments
(if provided) in the child process.
If the subroutine completes normally, the child
process exits with a status of zero. If the subroutine exits
abnormally (i.e., if it C<die>'s, or if the subroutine invokes
C<exit> with a non-zero argument), the child process exits with
non-zero status.

Returns the PID of the child process to the parent process.
Does not return from the child process, so you do not need to
check the fork() return value to determine whether code is running
in the parent or child process.

See L<"Alternate fork syntax">, below, for an alternate way of
specifying a subroutine to run in the child process.

=back

If neither the L<"cmd">, L<"exec">,
nor the L<"sub"> option is provided
to the fork call, then the fork() call behaves like a standard
Perl C<fork()> call, returning the child PID to the parent and also
returning zero to a new child process.

=head2 Options for simple job management

=head3 timeout

=head3 expiration

=over 4

=item C<< fork { timeout => $delay_in_seconds } >>

=item C<< fork { expiration => $timestamp_in_seconds_since_epoch_time } >>

Puts a deadline on the child process and causes the child to C<die>
if it has not completed by the deadline. With the C<timeout> option,
you specify that the child process should not survive longer than the
specified number of seconds. With C<expiration>, you are specifying
an epoch time (like the one returned by the L<time|perlfunc/"time__">
function) as the child process's deadline.

If the L<setpgrp()|perlfunc/"setpgrp"> system call is implemented
on your system, then this module will try to reset the process group
ID of the child process. On timeout, the module will attempt to kill
off all subprocesses of the expiring child process.

If the deadline is some time in the past (if the timeout is
not positive, or the expiration is earlier than the current time),
then the child process will die immediately after it is created.

This feature I<usually> uses Perl's L<alarm|perlfunc/"alarm"> call
and installs its own handler for C<SIGALRM>, but an alternate
L<"poor mans alarm"|http://stackoverflow.com/a/8452732/168657>
is available. If you wish to use the C<timeout> or C<expiration>
feature with a child L<sub|"sub"> that also uses
C<alarm>/C<SIGALRM>, or on a system that has issues with C<alarm>,
you can also pass the option C<< use_alternate_alarm => 1 >>
to force C<Forks::Super> to use the alternate alarm.

If you have installed the
L<DateTime::Format::Natural|DateTime::Format::Natural> module,
then you may also specify the timeout and expiration options using
natural language:

    $pid = fork { timeout => "in 5 minutes", sub => ... };

    $pid = fork { expiration => "next Wednesday", cmd => $long_running_cmd };

=back

=head3 dir

=over 4

=item C<< fork { dir => $directory } >>

=item C<< fork { chdir => $directory } >>

Causes the child process to be run from a different directory
than the parent.

If the specified directory does not exist or if the C<chdir>
call fails (e.g, if the caller does not have permission to
change to the directory), then the child process immediately
exits with a non-zero status.

C<chdir> and C<dir> are synonyms.

=back

=head3 env

=over 4

=item C<< fork { env => \%values } >>

Passes additional environment variable settings to a child process.

=back

=head3 umask

=over 4

=item C<< fork { umask => $mask } >>

Sets the "umask" of the background process to specify the default
permissions of files and directories created by the background process.
See L<perlfunc/umask> and L<umask(1)|umask(1)>.

As it is with the Perl builtin function, the C<$mask> argument is a
number, usually given in octal form, but it is not a string of octal
digits. So

    fork { umask => "0775" , ... }

will probably not do what you want. Instead, use one of

    fork { umask => 0775, ... }
    fork { umask => 509, ... }     # 509 == 0775
    fork { umask => oct "0775", ... }

=back

=head3 delay

=head3 start_after

=over 4

=item C<< fork { delay => $delay_in_seconds } >>

=item C<< fork { start_after => $timestamp_in_epoch_time } >>

Causes the child process to be spawned at some time in the future.
The return value from a C<fork> call that uses these features
will not be a process id, but it will be a very negative number
called a job ID. See the section on L<"Deferred processes">
for information on what to do with a job ID.

A deferred job will start B<no earlier> than its appointed time
in the future. Depending on what circumstances the queued jobs
are examined, B<the actual start time of the job could be significantly
later than the appointed time>.

A job may have both a minimum start time (through C<delay> or
C<start_after> options) and a maximum end time (through
L<"timeout"> and L<"expiration">).
Jobs with inconsistent times
(end time is not later than start time) will be killed of
as soon as they are created.

As with the L<"timeout"> and L<"expiration"> options, the
C<delay> and C<start_after> options can be expressed in
natural language if you have installed the
L<DateTime::Format::Natural|DateTime::Format::Natural> module.

    $pid = fork { start_after => "12:25pm tomorrow",  sub => ... };

    $pid = fork { delay => "in 7 minutes", cmd => ... };

=back

=head3 child_fh

=over 4

=item C<< $pid = fork { child_fh => $fh_spec } >>

=item C<< $pid = fork { child_fh => [ @fh_spec ] } >>

Launches a child process and makes the child process's
C<STDIN>, C<STDOUT>, and/or C<STDERR> file handles available to
the parent process in the instance members
C<< $pid->{child_stdin} >>, C<< $pid->{child_stdout} >>, and
C<< $pid->{child_stderr} >>, or in the package variables
C<$Forks::Super::CHILD_STDIN{$pid}>,
C<$Forks::Super::CHILD_STDOUT{$pid}>, and/or
C<$Forks::Super::CHILD_STDERR{$pid}>. C<$pid> is the
return value from the fork call. This feature makes it possible,
even convenient, for a parent process to communicate with a
child, as this contrived example shows.

    $pid = fork { sub => \&pig_latinize, timeout => 10,
                  child_fh => "all" };

    # in the parent, $Forks::Super::CHILD_STDIN{$pid} ($pid->{child_stdout})
    # is an **output** file handle

    print {$pid->{child_stdin}} "The blue jay flew away in May\n";

    sleep 2; # give child time to start up and get ready for input

    # and $Forks::Super::CHILD_STDOUT{$pid} ($pid->{child_stdout}) and
    # $Forks::Super::CHILD_STDERR{$pid} ($pid->{child_stderr}
    # are **input** handles.

    $result = < { $pid->{child_stdout} } >;
    print "Pig Latin translator says: ",
            "$result\n"; # ==> eThay ueblay ayjay ewflay awayay inay ayMay\n
    @errors = readline( $pid->{child_stderr} );
    print "Pig Latin translator complains: @errors\n" if @errors > 0;

    sub pig_latinize {
      for (;;) {
        while (<STDIN>) {
	  foreach my $word (split /\s+/) {
            if ($word =~ /^qu/i) {
              print substr($word,2) . substr($word,0,2) . "ay";  # STDOUT
            } elsif ($word =~ /^([b-df-hj-np-tv-z][b-df-hj-np-tv-xz]*)/i) {
              my $prefix = $1;
              $word =~ s/[b-df-hj-np-tv-z][b-df-hj-np-tv-xz]*//i;
	      print $word . $prefix . "ay";
	    } elsif ($word =~ /^[aeiou]/i) {
              print $word . "ay";
            } else {
	      print STDERR "Didn't recognize this word: $word\n";
            }
            print " ";
          }
	  print "\n";
        }
      }
    }

The set of file handles to make available are specified either as
a non-alphanumeric delimited string, or list reference. This spec
may contain one or more of the words:

    in
    out
    err
    join
    all
    socket
    pipe
    block
    :<layer>

C<in>, C<out>, and C<err> mean that the child's STDIN, STDOUT,
and STDERR, respectively, will be available in the parent process
through the file handles in C<$Forks::Super::CHILD_STDIN{$pid}>,
C<$Forks::Super::CHILD_STDOUT{$pid}>,
and C<$Forks::Super::CHILD_STDERR{$pid}>, where C<$pid> is the
child's process ID. C<all> is a convenient way to specify
C<in>, C<out>, and C<err>. C<join> specifies that the child's
STDOUT and STDERR will be returned through the same file handle,
specified as both C<$Forks::Super::CHILD_STDOUT{$pid}> and
C<$Forks::Super::CHILD_STDERR{$pid}>.

If C<socket> is specified, then local sockets will be used to
pass between parent and child instead of temporary files.

If C<pipe> is specified, then local pipes will be used to
pass between parent and child instead of temporary files.

If C<block> is specified, then the read end of each
file handle will block until input is available.
Note that this can lead to deadlock unless the I/O of the
write end of the file handle is carefully managed.

C<< :<layer> >> may be any valid L<PerlIO|PerlIO> I/O layer,
such as C<:crlf>, C<:utf8>, L<< C<:gzip>|PerlIO::gzip >>, etc.
Some I/O layers may not work well with socket and pipe IPC.
And of course they will not work well with Perl vE<lt>=5.6
and its poorer support for I/O layers.

See also: L<"write_stdin">, L<"read_stdout">, L<"read_stderr">.

=cut

#--------------------------------------------------
This syntax can be extended and cleaned up in 1.0.
#--------------------------------------------------

=back

=head4 Socket handles vs. file handles vs. pipes

Here are some things to keep in mind when deciding whether to
use sockets, pipes, or regular files for parent-child IPC:

=over 4

=item *

Using regular files is implemented everywhere and is the
most portable and robust scheme for IPC. Sockets and pipes
are best suited for Unix-like systems, and may have
limitations on non-Unix systems.

=item *

Sockets and pipes have a performance advantage, especially at
child process start-up.

=item *

Temporary files use disk space; sockets and pipes use memory.
One of these might be a relatively scarce resource on your
system.

=item *

Socket input buffers have limited capacity. Write operations
can block if the socket reader is not vigilant. Pipe input
buffers are often even smaller (as small as 512 bytes on
some modern systems).

I<The> C<Forks/Super/SysInfo.pm> I<file that is created
at build time will have information about the socket and
pipe capacity of your system, if you are interested.>

=item *

On Windows, sockets and pipes are blocking, and care must be taken
to prevent your script from reading on an empty socket. In
addition, sockets to the input/output streams of external
programs on Windows is a little flaky, so you are almost always
better off using file handles for IPC if your Windows program
needs external commands (the C<cmd> or C<exec> options to
C<Forks::Super::fork>).

=back

=head4 Socket and file handle gotchas

Some things to keep in mind when using socket or file handles
to communicate with a child process.

=over 4

=item *

care should be taken before calling L<close|perlfunc/"close">
on a socket handle.
The same socket handle can be used for both reading and writing.
Don't close a handle when you are only done with one half of the
socket operations.

In general, the C<Forks::Super> module knows whether a file handle
is associated with a file, a socket, or a pipe,
and the L<"close_fh">
function provides a safe way to close the file handles associated
with a background task:

    Forks::Super::close_fh($pid);          # close all STDxxx handles
    Forks::Super::close_fh($pid, 'stdin'); # close STDIN only
    Forks::Super::close_fh($pid, 'stdout', 'stderr'); # don't close STDIN
    # --- OO interface
    $pid->close_fh;
    $pid->close_fh('stdin');
    $pid->close_fh('stdout','stderr');

=item *

The test C<Forks::Super::Util::is_socket($handle)> can determine
whether C<$handle> is a socket handle or a regular file handle.
The test C<Forks::Super::Util::is_pipe($handle)>
can determine whether C<$handle> is reading from or writing to a pipe.

=cut

#-----------------------------------------------------
XXX This is the only documentation for the
Forks::Super::Util::is_socket/is_pipe functions.
#-----------------------------------------------------

=item *

IPC in this module is asynchronous. In general, you
cannot tell whether the parent/child has written anything to
be read in the child/parent. So getting C<undef> when reading
from the C<< $pid->{child_stdout} >> handle does not
necessarily mean that the child has finished (or even started!)
writing to its STDOUT. Check out the C<seek HANDLE,0,1> trick
in L<the perlfunc documentation for seek|perlfunc/seek>
about reading from a handle after you have
already read past the end. You may find it useful for your
parent and child processes to follow some convention (for example,
a special token like C<"__EOF__">) to denote the end of input.

=item *

There is a limit to how many file handles your process can have
open at one time. Sometimes that limit is quite small (I'm looking
at B<you>, default configuration of Solaris!) If your program creates
many child processes and you use file handles or socket handles for
interprocess communication with them, you could run out of
file handles. When this happens, you will see warning messages like
C<Too many open files while opening ...> or sometimes a cryptic
C<Can't locate Scalar/Util.pm in @INC (@INC contains: ...)> message.

When you are finished with I/O operations on your job, you should
call

    Forks::Super::close_fh($pid)

or

    $pid->dispose

to close the I/O handles and make them available for other processes.
If you set
L<"$Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES"|"ON_TOO_MANY_OPEN_FILEHANDLES">
 to the value

    $Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES = 'rescue';

    (also)

    use Forks::Super ON_TOO_MANY_OPEN_FILEHANDLES => 'rescue';

then C<Forks::Super> will try to determine when your program is
approaching the limit of open file handles, and will try to
determine which file handles can be safely closed.

=back

=head3 stdin

=over 4

=item C<< fork { stdin => $input } >>

Provides the data in C<$input> as the child process's standard input.
Equivalent to, but a little more efficient than:

    $pid = fork { child_fh => "in", sub => sub { ... } };
    Forks::Super::write_stdin($pid, $input);

C<$input> may either be a scalar, a reference to a scalar, or
a reference to an array.

=back

=head3 stdout

=head3 stderr

=over 4

=item C<< fork { stdout => \$output } >>

=item C<< fork { stderr => \$errput } >>

On completion of the background process, loads the standard output
and standard error of the child process into the given scalar
references. If you do not need to use the child's output while
the child is running, it could be more convenient to use this
construction than calling L<Forks::Super::read_stdout($pid)|/"read_stdout">
(or C<< readline($pid->{child_stdout}) >>) to obtain
the child's output.

=back

=head3 retries

=over 4

=item C<< fork { retries => $max_retries } >>

If the underlying system C<fork> call fails (returns
C<undef>), pause for a short time and retry up to
C<$max_retries> times.

This feature is probably not that useful. A failed
C<fork> call usually indicates some bad system condition
(too many processes, system out of memory or swap space,
impending kernel panic, etc.) where your expectations
of recovery should not be too high.

=back

=head2 Options for complicated job management

The C<fork()> call from this module supports options that help to
manage child processes or groups of child processes in ways to better
manage your system's resources. For example, you may have a lot of
tasks to perform in the background, but you don't want to overwhelm
your (possibly shared) system by running them all at once. There
are features to control how many, how, and when your jobs will run.

=head3 name

=over 4

=item C<< fork { name => $name } >>

Attaches a string identifier to the job. The identifier can be used
for several purposes:

=over 4

=item * 

to obtain a L<Forks::Super::Job|Forks::Super::Job> object
representing the background task through the
L<Forks::Super::Job::get|Forks::Super::Job/"get"> or
L<Forks::Super::Job::getByName|Forks::Super::Job/"getByName"> methods.

=item * 

as the first argument to L<"waitpid"> to wait on a job or jobs
with specific names

=item * 

as an argument to L<Forks::Super::kill|Forks::Super/"kill"> to
signal a job or group of jobs by name

=item * 

to identify and establish dependencies between background
tasks. See the L<"depend_on">
and L<"depend_start"> parameters below.

=item * 

if supported by your system, the name attribute will change
the argument area used by the ps(1) program and change the
way the background process is displaying in your process viewer.
(See L<$PROGRAM_NAME in perlvar|perlvar/"$PROGRAM_NAME">
about overriding the special C<$0> variable.)

=back

Each job need not be assigned a unique name. Calls to L<"waitpid">
by name will wait for I<any> job with the specified name, and
calls to L<"kill"> by name will signal I<all> of the jobs with
the specified name.

=back

=head3 daemon

=over 4

=item C<< fork { daemon => 1 } >>

Launches the background process as a I<daemon>, partially severing
the relationship between the parent and child process.

Features of daemon process:

=over 4

=item * closes all open file descriptors from the parent

=item * begins in root directory C<"/"> unless the
C<< dir => ... >> option is specified

=item * has umask of zero unless  umask => ...  option specified

=item * daemon will not be affected by signals to the parent

=back

The following restrictions apply to C<daemon> processes:

=over 4

=item * the C<finish> callback (see L<callbacks|"callback">), if any,
will never be called for a daemon

=item * the L<< Forks::Super::Job::is_XXX|Forks::Super::Job/"is_<state>" >>,
L<state|Forks::Super::Job/"state"> methods may not give correct
results for a daemon

=item * the L<Forks::Super::Job::status|Forks::Super::Job/status>
method will not work on a daemon

=item * you cannot use L<"waitpid"> on a daemon process

=item * on MSWin32, must be used with C<< cmd => ... >> or C<< exec => ... >>
option

=item * on MSWin32, this feature requires L<Win32::Process|Win32::Process>

=back

Also note that C<daemon> processes will B<not> count against the
C<$Forks::Super::MAX_PROC> limits.

=back

=head3 max_proc

=over 4

=item C<< fork { max_proc => $max_simultaneous_jobs } >>

=item C<< fork { max_proc => \&subroutine } >>

Specifies the maximum number of background processes that should run
simultaneously. If a C<fork> call is attempted while there are already
the maximum number of child processes running, then the C<fork()>
call will either block (until some child processes complete),
fail (return a negative value without spawning the child process),
or queue the job (returning a very negative value called a job ID),
according to the specified "on_busy" behavior (see L<"on_busy">, below).
See the L<"Deferred processes"> section for information about
how queued jobs are handled.

On any individual C<fork> call, the maximum number of processes may be
overridden by also specifying C<max_proc> or L<"force"> options.

    $Forks::Super::MAX_PROC = 8;
    # launch 2nd job only when system is very not busy
    # always launch 3rd job no matter how busy we are
    $pid1 = fork { sub => 'method1' };
    $pid2 = fork { sub => 'method2', max_proc => 1 };
    $pid3 = fork { sub => 'method3', force => 1 };

Setting C<max_proc> parameter
to zero or a negative number will disable the check for too many
simultaneous processes. Also see the L<"force"> option, below.

C<max_fork> is a synonym for C<max_proc>.

Also see L<$Forks::Super::MAX_PROC in MODULE VARIABLES|"MAX_PROC">,
which globally specifies the desired maximum number of simultaneous
background processes when a C<max_proc> parameter is not supplied to
the C<fork> call.

Since v0.77, the C<max_proc> parameter may be assigned a code reference
to a subroutine that returns the (possibly dynamic) number of simultaneous
background processes allowed. See
L<$Forks::Super::MAX_PROC in MODULE VARIABLES|"MAX_PROC">
for a use case and demonstration.

=back

=head3 max_load

=over 4

=item C<< fork { max_load => $max_cpu_load } >>

Specifies a maximum CPU load threshold at which this job
can be started. The C<fork>
command will not spawn a new jobs while the current
system CPU load is larger than this threshold.
CPU load checks are disabled if this value is set to zero
or to a negative number.

B<Note that the metric of "CPU load" is different on
different operating systems>.
On Windows (including Cygwin), the metric is CPU
utilization, which is always a value between 0 and 1.
On Unix-ish systems, the metric is the 1-minute system
load average, which could be a value larger than 1.
Also note that the 1-minute average load measurement
has a lot of inertia -- after a CPU intensive task
starts or stops, it will take at least several seconds
for that change to impact the 1-minute utilization.

If your system does not have a well-behaved L<uptime(1)|uptime(1)>
command, then it is recommended to install the 
L<Sys::CpuLoadX|Sys::CpuLoadX> module to use this feature.
The C<Sys::CpuLoadX> module is only available bundled with
C<Forks::Super> and otherwise cannot be downloaded from CPAN.

Also see L<$Forks::Super::MAX_LOAD in MODULE VARIABLES|"MAX_LOAD">,
which will specifies the maximum CPU load for launching a job when
the C<max_load> parameter is not provided to C<fork>.

=back

=head3 on_busy

=over 4

=item C<< fork { on_busy => "block" | "fail" | "queue" } >>

Dictates the behavior of C<fork> in the event that the module is not allowed
to launch the specified job for whatever reason. If you are using
C<Forks::Super> to throttle (see
L<max_proc, $Forks::Super::MAX_PROC|"max_proc">)
or impose dependencies on (see L<depend_start|"depend_start">,
L<depend_on|"depend_on">) background processes, then failure to launch a job
should be expected.

=over 4

=item C<block>

If the module cannot create a new child process for the specified job,
it will wait and periodically retry to create the child process until
it is successful. Unless a system fork call is attempted and fails,
C<fork> calls that use this behavior will return a positive PID.

=item C<fail>

If the module cannot immediately create a new child process
for the specified job, the C<fork> call will return with a
small negative value.

=item C<queue>

If the module cannot create a new child process for the specified job,
the job will be deferred, and an attempt will be made to launch the
job at a later time. See L<"Deferred processes">
below. The return
value will be a very negative number (job ID).

=back

Note that jobs that use any of the L<"delay">, L<"start_after">, L<"depend_on">,
or L<"depend_start"> options ignore this setting and always put the job
on the deferred job queue (unless a different C<on_busy> attribute is
explicitly provided).

Also see L<$Forks::Super::ON_BUSY in MODULE VARIABLES|"ON_BUSY">,
which specifies the busy behavior when an C<on_busy> parameter
is not supplied to the C<fork> call.

=back

=head3 force

=over 4

=item C<< fork { force => $bool } >>

If the C<force> option is set, the C<fork> call will disregard the
usual criteria for deciding whether a job can spawn a child process,
and will always attempt to create the child process.

=back

=head3 queue_priority

=over 4

=item C<< fork { queue_priority => $priority } >>

In the event that a job cannot immediately create a child process and
is put on the job queue (see L<"Deferred processes">), the C<queue_priority>
specifies the relative priority of the job on the job queue. In general,
eligible jobs with high priority values will be started before jobs
with lower priority values.

=back

=head3 depend_on

=head3 depend_start

=over 4

=item C<< fork { depend_on => $id } >>

=item C<< fork { depend_on => [ $id_1, $id_2, ... ] } >>

=item C<< fork { depend_start => $id } >>

=item C<< fork { depend_start => [ $id_1, $id_2, ... ] } >>

Indicates a dependency relationship between the job in this C<fork>
call and one or more other jobs. The identifiers may be
process/job IDs or L<"name"> attributes (see above) from
earlier C<fork> calls.

If a C<fork> call specifies a
C<depend_on> option, then that job will be deferred until
all of the child processes specified by the process or job IDs
have B<completed>. If a C<fork> call specifies a
C<depend_start> option, then that job will be deferred until
all of the child processes specified by the process or job
IDs have B<started>.

Invalid process and job IDs in a C<depend_on> or C<depend_start>
setting will produce a warning message but will not prevent
a job from starting.

Dependencies are established at the time of the C<fork> call
and can only apply to jobs that are known at run time. So for
example, in this code,

    $job1 = fork { cmd => $cmd, name => "job1", depend_on => "job2" };
    $job2 = fork { cmd => $cmd, name => "job2", depend_on => "job1" };

at the time the first job is cereated, the job named "job2" has not
been created yet, so the first job will not have a dependency (and a
warning will be issued when the job is created). This may
be a limitation but it also guarantees that there will be no
circular dependencies.

When a dependency identifier is a name attribute that applies to multiple
jobs, the job will be dependent on B<all> existing jobs with that name:

    # Job 3 will not start until BOTH job 1 and job 2 are done
    $job1 = fork { name => "Sally", ... };
    $job2 = fork { name => "Sally", ... };
    $job3 = fork { depend_on => "Sally", ... };

    # all of these jobs have the same name and depend on ALL previous jobs
    $job4 = fork {name=>"Ralph", depend_start=>"Ralph", ...}; # no dependencies
    $job5 = fork {name=>"Ralph", depend_start=>"Ralph", ...}; # depends on Job 4
    $job6 = fork {name=>"Ralph", depend_start=>"Ralph", ...}; # depends on 4 and 5

The default "on_busy" behavior for jobs with dependencies is to go on to
the job queue, ignoring the value of L<$Forks::Super::ON_BUSY/"ON_BUSY">
(but not ignoring the L<< C<on_busy>|"on_busy" >> attribute passed to the
job, if any).

=back

=head3 remote

=over 4

=item C<< fork { remote => 'hostname', cmd => \@cmd, ... } >>

=item C<< fork { remote => '[user[:pass]@]host[:port]', cmd => \@cmd, ... } >>

=item C<< fork { remote => \%remote_opts, cmd => \@cmd, ... } >>

=item C<< fork { remote => [host1,host2,...], cmd => \@cmd, ... } >>

=item C<< fork { remote => [\%opts1,\%opts2,...], cmd => \@cmd, ... } >>

Runs the external command specified in C<@cmd> on a remote host with C<ssh>
(other protocols like C<rsh> may be supported in the future).
C<Forks::Super> will connect to the remote host in a background process
and run the command through the L<Net::OpenSSH|Net::OpenSSH> module
or other available method.

The C<remote> parameter value is either a remote host specification,
or a reference to an array of remote host specifications. A remote host
specification can be a simple scalar consisting of a hostname or IP
address with optional username, password, or port

    remote => 'machine73.example.com'
    remote => 'root@machine72'
    remote => 'bob:pwdofbob@172.14.18.119:30022'

or it can be a hash reference with a C<host> key and optional entries
for C<user>, C<port>, C<password>, and other options accepted by the
L<constructor for Net::OpenSSH|Net::OpenSSH/"new">

    remote => { host => '172.14.18.119', user => 'bob', proto => 'ssh',
                port => 30022, key_path => "$ENV{HOME}/.ssh/id_dsa" }

A C<host> parameter is required. C<user> and C<port>
values default to the user executing the current program, and the
default ssh port. A C<password> parameter need not be used when a 
sufficient password-less public key authentication scheme is in place.

If the C<remote> parameter value is an array reference, then the
elements of that array are considered separate allowable
remote host specifications. When a background job is ready to be
launched, C<Forks::Super> will iterate over the specifications in
a random order looking for a specification that can be used to run
the job on a remote host.

The C<remote> feature only works with the C<cmd> style
calls to C<fork>. For other styles of C<fork> calls,
the information in the C<remote> option will be
ignored.

A background process run on the local host has a different
impact on the local machine's resources than a process run
on a remote host, so a different scheme to decide when
a job can be started is used for remote jobs.
See L<"%MAX_PROC" in MODULE VARIABLES|"MAX_PROC">.

=back



=head3 can_launch

=over 4

=item C<< fork { can_launch => \&methodName } >>

=item C<< fork { can_launch => sub { ... anonymous sub ... } } >>

Supply a user-specified function to determine when a job is
eligible to be started. The function supplied should return
0 if a job is not eligible to start and non-zero if it is
eligible to start.

During a C<fork> call or when the job queue is being examined,
the user's C<can_launch> method will be invoked with a single
C<Forks::Super::Job> argument containing information about the job
to be launched. User code may make use of the default launch
determination method by invoking the C<_can_launch> method
of the job object:

    # Running on a BSD system with the uptime(1) call.
    # Want to block jobs when the current CPU load
    # (1 minute) is greater than 4 and respect all other criteria:
    fork { cmd => $my_command,
           can_launch => sub {
             $job = shift;                    # a Forks::Super::Job object
             return 0 if !$job->_can_launch;  # default
             $cpu_load = (split /\s+/,`uptime`)[-3]; # get 1 minute avg CPU load
             return 0 if $cpu_load > 4.0;     # system too busy. let's wait
             return 1;
           } }

=back

=head3 callback

=over 4

=item C<< fork { callback => $subroutineName } >>

=item C<< fork { callback => sub { BLOCK } } >>

=item C<< fork { callback => { start => ..., finish => ...,
 queue => ..., fail => ... } } >>

Install callbacks to be run as certain events in the life cycle
of a background process occur. The first two forms of this option
are equivalent to

    fork { callback => { finish => ... } }

and specify code that will be executed when a background process is complete
and the module has received its C<SIGCHLD> event. A C<start> callback is
executed just after a new process is spawned. A C<queue> callback is run
if and only if the job is deferred for any reason
(see L<"Deferred processes">) and
the job is placed onto the job queue for the first time. And the C<fail>
callback is run if the job is not going to be launched (that is, a case
where the C<fork> call would return C<-1>).

Callbacks are invoked with two arguments: the
L<Forks::Super::Job|Forks::Super::Job> object that was created with the original
C<fork> call, and the job's ID (the return value from C<fork>).

You should keep your callback functions short and sweet, like you do
for your signal handlers. Sometimes callbacks are invoked from a
signal handler, and the processing of other signals could be
delayed if the callback functions take too long to run.

=back

=head3 suspend

=over 4

=item C<< fork { suspend => 'subroutineName' } } >>

=item C<< fork { suspend => \&subroutineName } } >>

=item C<< fork { suspend => sub { ... anonymous sub ... } } >>

Registers a callback function that can indicate when a background
process should be suspended and when it should be resumed.
The callback function will receive one argument -- the
L<Forks::Super::Job|Forks::Super::Job> object that owns the
callback -- and is expected to return a numerical value. The callback
function will be evaluated periodically (for example, during the
productive downtime of a L<"wait">/L<"waitpid"> call or
C<Forks::Super::Util::pause()> call).

When the callback function returns a negative value
and the process is active, the process will be suspended.

When the callback function returns a positive value
while the process is suspended, the process will be resumed.

When the callback function returns 0, the job will
remain in its current state.

    my $pid = fork { exec => "run-the-heater",
                     suspend => sub {
                       my $t = get_temperature(); # in degrees Fahrenheit
                       if ($t < 68) {
                           return +1;  # too cold, make sure heater is on
                       } elsif ($t > 72) {
                           return -1;  # too warm, suspend the heater process
                       } else {
                           return 0;   # leave it on or off
                       }
                    } };


=back

=head3 share

=over 4

=item C<< fork { share => [ >> I<list-of-references> C<< ] } >>

Allows variables in the parent process to be updated when the child exits.

Input is a listref of references -- scalar, list, or hash references --
that may be updated in a child process. When the child process finishes,
the values of these variables in the parent are updated with the values
that were in the child on its exit. The value of a scalar variable will
be overwritten with the child value, arrays and hashes will be appended
with the child values.

    use Forks::Super;
    my $a = 'old value';
    my @a = 1..5;
    my %a = (abc => 'def');
    $job = fork {
        share => [ \$a, \@a, \%a ],
        sub => {
           $a = 'new value';
           @a = qw(foo bar);
           %a = (bar => 'foo', 19 => 42);
        }
    };
    waitpid $job, 0;
    print "\$a now contains $a\n";     # scalar overwritten => 'new value'
    print "\@a now contains @a\n";     # list appended => 1 2 3 4 5 foo bar
    print "\%a now contains ",keys %a,"\n"; # hash appended => abc,bar,19

This option is not meaningful when used with the C<cmd> or C<exec> options.

If you use the C<share> option in perl's "taint" mode, you will also
need to pass an C<< untaint => 1 >> option to the C<fork> call.

=back

=head3 sync

=over 4

=item C<< fork { sync => $n } >>

=item C<< fork { sync => 'string' } >>

=item C<< fork { sync => \@list } >>

Creates one or more synchronization objects that will be accessible
to both the parent and child processes.

The argument to the C<sync> option is either a number,
a string consisting of C<'C'>, C<'P'>, and C<'N'> characters,
or a list reference consisting of C<'C'>, C<'P'>, and C<'N'> elements.
For a string or list reference input, the number of synchronization
objects created will be the length of the string or length of the list.
The values 'C', 'P', and 'N' determine which process initially has
exclusive access to each synchronization object after the fork.
C<'C'> means that the child process should begin with exclusive access
to the resource, C<'P'> means that the parent process should begin with
exclusive access to the resource, and C<'N'> means that neither process
should have access to the resource after the fork.

Both of these calls create 3 synchronization objects to be shared
between a parent and child process. The first resource is initially
held by the parent, the second resource is initially held by the
child, and the third resource is not held by either process:

    $pid = fork { sync => 'PCN' };
    $pid = fork { sync => ['P','C','N'] };

Using the C<sync> option with a numeric value will create that number
of synchronization objects, with none of the objects initially held by
either the parent or child process. That is, these three uses of the
C<sync> option are equivalent:

    $pid = fork { sync => 2 };
    $pid = fork { sync => 'NN' };
    $pid = fork { sync => ['N','N'] };

After the fork, the parent and child processes can acquire
and release exclusive access to these objects with the
L<acquire|Forks::Super::Job/"acquire"> and
L<release|Forks::Super::Job/"release"> methods of the
L<Forks::Super::Job|Forks::Super::Job> object.

Synchronization objects are useful for coordinating activity
between a parent and child processes. You could use a synchronization
object to coordinate appending to a common file, for example.

    # in parent:
    $job->acquire(0);
    open my $fh, '>>', $common_file;
    print $fh $some_message_from_parent;
    close $fh;
    $job->release(0);

    # in child:
    Forks::Super->acquire(0);
    open my $fh, '>>', $common_file;
    print $fh $some_message_from_child;
    close $fh;
    Forks::Super->release(0);

=back

=head3 os_priority

=over 4

=item C<< fork { os_priority => $priority } >>

On supported operating systems, and after the successful creation
of the child process, attempt to set the operating system priority
of the child process, using your operating system's notion of
what priority is.

On unsupported systems, this option is ignored.

=back

=head3 cpu_affinity

=over 4

=item C<< fork { cpu_affinity => $bitmask } >>

=item C<< fork { cpu_affinity => [ @list_of_processors ] } >>

On supported operating systems with multiple cores,
and after the successful creation of the child process,
attempt to set the child process's CPU affinity.

In the scalar style of this option, each bit of the bitmask represents
one processor. Set a bit to 1 to allow the process to use the
corresponding processor, and set it to 0 to disallow the corresponding
processor.

For example, to bind a new child process to use CPU #s 2 and 3
on a system with (at least) 4 processors, you would call one of

    fork { cpu_affinity => 12 , ... } ;    # 12 = 1<<2 + 1<<3
    fork { cpu_affinity => [2,3] , ... };

There may be additional restrictions on the range of valid
values for the C<cpu_affinity> option imposed by the operating
system. See L<the Sys::CpuAffinity docs|Sys::CpuAffinity> for
discussion of some of these restrictions.

This feature requires the L<Sys::CpuAffinity|Sys::CpuAffinity>
module. The C<Sys::CpuAffinity> module is bundled with C<Forks::Super>,
or it may be obtained from CPAN.

=back

=head3 debug

=head3 undebug

=over 4

=item C<< fork { debug => $bool } >>

=item C<< fork { undebug => $bool } >>

Overrides the debugging setting in C<$Forks::Super::DEBUG>
(see L<DEBUG under MODULE VARIABLES|"DEBUG">)
for this specific job. If specified, the C<debug> parameter
controls only whether the module will output debugging information related
to the job created by this C<fork> call.

Normally, the debugging settings of the parent, including the job-specific
settings, are inherited by child processes. If the C<undebug> option is
specified with a non-zero parameter value, then debugging will be
disabled in the child process.

Also see L<$Forks::Super::DEBUG in MODULE VARIABLES|"DEBUG">,
which specifies the debug settings for a job when the C<debug> parameter
is not supplied, and debug settings for messages that are not related
to a particular background job.

=back

=head3 emulate

=over 4

=item C<< fork { emulate => $bool } >>

When emulation mode is enabled, a call to C<fork> does not actually
spawn a new process, but instead runs the job to completion in the
parent process and returns a job object that is already in the
completed state.

When specified, the value for the parameter C<emulate> overrides 
the emulation mode setting in C<$Forks::Super::EMULATION_MODE> for
a specific job.

One use case for emulation mode is when you are debugging a
script with the perl debugger. Using the debugger with multi-process
programs is tricky, and having all Perl code execute in the
main process can be helpful.

Also see L<$EMULATION_MODE in MODULE VARIABLES|"EMULATION_MODE">,
which specifies the emulation mode for a job when the C<emulate>
parameter is not supplied.

Not all options to C<fork> are compatible with emulation mode.

=cut

#-------------------------------------------------------------
# What options behave differently in emulation mode?
#   exec
#       not allowed but automatically converted to  cmd
#   sub
#       exit from child sub not allowed (will exit from parent)
#       die from child can write $job->{error} in parent
#   share \@, \%
#       "child" overwrites parent values, not adds to parent values
#   timeout, expiration
#       can only use alarm, not the poor man's alarm or
#       other techniques, so may be less effective
#   depends_start
#       may behave differently than expected when dependcy is emulated
#   child_fh
#       interactive sessions are not supported
#       child_fh => 'in' is not useful as parent will not run at the same
#       time as "child". Use 'stdin' to preload standard input in the "child"
#   read_stdout, read_stderr
#       as "child" is complete, all output is ready immediately
#       block => 1  argument is useless
#   kill (function), suspend (function)
#       less useful since can't be called from parent once "child" has started
#-------------------------------------------------------------

=back

=head2 Deferred processes

Whenever some condition exists that prevents a C<fork()> call from
immediately starting a new child process, an option is to B<defer>
the job. Deferred jobs are placed on a queue. At periodic intervals,
in response to periodic events, or whenever you invoke the
C<Forks::Super::Deferred::check_queue> method in your code,
the queue will be examined to see if any deferred jobs are
eligible to be launched.

=head3 Job ID

When a C<fork()> call fails to spawn a child process but instead
defers the job by adding it to the queue, the C<fork()> call will
return a unique, large negative number called the job ID. The
number will be negative and large enough (E<lt>= -100000) so
that it can be distinguished from any possible PID,
Windows pseudo-process ID, process group ID, or C<fork()>
failure code.

Although the job ID is not the actual ID of a system process,
it may be used like a PID as an argument to L<"waitpid">,
as a dependency specification in another C<fork> call's
L<"depend_on"> or L<"depend_start"> option, or
the other module methods used to retrieve job information
(See L</"Obtaining job information"> below). Once a deferred
job has been started, it will be possible to obtain the
actual PID (or on Windows, the actual
psuedo-process ID) of the process running that job.

=head3 Job priority

Every job on the queue will have a priority value. A job's
priority may be set explicitly by including the
L<"queue_priority"> option in the C<fork()> call, or it will
be assigned a default priority near zero. Every time the
queue is examined, the queue will be sorted by this priority
value and an attempt will be made to launch each job in this
order. Note that different jobs may have different criteria
for being launched, and it is possible that that an eligible
low priority job may be started before an ineligible
higher priority job.

=head3 Queue examination

Certain events in the C<SIGCHLD> handler or in the
L<"wait">, L<"waitpid">,
and/or L<"waitall"> methods will cause
the list of deferred jobs to be evaluated and to start
eligible jobs. But this configuration does not guarantee
that the queue will be examined in a timely or frequent
enough basis. The user may invoke the

    Forks::Super::Deferred:check_queue()

method at any time to force the queue to be examined.

=head2 Special tips for Windows systems

On POSIX systems (including Cygwin), programs using the
C<Forks::Super> module are interrupted when a child process
completes. A callback function performs some housekeeping
and may perform other duties like trying to dispatch
things from the list of deferred jobs.

Windows systems do not have the signal handling capabilities
of other systems, and so other things equal, a script
running on Windows will not perform the housekeeping
tasks as frequently as a script on other systems.

The method C<Forks::Super::pause> can be used as a drop in
replacement for the Perl C<sleep> call. In a C<pause>
function call, the program will check on active
child processes, reap the ones that have completed, and
attempt to dispatch jobs on the queue.

Calling C<pause> with an argument of 0 is also a valid
way of invoking the child handler function on Windows.
When used this way, C<pause> returns immediately after
running the child handler.

Child processes are implemented differently in Windows
than in POSIX systems. The C<CORE::fork> and C<Forks::Super::fork>
calls will usually return a B<pseudo-process ID> to the
parent process, and this will be a B<negative value>.
The Unix idiom of testing whether a C<fork> call returns
a positive number needs to be modified on Windows systems
by testing whether  C<Forks::Super::isValidPid($pid)> returns
true, where C<$pid> is the return value from a C<Forks::Super::fork>
call.

=head1 Alternate fork syntax

Since v0.72, the C<fork> function recognizes these additional
syntax:

=head2 C<< fork \&code, %options >>

=head2 C<< fork \&code, \%options >>

If the first argument to C<fork> is a code reference, then it is
treated like a L<"sub"> argument, and is equivalent to the call

    fork { sub => \&code, %options }

This style of call resembles the L<async|Coro/"async"> function in
L<Coro|Coro>.

=head2 C<< fork \@cmd, %options >>

=head2 C<< fork \@cmd, \%options >>

If the first argument to C<fork> is an array reference, then it is
treated like a C<"cmd"> argument, and is equivalent to the call

    fork { cmd => \@cmd, %options }

=head1 OTHER FUNCTIONS

=head2 Process monitoring and signalling

=head3 wait

=over 4

=item C<$reaped_pid = wait [$timeout] >

Like the Perl L<< wait|perlfunc/wait >> system call,
blocks until a child process
terminates and returns the PID of the deceased process,
or C<-1> if there are no child processes remaining to reap.
The exit status of the child is returned in
L<$?|perlvar/"$CHILD_ERROR">.

This version of the C<wait> call can take an optional
C<$timeout> argument, which specifies the maximum length of
time in seconds to wait for a process to complete.
If a timeout is supplied and no process completes before the
timeout expires, then the C<wait> function returns the
value C<-1.5> (you can also test if the return value of the
function is the same as L<Forks::Super::TIMEOUT|/"TIMEOUT">, which
is a constant to indicate that a wait call timed out).

If C<wait> (or L<"waitpid"> or L<"waitall">) is called when
all jobs are either complete or suspended, and there is
at least one suspended job, then the behavior is
governed by the setting of the L<<
$Forks::Super::WAIT_ACTION_ON_SUSPENDED_JOBS|/"WAIT_ACTION_ON_SUSPENDED_JOBS"
>> variable.

=back

=head3 waitpid

=over 4

=item C<$reaped_pid = waitpid $pid, $flags [, $timeout] >

Waits for a child with a particular PID or a child from
a particular process group to terminate and returns the
PID of the deceased process, or C<-1> if there is no
suitable child process to reap. If the return value contains
a PID, then L<$?|perlvar/"$CHILD_ERROR">
is set to the exit status of that process.

A valid job ID (see L<"Deferred processes">) may be used
as the $pid argument to this method. If the C<waitpid> call
reaps the process associated with the job ID, the return value
will be the actual PID of the deceased child.

Note that the C<waitpid> function can wait on a
job ID even when the job associated with that ID is
still in the job queue, waiting to be started.

A $pid value of C<-1> waits for the first available child
process to terminate and returns its PID.

A $pid value of C<0> waits for the first available child
from the same process group of the calling process.

A negative C<$pid> that is not recognized as a valid job ID
will be interpreted as a process group ID, and the C<waitpid>
function will return the PID of the first available child
from the same process group.

On some^H^H^H^H every modern system that I know about,
 a C<$flags> value of C<POSIX::WNOHANG>
is supported to perform a non-blocking wait. See the
Perl L<< waitpid|perlfunc/waitpid >> documentation.

If the optional C<$timeout> argument is provided, the C<waitpid>
function will block for at most C<$timeout> seconds, and
return C<-1.5> (or L<Forks::Super::TIMEOUT|/"TIMEOUT"> if a suitable
process is not reaped in that time.

=back

=head3 waitall

=over 4

=item C<$count = waitall [$timeout] >

Blocking wait for all child processes, including deferred
jobs that have not started at the time of the C<waitall>
call. Return value is the number of processes that were
waited on.

If the optional C<$timeout> argument is supplied, the
function will block for at most C<$timeout> seconds before
returning.

=back

=head3 kill

=over 4

=item C<$num_signalled = Forks::Super::kill $signal, @jobsOrPids>

A cross-platform process signalling function. Sends "signals" to the
background processes specified by process IDs, job names, or
L<Forks::Super::Job|Forks::Super::Job> objects. Returns the number
of jobs that were successfully signalled.

This method "does what you mean" with respect to terminating,
suspending, or resuming processes. This method may "send signals"
to jobs in the job queue (that don't even have a proper process
id yet), or signal processes on Windows systems (which do not
have a Unix-like signals framework). The appropriate Windows API
calls are used to communicate with Windows processes and threads.
It is highly recommended that you install the L<Win32::API|Win32::API>
module for this purpose.

See also the L<<
Forks::Super::Job::suspend|Forks::Super::Job/"$job->suspend" >>
and L<< resume|Forks::Super::Job/"$job->resume" >> methods. It is
preferable (out of portability concerns) to use these methods

    $job->suspend;
    $job->resume;

rather than C<Forks::Super::kill>.

    Forks::Super::kill 'STOP', $job;
    Forks::Super::kill 'CONT', $job;

=back

=head3 kill_all

=over 4

=item C<$num_signalled = Forks::Super::kill_all $signal>

Sends a "signal" (see expanded meaning of "signal" in
L<"kill">, above). to all relevant processes spawned from the
C<Forks::Super> module.

=back

=head3 isValidPid

=over 4

=item C<Forks::Super::isValidPid( $pid )>

Tests whether the return value of a C<fork> call indicates that
a background process has been successfully created or not. On POSIX-y
systems it is sufficient to check whether C<$pid> is a
positive integer, but C<isValidPid> is a more portable way
to test the return value as it also identifies I<psuedo-process IDs>
on Windows systems, which are typically negative numbers.

C<isValidPid> will return false for a large negative process id,
which the C<fork> call returns to indicate that a job has been
deferred (see L<"Deferred processes">). Of course it is possible
that the job will run later and have a valid process id associated
with it.

=cut

#----------------------------------------------------------------
XXX Undocumented second argument to override DWIM behavior
    of treating completed jobs like their real PID and
    other jobs like their initial PID
#----------------------------------------------------------------

=back

=head2 PREFORK, POSTFORK

=head3 PREFORK { ... };

=head3 POSTFORK { ... };

=head3 POSTFORK_PARENT { ... };

=head3 POSTFORK_CHILD { ... };

Sets up one or more code blocks that are run before and after system
call to C<fork>. Use cases for these functions include setting up
I/O handles, database connections, or any other resource that doesn't
play nicely across a C<fork>.

C<POSTFORK> blocks are executed by both parent and child processes
immediately after the C<fork>. C<POSTFORK_PARENT> blocks are only
executed in the parent and C<POSTFORK_CHILD> blocks are only executed
in the child process.

C<PREFORK> blocks are executed first-in, first-out.

C<POSTFORK>, C<POSTFORK_PARENT>, and C<POSTFORK_CHILD> blocks are
executed last-in, first-out.

=head2 Interprocess communication functions

=head3 read_stdout

=head3 read_stderr

=over 4

=item C<$line = Forks::Super::read_stdout($pid [,%options] )>

=item C<@lines = Forks::Super::read_stdout($pid [,%options] )>

=item C<$line = Forks::Super::read_stderr($pid [, %options])>

=item C<@lines = Forks::Super::read_stderr($pid [, %options] )>

=item C<< $line = $job->read_stdout( [%options] ) >>

=item C<< @lines = $job->read_stdout( [%options] ) >>

=item C<< $line = $job->read_stderr( [%options]) >>

=item C<< @lines = $job->read_stderr( [%options] ) >>

For jobs that were started with the C<< child_fh => "out" >>
and C<< child_fh => "err" >> options enabled, read data from
the STDOUT and STDERR file handles of child processes.

Aside from the more readable syntax, these functions may be preferable to
some alternate ways of reading from an interprocess I/O handle

    $line = < {$Forks::Super::CHILD_STDOUT{$pid}} >;
    @lines = < {$job->{child_stdout}} >;
    @lines = < {$Forks::Super::CHILD_STDERR{$pid}} >;
    $line = < {$job->{child_stderr}} >;

because the C<read_stdout> and C<read_stderr> functions will

=over 4

=item * clear the EOF condition when the parent is reading from
the handle faster than the child is writing to it

=item * not block.

=back

Functions work in both scalar and list context. If there is no data to
read on the file handle, but the child process is still active and could
put more data on the file handle, these functions return  C<""> (empty
string) in scalar context and C<()> (empty list) in list context.
If there is no more data on the file handle and the
child process is finished, the return values of the functions
will be C<undef>.

These methods all take any number of arbitrary key-value
pairs as additional arguments. There are currently three
recognized options to these methods:

=over 4

=item * C<< block => 0 | 1 >>

Determines whether blocking I/O is used on the file, socket,
or pipe handle. If enabled, the
L<read_stdXXX|Forks::Super::Job/"read_stdout"> function will
hang until input is available or until the module can determine
that the process creating input for that handle has completed.
Blocking I/O can lead to deadlocks unless you are careful about
managing the process creating input for the handle. The default
mode is non-blocking.

=item * C<< warn => 0 | 1 >>

If warnings on the L<read_stdXXX|Forks::Super::Job/"read_stdout"> function
are disabled, then some warning messages (reading from a closed
handle, reading from a non-existent/unconfigured handle) will
be suppressed. Enabled by default.

Note that the output of the child process may be buffered, and
data on the channel that C<read_stdout> and C<read_stderr> read
from may not be available until the child process has produced
a lot of output, or until the child process has finished.
C<Forks::Super> will make an effort to autoflush the file handles
that write from one process and are read in another process,
but assuring that arbitrary external commands will flush
their output regularly is beyond the scope of this module.

=item * C<< timeout => $num_seconds >>

On an otherwise non-blocking file handle, waits up to the
specified number of seconds for input to become available.

=back

=back

=head3 getc_stdout

=head3 getc_stderr

=over 4

=item C<< $char = $job->getc_stdout( [%options] ) >>

=item C<< $char = $job->getc_stderr( [%options] ) >>

Retrieves a single character from a child process output stream,
if available. Supports the same C<block>, C<timeout>, and
C<warn> options as the L<"read_stdout"> and L<"read_stderr"> functions.

=back

=head3 C<< <$job> >>

=over 4

The C<< <> >> operator has been overloaded for the
L<Forks::Super::Job|Forks::Super::Job> package such that
calling

    <$job>

is equivalent to calling

    scalar $job->read_stdout()

(Due to a limitation of overloading in Perl, this construction
cannot be used in a list context.)

=back

=head3 close_fh

=over 4

=item C<Forks::Super::close_fh($pid)>

=item C<Forks::Super::close_fh($pid, 'stdin', 'stdout', 'stderr')>

Closes the specified open file handles and socket handles for
interprocess communication with the specified child process. With
no additional arguments, closes all open handles for the process.

Most operating systems impose a hard limit on the number of
file handles that can be opened in a process simultaneously,
so you should use this function when you are finished communicating with
a child process so that you don't run into that limit.

See also L<Forks::Super::Job/"close_fh">.

=back

=head3 open2

=head3 open3

=over 4

=item C< ($in,$out,$pid,$job) = Forks::Super::open2(
@command [, \%options ] )>

=item C< ($in,$out,$err,$pid,$job) = Forks::Super::open3(
@command [, \%options] )>

Starts a background process and returns file handles to the process's
standard input and standard output (and standard error in the case
of the C<open3> call). Also returns the process id and the
L<Forks::Super::Job|Forks::Super::Job> object associated with
the background process.

Compare these methods to the main functions of the
L<IPC::Open2|IPC::Open2> and L<IPC::Open3|IPC::Open3> modules.

Many of the options that can be passed to C<Forks::Super::fork> can also
be passed to C<Forks::Super::open2> and C<Forks::Super::open3>:

    # run a command but kill it after 30 seconds
    ($in,$out,$pid) =
         Forks::Super::open2("ssh me\@mycomputer ./runCommand.sh",
                             { timeout => 30 });

    # invoke a callback when command ends
    ($in,$out,$err,$pid,$job) =
         Forks::Super::open3(@cmd,
                             {callback => sub { print "\@cmd finished!\n" }});

=back

=head3 bg_eval

=over 4

=item C<< $result = bg_eval { BLOCK } >>

=item C<< $result = bg_eval { BLOCK } { option => value, ... } >>

Launches a block of code in a background process, returning immediately.
The next time the result of the function call is referenced, interprocess
communication is used to retrieve the result of the child process, waiting
until the child finishes, if necessary.

    $result = bg_eval { sleep 3; return 42 };  # this line returns immediately
    print "Result was $result\n";              # this line takes 3 seconds to execute

With the C<bg_eval> function, you can perform other tasks while waiting for
the results of another task to be available.

    $result = bg_eval { sleep 5; return [1,2,3] };
    do_thing_that_takes_about_5_seconds();
    print "Result was @$result\n";         # this line probably runs immediately

The background process is spawned with the C<Forks::Super::fork> call,
and will block, fail, or defer a job in accordance with all the other rules
of this module. Additional options may be passed to C<bg_eval> that will
be provided to the C<fork> call. Most valid options to the C<fork> call
are also valid for the C<bg_eval> call, including timeouts, delays, job
dependencies, names, and callbacks. This example will populate C<$result>
with the value C<undef> if the C<bg_eval> operation takes longer
than 60 seconds.

    # run task in background, but timeout after 20 seconds
    $result = bg_eval {
        download_from_teh_Internet($url, @options)
    } { timeout => 20, os_priority => 3 };
    do_something_else();
    if (!defined($result)) {
        # operation probably timed out ...
    } else {
        # operation probably succeeded, use $result
    }

An additional option that is recognized by C<bg_eval> (and L<"bg_qx">,
see below) is C<untaint>. If you are running perl in "taint" mode, the
value(s) returned by C<bg_eval> and C<bg_qx> are likely to be "tainted".
By passing the C<untaint> option (assigned to a true value), the values
returned by C<bg_eval> and C<bg_qx> will be taint clean.


Calls to C<bg_eval> (and L<"bg_qx">) will populate the
variables C<$Forks::Super::LAST_JOB> and C<$Forks::Super::LAST_JOB_ID>
with the L<Forks::Super::Job|Forks::Super::Job> object and the job id,
respectively, for the job created by the C<bg_eval>/C<bg_qx> call.
See L<"LAST_JOB" in MODULE VARIABLES|"LAST_JOB"> below.

Since v0.74, the value returned by the background code block may
be a blessed object.

    # ok since v0.74
    $result = bg_eval { sleep 10; Some::Object->new };
    $result->someMethod();

List context is not supported directly by the C<bg_eval> function, but the
L<Forks::Super::bg_eval tied class|"Forks::Super::bg_eval_tied_class">
provides a way to evaluate a code block asynchronously in list context.


See also: L<"bg_qx">.

=back

=head3 bg_qx

=over 4

=item C<< $result = bg_qx $command >>

=item C<< $result = bg_qx $command, { option => value, ... } >>

=item C<< $result = bg_qx [@command] >>

=item C<< $result = bg_qx [@command], { option => value, ... } >>

Launches an external program and returns immediately. Execution of
the command continues in a background process. When the command completes,
interprocess communication copies the output of the command into the
result (left hand side) variable. If the result variable is referenced
again before the background process is complete, the program will wait
until the background process completes. A job that fails or otherwise
produces no output will return the empty string (C<"">).

Think of this command as a background version of Perl's backticks
or L<qx()|perlop/"qx"> function (albeit one that can only work in
scalar context).

The background job will be spawned with the C<Forks::Super::fork> call,
and the command can block, fail, or defer a background job in accordance
with all of the other rules of this module. Additional options may
be passed to C<bg_qx> that will be provided to the C<fork> call.
For example,

    $result = bg_qx "nslookup joe.schmoe.com", { timeout => 15 }

will run C<nslookup> in a background process for up to 15 seconds.
The next time C<$result> is referenced in the program, it will
contain all of the output produced by the process up until the
time it was terminated. Most valid options for the C<fork> call
are also valid options for C<bg_qx>, including timeouts, delays,
job dependencies, names, and callbacks. The only invalid options
for C<bg_qx> are L<"cmd">, L<"sub">, L<"exec">, and L<"child_fh">.

Like L<"bg_eval">, a call to C<bg_qx> will populate the
variables C<$Forks::Super::LAST_JOB> and C<$Forks::Super::LAST_JOB_ID>
with the L<Forks::Super::Job|Forks::Super::Job> object and the job id,
respectively, for the job created by the C<bg_qx> call.
See L<"LAST_JOB" under MODULE VARIABLES|"LAST_JOB"> below.

The C<bg_qx> function does not directly support list context, but see the
L<Forks::Super::bg_qx tied class|"Forks::Super::bg_qx_tied_class">
for a way to evaluate the output of an external command in list
context asynchronously.

See also: L<"bg_eval">.

=back

=begin COMMENT

Forks%3A%3ASuper%3A%3Abg_eval_tied_class,
Forks%3A%3ASuper%3A%3Abg_qx_tied_class headers here are a hack so that
links above like L<"Forks::Super::bg_qx tied class"> and
L<"Forks::Super::bg_eval tied class"> will work.

=end COMMENT

=head3 Forks%3A%3ASuper%3A%3Abg_eval_tied_class

=head3 Forks%3A%3ASuper%3A%3Abg_qx_tied_class

=head3 Forks::Super::bg_eval tied class

=head3 Forks::Super::bg_qx tied class

=over 4

=item C<< tie $result, 'Forks::Super::bg_eval', sub { CODE }, \%options >>

=item C<< tie @result, 'Forks::Super::bg_eval', sub { CODE }, \%options >>

=item C<< tie %result, 'Forks::Super::bg_eval', sub { CODE }, \%options >>

=item C<< tie $output, 'Forks::Super::bg_qx', $command, \%options >>

=item C<< tie @output, 'Forks::Super::bg_qx', $command, \%options >>

=item C<< tie %output, 'Forks::Super::bg_qx', $command, \%options >>

Alternative calls to L<"bg_eval"> and L<"bg_qx"> functions that also
work in list context.

Instead of calling

    my $result = long_running_function($arg1, $arg2);
    my @output = qx(some long running command);
    my %hash = long_running_function_that_returns_hash();

you could say

    tie $result,'Forks::Super::bg_eval',sub{long_running_function($arg1,$arg2)};
    tie @output,'Forks::Super::bg_qx',qq[some long running command];
    tie %hash,'Forks::Super::bg_eval',sub{long_running_func_returns_hash()};

The result of each of these expressions is to tie a variable to the result
of a background process. Like C<bg_qx> and C<bg_eval>, these expressions
spawn a background process and return immediately. Also like C<bg_qx> and
C<bg_eval>, the module retrieves the results of the background operation
the next time the tied variables are evaluated, waiting for the background
process to finish if necessary.

Like other L<bg_qx|"bg_qx"> and L<bg_eval|"bg_eval"> calls, these
expressions respect most of the additional options that you can pass
to L<Forks::Super::fork|"fork">.

    tie @output,'Forks::Super::bg_qx',"ssh me@remotehost who",{ timeout => 10 };
    tie %result,'Forks::Super::bg_eval',\&my_function,{ cpu_affinity => 0x2 };

Note: the constants C<BG_QX> and C<BG_EVAL> are exported by default, and
provide a convenient shorthand for "C<Forks::Super::bg_qx>" and
"C<Forks::Super::bg_eval>", respectively. So you could rewrite the previous two
expressions as

    tie @output, BG_QX, "ssh me@remotehost who", { timeout => 10 };
    tie %result, BG_EVAL, \&my_function, { cpu_affinity => 0x2 };

=back



=head2 Obtaining job information

=head3 Forks::Super::Job::get

=over 4

=item C<$job = Forks::Super::Job::get($pid)>

Returns a C<Forks::Super::Job> object associated with process ID
or job ID C<$pid>. See L<Forks::Super::Job|Forks::Super::Job> for
information about the methods and attributes of these objects.

I<This subroutine is mainly redundant since v0.41, where the
default return value of> C<fork> I<is an overloaded>
C<Forks::Super::Job> I<object instead of a simple scalar
process id>.

=back

=head3 Forks::Super::Job::getByName

=over 4

=item C<@jobs = Forks::Super::Job::getByName($name)>

Returns zero of more C<Forks::Super::Job> objects with the specified
job name. A job has a name if a L<"name"> parameter was provided
in the C<Forks::Super::fork> call.

=back

=head3 state

=over 4

=item C<$state = Forks::Super::state($pid)>

Returns the state of the job specified by the given process ID,
job ID, or job name. See L<Forks::Super::Job/"state">.

=back

=head3 status

=over 4

=item C<$status = Forks::Super::status($pid)>

Returns the exit status of a completed child process
represented by process ID, job ID, or C<name> attribute.
Aside from being a permanent store of the exit status of a job,
using this method might be a more reliable indicator of a job's
status than checking C<$?> after a L<"wait"> or L<"waitpid"> call,
because it is possible for this module's C<SIGCHLD> handler
to temporarily corrupt the C<$?> value while it is checking
for deceased processes.

=back

=head2 Miscellaneous functions

=head3 pause

=over 4

=item C<Forks::Super::pause($delay)>

A B<productive> drop-in replacement for the Perl L<sleep|perlfunc/"sleep">
system call (or L<Time::HiRes::sleep|Time::HiRes/"sleep">, if available). On
systems like Windows that lack a proper method for
handling C<SIGCHLD> events, the C<Forks::Super::pause> method
will occasionally reap child processes that have completed
and attempt to dispatch jobs on the queue.

On other systems, using C<Forks::Super::pause> is less vulnerable
than C<sleep> to interruptions from this module (See
L</"BUGS AND LIMITATIONS"> below).

=head3 init_pkg

=head3 deinit_pkg

=over 4

=item C<< Forks::Super->deinit_pkg >>

=item C<< Forks::Super->init_pkg >>

L<RT#124316|https://rt.cpan.org/Public/Bug/Display.html?id=124316>
identified an issue where the C<SIGCHLD> handler used by
C<Forks::Super> would interfere with a piped open. That is, the
C<close> call in code like

    my $pid = open my $fh, "|-", "some command you expect to work ...";
    ...
    close $fh or die "...";

will fail because C<Forks::Super>'s C<SIGCHLD> handler reaps the
process before the implicit C<waitpid> call in the C<close> function
gets to it.

In some situations -- say, near the end of your program, when you
are not going to use C<Forks::Super::fork> anymore, but you 
still have a reason to call a piped open -- it is desirable and
appropriate to uninstall C<Forks::Super>'s C<SIGCHLD> handler.
The C<Forks::Super::deinit_pkg> is provided for this purpose.

    Forks::Super::deinit_pkg;
    Forks::Super->deinit_pkg;

Either one of these calls will uninstall the C<SIGCHLD> handler
and revert the C<fork>, C<waitpid>, C<wait>, and C<kill> functions
to Perl's builtin behaviors. It is a kludgy attempt to "uninstall" the
module, or at least several features of the module, to workaround
the issue with piped opens.

The C<init_pkg> function, invoked as either C<Forks::Super::init_pkg>
or C<< Forks::Super->init_pkg >>, installs features of the module
into your program. It is automatically called when the C<Forks::Super>
module is imported. So it is not necessary for users to call it
explicitly, I<unless> they have previously called C<deinit_pkg>
and wish to I<re-enable> features of the module.

=back

=head1 MODULE VARIABLES

Module variables may be initialized on the C<use Forks::Super> line

    # set max simultaneous procs to 5, allow children to call CORE::fork()
    use Forks::Super MAX_PROC => 5, CHILD_FORK_OK => -1;

or they may be set explicitly in the code:

    $Forks::Super::ON_BUSY = 'queue';
    $Forks::Super::IPC_DIR = "/home/joe/temp-ipc-files";

Some module variables govern global settings that affect most C<fork> calls,
but can be overridden by a parameter setting in any specific C<fork> call.

    $Forks::Super::ON_BUSY = 'queue';
    $j1 = fork { sub => ... };                     # put on queue if busy
    $j2 = fork { sub => ..., on_busy = 'block' };  # block if busy

Module variables that may be of interest include:

=head3 MAX_PROC

=over 4

=item C<< $Forks::Super::MAX_PROC = int >>

The maximum number of simultaneous background processes that can
be spawned by C<Forks::Super>. If a C<fork> call is attempted while
there are already at least this many active background processes,
the behavior of the C<fork> call will be determined by the
value in L<$Forks::Super::ON_BUSY|/"ON_BUSY"> or by the
L<"on_busy"> option passed
to the C<fork> call.

This value will be ignored during a C<fork> call if the L<"force">
option is passed to C<fork> with a non-zero value. The value might also
not be respected if the user supplies a code reference in the
L<"can_launch"> option and the user-supplied code does not test
whether there are already too many active proceeses.

Since v0.77, the package variable C<$Forks::Super::MAX_PROC> or the
C<max_proc> parameter to C<fork> may be assigned a code reference.
When the module needs to know the maximum
number allowed background processes, it will invoke the subroutine
and expect it to return an integer. Here's a demonstration of how
you could assign a multi-process program to use fewer resources
between 9:00am and 5:00pm:

    $Forks::Super::MAX_PROC = sub {
        my @lt = localtime;
        my $hour = $lt[2];
        $hour >= 9 && $hour < 17 ? 4 : 16;
    }

=back

=head3 %MAX_PROC

=over 4

=item C<%Forks::Super::MAX_PROC>

Since v0.75. The maximum number of simultaneous
background processes that can be spawned by C<Forks::Super>
and run on a remote host. The keys of this hash are remote
hostnames, and the values are integers specifying how many
jobs can be dispatched to those hosts (see the
L<"remote"> option). The key C<"DEFAULT"> can be used to
provide a default maximum for hosts otherwise not
specified. If a maximum process count for a remote hostname
is not specified in C<%MAX_PROC> and there is not a
C<"DEFAULT"> setting in C<%MAX_PROC>, the maximum number of
processes that can be dispatched to the host defaults to
C<$Forks::Super::MAX_PROC>.

=back

=head3 MAX_LOAD

=over 4

=item C<< $Forks::Super::MAX_LOAD = $max_cpu_utilization >>

The threshold CPU load at which jobs created by a C<fork> call will
be deferred. The metric of "CPU load" means different things
on different operating systems. See the discussion under the
L<"max_load"> parameter to C<fork> for details.

=back

=head3 ON_BUSY

=over 4

=item C<$Forks::Super::ON_BUSY = 'block' | 'fail' | 'queue'>

Determines behavior of a C<fork> call when the system is too
busy to create another background process.

If this value is set
to C<block>, then C<fork> will wait until the system is no
longer too busy and then launch the background process.
The return value will be a normal process ID value (assuming
there was no system error in creating a new process).

If the value is set to C<fail>, the C<fork> call will return
immediately without launching the background process. The return
value will be C<-1>. A C<Forks::Super::Job> object will not be
created.

If the value is set to C<queue>, then the C<fork> call
will create a "deferred" job that will be queued and run at
a later time. Also see the L<"queue_priority"> option to C<fork>
to set the urgency level of a job in case it is deferred.
The return value will be a large and negative
job ID.

This value will be ignored in favor of an L<"on_busy"> option
supplied to the C<fork> call.

=back

=head3 CHILD_FORK_OK

=over 4

=item C<$Forks::Super::CHILD_FORK_OK = -1 | 0 | +1>

Spawning a child process from another child process with this
module has its pitfalls, and this capability is disabled by
default: you will get a warning message and the C<fork()> call
will fail if you try it.

To override this behavior, set C<$Forks::Super::CHILD_FORK_OK> to
a non-zero value. Setting it to a positive value will allow
you to use all the functionality of this module from a child
process (with the obvious caveat that you cannot C<wait> on the
child process of a child process from the main process).

Setting C<$Forks::Super::CHILD_FORK_OK> to a negative value will
disable the functionality of this module in child processes but will
reenable the Perl builtin C<fork()> system call.

Note that this module will not have any preconceptions about which
is the "parent process" until you the first
call to C<Forks::Super::fork>. This means it is possible to use
C<Forks::Super> functionality in processes that were I<not>
spawned by C<Forks::Super>, say, by an explicit C<CORE::fork()> call:

     1: use Forks::Super;
     2: $Forks::Super::CHILD_FORK_OK = 0;
     3:
     4: $child1 = CORE::fork();
     5: if ($child1 == 0) {
     6:    # OK -- child1 is still a valid "parent process"
     7:    $grandchild1 = Forks::Super::fork { ... };
     8:    ...;
     9:    exit;
    10: }
    11: $child2 = Forks::Super::fork();
    12: if ($child2 == 0) {
    13:    # NOT OK - parent of child2 is now "the parent"
    14:    $grandchild2 = Forks::Super::fork { ... };
    15:    ...;
    16:    exit;
    17: }
    18: $child3 = CORE::fork();
    19: if ($child3 == 0) {
    20:    # NOT OK - call in line 11 made parent of child3 "the parent"
    21:    $grandchild3 = Forks::Super::fork { ... };
    22:    ...;
    23:    exit;
    24: }

More specifically, this means it is OK to use the C<Forks::Super>
module in a daemon process:

    use Forks::Super;
    $Forks::Super::CHILD_FORK_OK = 0;
    CORE::fork() && exit;
    $daemon_child = Forks::Super::fork();   # ok

=back

=head3 DEBUG

=over 4

=item C<$Forks::Super::DEBUG = bool>

To see the internal workings of the C<Forks::Super> module, set
C<$Forks::Super::DEBUG> to a non-zero value. Information messages
will be written to the C<Forks::Super::Debug::DEBUG_FH> file handle. By default
C<Forks::Super::Debug::DEBUG_FH> is aliased to C<STDERR>, but it may be reset
by the module user at any time.

Debugging behavior may be overridden for specific jobs
if the L<"debug"> or L<"undebug"> option is provided to C<fork>.

=back

=head3 EMULATION_MODE

=over 4

=item C<$Forks::Super::EMULATION_MODE = bool>

When emulation mode is enabled, the C<fork> call does not actually
spawn a new process, but instead runs the job to completion
in the foreground process and returns a job object that
is already in the completed state.

One use case for emulation mode is when you are debugging a
script with the perl debugger. Using the debugger with multi-process
programs is tricky, and having all Perl code execute in the
main process can be helpful.

The default emulation mode may be overridden for specific jobs
if the L<"emulate"> option is provided to C<fork>.

Not all options to C<fork> are compatible with emulation mode.

=cut

#--------------------------------------------------------------
See the discussion under the L<"emulate"> parameter to C<fork>.
#--------------------------------------------------------------

=back

=head3 CHILD_STDxxx

=head3 %CHILD_STDxxx

=over 4

=item C<%Forks::Super::CHILD_STDIN>

=item C<%Forks::Super::CHILD_STDOUT>

=item C<%Forks::Super::CHILD_STDERR>

B<Deprecated>. See B<Note>, below.

In jobs that request access to the child process file handles,
these hash arrays contain file handles to the standard input
and output streams of the child. The file handles for particular
jobs may be looked up in these tables by process ID or job ID
for jobs that were deferred.

Remember that from the perspective of the parent process,
C<$Forks::Super::CHILD_STDIN{$pid}> is an output file handle (what you
print to this file handle can be read in the child's STDIN),
and C<$Forks::Super::CHILD_STDOUT{$pid}>
and C<$Forks::Super::CHILD_STDERR{$pid}>
are input file handles (for reading what the child wrote
to STDOUT and STDERR).

As with any asynchronous communication scheme, you should
be aware of how to clear the EOF condition on file handles
that are being simultaneously written to and read from by
different processes. A construction like this works on most systems:

    # in parent, reading STDOUT of a child
    for (;;) {
        while (<{$Forks::Super::CHILD_STDOUT{$pid}}>) {
          print "Child $pid said: $_";
        }

        # EOF reached, but child may write more to file handle later.
        sleep 1;
        seek $Forks::Super::CHILD_STDOUT{$pid}, 0, 1;
    }

The L<Forks::Super::Job|Forks::Super::Job> object provides the
methods C<write_stdin(@msg)>, C<read_stdout(\%options)>, and
C<read_stderr(\%options)> for object oriented read and write
operations to and from a child's IPC file handles. These methods
can adjust their behavior based on the type of IPC channel
(file, socket, or pipe) or other idiosyncracies of your operating
system (#@$%^&*! Windows), B<so using those methods is preferred
to using the file handles directly>.

B<Note that handles for background process IPC are also available
through the> L<Forks::Super::Job|Forks::Super::Job> B<object>
(the return value from C<Forks::Super::fork>), in

    $pid->{child_stdin}
    $pid->{child_stdout}
    $pid->{child_stderr}

This usage should be preferred to C<$CHILD_STDxxx{...}>.

=back

=head3 ALL_JOBS

=over 4

=item C<@Forks::Super::ALL_JOBS>

=item C<%Forks::Super::ALL_JOBS>

List of all C<Forks::Super::Job> objects that were created
from C<fork()> calls, including deferred and failed jobs.
Both process IDs and job IDs for jobs that were deferred at
one time) can be used to look up Job objects in the
C<%Forks::Super::ALL_JOBS> table.

=back

=head3 IPC_DIR

=over 4

=item C<$Forks::Super::IPC_DIR>

A directory where temporary files to be shared among processes
for interprocess communication (IPC) can be created. If not specified,
C<Forks::Super> will try to guess a good directory such as an
OS-appropriate temporary directory or your home directory as a
suitable store for these files.

C<$Forks::Super::IPC_DIR> is a tied variable and an
assignment to it will fail if the RHS is not suitable for
use as a temporary IPC file store.

C<Forks::Super> will look for the environment variable
C<IPC_DIR> and for an C<IPC_DIR> parameter on module import
(that is,

    use Forks::Super IPC_DIR => '/some/directory'

) for suggestions about where to store the IPC files.

Setting this value to C<"undef"> (the string literal C<"undef">,
not the Perl special value C<undef>) will disable
file-based interprocess communication for your program.
The module will fall back to using sockets or pipes
(probably sockets) for all IPC. Some features of this distribution
may not work or may not work properly if file-based IPC is disabled.

=back

=head3 QUEUE_INTERRUPT

=over 4

=item C<$Forks::Super::QUEUE_INTERRUPT>

On systems with mostly-working signal frameworks, this
module installs a signal handler the first time that a
task is deferred. The signal that is trapped is
defined in the variable C<$Forks::Super::QUEUE_INTERRUPT>.
The default value is C<USR1>, and it may be overridden
directly or set on module import

    use Forks::Super QUEUE_INTERRUPT => 'TERM';
    $Forks::Super::QUEUE_INTERRUPT = 'USR2';

You would only worry about resetting this variable
if you (including other modules that you import) are
making use of an existing C<SIGUSR1> handler.

B<Since v0.40> this variable is generally not used unless

1. your system has a POSIX-y signal framework, and

2. L<Time::HiRes::setitimer|Time::HiRes/"setitimer">
is B<not> implemented for your system.

=back

=head3 TIMEOUT

=over 4

=item C<Forks::Super::TIMEOUT>

A possible return value from L<"wait"> and L<"waitpid">
functions when a timeout argument is supplied.
The value indicating a timeout should not collide with any other
possible value from those functions, and should be recognizable
as not an actual process ID.

    my $pid = wait 10.0;  # Forks::Super::wait with timeout
    if ($pid == Forks::Super::TIMEOUT) {
        # no tasks have finished in the last 10 seconds ...
    } else {
        # task has finished, process id in $pid.
    }

=back

=head3 LAST_JOB

=head3 LAST_JOB_ID

=over 4

=item C<$Forks::Super::LAST_JOB>

=item C<$Forks::Super::LAST_JOB_ID>

Calls to the L<"bg_eval"> and L<"bg_qx"> functions launch
a background process and set the variables C<$Forks::Super::LAST_JOB_ID>
to the job's process ID and C<$Forks::Super::LAST_JOB> to the job's
L<Forks::Super::Job|Forks::Super::Job> object. These functions do
not explicitly return the job id, so these variables provide a
convenient way to query that state of the jobs launched by these functions.

Some C<bash> users will immediately recognize the parallels
between these variables and the special bash C<$!> variable, which
captures the process id of the last job to be run in the background.

=back

=head3 WAIT_ACTION_ON_SUSPENDED_JOBS

=over 4

=item C<$Forks::Super::Wait::WAIT_ACTION_ON_SUSPENDED_JOBS>

Governs the action of a call to L<"wait">, L<"waitpid">, or
L<"waitall"> in the case when all remaining jobs are in the
C<SUSPENDED> or C<DEFERRED-SUSPENDED> state (see
L<Forks::Super::Job/"state">). Allowable values for this variable
are

=over 4

=item C<wait>

Causes the call to L<"wait">/L<"waitpid"> to block indefinitely
until those jobs start and one or more of them is completed.
In this case it is presumed that the queue monitor is running periodically
and conditions that allow those jobs to get started will occur.
This is the default setting for this variable.

=item C<fail>

Causes the L<"wait">/L<"waitpid"> call to return with the special
(negative) value C<Forks::Super::Wait::ONLY_SUSPENDED_JOBS_LEFT>.

=item C<resume>

Causes one of the suspended jobs to be resumed. It is presumed
that this job will complete and allow the L<"wait">/L<"waitpid">
function to return.

=back

=back

=head3 ON_TOO_MANY_OPEN_FILEHANDLES

=over 4

=item C<< $Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES = 'rescue' | 'fail' >>

Open file handles are a scarce computing resource, and a script
that launches many small jobs with C<Forks::Super> and is not
meticulous about calling L<"close_fh"> or L<"dispose"> on those
jobs may bump up against this limit.  The module variable
C<$Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES> dictates what
happens when C<Forks::Super> detects that you are getting close
to this limit. This variable can have two possible values:

=over 4

=item C<$Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES = 'fail'>

This is the default. With this setting, C<Forks::Super> will
allow you to attempt to open more file handles, and not do
anything special about it on failure.

=item C<$Forks::Super::ON_TOO_MANY_OPEN_FILEHANDLES = 'rescue'>

With this setting, C<Forks::Super> will attempt to close some
open file handles from other jobs when it detects that it is
getting close to the maximum number of open file handles.
Output from child processes may be lost if this safeguard
kicks in.

=back

=back

=head1 EXPORTS

This module always exports the C<fork>, L<"wait">, L<"waitpid">,
and L<"waitall"> functions, overloading the Perl system calls
with the same names. Mixing C<Forks::Super> calls with the
similarly-named Perl calls is strongly discouraged, but you
can access the original builtin functions at C<CORE::fork>,
C<CORE::wait>, etc.

Functions that can be exported to the caller's package include

    Forks::Super::bg_eval
    Forks::Super::bg_qx
    Forks::Super::isValidPid
    Forks::Super::open2
    Forks::Super::open3
    Forks::Super::pause
    Forks::Super::read_stderr
    Forks::Super::read_stdout

Module variables that can be exported are:

    %Forks::Super::CHILD_STDIN
    %Forks::Super::CHILD_STDOUT
    %Forks::Super::CHILD_STDERR

The special tag C<:var> will export all three of these hash tables
to the calling namespace.

The tag C<:all> will export all the functions and variables
listed above.

The C<Forks::Super::kill> function cannot be exported
for now, while I think through the implications of
overloading yet another Perl system call.

=head1 IMPORT CONFIG

Many of these settings have been mentioned in other parts of this document,
but here is a summary of the configuration that can be done on the
C<use Forks::Super ...> line

=head2 MAX_PROC => integer | subroutine that returns integer

Initializes C<$Forks::Super::MAX_PROC>, which governs the maximum number
of simultaneous background processes managed
by this module. When a new process is requested and this limit has been
reached, the C<fork> call will fail, block (until at least one current
process finishes), or queue, depending on the setting of
C<$Forks::Super::ON_BUSY>. See L<"MAX_PROC" under MODULE VARIABLES|"MAX_PROC">.

=head2 ON_BUSY => 'block' | 'fail' | 'queue'

Sets C<$Forks::Super::ON_BUSY>, which governs the behavior of C<fork>
when the limit of simultaneous background processes has been reached.
See L<"ON_BUSY" under MODULE VARIABLES|"ON_BUSY">.

=head2 CHILD_FORK_OK => -1 | 0 | 1

Sets C<$Forks::Super::CHILD_FORK_OK>, which governs the behavior of
C<Forks::Super::fork> when called from a child process.
See L<"CHILD_FORK_OK"> in L<"MODULE VARIABLES">.

=head2 DEBUG => boolean

Turns module debugging on and off. On the import line, this configuration
overrides the value of C<$ENV{FORKS_SUPER_DEBUG}> (see L<"ENVIRONMENT">).

=head2 QUEUE_MONITOR_FREQ => num_seconds

Sets C<$Forks::Super::Deferred::QUEUE_MONITOR_FREQ>, which governs how frequently
the main process should be interrupted to examine the queue of jobs
that have not started yet. See L<Forks::Super::Deferred|Forks::Super::Deferred>.

=head2 QUEUE_INTERRUPT => signal_name

Sets C<$Forks::Super::QUEUE_INTERRUPT>, the name of the signal used by
C<Forks::Super> to periodically examine the queue of background jobs that
have not started yet. The default setting is C<USR1>, but you should
change this if you with to use C<SIGUSR1> for other purposes in your
program. This setting does not have any effect on MSWin32 systems.

=head2 IPC_DIR => directory, FH_DIR => directory

Use the specified directory for temporary interprocess communication
files used by C<Forks::Super>. Overrides settings of
C<$ENV{IPC_DIR}> or C<$ENV{FH_DIR}>.

=head2 CONFIG => file, CONFIG_FILE => file

Loads module configuration out of the specified file. The file
is expected to contain key-value pairs for the same parameter
documented in this section. Parameter names in the configuration
file are not case sensitive.

    # sample Forks::Super config file
    max_proc=10
    IPC_DIR=/home/mob/.forks-super-ipc

=cut

#------------------------------------------------------------------
Setting a configuration file name with a C<< CONFIG => file >>
directive also specifies the file that will be reloaded when you
are using dynamic configuration with signals.
#------------------------------------------------------------------

=head1 ENVIRONMENT

C<Forks::Super> makes use of the following optional variables
from your environment.

=over 4

=item FORKS_SUPER_DEBUG

If set, sets the default value of C<$Forks::Super::DEBUG>
(see L<"MODULE VARIABLES">) to true.

=item FORKS_SUPER_QUEUE_DEBUG

If set and true, sends additional information about the
status of the queue (see L<"Deferred processes">) to
standard output. This setting is independent of the
C<$ENV{FORKS_SUPER_DEBUG}>/C<$Forks::Super::DEBUG> setting.

=item FORKS_DONT_CLEANUP

If set and true, the program will not remove the temporary
files used for interprocess communication. This setting can
be helpful if you want to analyze the messages that were
sent between processes after the fact.

=item FORKS_SUPER_CONFIG

C<Forks::Super> will probe your system for available functions,
Perl modules, and external programs and try suitable workarounds
when the desired feature is not available. With
C<$ENV{FORKS_SUPER_CONFIG}>, you can command C<Forks::Super> to
assume that certain features are available (or are not available)
on your system. This is a little bit helpful for testing; I
don't know whether it would be helpful for anything else.
See the source for C<Forks/Super/Config.pm> for more information
about how C<$ENV{FORKS_SUPER_CONFIG}> is used.

=item FORKS_SUPER_JOB_OVERLOAD

Specifies whether the C<fork> call will return an overloaded
L<Forks::Super::Job|Forks::Super::Job> object instead of a scalar process
identifier. See L<Forks::Super::Job/"OVERLOADING">.
B<< Since v0.41 overloading is enabled by default. >>
If the C<FORKS_SUPER_JOB_OVERLOAD> variable is set, it will
override this default.

=item FORKS_SUPER_ENABLE_DUMP

If set, will invoke L<the Forks::Super::Debug::enable_dump
function|Forks::Super::Debug/"enable_dump">
and enable a Java Virtual Machine-like feature to report the status of all
the background jobs your program has created. If this variable contains
the name of a signal, then that signal will be trapped by your program
to produce the process dump. If the variable value is not a signal name
but is a true value, then the program will produce a process dump in
response to a C<SIGQUIT>. See L<Forks::Super::Debug|Forks::Super::Debug>.

This feature can also be enabled on import of C<Forks::Super> by
passing an C<ENABLE_DUMP> parameter on import, like

    use Forks::Super ENABLE_DUMP => 1;    # same as ENABLE_DUMP => 'QUIT'
    use Forks::Super ENABLE_DUMP => 'USR1';

=item IPC_DIR

Specifies a directory for storing temporary files for
interprocess communication.
See L<"IPC_DIR" in "MODULE VARIABLES"|"IPC_DIR">.

=back

=head1 DIAGNOSTICS

=over 4

=item C<fork() not allowed in child process ...>

When the package variable C<$Forks::Super::CHILD_FORK_OK> is zero,
this package does not allow the C<fork()> method to be called from
a child process. Set
L<< C<$Forks::Super::CHILD_FORK_OK>|/"CHILD_FORK_OK" >>
to change this behavior.

=item C<quick timeout>

A job was configured with a timeout/expiration time such that the
deadline for the job occurred before the job was even launched. The job
was killed immediately after it was spawned.

=item C<< Job start/Job dependency E<lt>nnnE<gt> 
for job E<lt>nnnE<gt> is invalid. Ignoring. >>

A process id or job id that was specified as a L<"depend_on">
or L<"depend_start">
option did not correspond to a known job.

=item C<Job E<lt>nnnE<gt> reaped before parent initialization.>

A child process finished quickly and was reaped by the parent
process C<SIGCHLD> handler before the parent process could even
finish initializing the job state. The state of the job in the
parent process might be unavailable or corrupt for a short time,
but eventually it should be all right.

=item C<could not open file handle to provide child STDIN/STDOUT/STDERR>

=item C<child was not able to detect STDIN file ... 
Child may not have any input to read.>

=item C<could not open file handle to write child STDIN>

=item C<could not open file handle to read child STDOUT/STDERR>

Initialization of file handles for a child process failed. The child process
will continue, but it will be unable to receive input from the parent through
the C<$Forks::Super::CHILD_STDIN{pid}> (C<pid->{child_stdin}>) file handle,
or pass output to the parent through the file handles
C<$Forks::Super::CHILD_STDOUT{pid}> and C<$Forks::Super::CHILD_STDERR{pid}>
(C<pid->{child_stdout}> and C<pid->{child_stderr}>).

=cut

----------------------------------------------------------
-item C<exec option used, timeout option ignored>

A C<fork> call was made using the incompatible options
L<"exec"> and L<"timeout">.
----------------------------------------------------------

=back

=head1 INCOMPATIBILITIES

This module requires its own C<SIGCHLD> handler. Installing
other C<SIGCHLD> handlers may cause undefined behavior,
though if L<you are used to setting|perlfunc/"fork">

    $SIG{CHLD} = 'IGNORE'

in your code, you should still be OK.

=cut

#----------------------------------------------------------------------
# ------ 0.55 changes in FS::Wait might change this behavior.
# ------ $SIG{CHLD}='IGNORE' may cause  wait/waitpid  to
#        always return 0/-1
#----------------------------------------------------------------------

=head1 DEPENDENCIES

The L<Win32::API|Win32::API> module is required for Windows users.

The L<"bg_eval"> function requires at least of the data
serialization modules L<Data::Dumper|Data::Dumper> or L<YAML|YAML>.
(I<< C<JSON> is no longer supported as
of v0.74 and C<YAML::Tiny> is not supported after v0.80 >>).
If none of these modules are available,
then using L<"bg_eval"> will result in a fatal error.

Otherwise, there are no hard dependencies on non-core
modules. Some features, especially operating-system
specific functions, depend on some modules (L<Win32::Process|Win32::Process>
and L<Win32|Win32> for Wintel systems, for example), but the module will
compile without those modules. Attempts to use these features
without the necessary modules will be silently ignored.

=head1 BUGS AND LIMITATIONS

=head2 Interference with piped C<open>

As documented in
L<RT#124316|https://rt.cpan.org/Public/Bug/Display.html?id=124316>,
C<Forks::Super> sets a relatively heavy C<SIGCHLD> handler, which
can apparently cause a race condition when you call C<close> on a
piped filehandle

    open my $fh, '|-', "command you expect to work ...";
    ...
    close $fh or die;

Sometimes, a C<waitpid> call inside the signal handler will reap
the process before the C<close> call. If that happens, the
C<close> call will fail (and set C<$!> to "C<No child processes>"
and C<$?> to -1).

If this behavior is undesired, and there are no calls to L<"fork">
between the piped C<open> and C<close> statements, the workaround is
to call the L<< "deinit_pkg"|C<Forks::Super::deinit_pkg> >>
function and disable the problematic features of the module.

=head2 Leftover temporary files and directories

In programs that use the interprocess communication features,
the module will usually but not always do a good job of cleaning
up after itself. You may find directories called C<< .fhfork<nnn> >>
that may or not be empty scattered around your filesystem.

You can invoke this module as one of:

    $ perl -MForks::Super=cleanse
    $ perl -MForks::Super=cleanse,<directory>

to run a function that will clean up these directories.

=head2 Interrupted system calls

A typical script using this module will have a lot of
behind-the-scenes signal handling as child processes
finish and are reaped. These frequent interruptions can
affect the execution of the rest of your program.
For example, in this script:

    1: use Forks::Super;
    2: fork(sub => sub { sleep 2 });
    3: sleep 5;
    4: # ... program continues ...

the C<sleep> call in line 3 is probably going to get
interrupted before 5 seconds have elapsed as the end
of the child process spawned in line 2 will interrupt
execution and invoke the SIGCHLD handler.
In some cases there are tedious workarounds:

    3a: $stop_sleeping_at = time + 5;
    3b: sleep 1 while time < $stop_sleeping_at;

In this distribution, the L<Forks::Super::pause|/"pause">
call provides an interruption-resistant alternative to
C<sleep>.

    3: Forks::Super::pause(5);

The C<pause> call itself has the limitation that it may
sleep for B<longer> than the desired time. This is because
the "productive" code executed in a C<pause> function
call can take an arbitrarily long time to run.

=head2 Idiosyncratic behavior on some systems

The system implementation of fork'ing and wait'ing varies
from platform to platform. This module has been extensively
tested on Cygwin, Windows, and Linux, but less so on other
systems. It is possible that some features will not work
as advertised. Please report any problems you encounter
to E<lt>mob@cpan.orgE<gt> and I'll see what I can do
about it.

=head2 Other bugs or feature requests

Feel free to report other bugs or feature requests
to C<bug-forks-super at rt.cpan.org> or through the
web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Forks-Super>.
This includes any cases where you think the documentation
might not be keeping up with the development.
I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SEE ALSO

There are reams of other modules on CPAN for managing background
processes. See Parallel::*, L<Proc::Parallel|Proc::Parallel>,
L<Proc::Queue|Proc::Queue>,
L<Proc::Fork|Proc::Fork>, L<Proc::Launcher|Proc::Launcher>.
Also L<Win32::Job|Win32::Job>.

Inspiration for L<"bg_eval"> function from
L<Acme::Fork::Lazy|Acme::Fork::Lazy>.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2018, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

TODO in future releases: See TODO file.
