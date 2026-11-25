package Developer::Dashboard::ProcessSupervision;

use strict;
use warnings;

our $VERSION = '6.31';

use Exporter 'import';

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use File::Spec;
use Time::HiRes qw(sleep);

# POSIX WITHOUT IMPORTING, deliberately. Both source modules do
# `use POSIX qw(close setsid strftime)`, and importing `close` SHADOWS the
# built-in - which is why their code says CORE::close($fh) when it means the
# ordinary one. Nothing here needs that hazard: the only POSIX call is
# fully qualified, so the empty import list keeps the built-in intact.
use POSIX ();

use Developer::Dashboard::Platform qw(command_in_path is_windows);

# Capture the directory in which Perl loaded its process helpers. Relative
# @INC entries remain relative after chdir, but a fresh child would resolve
# them against its new cwd rather than the location that loaded this runtime.
our $PERL_LIBRARY_BASE = getcwd();

# These are exported into the consuming package rather than called as functions,
# so every existing call site stays `$self->_helper(...)` unchanged. Perl resolves
# a method call through the invoking package's symbol table, so an imported sub is
# found there and receives $self as its first argument - which is the signature
# these already had as methods.
#
# That is not a stylistic choice. Two of them call helpers that legitimately
# DIFFER between the consuming modules: _pid_is_running calls _read_process_state,
# and _replace_state_file calls _replace_path_via_powershell. Keeping method
# dispatch means each consumer's own version is used, preserving today's behaviour
# exactly. Extracting these as plain functions would bind them to one version and
# silently change the other module - against a test suite that would stay green,
# because each version satisfies its own module's tests.
our @EXPORT_OK = qw(
    _perl_library_args
    _current_perl_command
    _dashboard_core_helper_path
    _descriptor_is_inherited_pipe
    _open_file_descriptors
    _overwrite_state_file_in_place
    _pid_is_running
    _lifetime_owner_pid
    _lifetime_owner_is_gone
    _lifetime_owner_poll_seconds
    _pid_namespace_id
    _powershell_command
    _powershell_single_quote
    _taskkill_command
    _process_exists
    _read_process_env_marker
    _reap_child_process
    _rename_path
    _replace_state_file
    _source_is_movable
    _unlink_path
    _helper_file_supports_internal_command
    _same_pid_namespace
    _close_inherited_fds
);

# _reap_child_process($pid)
# Reaps one direct runtime child when it has already exited so background
# lifecycle helpers do not accumulate zombie processes.
# Input: process id integer.
# Output: boolean true when waitpid reaped the child.
sub _reap_child_process {
    my ( $self, $pid ) = @_;
    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS. waitpid below reads the
    # reaped child's status into $?, and without this guard that value stays set
    # in the caller after a question - "is this pid still mine to reap" - has been
    # answered. Same rule as _read_process_state and the rest of the $?-touching
    # functions; the copies this sub was extracted from were missing it, and the
    # leak only became visible once a test process ended with the stale value.
    local $?;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    if ( is_windows() ) {
        # A GoRoutine (CreateProcess) child is reaped through the native
        # process API, because waitpid below cannot reliably see one once
        # its process object is gone. A pid the spawn registry does not
        # know falls through to waitpid, which keeps its existing behaviour
        # for any other direct child.
        require Developer::Dashboard::GoRoutine;
        return 1 if Developer::Dashboard::GoRoutine::reap_child($pid);
    }
    my $waited = waitpid( $pid, 1 );
    return $waited == $pid ? 1 : 0;
}

# _pid_is_running($pid)
# Determines whether one runtime-managed pid is still alive after opportunistic
# child reaping.
# Input: process id integer.
# Output: boolean true when the process is still running.
sub _pid_is_running {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    return 0 if $self->_reap_child_process($pid);
    return 0 if ( $self->_read_process_state($pid) || '' ) eq 'Z';
    return $self->_process_exists($pid) ? 1 : 0;
}

