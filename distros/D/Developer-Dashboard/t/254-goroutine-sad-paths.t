#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Cwd qw(abs_path);
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use IO::Socket::INET;
use Time::HiRes qw(time);

use lib 'lib';
use Developer::Dashboard::GoRoutine;

# Regression tests for the two C-code sad paths in the GoRoutine redesign
# that the coverage gate cannot prove (it measures Perl lib/ only):
# the malloc-failure sleep branch in go_ev_wait (GoRoutineEvent.h) and
# the destructor-dies-during-cleanup ordering in _ev_invoke_callback
# (GoRoutine012.xs).

# ----------------------------------------------------------------------
# Part 1: a dying destructor in a routine's return value.
#
# The callback returns an object whose DESTROY dies. The return value is
# a mortal: with G_DISCARD the XSUB leaves it on the temps stack, so it
# is freed at the XSUB's FREETMPS, AFTER the custom runops is restored.
# Perl downgrades a die during mortal cleanup to an "(in cleanup)"
# warning, so the routine must finish 'done' and wait_all must not die.
# The child-process probe below proves the runops state directly: exit()
# at top level goes through PL_runops, so a leaked custom runops would
# croak __GOROUTINE_EXIT__ and the child would die with 255 instead of
# exiting 42.
# ----------------------------------------------------------------------
{
    package DyingReturn;
    our $DESTROYED = 0;
    sub new { bless {}, shift }
    sub DESTROY { $DyingReturn::DESTROYED = 1; die "SAD_PATH_DESTROY_DIED\n"; }
}

my $routine_a = go sub { return DyingReturn->new };
my $wait_died = eval { wait_all(); 1 } ? 0 : 1;
my $wait_err = $@;
ok($DyingReturn::DESTROYED, 'destructor ran during dispatch cleanup');
ok(!$wait_died, 'wait_all did not die from a destructor error');
is($wait_err, '', 'no error propagated from the dying destructor');
is($routine_a->status, 'done', 'routine finished done despite the dying destructor');

# ----------------------------------------------------------------------
# Part 1b: the same dance in a child perl, which proves PL_runops was
# restored: a leaked custom runops would make exit(42) croak
# __GOROUTINE_EXIT__ and die with 255 instead of 42.
# ----------------------------------------------------------------------
my $lib_dir = abs_path("$Bin/../lib");
my @blib_inc = grep { /blib/ } @INC;
if (!@blib_inc) {
    my $blib_lib  = abs_path("$Bin/../blib/lib");
    my $blib_arch = abs_path("$Bin/../blib/arch");
    @blib_inc = grep { -d $_ } ($blib_lib, $blib_arch);
}
my $child_program = <<'CHILD';
use strict;
use warnings;
BEGIN { open(STDERR, '>&', STDOUT) or die "cannot dup stderr: $!"; }
print "child started\n";
use lib 'LIBDIR';
use Developer::Dashboard::GoRoutine;
our $DESTROYED = 0;
{
    package DyingReturn;
    sub new { bless {}, shift }
    sub DESTROY { $main::DESTROYED = 1; die "SAD_PATH_DESTROY_DIED\n"; }
}
my $r = go sub { return DyingReturn->new };
my $died = eval { wait_all(); 1 } ? 0 : 1;
print "destroyed=$main::DESTROYED died=$died\n";
if (my $out = $ENV{SAD_PATH_CHILD_OUT}) {
    open my $ofh, '>', $out or die "cannot write child out: $!";
    print {$ofh} "destroyed=$main::DESTROYED died=$died\n";
    close $ofh;
}
exit(42);
CHILD
$child_program =~ s/LIBDIR/$lib_dir/;
my ($child_fh, $child_file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
print {$child_fh} $child_program;
close $child_fh;
my ($out_fh, $out_file) = tempfile(SUFFIX => '.txt', UNLINK => 1);
close $out_fh;
local $ENV{SAD_PATH_CHILD_OUT} = $out_file;
# NOTE: the map is parenthesised on purpose. An unparenthesised
#   map { '-I' . $_ } @blib_inc, $child_file
# maps over $child_file too, so perl receives the script as an -I
# entry and no program at all, reads empty stdin and exits 0.
my @child_args = ($^X, '-I' . $lib_dir, (map { '-I' . $_ } @blib_inc), $child_file);
open my $pipe, '-|', @child_args or die "cannot spawn child: $!";
my $child_out = do { local $/; <$pipe> };
close $pipe;
my $child_rc = $? >> 8;
my $file_out = do { local $/; open my $rfh, '<', $out_file or die "cannot read child out: $!"; <$rfh> };
diag('child file out=' . (defined $file_out ? $file_out : 'undef'));
is($child_rc, 42, 'child exit(42) works after a dying destructor (runops restored)');
like($child_out // '', qr/destroyed=1/, 'child destructor ran during dispatch cleanup');

# ----------------------------------------------------------------------
# Part 2: malloc failure in go_ev_wait.
#
# _ev_fail_malloc_once is a test-only fault-injection hook: it makes the
# next go_ev_wait call treat its pollfd malloc as failed, so the engine
# takes the fds == NULL branch and sleeps via poll() on a dummy fd
# instead of busy-looping. With the hook set, a wait over a never-ready
# IO trigger must sleep the full wait period (not return at once, not
# spin) and return no due ids, and the engine must recover on the next
# wait. The branch is Unix-only: the Windows select path allocates
# nothing, so this part skips there.
# ----------------------------------------------------------------------
SKIP: {
    skip 'malloc-failure branch is Unix-only (Windows select path allocates nothing)', 6
        if $^O eq 'MSWin32';
    my $has_hook = eval { Developer::Dashboard::GoRoutine::_ev_fail_malloc_once(); 1 };
    ok($has_hook, '_ev_fail_malloc_once exists');
    skip 'malloc hook missing, cannot exercise the failure branch', 5
        unless $has_hook;

    my $server = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'tcp', ReuseAddr => 1,
    ) or die "cannot listen: $!";
    my $client = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $server->sockport, Proto => 'tcp',
    ) or die "cannot connect: $!";
    my $accepted = $server->accept or die "cannot accept: $!";
    my $ran = 0;
    my $routine_b = go sub { $ran++ }, { readable => $accepted };
    Developer::Dashboard::GoRoutine::_ev_fail_malloc_once();
    my $t0 = time();
    my ($u0, $s0) = times();
    my @due = Developer::Dashboard::GoRoutine::_ev_wait(200);
    my ($u1, $s1) = times();
    my $elapsed = time() - $t0;
    my $cpu = ($u1 - $u0) + ($s1 - $s0);
    diag("after forced-failure _ev_wait elapsed=$elapsed cpu=$cpu due=@due");
    is(scalar(@due), 0, 'forced malloc failure returns no due ids');
    ok($elapsed >= 0.15, 'forced malloc failure still sleeps the wait period');
    ok($cpu < 0.05, 'forced malloc failure does not busy-loop (low CPU)');
    print $client "x";
    my @due2 = Developer::Dashboard::GoRoutine::_ev_wait(200);
    diag("after recovery wait due=@due2 ran=$ran");
    is(scalar(@due2), 1, 'engine recovers after a failed malloc');
    is($due2[0], $routine_b->{id}, 'recovery wait returns the waiting routine');
    $routine_b->kill;
}

