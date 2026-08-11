#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL::rename override must be installed before
# Developer::Dashboard::Collector is compiled so the module's own rename call
# resolves through this intercept. $FAIL_RENAME is a test-controlled switch:
# when it is true the override reports a rename failure, otherwise it delegates
# to the real rename so unrelated renames keep working.
our $FAIL_RENAME;

BEGIN {
    *CORE::GLOBAL::rename = sub {
        return 0 if $FAIL_RENAME;
        return CORE::rename( $_[0], $_[1] );
    };
}

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::PathRegistry;

# build_collector()
# Builds a Collector backed by a throwaway home-rooted path registry so the
# atomic write helper can be exercised in isolation.
# Input: none.
# Output: a Developer::Dashboard::Collector object.
sub build_collector {
    my $home  = tempdir( CLEANUP => 1 );
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
    );
    return Developer::Dashboard::Collector->new( paths => $paths );
}

# read_file($file)
# Slurps a file so a written target can be compared against expected contents.
# Input: file path string.
# Output: full file content string.
sub read_file {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return scalar <$fh>;
}

# Finding: _atomic_write_text unlinked the existing target before the rename,
# so a rename that failed destroyed the previous file and broke the atomicity
# the method name promises. The fixed helper must rename over the target in one
# step and leave the previous file untouched when the rename cannot complete.
{
    my $collector = build_collector;

    # A sibling temp directory (outside the registry home) keeps the secure
    # permission hook a no-op so this test isolates the rename behaviour only.
    my $outside = tempdir( CLEANUP => 1 );
    my $target  = File::Spec->catfile( $outside, 'status.json' );
    open my $seed, '>:raw', $target or die "Unable to seed $target: $!";
    print {$seed} 'ORIGINAL' or die "Unable to seed $target: $!";
    close $seed or die "Unable to close $target: $!";

    my $failed;
    {
        local $FAIL_RENAME = 1;
        $failed = !eval {
            $collector->_atomic_write_text( $target, 'REPLACEMENT' );
            1;
        };
    }

    ok( $failed,
        '_atomic_write_text dies when the atomic rename cannot complete' );
    ok( -f $target,
        '_atomic_write_text preserves the existing target after a failed rename (no pre-rename unlink)'
    );
    is( read_file($target), 'ORIGINAL',
        '_atomic_write_text leaves the previous contents intact after a failed rename'
    );

    # Sanity: with rename working, the helper replaces the target atomically.
    my $written = $collector->_atomic_write_text( $target, 'REPLACEMENT' );
    is( $written, $target, '_atomic_write_text returns the written target path' );
    is( read_file($target), 'REPLACEMENT',
        '_atomic_write_text replaces the target contents when the rename succeeds'
    );
}

# Finding: _atomic_write_text ignored close(), so a short or failed flush was
# renamed into place as a truncated file. /dev/full forces the flush to fail on
# close while the small payload stays buffered until then, proving the fixed
# helper surfaces the failure instead of publishing a broken file.
SKIP: {
    skip 'requires a writable /dev/full to force a flush failure', 1
      if !-e '/dev/full' || !-w '/dev/full';

    my $collector = build_collector;
    my $outside   = tempdir( CLEANUP => 1 );
    my $target    = File::Spec->catfile( $outside, 'stdout' );

    # The real pending name carries a per-process uniquifier (DD-418), so the
    # staging path is pinned to a fixed value here purely to let the device
    # symlink stand in for it. What is under test is the flush failure, not the
    # name; the name itself is asserted separately below.
    my $pending = "$target.forced-full.pending";
    no warnings 'redefine';
    local *Developer::Dashboard::Collector::_pending_path = sub { return $pending };
    use warnings 'redefine';

    skip "unable to symlink /dev/full: $!", 1
      if !symlink( '/dev/full', $pending );

    my $died = !eval {
        $collector->_atomic_write_text( $target, "chunk\n" );
        1;
    };
    ok( $died,
        '_atomic_write_text dies on a failed flush instead of renaming a truncated file into place'
    );

    unlink $pending if -l $pending;
}

