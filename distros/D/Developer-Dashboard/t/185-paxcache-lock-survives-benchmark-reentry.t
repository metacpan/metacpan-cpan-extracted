#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Time::HiRes qw(sleep);
use POSIX ();

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PaxCache;

# Hermetic runtime: isolated home so PathRegistry::home_cache_root resolves
# into a controlled scratch tree, never the real ~/.developer-dashboard.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

# write_fake_pax(%opts)
# Same fake-pax pattern t/181-paxcache-coverage.t already uses: a stub
# script that logs one line per invocation (pid + argv) and, after an
# optional sleep, writes a fixed-content "binary" to its -o target. The
# sleep is what makes this test able to observe a genuinely still-running
# compile rather than a completed one.
# Input: optional sleep (seconds) and log_file path.
# Output: (bin_dir, pax_path, log_file) path strings.
sub write_fake_pax {
    my (%opts) = @_;
    my $bin_dir       = tempdir( CLEANUP => 1 );
    my $pax_path      = File::Spec->catfile( $bin_dir, 'pax' );
    my $sleep_seconds = $opts{sleep} || 0;
    my $log_file      = $opts{log_file} || File::Spec->catfile( $bin_dir, 'pax-calls.log' );
    open my $fh, '>', $pax_path or die "Unable to write fake pax: $!";
    print {$fh} "#!/usr/bin/env perl\n";
    print {$fh} "open my \$log, '>>', '$log_file' or die \$!;\n";
    print {$fh} "print {\$log} \"\$\$ \@ARGV\\n\"; close \$log;\n";
    print {$fh} "sleep($sleep_seconds);\n" if $sleep_seconds;
    print {$fh} "my \$out;\n";
    print {$fh} "for (my \$i = 0; \$i < \@ARGV; \$i++) { \$out = \$ARGV[\$i+1] if \$ARGV[\$i] eq '-o'; }\n";
    print {$fh} "if (\$out) { open my \$ofh, '>', \$out or die \$!; print {\$ofh} \"fake-compiled-binary\\n\"; close \$ofh; chmod 0755, \$out; }\n";
    close $fh;
    chmod 0755, $pax_path;
    return ( $bin_dir, $pax_path, $log_file );
}

sub source_file_with_content {
    my ($content) = @_;
    my $dir  = tempdir( CLEANUP => 1 );
    my $path = File::Spec->catfile( $dir, 'entrypoint' );
    open my $fh, '>', $path or die $!;
    print {$fh} $content;
    close $fh;
    return $path;
}

# DD-882 (severe runaway found and fixed during this ticket's own
# vulnerability-scan gate): the compile lock file used to be written with
# the ORIGINAL CALLER's own pid ($$ inside _maybe_spawn_compile), which
# exits almost immediately after spawning the detached background compile
# (it only waitpid()s its own short-lived first child, then finishes its
# real command and terminates normally). _lock_is_stale's kill(0,$pid)
# check on that now-dead pid therefore reported the lock stale within
# moments of it being created, even though the REAL background compile (a
# different pid - the double-forked grandchild) was still genuinely
# running - so a second, third, fourth... caller each believed the lock
# was free, deleted it, and started their OWN real duplicate compile,
# unboundedly. This is exactly what happens when PAX's own build-time
# benchmark step (Benchmark.pm's live-timing run) executes the entrypoint
# it is compiling as a side effect of timing it, re-entering this exact
# self-compile hook on a source that is itself mid-compile.
#
# This test simulates that re-entry directly: resolve() is called once
# (the "outer" invocation, spawning a slow fake compile), then called
# AGAIN shortly after while the fake compile is still sleeping (the
# "benchmark re-entry"). The fake pax logs one line per real invocation it
# receives, so the fix is proven by that log staying at exactly one line
# throughout the sleep window - a regression would show two or more lines,
# one per duplicate compile the second (or later) resolve() call wrongly
# started.
{
    my ( $bin_dir, $pax_path, $log_file ) = write_fake_pax( sleep => 3 );
    local $ENV{PATH} = "$bin_dir:$ENV{PATH}";
    my $source = source_file_with_content("#!/usr/bin/env perl\nprint 'outer';\n");

    # The outer resolve() call MUST happen in a genuinely separate,
    # short-lived process - exactly like the real bug, where the "outer"
    # dashboard invocation and the "benchmark re-entry" invocation are two
    # distinct OS processes, the first of which exits almost immediately.
    # Calling resolve() twice from this SAME test process would write the
    # test's own (obviously-still-alive) pid into the lock both times,
    # making _lock_is_stale report "not stale" for the wrong reason
    # regardless of whether the fix is present - a test that could not
    # actually distinguish fixed from broken.
    my $outer_pid = fork();
    die "fork failed: $!" if !defined $outer_pid;
    if ( $outer_pid == 0 ) {
        my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
        $cache->resolve($source);
        POSIX::_exit(0);
    }
    waitpid( $outer_pid, 0 );
    ok( !kill( 0, $outer_pid ), 'the outer resolve()-calling process has genuinely exited, like a real dashboard invocation does' );

    # Give the detached background compile time to actually start (write
    # its first log line) before the "re-entry" call below - matching the
    # real timing where the benchmark subprocess starts a beat after the
    # outer dashboard invocation.
    my $waited = 0;
    while ( $waited < 5 && !-s $log_file ) {
        sleep(0.1);
        $waited += 0.1;
    }
    ok( -s $log_file, 'the background compile has genuinely started (fake pax wrote its first log line)' );

    # The re-entry: a second resolve() call for the SAME source, from a
    # DIFFERENT process (this test process itself, distinct from the
    # already-exited outer one above), while the first compile is still
    # sleeping (still mid-build). Before the fix, this would see a "stale"
    # lock (the outer process's pid, now genuinely dead) and start a second
    # real fake-pax invocation, appending a second line to $log_file.
    my $cache = Developer::Dashboard::PaxCache->new( paths => $paths, pax_bin => $pax_path );
    my $reentry_result = $cache->resolve($source);
    is( $reentry_result, undef, 'benchmark re-entry resolve(): still a miss (compile not finished), returns undef' );

    # Give any WRONGLY-spawned duplicate compile the same chance to log
    # that the legitimate one got, so a regression is not hidden by a
    # timing race in the test's own favor.
    sleep(0.5);

    open my $fh, '<', $log_file or die "Unable to read $log_file: $!";
    my @lines = <$fh>;
    close $fh;
    is( scalar(@lines), 1,
        'exactly ONE real compile was ever started - the re-entry did not spawn a duplicate' )
      or diag( "Log content:\n" . join( '', @lines ) );

    # Let the real (single) fake compile finish and confirm the cache
    # genuinely ends up populated - the fix does not just suppress
    # duplicates, the original compile still completes and installs
    # normally.
    sleep(3);
    my $final_result = $cache->resolve($source);
    ok( defined $final_result && -x $final_result,
        'after the compile finishes, resolve() returns the installed executable binary' );
}