done_testing;

__END__

=head1 NAME

t/254-goroutine-sad-paths.t - regression tests for the GoRoutine C sad paths

=head1 PURPOSE

Proves the two C-code sad paths in the GoRoutine redesign behave
correctly: the malloc-failure sleep branch in C<go_ev_wait>
(GoRoutineEvent.h) and the destructor-dies-during-cleanup ordering in
C<_ev_invoke_callback> (GoRoutine012.xs). The coverage gate cannot prove
either: it measures Perl C<lib/> only, and both paths live in C code.

=head1 WHEN TO USE

Run this file whenever GoRoutineEvent.h, GoRoutine012.xs, or the event
loop changes. It is part of the normal suite, not a probe: if it fails,
one of the two sad paths regressed.

=head1 WHY IT EXISTS

Both paths are easy to break silently. The malloc-failure branch only
runs when an allocation fails, which cannot be triggered deterministically
from Perl without the C<_ev_fail_malloc_once> fault-injection hook; a
regression there would busy-loop the event loop under memory pressure.
The runops-restore ordering only matters when a callback returns an
object whose destructor dies; a regression there would leave the custom
runops installed and break exit() at top level. Neither path is
exercised by any other test, and neither shows up in coverage.

=head1 WHAT IT COVERS

=over 4

=item * A routine whose callback returns an object with a dying
destructor: the destructor runs during dispatch cleanup, the die is
downgraded to an "(in cleanup)" warning, wait_all does not die, and the
routine finishes C<done>.

=item * The same dance in a child perl: the child exits 42, proving
PL_runops was restored (a leak would make exit() croak
C<__GOROUTINE_EXIT__> and die with 255).

=item * A forced malloc failure in C<go_ev_wait> (Unix only): the wait
returns no due ids, still sleeps the full wait period, burns no CPU,
and the engine recovers on the next wait.

=back

=head1 HOW TO USE

    prove -v t/254-goroutine-sad-paths.t

On Windows the malloc-failure part skips by design (the Windows select
path allocates nothing). The destructor parts run on all platforms. The
child probe spawns a perl with C<$^X> and the same C<-I> paths the test
itself runs under, so it works wherever the suite runs.

=head1 WHAT USES IT

Nothing calls this file directly. It guards GoRoutineEvent.h
(C<go_ev_wait>), GoRoutine012.xs (C<_ev_invoke_callback>,
C<_ev_fail_malloc_once>), and lib/Developer/Dashboard/GoRoutine.pm
(which dispatches the routines these paths serve).

=head1 EXAMPLES

A destructor that dies in a returned object must not fail the routine:

    my $r = go sub { return DyingReturn->new };
    wait_all();              # lives; $r->status is 'done'

A forced malloc failure must sleep, not spin:

    Developer::Dashboard::GoRoutine::_ev_fail_malloc_once();
    my @due = Developer::Dashboard::GoRoutine::_ev_wait(200);
    # @due is empty, ~0.2s elapsed, ~0 CPU, next wait recovers.

=cut
