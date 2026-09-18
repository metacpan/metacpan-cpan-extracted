package Developer::Dashboard::PaxCache;

use strict;
use warnings;

our $VERSION = '4.45';

use Digest::MD5 ();
use File::Spec ();
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use POSIX qw(setsid);
use Developer::Dashboard::Platform qw(command_in_path is_windows);
use Developer::Dashboard::PathsRegistryArg qw(require_paths_arg);

# new(%args)
# Constructs a PAX compile-cache resolver bound to a path registry.
# Input: paths object, plus optional pax_bin override for tests.
# Output: Developer::Dashboard::PaxCache object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = require_paths_arg(%args);
    return bless {
        paths   => $paths,
        pax_bin => $args{pax_bin},
    }, $class;
}

# resolve($source_path)
# Decides how one Perl source file should run this invocation: a cached
# PAX-compiled binary path on a fresh MD5-matched hit, or undef (meaning
# "run interpreted") after triggering at most one non-blocking background
# compile on a miss or stale cache. Never blocks the caller, never reuses a
# stale binary, and never lets overlapping calls on the same source each
# spawn their own redundant compile (owner correction 2026-09-15, msg
# #1975 - "make sure to prevent this disaster").
# Input: source file path string.
# Output: cached binary path string, or undef.
sub resolve {
    my ( $self, $source_path ) = @_;

    return undef if !defined $source_path || $source_path eq '' || !-f $source_path;

    my $pax_bin = $self->_pax_bin;
    return undef if !defined $pax_bin;

    # Cascades from _source_md5's own open() failure, itself annotated
    # uncoverable (root bypasses permission checks on the test host, so a
    # file that just passed -f above cannot fail open).
    my $md5 = $self->_source_md5($source_path);
    return undef if !defined $md5;    # uncoverable branch true

    my $key       = $self->_cache_key($source_path);
    my $cache_dir = $self->_cache_dir;
    my $md5_file  = File::Spec->catfile( $cache_dir, "$key.md5" );
    my $bin_file  = File::Spec->catfile( $cache_dir, "$key.pax" );
    my $lock_file = File::Spec->catfile( $cache_dir, "$key.compiling" );

    my $cached_md5 = $self->_read_file($md5_file);
    if ( defined $cached_md5 && $cached_md5 eq $md5 && -x $bin_file ) {
        return $bin_file;
    }

    # DD-936: opt-in kill switch, owner-specified 2026-09-17 (Q-167: option A),
    # put in place after observing pax build burn ~66% CPU for 90+ seconds per
    # invocation in a live container merely from running 'dashboard
    # init'/'d2 init'. Scoped to ONLY the spawn-a-new-compile path, not the
    # cache-hit check above: an already-existing, valid cache hit (e.g. one
    # seeded directly, or left over from an earlier DD_PAX=on compile) is
    # still reported normally regardless of DD_PAX, so bin/d2's own
    # designed self-exec feature (DD-882) keeps working off an existing
    # binary. Only the act of SPAWNING a brand new background compile - the
    # actual CPU cost that was observed - requires DD_PAX=on. Default is
    # OFF: the user does not set anything to keep new compiles disabled,
    # only sets DD_PAX=on to enable them. Independent of, and does not
    # require, DD-935's compile-time/CPU fix landing first.
    return undef if ( $ENV{DD_PAX} // '' ) ne 'on';

    $self->_maybe_spawn_compile(
        source_path => $source_path,
        pax_bin     => $pax_bin,
        md5         => $md5,
        md5_file    => $md5_file,
        bin_file    => $bin_file,
        lock_file   => $lock_file,
    );
    return undef;
}

# _pax_bin()
# Resolves the pax executable, honoring a constructor override for tests.
# PAX is vendored into this repository (Developer::Dashboard::Pax::*,
# 2026-09-15) specifically so this resolution never depends on a separate
# PAX checkout or the caller's shell PATH - the staged internal 'pax'
# command (share/private-cli/pax) is tried first; an external PATH lookup
# remains only as a last-resort fallback.
# Input: none.
# Output: absolute pax path string, or undef when unavailable.
sub _pax_bin {
    my ($self) = @_;
    return $self->{pax_bin} if defined $self->{pax_bin};
    require Developer::Dashboard::InternalCLI;
    my $staged = eval {
        Developer::Dashboard::InternalCLI::ensure_helper( paths => $self->{paths}, name => 'pax' );
        Developer::Dashboard::InternalCLI::helper_path( paths => $self->{paths}, name => 'pax' );
    };
    return $staged if defined $staged && -f $staged;
    return command_in_path('pax');
}

# _source_md5($source_path)
# Computes the MD5 hex digest of a source file's current contents.
# Input: source file path string.
# Output: hex digest string, or undef if the file cannot be read.
sub _source_md5 {
    my ( $self, $source_path ) = @_;
    open my $fh, '<:raw', $source_path or return undef;    # uncoverable branch true
    my $md5 = Digest::MD5->new;
    $md5->addfile($fh);
    close $fh;
    return $md5->hexdigest;
}

# _cache_key($source_path)
# Derives a filesystem-safe, collision-resistant cache key for a source path.
# Input: source file path string.
# Output: hex digest string suitable for use in a filename.
sub _cache_key {
    my ( $self, $source_path ) = @_;
    return Digest::MD5::md5_hex($source_path);
}

# _cache_dir()
# Returns the per-machine PAX cache directory, creating it if needed.
# Input: none.
# Output: directory path string.
sub _cache_dir {
    my ($self) = @_;
    my $dir = File::Spec->catdir( $self->{paths}->home_cache_root, 'pax' );
    if ( !-d $dir ) {
        require File::Path;
        File::Path::make_path($dir);
    }
    return $dir;
}

# _read_file($path)
# Reads one small cache metadata file's entire contents.
# Input: file path string.
# Output: file contents string, or undef if the file does not exist.
sub _read_file {
    my ( $self, $path ) = @_;
    return undef if !-f $path;
    open my $fh, '<:raw', $path or return undef;    # uncoverable branch true
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# _maybe_spawn_compile(%args)
# Claims the exclusive right to compile one source file's cache entry and, if
# claimed successfully, spawns a detached background PAX compile. Uses
# sysopen with O_CREAT|O_EXCL on the lock file so the filesystem itself
# arbitrates "exactly one winner" among any number of overlapping callers -
# a plain existence check would have a race window between the check and the
# write that this project's own lesson set (never write a value from a plan,
# only from what actually happened) exists to avoid repeating.
# Input: named args - source_path, pax_bin, md5, md5_file, bin_file,
# lock_file.
# Output: true if a compile was spawned, false if one was already in flight
# or already stale-but-alive.
sub _maybe_spawn_compile {
    my ( $self, %args ) = @_;

    if ( $self->_lock_is_stale( $args{lock_file} ) ) {
        unlink $args{lock_file};
    }

    my $claimed = sysopen( my $lock_fh, $args{lock_file}, O_CREAT | O_EXCL | O_WRONLY );
    if ( !$claimed ) {
        # Another invocation already holds the lock and is compiling this
        # exact source - do not spawn a second, redundant compile.
        return 0;
    }
    print {$lock_fh} $$;
    close $lock_fh;

    $self->_spawn_background_compile(%args);
    return 1;
}

# _lock_is_stale($lock_file)
# Determines whether an existing lock file's recorded PID is no longer
# alive, mirroring this project's own coverage-gate lock-holder check (a
# self-contained PID-in-file comparison, no /proc dependency).
# Input: lock file path string.
# Output: boolean true when the lock exists but its owning process is dead.
sub _lock_is_stale {
    my ( $self, $lock_file ) = @_;
    return 0 if !-f $lock_file;
    # $pid undef only happens if _read_file's own open() fails, which is
    # itself annotated uncoverable (root bypasses permission checks on the
    # test host, so a file that just passed -f above cannot fail open).
    my $pid = $self->_read_file($lock_file);
    return 1 if !defined $pid || $pid !~ /^\d+\z/;    # uncoverable condition left
    return kill( 0, $pid ) ? 0 : 1;
}

# _spawn_background_compile(%args)
# Detaches a child process that runs `pax build` for one source file and
# atomically installs the resulting binary plus its MD5 marker on success,
# then removes the compile lock. Uses a double-fork so the calling process
# never waits on or reaps the compile, and the compile itself is immune to
# the calling terminal/session going away.
# Input: named args - source_path, pax_bin, md5, md5_file, bin_file,
# lock_file.
# Output: none; never returns on the grandchild path (it always exits).
sub _spawn_background_compile {
    my ( $self, %args ) = @_;

    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-585/589-593/597,
    # DD-670). waitpid below reads the reaped first-child's status into $?,
    # and without this guard that value leaks into whatever the dashboard
    # dispatch caller reads next.
    local $?;

    # The test host is Linux, never Windows.
    if ( is_windows() ) {    # uncoverable branch true
        $self->_spawn_background_compile_windows(%args);    # uncoverable statement
        return;                                              # uncoverable statement
    }

    # From here down: everything reached only on the child side of a fork()
    # (the $pid==0 / $grandchild==0 paths) runs in a process that terminates
    # via POSIX::_exit(), which bypasses Perl's normal global-destruction/END
    # phase - the phase Devel::Cover flushes a process's counters from. Every
    # one of those statements genuinely executes on every real compile
    # (proven by AC-1/AC-2 waiting on and observing the compiled output file)
    # but is structurally invisible to this coverage instrument. fork(2)
    # itself is also treated as uncoverable here: it does not fail for a
    # process under its limits on the test host.
    my $pid = fork();
    if ( !defined $pid ) {    # uncoverable branch true
        unlink $args{lock_file};    # uncoverable statement
        return;                     # uncoverable statement
    }
    if ( $pid > 0 ) {    # uncoverable branch false
        waitpid( $pid, 0 );
        return;
    }

    # First child: detach into its own session so it survives the parent
    # dashboard invocation exiting, then fork again (the classic double-fork)
    # so the caller's waitpid above reaps this short-lived first child
    # immediately rather than the long-running grandchild. setsid() alone
    # only detaches the process/session group (relevant to signal delivery);
    # it does NOT redirect file descriptors, so without the explicit
    # redirects below this process (and any `pax build` subprocess it later
    # spawns via system()) would keep writing live build progress straight
    # into the calling terminal/pipe - discovered live when this cache
    # started covering bin/dashboard itself (DD-882), which made every
    # cache-miss invocation of ANY command visibly leak PAX's own progress
    # output. Matches the established detach pattern already used by
    # ActionRunner's own background-action path (open STDIN from /dev/null,
    # STDOUT/STDERR to a log file, never left connected to the caller).
    setsid();    # uncoverable statement
    my $log_file = $args{lock_file};    # uncoverable statement
    $log_file =~ s/\.compiling\z/.log/;    # uncoverable statement
    open STDIN, '<', File::Spec->devnull();    # uncoverable statement
    open STDOUT, '>>', $log_file;              # uncoverable statement
    open STDERR, '>>', $log_file;              # uncoverable statement
    my $grandchild = fork();         # uncoverable statement
    # uncoverable statement
    # uncoverable branch true
    # uncoverable branch false
    if ( !defined $grandchild ) {
        unlink $args{lock_file};    # uncoverable statement
        POSIX::_exit(1);            # uncoverable statement
    }
    # uncoverable statement
    # uncoverable branch true
    # uncoverable branch false
    if ( $grandchild > 0 ) {
        # DD-882 (severe runaway found and fixed during this ticket's own
        # vulnerability-scan gate): the lock file was written with $$ back in
        # _maybe_spawn_compile - the ORIGINAL CALLER's pid, not any
        # background process's. That caller returns and exits almost
        # immediately (it only ever waitpid()s on this short-lived first
        # child, then falls through to finish its own real command and
        # terminate normally), so _lock_is_stale's kill(0,$pid) check on
        # that now-dead pid reports the lock stale within moments of it
        # being created - even though the actual compile (this fork's own
        # child, $grandchild) is still genuinely running. Any later caller
        # then deletes the "stale" lock and starts a SECOND real compile,
        # which repeats the same mistake, unboundedly. Observed live: PAX's
        # own build-time benchmark step (Benchmark.pm's live-timing run)
        # invokes the entrypoint being compiled as a side effect of timing
        # it, re-entering this exact self-compile hook on a source that is
        # itself mid-compile - within minutes this produced dozens of
        # concurrent real `pax build` processes on the host, each spawning
        # its own benchmark, each spawning another compile. Rewriting the
        # lock here - after the double-fork, in the still-alive first child,
        # naming $grandchild instead - closes the race: waitpid() in the
        # true parent (the _maybe_spawn_compile caller) blocks until THIS
        # process exits, so the rewrite is guaranteed to land before that
        # caller ever returns control to whatever invoked resolve().
        # uncoverable statement
        # uncoverable branch true
        # uncoverable branch false
        if ( open my $lock_fh, '>', $args{lock_file} ) {
            print $lock_fh $grandchild;    # uncoverable statement
            close $lock_fh;                  # uncoverable statement
        }
        POSIX::_exit(0);    # uncoverable statement
    }

    $self->_run_compile_and_install(%args);    # uncoverable statement
    POSIX::_exit(0);                           # uncoverable statement
}

# _spawn_background_compile_windows(%args)
# Windows has no fork/setsid; detach via a background system() call instead,
# mirroring CollectorRunner's own Windows background-spawn precedent.
# Input: named args - source_path, pax_bin, md5, md5_file, bin_file,
# lock_file.
# Output: none.
sub _spawn_background_compile_windows {
    my ( $self, %args ) = @_;
    my $pid = fork();
    if ( !defined $pid ) {    # uncoverable branch true
        unlink $args{lock_file};    # uncoverable statement
        return;                     # uncoverable statement
    }
    if ( $pid == 0 ) {    # uncoverable branch true
        $self->_run_compile_and_install(%args);    # uncoverable statement
        POSIX::_exit(0);                           # uncoverable statement
    }
    return;
}

# _run_compile_and_install(%args)
# Runs the actual pax build and, on success, atomically installs the new
# binary and its MD5 marker before releasing the compile lock.
# Input: named args - source_path, pax_bin, md5, md5_file, bin_file,
# lock_file.
# Output: none.
sub _run_compile_and_install {
    my ( $self, %args ) = @_;

    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-585/589-593/597,
    # DD-670). system() below sets $?, and this sub's own caller (the
    # grandchild path of _spawn_background_compile, which never returns to
    # anything reading $?) must not have that value leak past this sub.
    local $?;

    my $temp_out = "$args{bin_file}.tmp.$$";
    system( $args{pax_bin}, 'build', $args{source_path}, '-o', $temp_out );
    my $exit_code = $? >> 8;

    if ( $exit_code == 0 && -f $temp_out ) {
        chmod 0755, $temp_out;
        rename $temp_out, $args{bin_file};
        # uncoverable branch false
        if ( open my $mfh, '>', $args{md5_file} ) {
            print {$mfh} $args{md5};
            close $mfh;
        }
    }
    else {
        unlink $temp_out;
    }

    unlink $args{lock_file};
    return;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PaxCache - MD5-keyed, non-blocking, per-machine PAX compile cache

=head1 PURPOSE

Decides, for one Perl source file at a time, whether the current invocation
should run a cached PAX-compiled standalone binary or fall back to the
normal interpreted path - and if the cache is missing or stale, triggers at
most one detached background compile so a later invocation can benefit,
without ever blocking the invocation that discovered the cache was stale.

=head1 WHY IT EXISTS

DD-871/DD-872 measured that PAX (a sibling adaptive Perl compiler/packager)
can compile this project's CLI entrypoints cleanly and run them roughly 36x
faster than interpreted Perl. DD-877 turns that measurement into a real,
safe caching layer: correctness only holds if a compile never blocks the
user (owner decision, Q-157) and if overlapping invocations of the same
stale source never each spawn their own redundant compile process - a
defect the owner explicitly flagged as "make sure to prevent this disaster"
(Telegram msg #1975, 2026-09-15) after asking what would happen if a second
invocation arrived while the first invocation's background compile was
still running.

=head1 WHEN TO USE

Any internal CLI command that wants to transparently benefit from a PAX
compiled binary, once one exists and is fresh, calls C<resolve()> with its
own source file's path before deciding how to run itself.

=head1 HOW TO USE

    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths );
    my $binary_path = $cache->resolve('/path/to/share/private-cli/ps1');
    if ( defined $binary_path ) {
        exec { $binary_path } $binary_path, @ARGV;
    }
    # else: fall through to the normal interpreted dispatch path.

=head1 WHAT USES IT

C<bin/dashboard>'s C<_exec_switchboard_command> calls this immediately
before its existing C<command_argv_for_path> resolution, currently scoped
to the C<ps1> command only as a proof of concept under epic DDE-002.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::PaxCache -e 1

Do a direct compile-and-load check against the module from a source
checkout.

Example 2:

  prove -lv t/181-paxcache-coverage.t

Run the focused regression tests that exercise cache-hit, cache-miss,
stale-MD5, no-pax-installed, and the overlapping-invocation concurrency
guard directly.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying
on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite
before release.

=for comment FULL-POD-DOC END

=cut
