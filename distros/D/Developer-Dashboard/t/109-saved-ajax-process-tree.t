#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Time::HiRes qw(sleep time);

use lib 'lib';

use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform qw(is_windows);

sub _process_is_live {
    my ($pid) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    return 0 if !kill 0, $pid;
    my $stat_path = "/proc/$pid/stat";
    if ( open my $stat_fh, '<', $stat_path ) {
        my $stat = <$stat_fh> // '';
        close $stat_fh;
        return 0 if $stat =~ /^\d+\s+\(.*\)\s+Z\b/;
    }
    return 1;
}

sub _wait_until {
    my ( $predicate, $timeout ) = @_;
    my $deadline = time + $timeout;
    while ( time < $deadline ) {
        return 1 if $predicate->();
        sleep 0.05;
    }
    return $predicate->() ? 1 : 0;
}

sub _read_pid_marker {
    my ($path) = @_;
    return if !-s $path;
    open my $fh, '<', $path or return;
    my $pid = <$fh> // '';
    close $fh;
    $pid =~ s/\s+//g;
    return $pid =~ /^\d+$/ ? $pid + 0 : undef;
}

sub _stop_process {
    my ($pid) = @_;
    return 1 if !_process_is_live($pid);
    kill 15, $pid;
    return 1 if _wait_until( sub { !_process_is_live($pid) }, 1 );
    kill 9, $pid;
    return _wait_until( sub { !_process_is_live($pid) }, 2 );
}

my @cleanup_pids;
my @cleanup_markers;
END {
    for my $pid (@cleanup_pids) {
        _stop_process($pid)
          or warn "DD-396 cleanup trap could not terminate pid=$pid\n";
    }
    unlink grep { defined $_ && -e $_ } @cleanup_markers;
}

SKIP: {
    skip 'POSIX saved-Ajax process-group behavior is not implemented by the Windows path', 5
      if is_windows();

    my $home = tempdir( 'dd396-process-tree-XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    local $ENV{HOME} = $home;
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
    my $ajax_dir = File::Spec->catdir( $paths->dashboards_root, 'ajax' );
    make_path($ajax_dir);

    my $marker = File::Spec->catfile( $home, "dd396-grandchild-$$.pid" );
    push @cleanup_markers, $marker;
    my $saved_path = File::Spec->catfile( $ajax_dir, 'dd396-process-tree.pl' );
    open my $saved_fh, '>', $saved_path or die "Unable to write $saved_path: $!";
    print {$saved_fh} <<'SAVED_AJAX';
my $marker = params()->{marker} || die "missing marker\n";
my $grandchild = fork();
die "fork failed: $!\n" if !defined $grandchild;
if ( !$grandchild ) {
    close STDOUT;
    close STDERR;
    $SIG{TERM} = 'IGNORE';
    open my $marker_fh, '>', $marker or exit 91;
    print {$marker_fh} "$$\n";
    close $marker_fh or exit 92;
    sleep 30;
    exit 0;
}
for ( 1 .. 100 ) {
    last if -s $marker;
    select undef, undef, undef, 0.02;
}
print "worker=$$ grandchild=$grandchild\n";
$SIG{TERM} = sub { exit 0 };
sleep 30;
SAVED_AJAX
    close $saved_fh or die "Unable to close $saved_path: $!";
    chmod 0700, $saved_path or die "Unable to chmod $saved_path: $!";

    my ( $worker_pid, $grandchild_pid, $stream_result );
    my $grandchild_was_live = 0;
    my $run_error = '';
    {
        local $SIG{ALRM} = sub { die "DD-396 saved-Ajax process-tree test timed out\n" };
        alarm 8;
        eval {
            $stream_result = $runtime->stream_saved_ajax_file(
                path          => $saved_path,
                page          => 'dd396-process-tree',
                type          => 'text',
                params        => {
                    file   => 'dd396-process-tree.pl',
                    marker => $marker,
                    page   => 'dd396-process-tree',
                    type   => 'text',
                },
                stdout_writer => sub {
                    my ($chunk) = @_;
                    if ( defined $chunk && $chunk =~ /worker=(\d+)\s+grandchild=(\d+)/ ) {
                        ( $worker_pid, $grandchild_pid ) = ( $1 + 0, $2 + 0 );
                        $grandchild_was_live = _process_is_live($grandchild_pid);
                    }
                    return 0;
                },
                stderr_writer => sub { return 0 },
            );
            1;
        } or do {
            $run_error = $@ || 'unknown stream error';
        };
        alarm 0;
    }
    $grandchild_pid ||= _read_pid_marker($marker);

    # Feature: Saved-Ajax cancellation owns the complete POSIX process tree.
    # Scenario: Browser disconnects after a saved-Ajax worker forks a descendant.
    # Given the worker and TERM-ignoring grandchild are both running,
    ok( defined $worker_pid && $worker_pid > 0, 'BDD Given: saved-Ajax worker reports its pid before disconnect' );
    ok( $grandchild_was_live, 'BDD Given: saved-Ajax grandchild is alive before disconnect cleanup' );
    # When the response writer reports the browser disconnect,
    is( $run_error, '', 'BDD When: disconnect cleanup returns without an internal runtime error' );
    ok( $stream_result && $stream_result->{disconnected}, 'ATDD: saved-Ajax result records the writer disconnect' );
    # Then no runnable descendant remains after the bounded cleanup.
    ok(
        defined $grandchild_pid && _wait_until( sub { !_process_is_live($grandchild_pid) }, 2 ),
        'ATDD Then: disconnect cleanup terminates the saved-Ajax grandchild process',
    );

    if ( defined $grandchild_pid && _process_is_live($grandchild_pid) ) {
        diag("RED cleanup: terminating leaked saved-Ajax grandchild pid=$grandchild_pid marker=$marker");
        _stop_process($grandchild_pid)
          or diag("RED cleanup FAILED: saved-Ajax grandchild pid=$grandchild_pid is still live");
    }
    unlink $marker if -e $marker;
}

done_testing;

__END__

=head1 NAME

109-saved-ajax-process-tree.t - saved-Ajax disconnect process-tree acceptance test

=head1 DESCRIPTION

This test proves that disconnecting a streamed saved-Ajax response terminates
both the directly launched worker and a real TERM-ignoring grandchild on POSIX.
It uses a unique temporary marker, bounded waits, and an explicit cleanup path
so a failing regression test does not leave a runnable descendant behind.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Protect the saved-Ajax lifecycle contract at the process boundary rather than
mocking signal calls. The scenario reproduces the browser-disconnect path and
observes the descendant process directly.

=head1 WHY IT EXISTS

Terminating only the worker pid can orphan commands forked by a saved-Ajax
handler. A real process-tree fixture catches that leak and prevents direct-pid
cleanup from being mistaken for complete cancellation.

=head1 WHEN TO USE

Run this test whenever saved-Ajax launch, stream cancellation, signal handling,
or process ownership changes.

=head1 HOW TO USE

Run C<prove -lv t/109-saved-ajax-process-tree.t> for the focused TDD, BDD, and
ATDD loop. Then include it in the repository-wide tests and platform gates.

=head1 WHAT USES IT

Developers, the Perl test harness, and the saved-Ajax lifecycle delivery gates
use this executable scenario.

=head1 EXAMPLES

  prove -lv t/109-saved-ajax-process-tree.t

Run the deterministic POSIX process-tree scenario.

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/109-saved-ajax-process-tree.t

Collect focused implementation coverage while exercising the same acceptance
behavior.

  prove -lr t

Include the scenario in the complete repository test suite.

=for comment FULL-POD-DOC END

=cut
