package EV::Future;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.05';

use EV ();
use base 'Exporter';
our @EXPORT = qw(parallel parallel_limit series race);

require XSLoader;
XSLoader::load('EV::Future', $VERSION);

=head1 NAME

EV::Future - Minimalist high-performance async control flow for EV

=head1 SYNOPSIS

  use EV;
  use EV::Future;

  my @w;
  parallel([
      sub { my $done = shift; push @w, EV::timer 0.1, 0, sub { $done->() } },
      sub { my $done = shift; push @w, EV::timer 0.2, 0, sub { $done->() } },
  ], sub { print "all done\n" });

  parallel_limit([
      sub { my $done = shift; push @w, EV::timer 0.1, 0, sub { $done->() } },
      sub { my $done = shift; push @w, EV::timer 0.2, 0, sub { $done->() } },
      sub { my $done = shift; push @w, EV::timer 0.1, 0, sub { $done->() } },
  ], 2, sub { print "all done (max 2 in-flight)\n" });

  series([
      sub { my $done = shift; $done->() },
      sub { my $done = shift; $done->() },
  ], sub { print "all done in order\n" });

  race([
      sub { my $done = shift; push @w, EV::timer 0.1, 0, sub { $done->("a") } },
      sub { my $done = shift; push @w, EV::timer 0.2, 0, sub { $done->("b") } },
  ], sub { my $winner = shift; print "winner: $winner\n" });

  EV::run;

=head1 DESCRIPTION

Four control-flow primitives (C<parallel>, C<parallel_limit>, C<series>,
C<race>), implemented in XS for minimal overhead. All four are exported by
default.

Each task is a coderef that receives a single C<done> callback as its only
argument; the task must invoke C<done> exactly once to mark completion.

If C<\@tasks> is empty, C<final_cb> fires immediately. Non-coderef elements
in C<\@tasks> are treated as no-op tasks that complete instantly.

=head2 Safe vs unsafe mode

Each function takes an optional trailing C<$unsafe> flag. In safe mode (the
default), each dispatch is wrapped in C<G_EVAL>, every task gets its own
C<done> CV, and double-calls are silently dropped. Unsafe mode skips
C<G_EVAL> and reuses a single shared CV, roughly doubling throughput at the
cost of:

=over 4

=item *

Exceptions from a task bypass cleanup and leak the internal context.

=item *

Double-calling C<done> corrupts the completion counter, which may invoke
C<final_cb> before all tasks have actually finished.

=back

Use unsafe mode only when tasks are well-behaved and performance is
critical.

=head1 FUNCTIONS

=head2 parallel(\@tasks, \&final_cb, [$unsafe])

Dispatch every task immediately; call C<final_cb> once each task has invoked
its C<done> callback.

=head2 parallel_limit(\@tasks, $limit, \&final_cb, [$unsafe])

Dispatch tasks with at most C<$limit> in flight at any time. C<$limit> is
clamped to C<1..scalar(@tasks)>: C<$limit == 1> degenerates to C<series>,
C<$limit E<gt>= @tasks> degenerates to C<parallel>.

There is no cancellation mechanism; all dispatched tasks must complete.
The truthy-C<done> cancellation supported by C<series> does not apply here.

=head2 series(\@tasks, \&final_cb, [$unsafe])

Run tasks sequentially; each task starts only after the previous calls its
C<done>. To cancel the series and skip remaining tasks, pass a true value
to C<done>:

  series([
      sub { my $d = shift; $d->(1) },        # cancel here
      sub { die "never reached" },
  ], sub { print "finished early\n" });

Cancellation works in both safe and unsafe modes.

=head2 race(\@tasks, \&final_cb, [$unsafe])

Dispatch every task; call C<final_cb> with the arguments passed to the
first C<done> invocation. Subsequent C<done> calls (whether from the
winning task or losers) are silently ignored.

Losing tasks continue to run; C<EV::Future> does not cancel their EV
watchers (it didn't create them). To tear losers down, hold their
watchers in a shared lvalue and clear it from C<final_cb>:

  my @w;
  race([
      sub { my $d = shift; push @w, EV::timer 0.1, 0, sub { $d->("a") } },
      sub { my $d = shift; push @w, EV::timer 0.2, 0, sub { $d->("b") } },
  ], sub { my $winner = shift; @w = () });

Non-coderef elements in C<\@tasks> count as instantly-completed winners
(with no arguments) and short-circuit dispatch.

=head1 BENCHMARKS

1000 synchronous tasks, 5000 iterations (C<bench/comparison.pl>):

  --- PARALLEL (iterations/sec) ---
  EV::Future (unsafe)          4,386
  EV::Future (safe)            2,262
  AnyEvent::cv (begin/end)     1,027
  Future::XS::wait_all           982
  Promise::XS::all                32

  --- PARALLEL LIMIT 10 (iterations/sec) ---
  EV::Future (unsafe)          4,673
  EV::Future (safe)            2,688
  Future::Utils::fmap_void       431

  --- SERIES (iterations/sec) ---
  EV::Future (unsafe)          5,000
  AnyEvent::cv (stack-safe)    3,185
  EV::Future (safe)            2,591
  Future::XS (chain)             893
  Promise::XS (chain)            809

=head1 SEE ALSO

L<EV>, L<Future::XS>, L<Promise::XS>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