# _lifetime_owner_pid()
# Returns the pid this runtime's lifetime is tied to. A starter opts in
# by exporting DEVELOPER_DASHBOARD_LIFETIME_PID before it starts the
# runtime; every process the runtime starts inherits it. It exists for
# starters that can be killed without ever running a stop, such as a
# test run ended by a CI stop-all: the web, the supervisor and the loops
# are all detached, so nothing else would ever end them. An ordinary
# user never sets it, so a runtime started from a shell still outlives
# that shell exactly as before. The calling process's own pid is
# refused, so a process cannot be tied to itself. This is the one
# reader of the variable: the collector supervisor, each collector loop
# and the web owner watcher all go through it.
# Input: none.
# Output: pid integer, or undef when no usable owner pid is set.
sub _lifetime_owner_pid {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_LIFETIME_PID};
    # An explicit undef, never a bare return: callers build a hash with
    # this value in list context, and an empty list there would shift
    # the next key into the pid slot and make an ordinary user look
    # opted in to an owner that can never be alive.
    return undef if !defined $value || $value !~ /\A\d+\z/ || $value < 1;    ## no critic (ProhibitExplicitReturnUndef)
    return undef if $value == $$;                                             ## no critic (ProhibitExplicitReturnUndef)
    return $value + 0;
}

# _lifetime_owner_is_gone($owner)
# Counts one liveness poll of the opted-in lifetime owner and reports
# whether it is now confirmed dead. The owner must be seen dead on two
# polls in a row, so one failed liveness probe cannot end a healthy
# process; a live poll resets the count. Liveness is the consumer's own
# _pid_is_running, reached by method dispatch like every other helper
# here, so the identical platform-aware path runs on Windows.
# Input: owner-state hash reference the caller keeps across polls (pid,
# dead_polls). An undef pid means the starter did not opt in.
# Output: boolean true once the owner has been dead on two polls in a
# row, false otherwise.
sub _lifetime_owner_is_gone {
    my ( $self, $owner ) = @_;
    return 0 if ref($owner) ne 'HASH' || !defined $owner->{pid};
    if ( $self->_pid_is_running( $owner->{pid} ) ) {
        $owner->{dead_polls} = 0;
        return 0;
    }
    $owner->{dead_polls}++;
    return $owner->{dead_polls} >= 2 ? 1 : 0;
}

# _lifetime_owner_poll_seconds()
# Returns how many seconds pass between two polls of the opted-in
# lifetime owner in a process that has no faster loop of its own to
# poll from. Two dead polls in a row are needed, so such a process ends
# about twice this long after its owner dies.
# Input: none.
# Output: seconds number.
sub _lifetime_owner_poll_seconds {
    return 5;
}

# _replace_state_file($source, $target)
# Replaces one runtime state file with a prepared temporary file, including a
# Windows-specific retry path when the destination already exists and plain
# rename replacement semantics are unavailable.
# Input: temporary source path and final state-file path.
# Output: true value after the target file has been replaced.
sub _replace_state_file {
    my ( $self, $source, $target ) = @_;
    return 1 if $self->_rename_path( $source, $target );

    my $rename_error = $!;
    if ( $self->is_windows ) {
        # A rename can fail two ways: the target already exists (a collision,
        # where the source itself is movable) or the source is locked against
        # rename/delete (which the writer itself holds briefly after close).
        # Only the second case goes straight to the in-place overwrite: it
        # reads the source (which still works while the source is locked) and
        # rewrites the target without ever removing it, so a reader never
        # finds the target missing. The unlink-then-rename and PowerShell
        # paths below delete the target first and can leave it missing for
        # seconds (PowerShell startup) while a locked source defeats every
        # move, which starved loop_state and killed the t/07 stale-loop
        # test at 580.
        if ( !$self->_source_is_movable($source) ) {
            my ( $overwrite_ok, $overwrite_error ) = $self->_overwrite_state_file_in_place( $source, $target );
            return 1 if $overwrite_ok;
            if ( defined $overwrite_error && $overwrite_error ne '' ) {
                chomp $overwrite_error;
                $rename_error = "$rename_error; in-place overwrite fallback failed: $overwrite_error";
            }
        }
        for my $attempt ( 1 .. 10 ) {
            if ( -e $target ) {
                $self->_unlink_path($target)
                  or die "Unable to remove $target before Windows replace retry: $!";
                return 1 if $self->_rename_path( $source, $target );
                $rename_error = $!;
            }

            my ( $fallback_ok, $fallback_error ) = $self->_replace_path_via_powershell( $source, $target );
            return 1 if $fallback_ok;
            if ( defined $fallback_error && $fallback_error ne '' ) {
                chomp $fallback_error;
                $rename_error = "$rename_error; PowerShell Move-Item fallback failed: $fallback_error";
            }
            my ( $overwrite_ok, $overwrite_error ) = $self->_overwrite_state_file_in_place( $source, $target );
            return 1 if $overwrite_ok;
            if ( defined $overwrite_error && $overwrite_error ne '' ) {
                chomp $overwrite_error;
                $rename_error = "$rename_error; in-place overwrite fallback failed: $overwrite_error";
            }
            last if $attempt == 10;
            sleep 0.05;
            return 1 if $self->_rename_path( $source, $target );
            $rename_error = $!;
        }
    }

    $self->_unlink_path($source) if -e $source;
    die "Unable to rename $source to $target: $rename_error";
}