done_testing;

__END__

=head1 NAME

t/185-paxcache-lock-survives-benchmark-reentry.t - PaxCache compile lock
survives re-entry while the real compile is still running

=head1 PURPOSE

Proves the fix for a severe DD-882 regression: PaxCache's compile lock file
used to record the wrong process's pid (the short-lived original caller,
not the long-lived detached background compile), so C<_lock_is_stale>
falsely reported an in-progress compile as dead almost immediately, and any
later C<resolve()> call for the same source - most dangerously, PAX's own
build-time benchmark step executing the very entrypoint it is compiling -
would delete the "stale" lock and start a genuine duplicate compile,
unboundedly.

=head1 WHY IT EXISTS

Discovered live during DD-882's vulnerability-scan gate: PAX's build-time
benchmark step timing the entrypoint it was compiling caused dozens of real
concurrent C<pax build> processes on the host within minutes, each spawning
its own benchmark, each spawning another compile, consuming enough memory
to OOM-kill an unrelated background job. This test is the permanent
regression guard for the fix (rewriting the lock file with the detached
grandchild's real pid, inside C<_spawn_background_compile>, before the
still-alive first child exits) - simulating the exact re-entry shape
without needing a real multi-minute PAX compile or the actual benchmark
machinery.

=head1 WHEN TO USE

Run this file whenever PaxCache's lock-claiming or lock-staleness logic
changes (C<_maybe_spawn_compile>, C<_spawn_background_compile>,
C<_lock_is_stale>), or whenever the self-compile hook in bin/dashboard or
bin/d2 changes in a way that could alter how often C<resolve()> is called
for the same source in quick succession.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/185-paxcache-lock-survives-benchmark-reentry.t

The test uses a fake C<pax> stub (matching t/181's own pattern) that sleeps
for a few seconds before writing its fake binary, so a second C<resolve()>
call issued while it is still sleeping exercises the exact re-entry window
that exposed the real bug - without needing a genuine multi-minute compile.

=head1 WHAT USES IT

The suite, through C<prove -lr t>. Its subject is
L<Developer::Dashboard::PaxCache>'s lock mechanics specifically, as
consumed by C<bin/dashboard>'s and C<bin/d2>'s self-compile hooks and by
any other future caller of C<resolve()> that might re-enter it while a
compile is in flight.

=head1 EXAMPLES

Watching this test fail on a reintroduced regression: revert the lock
rewrite in C<_spawn_background_compile> back to leaving the original
caller's pid in place, then rerun - the "exactly ONE real compile" assertion
fails with two or more log lines, showing the duplicate the re-entry
started.

Watching it pass on the fix: the fake pax's log file holds exactly one line
after both C<resolve()> calls and the sleep window, and the final
C<resolve()> call returns a real, executable installed binary once the
single genuine compile finishes.

=cut