# Finding (DD-418): _atomic_write_text derived its temporary file name from the
# target alone ("$file.pending"), so two worker processes running the SAME
# collector under mode => 'multiple' shared one pending path. The second worker
# reopened it with O_TRUNC, renamed it away, and the first worker's rename then
# failed with ENOENT. Because mark_run_finished dies inside write_result, the
# active-run counter incremented by mark_run_started is never decremented, so the
# collector is reported as permanently running (COLLECTOR-GHOST-STATUS).
#
# The reproduction below is deterministic, not opportunistic: the two workers are
# rendezvoused through a pair of pipes at the exact instant that matters. The
# child worker is frozen inside its own _atomic_write_text between close() and
# rename() (the paths registry's secure_file_permissions call on the pending file
# is that seam), the parent worker then performs a whole run start-to-finish, and
# only afterwards is the child released to attempt its rename. No sleep, no race
# window, and no dependence on scheduler luck.
{
    my $home = tempdir( CLEANUP => 1 );
    local $ENV{HOME}                           = $home;
    local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );

    my $paths     = Developer::Dashboard::PathRegistry->new( home => $home );
    my $collector = Developer::Dashboard::Collector->new( paths => $paths );

    my $name   = 'overlapping';
    my $target = $collector->collector_paths($name)->{stdout};

    # Distinct multi-page payloads so a clobbered or interleaved write is
    # observable in the final file rather than hidden by a short string.
    my $child_payload  = 'child-' x 1000;
    my $parent_payload = 'parent-' x 1000;

    pipe my ( $ready_r, $ready_w ) or die "Unable to create the rendezvous pipe: $!";
    pipe my ( $go_r,    $go_w )    or die "Unable to create the release pipe: $!";

    my $child_error_file = File::Spec->catfile( $home, 'overlapping-child-error.txt' );

    my $child_pid = fork;
    die "Unable to fork the second collector worker: $!" if !defined $child_pid;

    if ( !$child_pid ) {
        # Worker A. It freezes mid-write so worker B can be driven past it.
        close $ready_r;
        close $go_w;
        {
            my $previous = select $ready_w;
            $| = 1;
            select $previous;
        }

        my $real_secure = \&Developer::Dashboard::PathRegistry::secure_file_permissions;
        my $rendezvoused = 0;
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::secure_file_permissions = sub {
            my ( $registry, $file, %args ) = @_;
            if ( !$rendezvoused && defined $file && $file =~ m{stdout[^/\\]*\.pending\z} ) {
                $rendezvoused = 1;
                print {$ready_w} "paused\n";
                my $release = <$go_r>;
                die "Rendezvous pipe closed before the overlapping worker was released\n"
                  if !defined $release;
            }
            return $real_secure->( $registry, $file, %args );
        };
        use warnings 'redefine';

        $collector->mark_run_started( $name, { enabled => 1 } );
        my $finished = eval {
            $collector->mark_run_finished(
                $name,
                exit_code => 0,
                stdout    => $child_payload,
                stderr    => '',
            );
            1;
        };
        if ( !$finished ) {
            my $error = "$@";
            if ( open my $efh, '>:raw', $child_error_file ) {
                print {$efh} $error;
                close $efh;
            }
            exit 17;
        }
        exit 0;
    }

    close $ready_w;
    close $go_r;

    # Blocks until worker A is parked between its close() and its rename().
    my $paused = <$ready_r>;
    is( $paused, "paused\n", 'the first collector worker parked between its pending write and its rename' );

    # Worker B: a whole overlapping run, exactly as a mode => 'multiple' loop
    # would issue it from a second process.
    $collector->mark_run_started( $name, { enabled => 1 } );
    $collector->mark_run_finished(
        $name,
        exit_code => 0,
        stdout    => $parent_payload,
        stderr    => '',
    );

    print {$go_w} "release\n";
    close $go_w;

    waitpid $child_pid, 0;
    my $child_exit = $? >> 8;

    my $child_error = '';
    if ( -f $child_error_file ) {
        open my $efh, '<:raw', $child_error_file or die "Unable to read $child_error_file: $!";
        local $/;
        $child_error = <$efh>;
        close $efh;
    }

    is( $child_exit, 0,
        'both concurrent collector workers complete their result write when their pending temp files cannot collide'
    ) or diag("overlapping worker died with: $child_error");

    my $written = read_file($target);
    ok( $written eq $child_payload || $written eq $parent_payload,
        'the collector stdout file holds one complete result rather than a clobbered mixture'
    );

    my $status = $collector->read_status($name);
    is( $status->{active_runs}, 0,
        'the active-run counter returns to zero after both overlapping runs finish'
    );
    is( $status->{running}, 0,
        'the collector is not left permanently reported as running after overlapping runs'
    );
}

