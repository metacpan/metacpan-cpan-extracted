package Developer::Dashboard::ProcessSupervision;

use strict;
use warnings;

our $VERSION = '4.31';

use Exporter 'import';

use Capture::Tiny qw(capture);
use File::Spec;
use Time::HiRes qw(sleep);

# POSIX WITHOUT IMPORTING, deliberately. Both source modules do
# `use POSIX qw(close setsid strftime)`, and importing `close` SHADOWS the
# built-in - which is why their code says CORE::close($fh) when it means the
# ordinary one. Nothing here needs that hazard: the only POSIX call is
# fully qualified, so the empty import list keeps the built-in intact.
use POSIX ();

use Developer::Dashboard::Platform qw(command_in_path is_windows);

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
    _current_perl_command
    _dashboard_core_helper_path
    _descriptor_is_inherited_pipe
    _fork_process
    _open_file_descriptors
    _overwrite_state_file_in_place
    _pid_is_running
    _pid_namespace_id
    _powershell_command
    _powershell_single_quote
    _process_exists
    _read_process_env_marker
    _reap_child_process
    _rename_path
    _replace_state_file
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

# _fork_process()
# Wraps Perl fork so tests can drive parent and child runtime paths directly.
# Input: none.
# Output: child pid in the parent, zero in the child, or undef on failure.
sub _fork_process {
    return fork();
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
    if ( -e $source ) {    # uncoverable branch false the source pending file still exists when the overwrite path reaches this cleanup
        $self->_unlink_path($source) or undef;
    }
    return ( 1, '' );
}

# _open_file_descriptors()
# Lists the current process file-descriptor numbers from procfs or /dev/fd so
# detached runtime children can close inherited caller pipes safely.
# Input: none.
# Output: sorted list of descriptor integers.
sub _open_file_descriptors {
    my ($self) = @_;
    my %seen;
    my @fds;
    for my $path ( glob('/proc/self/fd/*'), glob('/dev/fd/*') ) {
        next if $path !~ m{(?:/proc/self/fd|/dev/fd)/(\d+)\z};    # uncoverable branch true the two globs only ever yield numeric descriptor entries under these directories
        my $fd = $1 + 0;
        next if $seen{$fd}++;
        push @fds, $fd;
    }
    return sort { $a <=> $b } @fds;
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
    my $proc_target = readlink("/proc/self/fd/$fd");
    my $dev_target  = readlink("/dev/fd/$fd");
    my $target = defined $proc_target ? $proc_target : $dev_target;
    return 0 if !defined $target || $target eq '';    # uncoverable condition right readlink returns a non-empty path or undef, never an empty string
    return 1 if $target =~ /^pipe:/;
    return 0 if !$args{close_ipc};
    return $target =~ /^(?:socket:|anon_inode:)/ ? 1 : 0;
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

# _read_process_env_marker($pid, $key)
# Reads a specific environment variable from a running process when possible.
# Input: process id integer and env key string.
# Output: env value string or undef.
sub _read_process_env_marker {
    my ( $self, $pid, $key ) = @_;
    my $proc = "/proc/$pid/environ";
    return if !-r $proc;
    # The readability guard above already excluded an unreadable environ file,
    # so open() failing here cannot be reached on this test host.
    open my $fh, '<', $proc or return;    # uncoverable branch true
    local $/;
    my $env = scalar <$fh>;
    # A readable environ file always slurps back a defined, non-empty string.
    return if !defined $env || $env eq '';    # uncoverable condition left
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
    my $path = "/proc/$pid/ns/pid";
    return if !-l $path;
    return readlink $path;
}

# _process_exists($pid)
# Checks whether one process id still exists from the current runtime view.
# Input: process id integer.
# Output: boolean true when signal 0 succeeds.
sub _process_exists {
    my ( $self, $pid ) = @_;
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
    # closing a freshly read, read-only handle does not fail on the test host
    CORE::close($fh) or return 0;    # uncoverable branch true
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