# _rename_path($source, $target)
# Wraps rename so tests can simulate platform-specific file replacement
# failures without mutating the real filesystem behavior globally.
# Input: source file path and destination file path.
# Output: true when the rename succeeds, false otherwise.
sub _rename_path {
    my ( $self, $source, $target ) = @_;
    return rename $source, $target;
}

# _unlink_path($path)
# Wraps unlink so tests can observe cleanup and Windows replacement retries in
# isolation from the caller.
# Input: one filesystem path string.
# Output: true when the path was removed, false otherwise.
sub _unlink_path {
    my ( $self, $path ) = @_;
    return unlink $path;
}

# _source_is_movable($source)
# Probes whether a prepared temporary file can be renamed, to tell a target
# collision (the rename failed only because the destination exists) from a
# locked source (the rename fails because the source itself cannot be moved).
# Renames the source to a probe name and straight back, so the file ends up
# exactly where it started; uses the real rename, not the _rename_path
# wrapper, so a test stubbing that wrapper to simulate a collision still sees
# the true movability of the file on disk.
# Input: temporary source path string.
# Output: true when the source renames away and back, false otherwise.
sub _source_is_movable {
    my ( $self, $source ) = @_;
    my $probe = $source . '.movable-probe';
    return 0 if !CORE::rename( $source, $probe );
    CORE::rename( $probe, $source )
      or die "Unable to restore $source after movability probe: $!";
    return 1;
}

# _overwrite_state_file_in_place($source, $target)
# Rewrites one runtime state target in place from the prepared temporary
# payload when Windows denies delete-or-move replacement but still permits a
# direct overwrite.
# Input: temporary source path and final state-file path.
# Output: boolean success flag and optional failure text string.
sub _overwrite_state_file_in_place {
    my ( $self, $source, $target ) = @_;
    return ( 0, '' ) if !$self->is_windows;
    open my $source_fh, '<', $source or return ( 0, "Unable to read $source for in-place overwrite: $!" );
    local $/;
    my $content = <$source_fh>;
    close $source_fh;
    open my $target_fh, '>', $target or return ( 0, "Unable to open $target for in-place overwrite: $!" );
    print {$target_fh} $content
      or return ( 0, "Unable to write $target during in-place overwrite: $!" );
    close $target_fh;
    $self->_unlink_path($source);
    return ( 1, '' );
}