# Finding (DD-418): the pending temp path must be unique per writing process, in
# the same "<file>.<pid>.<time>.pending" shape the other two lock-free atomic
# writers in this distribution already use.
{
    my $collector = build_collector;
    my $file      = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'status.json' );

    my $pending = $collector->_pending_path($file);
    isnt( $pending, "$file.pending",
        '_pending_path no longer returns the shared, process-independent temp name' );
    like( $pending, qr/\A\Q$file\E\.\Q$$\E\..+\.pending\z/,
        '_pending_path embeds the writing process id in a "<file>.<pid>.<time>.pending" name' );
}

done_testing;

__END__

=head1 NAME

54-hunt-collector.t - collector atomic-write durability regression tests

=head1 DESCRIPTION

This test pins down the durability contract of
C<Developer::Dashboard::Collector::_atomic_write_text>: it must publish
collector state only after a fully flushed write, it must replace the target
through a single rename that never leaves the destination missing, and it must
stage that write under a temporary name that is unique to the writing process so
two workers of one collector configured with C<< mode =E<gt> 'multiple' >>
cannot truncate and rename away each other's staged file.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the collector atomic-write
helper. It proves that a failed rename never destroys the previous file, that a
failed flush is raised as an error instead of being renamed into place as a
truncated file, and that two collector workers running at the same time both
complete their result write and leave the active-run counter back at zero, so
consumers that read cached collector state always observe a whole file and never
a collector stuck at "running".

=head1 WHY IT EXISTS

It exists because collector status, output, and log files are written from
background work and read by prompt rendering, the web status strip, and CLI
inspection. A pre-rename unlink or an unchecked close would let those readers
briefly see a missing file or permanently keep a truncated one, and a staging
name shared by every writer let one overlapping worker destroy another's write
mid-run: the losing worker died before it could decrement the active-run counter
it had already incremented, so the collector was reported as running forever. A
code-only review can miss all three. Encoding the expectation here keeps the TDD
loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the collector atomic-write helper, its temporary
file naming or handling, the order in which the pending file is flushed and
renamed, or the active-run accounting that overlapping collector runs depend on,
and whenever a focused failure points here.

=head1 HOW TO USE

Run it directly with C<prove -lv t/54-hunt-collector.t> while iterating, then
keep it green under C<prove -lr t> and the coverage runs before release. The
flush-failure assertion uses C</dev/full> and self-skips where that device is
unavailable. The overlapping-worker case forks a second worker and rendezvouses
the two through pipes, so it is deterministic and needs no timing tolerance.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and
the release verification loop all rely on this file to keep collector state
writes durable and atomic.

=head1 EXAMPLES

Example 1:

  prove -lv t/54-hunt-collector.t

Run the focused regression test by itself while changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/54-hunt-collector.t

Exercise the same focused test while collecting coverage for the collector code
it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the
work finished.

=for comment FULL-POD-DOC END

=cut