# _open_file_descriptors()
# Lists the current process file-descriptor numbers from procfs or /dev/fd so
# detached runtime children can close inherited caller pipes safely.
# Input: none.
# Output: sorted list of descriptor integers.
sub _open_file_descriptors {
    my ($self) = @_;
    if ( is_windows() ) {
        # There is no /proc or /dev/fd on Windows, so there is no
        # directory to list descriptors from. Probe the CRT descriptor
        # table instead: a descriptor that duplicates is open, one that
        # does not is not. The bound is the common CRT table size; a
        # detached child only ever inherits low-numbered descriptors,
        # and the standard three are always found this way, so the
        # listing still includes stdin.
        my @fds;
        for my $fd ( 0 .. 1023 ) {
            my $handle;
            if ( open( $handle, '<&', $fd ) || open( $handle, '>&', $fd ) ) {
                push @fds, $fd;
                close $handle;
            }
        }
        return @fds;
    }
    my %seen;
    my @fds;
    for my $path ( Developer::Dashboard::ProcessSupervision::_fd_candidate_paths($self) ) {
        my ($fd) = $path =~ m{(\d+)\z};
        $fd += 0;
        next if $seen{$fd}++;
        push @fds, $fd;
    }
    return sort { $a <=> $b } @fds;
}

# _fd_candidate_paths()
# Returns procfs and devfs descriptor paths; isolated as a method so tests can
# supply duplicated directory entries on hosts without both descriptor trees.
# Input: none.
# Output: list of descriptor-path strings.
sub _fd_candidate_paths {
    my ($self) = @_;
    return ( glob('/proc/self/fd/*'), glob('/dev/fd/*') );
}

# _descriptor_is_inherited_pipe($fd)
# Returns whether one descriptor currently points at an inherited capture or
# IPC endpoint that a detached runtime child should close after stdio has been
# redirected.
# Input: descriptor integer.
# Output: boolean true when the descriptor target is an inherited pipe,
# socketpair, or anonymous kernel handle.
sub _descriptor_is_inherited_pipe {
    my ( $self, $fd, %args ) = @_;
    return 0 if !defined $fd || $fd !~ /^\d+$/;
    my $handle;
    open( $handle, '<&', $fd ) or open( $handle, '>&', $fd ) or return 0;
    my $pipe   = -p $handle ? 1 : 0;
    my $socket = -S $handle ? 1 : 0;
    close $handle;
    return 1 if $pipe;
    return 0 if !$args{close_ipc};
    return 1 if $socket;
    my $target = _fd_link_target($fd);
    return defined($target) && $target =~ /^anon_inode:/ ? 1 : 0;
}

# Linux anonymous kernel handles have no ordinary socket or pipe file type.
# Keep their procfs identity check while using portable fstat for other FDs.
sub _fd_link_target {
    my ($fd) = @_;
    my $target = readlink("/proc/self/fd/$fd");
    return defined $target ? $target : readlink("/dev/fd/$fd");
}

# _current_perl_command()
# Resolves a runnable Perl interpreter path for detached helper launches,
# including Windows sessions where $^X can point at a nonexistent local::lib
# shim path.
# Input: none.
# Output: executable path string for the current Perl interpreter.
sub _current_perl_command {
    my ($self) = @_;
    if ($self->is_windows) {
        return command_in_path('perl')     if command_in_path('perl');
        return command_in_path('perl.exe') if command_in_path('perl.exe');
    }
    return $^X if defined $^X && $^X ne '' && -f $^X;
    return command_in_path('perl')     if command_in_path('perl');
    return command_in_path('perl.exe') if command_in_path('perl.exe');
    return $^X;
}

# _perl_library_args()
# Builds literal Perl -I arguments for string-valued entries in the current
# interpreter's @INC, preserving its active module search path in native child
# processes that cannot inherit in-memory use lib changes. Relative entries are
# made absolute against the directory that loaded this helper. Every path is
# canonicalised (File::Spec->canonpath): on Windows @INC routinely mixes
# separators, because Strawberry Perl and local::lib PERL5LIB entries use
# forward slashes (e.g. C:\...\try\lib\perl5/MSWin32-x64-multi-thread), while
# the spawned child must receive the native form the dashboard's own path
# comparisons and the t/236 contract expect.
# Input: none; reads the current interpreter's @INC.
# Output: list of -I<path> argument strings; reference hooks are omitted because
#         they are not filesystem paths and cannot be passed to another Perl.
sub _perl_library_args {
    my ($self) = @_;
    my $base = $PERL_LIBRARY_BASE || getcwd();
    return map {
        my $path = $_;
        $path = File::Spec->rel2abs( $path, $base ) if !File::Spec->file_name_is_absolute($path);
        $path = File::Spec->canonpath($path);
        "-I$path";
    } grep { defined && !ref && length } @INC;
}

# _powershell_command()
# Resolves the PowerShell executable to invoke on Windows. Tries PATH under both
# spellings, then the SystemRoot install path, because a Windows host commonly has
# powershell.exe present at its standard location while PATH does not name it.
# Shared by RuntimeManager and CollectorRunner (DD-753): RuntimeManager previously
# hardcoded the bare string at four call sites and so failed through system() with
# an empty capture, while CollectorRunner resolved it and named the failure.
# Called as a plain function, not a method - it needs no object state.
# Input: none.
# Output: a usable PowerShell command string, or the empty string when none
#         resolves or the host is not Windows. Callers branch on empty and report
#         which executable was missing.
sub _powershell_command {
    return '' if !is_windows();
    return command_in_path('powershell')     if command_in_path('powershell');
    return command_in_path('powershell.exe') if command_in_path('powershell.exe');
    my $system_root = $ENV{SystemRoot} || 'C:\\Windows';
    my $fallback = File::Spec->catfile( $system_root, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe' );
    return $fallback if -f $fallback;
    return '';
}

# _taskkill_command()
# Resolves the taskkill executable _send_signal shells out to on
# Windows. A bare 'taskkill' handed to system() is resolved by
# CreateProcess, which only appends .exe, so a .bat on PATH is
# invisible to it - the t/09 fake taskkill.bat never ran and build
# #269 died reading the args file it never wrote (the real taskkill
# ran instead and exited 128 for the nonexistent pids; micro t/988
# proved it). Resolving here through command_in_path, which expands
# PATHEXT, finds the .bat, and the absolute path runs it through cmd.
# Falls back to System32 taskkill.exe when PATH cannot find it, and
# to the bare name when even that is absent, so callers that stub
# capture keep their existing behaviour. Called as a plain function,
# not a method - it needs no object state.
# Input: none.
# Output: taskkill path string (resolved, System32 fallback, or bare name).
sub _taskkill_command {
    return 'taskkill' if !is_windows();
    my $resolved = command_in_path('taskkill');
    return $resolved if defined $resolved && $resolved ne '';
    my $system_root = $ENV{SystemRoot} || 'C:\\Windows';
    my $fallback = File::Spec->catfile( $system_root, 'System32', 'taskkill.exe' );
    return $fallback if -f $fallback;
    return 'taskkill';
}

# _powershell_single_quote($value)
# Escapes one literal string for safe use in a single-quoted PowerShell
# argument position.
# Input: raw scalar string value.
# Output: single-quoted PowerShell literal string.
sub _powershell_single_quote {
    my ($value) = @_;
    $value = '' if !defined $value;
    $value =~ s/'/''/g;
    return "'$value'";
}

# Default procfs root; tests may use a private fixture directory so process
# metadata parsing is exercised on systems without Linux procfs.
our $PROCFS_ROOT = '/proc';

# _read_process_env_marker($pid, $key)
# Reads a specific environment variable from a running process when possible.
# Input: process id integer and env key string.
# Output: env value string or undef.
sub _read_process_env_marker {
    my ( $self, $pid, $key ) = @_;
    my $proc = "$PROCFS_ROOT/$pid/environ";
    return if !-r $proc;
    open my $fh, '<', $proc or return;
    local $/;
    my $env = scalar <$fh>;
    return if !defined $env || $env eq '';
    for my $pair ( split /\0/, $env ) {
        next if $pair !~ /^([^=]+)=(.*)$/s;
        return $2 if $1 eq $key;
    }
    return;
}

# _pid_namespace_id($pid)
# Reads the pid-namespace identity for one process from procfs when available.
# Input: process id integer.
# Output: namespace identity string or undef.
sub _pid_namespace_id {
    my ( $self, $pid ) = @_;
    my $path = "$PROCFS_ROOT/$pid/ns/pid";
    return if !-l $path;
    return readlink $path;
}

# Cached Win32 process-query imports, attempted once; a failed import is
# never retried, so a missing Win32 primitive degrades to kill(0) exactly
# once (the Watch.pm _windows_peek_named_pipe shape).
my $_WINDOWS_PROCESS_API;
my $_WINDOWS_PROCESS_API_FAILED;

# STILL_ACTIVE is the exit code GetExitCodeProcess reports for a process
# that has not exited; PROCESS_QUERY_LIMITED_INFORMATION is the access
# right OpenProcess needs to query it (micro t/997, solo #385).
my $_WINDOWS_STILL_ACTIVE              = 259;
my $_WINDOWS_QUERY_LIMITED_INFORMATION = 0x1000;

# _windows_process_api()
# Imports the four kernel32 functions the Windows liveness check needs,
# once, and caches them. Win32::API is loaded lazily so Unix legs never
# pay for it and a leg without it keeps working.
# Input: none.
# Output: hash reference of imported function objects, or undef when the
# import fails (callers fall back to kill(0)).
sub _windows_process_api {
    return $_WINDOWS_PROCESS_API if defined $_WINDOWS_PROCESS_API;
    return undef if $_WINDOWS_PROCESS_API_FAILED;
    my $api = eval {
        require Win32::API;
        my $open_process = Win32::API->new( 'kernel32', 'OpenProcess', 'NIN', 'Q' );
        die "OpenProcess import failed\n" if !defined $open_process;
        my $get_exit_code = Win32::API->new( 'kernel32', 'GetExitCodeProcess', 'QP', 'I' );
        die "GetExitCodeProcess import failed\n" if !defined $get_exit_code;
        my $get_process_id = Win32::API->new( 'kernel32', 'GetProcessId', 'Q', 'N' );
        die "GetProcessId import failed\n" if !defined $get_process_id;
        my $close_handle = Win32::API->new( 'kernel32', 'CloseHandle', 'Q', 'I' );
        die "CloseHandle import failed\n" if !defined $close_handle;
        {
            open_process   => $open_process,
            get_exit_code  => $get_exit_code,
            get_process_id => $get_process_id,
            close_handle   => $close_handle,
        };
    };
    if ( !$api ) {
        $_WINDOWS_PROCESS_API_FAILED = 1;
        return undef;
    }
    $_WINDOWS_PROCESS_API = $api;
    return $api;
}

# _process_exists_windows($pid)
# Windows-only liveness check. A bare kill(0) cannot be trusted here:
# Perl's kill(0) on Windows is OpenProcess-based, and OpenProcess rounds
# the requested pid DOWN to a multiple of 4 (Windows pids are multiples
# of 4), so kill(0, 3101) tests live pid 3100 and answers true - and a
# process object can linger after exit while some handle to it is still
# open, so the exit code must be checked too (round 42, t/09 test 209
# with fake loop pids 3101/3102; micro t/997 proved both traps in solo
# #385). All three must hold: the handle opened, GetProcessId on the
# handle is exactly the pid asked for, and the exit code is STILL_ACTIVE.
# The handle is closed on every path once opened: the values are read
# into Perl scalars first and CloseHandle runs before any of the verdict
# returns below, so there is no early return that can leak it. Called as
# a plain function, not a method - it needs no object state. When the
# Win32 imports are unavailable the check falls back to kill(0), so
# behaviour degrades to today's rather than dying.
# Input: process id integer.
# Output: boolean true when the process is really running.
sub _process_exists_windows {
    my ($pid) = @_;
    my $api = _windows_process_api();
    return kill( 0, $pid ) ? 1 : 0 if !$api;
    my $handle = $api->{open_process}->Call( $_WINDOWS_QUERY_LIMITED_INFORMATION, 0, $pid );
    return 0 if !$handle;
    my $real_pid = $api->{get_process_id}->Call($handle);
    my $code_buf = pack 'L', 0;
    my $ok = $api->{get_exit_code}->Call( $handle, $code_buf );
    my $code = $ok ? unpack( 'L', $code_buf ) : undef;
    $api->{close_handle}->Call($handle);
    return 0 if !defined $real_pid || $real_pid != $pid;
    return 0 if !defined $code;
    return $code == $_WINDOWS_STILL_ACTIVE ? 1 : 0;
}

# _process_exists($pid)
# Checks whether one process id still exists from the current runtime view.
# On Windows a bare kill(0) is not that check: OpenProcess rounds the pid
# down to a multiple of 4 and a lingering process object still opens, so
# _process_exists_windows verifies the handle, the real pid and the exit
# code instead (round 42, micro t/997). Unix keeps the bare kill(0),
# which is exact there.
# Input: process id integer.
# Output: boolean true when the process is really running.
sub _process_exists {
    my ( $self, $pid ) = @_;
    return _process_exists_windows($pid) if is_windows();
    return kill( 0, $pid ) ? 1 : 0;
}

1;

# _dashboard_core_helper_path($command)
# Resolves the private _dashboard-core helper that advertises one internal
# command, preferring the staged working copy over the shipped dist asset.
# $command is REQUIRED: both former per-class copies of this helper were
# identical apart from a default (web-foreground in RuntimeManager,
# collector-loop-foreground in CollectorRunner), and no caller in lib/ ever
# relied on either - every one passes the command it wants. A default that only
# tests exercise is behaviour that looks supported and is never proven, so the
# argument is now required and each call site states its own command (DD-669).
# Input: internal helper command string.
# Output: absolute helper path string.
sub _dashboard_core_helper_path {
    my ( $self, $command ) = @_;
    my $staged = File::Spec->catfile( $self->{paths}->home_runtime_root, 'cli', 'dd', '_dashboard-core' );
    return $staged if $self->_helper_file_supports_internal_command( $staged, $command );

    my $shipped = eval { Developer::Dashboard::InternalCLI::_helper_asset_path('_dashboard-core') };
    $shipped = '' if !defined $shipped;
    return $shipped if $self->_helper_file_supports_internal_command( $shipped, $command );

    return $staged;
}

# _helper_file_supports_internal_command($path, $command)
# Purpose: whether a staged or shipped helper file implements a given internal
#          command, decided by looking for the command name in its text.
# Input:   the file path, and the command name to look for
# Output:  1 when the file exists and mentions the command, 0 otherwise
#
# SHARED (DD-669). RuntimeManager and CollectorRunner carried this under the same
# name with the same behaviour - the only difference was that one assigned the
# match to a variable before returning it. Same name, same behaviour, two copies
# is the cheapest kind of divergence to remove and the easiest to let drift.
sub _helper_file_supports_internal_command {
    my ( $self, $path, $command ) = @_;
    return 0 if !defined $path || $path eq '' || !-f $path;
    return 0 if !defined $command || $command eq '';
    open my $fh, '<:raw', $path or return 0;
    local $/;
    my $content = <$fh>;
    CORE::close($fh) or return 0;
    return $content =~ /\Q$command\E/ ? 1 : 0;
}

# _same_pid_namespace($pid)
# Purpose: whether a pid lives in the same PID namespace as this process, so a
#          liveness answer about it can be trusted.
# Input:   the pid to check
# Output:  1 when the namespaces match or either is unknown, 0 when they differ
#
# SHARED (DD-669). RuntimeManager and CollectorRunner carried this under the same
# name with the same behaviour; the only difference was that RuntimeManager
# reached the current namespace through a one-line _current_pid_namespace_id
# wrapper and CollectorRunner called _pid_namespace_id($$) directly. The wrapper
# is gone with this extraction - it had exactly one caller, this sub.
#
# UNKNOWN IS TRUSTED, DELIBERATELY: a namespace id we cannot read must not make a
# live process look dead, so an unreadable id on either side answers 1.
sub _same_pid_namespace {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    my $current = $self->_pid_namespace_id($$);
    my $target  = $self->_pid_namespace_id($pid);
    return 1 if !defined $current || $current eq '';
    return 1 if !defined $target  || $target eq '';
    return $current eq $target ? 1 : 0;
}

# _close_inherited_fds(%args)
# Purpose: close file descriptors this process inherited but must not keep, so a
#          detached child cannot hold a parent's pipe open.
# Input:   keep => [fd, ...] to spare; preserve_harness => 1 to do nothing under
#          an in-process TAP harness; further args reach the inherited-pipe test
# Output:  1 always
#
# SHARED (DD-669), and it is a UNION rather than a choice. The two copies were
# identical except that RuntimeManager's carried the preserve_harness guard and
# CollectorRunner's built its keep-set with an explicit loop instead of map/grep -
# a style difference, not a behavioural one. preserve_harness is an ARGUMENT, and
# exactly one caller in the tree passes it (RuntimeManager, for in-process TAP),
# so keeping the guard costs CollectorRunner nothing: its single caller passes
# close_ipc and never reaches the early return.
#
# This card first classified it as a genuine behavioural difference needing a
# rename. Reading the callers showed one version is a strict superset of the
# other, which is why it is reconciled instead.
sub _close_inherited_fds {
    my ( $self, %args ) = @_;
    return 1 if $args{preserve_harness} && $ENV{HARNESS_ACTIVE};
    my %keep = map { $_ => 1 } grep { defined $_ && $_ =~ /^\d+$/ } @{ $args{keep} || [] };
    $keep{0} = 1;
    $keep{1} = 1;
    $keep{2} = 1;
    for my $fd ( $self->_open_file_descriptors ) {
        next if $keep{$fd};
        next if !$self->_descriptor_is_inherited_pipe( $fd, %args );
        POSIX::close($fd);
    }
    return 1;
}

__END__

=head1 NAME

Developer::Dashboard::ProcessSupervision - process-supervision helpers shared by the runtime manager and the collector runner

=head1 PURPOSE

Hold the one definition of each low-level helper that RuntimeManager and
CollectorRunner both need: deciding whether a pid is alive, forking and reaping
children, reading a process's namespace and environment, replacing state
files atomically, and resolving the PowerShell executable to invoke on Windows.

=head1 WHY IT EXISTS

Both modules supervise processes, and both grew their own copy of the same
helpers. The copies did not merely cost duplicated maintenance - they had to
receive the same fix independently more than once, across separate pieces of
work, until a standing test sweep was added to catch the next recurrence. Worse,
the duplication hid a subtler problem: two copies can be identical in code while
only one of them has a test, so both files report full coverage and one outcome
is never exercised.

=head1 WHEN TO USE

Import a helper here when a module needs to ask whether a process is running,
start or reap a child, inspect a process through the platform's process
interface, or replace a state file without a reader seeing a partial write.

Do NOT move a helper here because two modules happen to have one with the same
name. Some same-named helpers differ deliberately between consumers; sharing one
of those imposes a single behaviour on both and no existing test will object.

=head1 HOW TO USE

    use Developer::Dashboard::ProcessSupervision qw(_pid_is_running _reap_child_process);

    # call sites are unchanged - these arrive as methods on the importing class
    return if !$self->_pid_is_running($pid);

Import only what the module uses. Nothing is exported by default.

=head1 WHAT USES IT

C<Developer::Dashboard::RuntimeManager> and
C<Developer::Dashboard::CollectorRunner>.

=head1 EXAMPLES

Asking whether a supervised child is still alive, where a bare C<kill 0> would
report a zombie as running:

    if ( !$self->_pid_is_running($pid) ) {
        $self->_restart_collector($name);
    }

Replacing a cached state file so a concurrent reader sees the whole old file or
the whole new one, never a partial write:

    $self->_replace_state_file( $path, $payload );

=cut
