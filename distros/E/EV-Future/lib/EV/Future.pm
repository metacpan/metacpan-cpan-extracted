package EV::Future;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.06';

use EV ();
use base 'Exporter';
our @EXPORT = qw(parallel parallel_limit series race
                 parallel_map parallel_map_limit series_map);

require XSLoader;
XSLoader::load('EV::Future', $VERSION);

{
    # The handle class is implemented entirely in Future.xs; this stanza gives
    # it a Perl-side home so it can be indexed, versioned and documented.
    package EV::Future::Handle;

    our $VERSION = $EV::Future::VERSION;

    # A handle is a blessed reference to an integer holding a C pointer to a
    # refcounted cell. Duplicating the Perl object would produce a second owner
    # of that one cell, and the second DESTROY would free what the first one
    # already freed. Refuse to be duplicated, by both routes that can do it:
    #
    #   * ithread cloning, where CLONE_SKIP makes the copy undef;
    #   * Storable, which does NOT honour CLONE_SKIP (verified: dclone of a
    #     handle aborts with a double free), and needs its own hooks. Freezing
    #     to nothing and thawing to a zeroed payload makes the copy an inert
    #     dead handle - the same state every handle reaches once its operation
    #     is over, where cancel does nothing and both counters read 0.
    sub CLONE_SKIP { 1 }

    sub STORABLE_freeze { return '' }
    sub STORABLE_thaw   { ${ $_[0] } = 0; return }
}

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

  parallel_map([qw(a b c)], sub {
      my ($item, $done) = @_;
      push @w, EV::timer 0.1, 0, sub { $done->() };
  }, sub { print "all mapped\n" });

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

  # In non-void context you get a handle; in void context, nothing is allocated
  my $h = parallel_map(\@items, \&worker, sub { print "done\n" });
  printf "%d in flight, %d to go\n", $h->active, $h->pending;
  $h->cancel;                      # stop dispatching; final_cb will not fire

  EV::run;

=head1 DESCRIPTION

Control-flow primitives (C<parallel>, C<parallel_map>, C<parallel_limit>,
C<parallel_map_limit>, C<series>, C<series_map>, C<race>), implemented in XS
for minimal overhead. All are exported by default.

Each primitive follows one of two conventions. In the task form, C<\@tasks>
holds the work directly: each element is a coderef that receives a single
C<done> callback as its only argument, and must invoke C<done> exactly once
to mark completion. In the map form (C<parallel_map>, C<parallel_map_limit>,
C<series_map>), C<\@items> holds plain data, and a separate C<\&worker> is
dispatched once per element as C<($item, $done)>.

If the list is empty, C<final_cb> fires immediately in either form. See each
function's entry below for its exact contract.

=head2 Silent traps

Four things this module does quietly rather than loudly. None of them warns, so
each is worth knowing before it bites.

A non-coderef element of C<\@tasks> is treated as a no-op task that completes
instantly. The test is for a genuine code reference, so an object with a C<&{}>
overload is skipped rather than invoked. The map form inverts this: elements
there are data, and are handed to the worker whatever their type.

C<\@tasks> must be a plain array. Elements of a tied or otherwise magical array
are never fetched, so none of them looks like a code reference and the whole
list is treated as no-ops: nothing runs and C<final_cb> fires immediately. Copy
into a plain array first. The map form is unaffected, because the worker reads
the element it is handed and that performs the fetch.

C<final_cb> is never validated. A value that is not a code reference, including
C<undef>, is accepted and simply never called, so a mistyped callback fails in
total silence. The map-form C<\&worker> is stricter: a non-coderef worker croaks
before any dispatch.

Handing C<done> itself to an EV watcher cancels a series, because EV calls back
with the truthy watcher as the first argument. Always wrap it as
C<< sub { $done->() } >>; the C<series> entry below has the detail.

=head2 Safe vs unsafe mode

Each function takes an optional trailing C<$unsafe> flag. In safe mode (the
default), each dispatch is wrapped in C<G_EVAL>, every task gets its own
C<done> CV, and double-calls are silently dropped. Unsafe mode skips
C<G_EVAL> and reuses a single shared CV, roughly doubling throughput at the
cost of:

=over 4

=item *

An exception from a task propagates out uncaught and abandons the whole
operation: no further task is dispatched, C<final_cb> never fires, and a
C<done> called later by an already-running task is ignored. Safe mode reaches
the same outcome by tearing the operation down and re-throwing; unsafe mode
cannot run that cleanup, so it leaks the internal context instead.

Where the exception surfaces depends on when the task ran. A task dispatched
synchronously, while the C<parallel> or C<series> call is still on the stack,
throws to that caller. A task dispatched later from an event-loop callback
throws into C<EV>, which by default reports it as C<"EV: error in callback
(ignoring)"> and keeps the loop running.

An abandoned operation is frozen rather than finished, and a handle held over
it (see L</CANCELLATION>) shows that. C<pending> and C<active> go on reporting
the counts they had when the exception escaped, permanently, because nothing
will ever advance them; each is still literally true, but a non-zero C<pending>
no longer means the operation is going to make progress. Calling
C<$h-E<gt>cancel> on an abandoned handle runs the cleanup the unwind could not:
it detaches every outstanding C<done>, frees the leaked context and zeroes both
counters. That is the intended way to recover an abandoned operation's memory,
and the only one. C<$h-E<gt>cancel(1)> does the same and additionally calls
C<final_cb>, which is the single exception to "C<final_cb> never fires" above.

=item *

Double-calling C<done> corrupts the completion counter, which may invoke
C<final_cb> before all tasks have actually finished.

=back

Use unsafe mode only when tasks are well-behaved and performance is
critical.

=head1 FUNCTIONS

Every function below returns an C<EV::Future::Handle> when called in non-void
context; called in void context, no handle is allocated and nothing is
returned. See L</CANCELLATION>.

=head2 parallel(\@tasks, \&final_cb, [$unsafe])

Dispatch every task immediately; call C<final_cb> once each task has invoked
its C<done> callback.

=head2 parallel_map(\@items, \&worker, \&final_cb, [$unsafe])

Dispatch C<\&worker> once per element of C<\@items>, passing
C<($item, $done)>; call C<final_cb> once every worker has invoked its C<done>.

  parallel_map(\@urls, sub {
      my ($url, $done) = @_;
      $client->request($url, sub { ...; $done->() });
  }, sub { print "all fetched\n" });

Unlike the task form, elements are data: a non-coderef element is dispatched to
the worker like any other value, not treated as a task that completes
instantly. Holes in C<\@items> arrive as C<undef>. A non-coderef C<\&worker>
is a fatal error, raised before any dispatch.

The item is passed without copying, so modifying C<$_[0]> modifies the array
element, as with Perl's own C<for> and C<map>.

=head2 parallel_limit(\@tasks, $limit, \&final_cb, [$unsafe])

Dispatch tasks with at most C<$limit> in flight at any time. C<$limit> is
clamped to C<1..scalar(@tasks)>: C<$limit == 1> degenerates to C<series>,
C<$limit E<gt>= @tasks> degenerates to C<parallel>.

The truthy-C<done> cancellation supported by C<series> does not apply here; see
L</CANCELLATION> to stop dispatch from outside via the returned handle.

=head2 parallel_map_limit(\@items, \&worker, $limit, \&final_cb, [$unsafe])

As C<parallel_map>, with at most C<$limit> workers in flight at any time.
C<$limit> is clamped to C<1..scalar(@items)>.

  parallel_map_limit(\@urls, sub {
      my ($url, $done) = @_;
      $client->request($url, sub { ...; $done->() });
  }, 4, sub { print "all fetched\n" });

The item conventions of C<parallel_map> apply unchanged.

=head2 series(\@tasks, \&final_cb, [$unsafe])

Run tasks sequentially; each task starts only after the previous calls its
C<done>. To cancel the series and skip remaining tasks, pass a true value
to C<done>:

  series([
      sub { my $d = shift; $d->(1) },        # cancel here
      sub { die "never reached" },
  ], sub { print "finished early\n" });

Cancellation works in both safe and unsafe modes.

Beware: EV invokes watcher callbacks as C<$cb-E<gt>($watcher, $revents)>, and
C<$watcher> is truthy, so handing C<done> itself to EV silently cancels the
series. The broken form:

  sub { my $done = shift; push @w, EV::timer 0.01, 0, $done }

runs the first task, skips every remaining one, and still fires C<final_cb>
as if all went well, because the timer calls C<done> with the truthy watcher.
Always wrap C<done> in a closure:

  sub { my $done = shift; push @w, EV::timer 0.01, 0, sub { $done->() } }

=head2 series_map(\@items, \&worker, \&final_cb, [$unsafe])

As C<parallel_map>, but sequential: the worker is called for the next item only
after the previous call has invoked its C<done>. Passing a true value to
C<done> cancels the remaining items, exactly as in C<series>, and the same
bare-C<done> trap applies: never hand C<$done> itself to an EV watcher,
whose callback receives the truthy watcher and cancels the rest; wrap it
as C<< sub { $done->() } >>.

  series_map(\@steps, sub {
      my ($step, $done) = @_;
      $etcd->put($step->{key}, $step->{val}, sub { ...; $done->() });
  }, sub { print "all steps applied\n" });

The item conventions of C<parallel_map> apply unchanged.

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

=head1 CANCELLATION

Called in non-void context, every function returns an C<EV::Future::Handle>.
Called in void context, no handle is allocated and nothing is returned, so
existing call sites are unaffected.

  my $h = parallel_limit(\@tasks, 4, sub { print "done\n" });
  $h->cancel;     # stop dispatching; final_cb never fires
  $h->cancel(1);  # stop dispatching; final_cb fires once, with no arguments

Cancellation stops further dispatch. It cannot interrupt a task already in
flight, because that is your code sitting in an C<EV> callback; such a task
runs to completion, and the C<done> it eventually calls is ignored.

C<cancel> is idempotent and is a no-op once the operation has finished. It may
be called from inside a task, in which case the remaining tasks are not
dispatched, and from C<final_cb>, where it does nothing.

For C<series> this complements the truthy-C<done> form: pass a true value
to C<done> to cancel from inside a task, or use the handle to cancel from
outside one. They are not interchangeable, and a task that reads the handle
right after cancelling itself sees the difference. A truthy C<done> ends the
series through its ordinary completion path, so C<final_cb> still fires and the
task you are standing in is still counted: C<pending> reads 1 until that task
returns. C<$h-E<gt>cancel> tears the series down on the spot, so C<final_cb>
does not fire and C<pending> reads 0 straight away.

The handle also reports progress:

  my $h = parallel_limit(\@tasks, 4, sub { });
  printf "%d in flight, %d to go\n", $h->active, $h->pending;

=head1 EV::Future::Handle

The object every primitive returns in non-void context. It is a lightweight
reference to the operation and owns nothing: destroying the handle does not
cancel the operation, and the operation ending does not invalidate the handle.
Every method below is safe to call at any time, including on a handle whose
operation is already over, where C<cancel> does nothing and both counters read
0.

The object wraps a raw pointer to one refcounted cell, so duplicating it would
produce a second owner of that cell and, eventually, a double free. Two
duplication routes are defended against: a thread clone yields C<undef>
(C<EV::Future::Handle> sets C<CLONE_SKIP>), and a C<Storable> freeze, thaw or
C<dclone>, which does not honour C<CLONE_SKIP>, yields an inert dead handle
rather than a second owner.

That is not a general guarantee. A deep cloner that copies the underlying
scalar directly, bypassing both hooks, still yields a second live owner;
C<Clone::clone> is one such. Do not copy a handle by any means other than
assigning the reference itself, and create a handle in, and use it from, one
interpreter.

=head2 cancel([$fire])

Stop dispatching. With no argument, or a false one, C<final_cb> never fires;
with a true C<$fire> it fires exactly once, with no arguments, before C<cancel>
returns. Idempotent, and a no-op once the operation is over. See L</CANCELLATION>
above for what cancellation can and cannot reach.

=head2 pending

Tasks that have not yet completed, counting both those in flight and those not
yet dispatched.

=head2 active

Tasks currently in flight. C<parallel> and C<race> report the same value here as
for C<pending>, because they dispatch every task before returning; C<series>
always reports 1 while it is running.

=head2 What the counters guarantee

Both read 0 once the operation is over, so C<pending == 0> means it has finished
or been cancelled. The one exception is an operation abandoned by an escaping
unsafe-mode exception, whose counters freeze instead; see
L</"Safe vs unsafe mode">.

In unsafe mode, double-calling C<done> corrupts the completion counter, so
C<pending> under-reports for C<parallel> and C<parallel_limit> for the same
reason C<final_cb> can fire early. The same double-call can drive the in-flight
count below zero; C<active> is floored at 0 rather than reporting a negative.

=head1 BENCHMARKS

1000 synchronous tasks, 5000 iterations (C<bench/comparison.pl>). The script
covers the task form only, so C<race> and the three map primitives have no
figures here; see L</"Task form versus map form"> below for those. Measured
with EV 4.37, AnyEvent 7.17, Future::XS 0.15, Promise::XS 0.21 and
Future::Utils 0.52.

  --- PARALLEL (iterations/sec) ---
  EV::Future (unsafe)          9,259
  EV::Future (safe)            4,098
  AnyEvent::cv (begin/end)     1,563
  Future::XS::wait_all         1,563
  Promise::XS::all             1,323

  --- PARALLEL LIMIT 10 (iterations/sec) ---
  EV::Future (unsafe)          7,692
  EV::Future (safe)            4,032
  Future::Utils::fmap_void       624

  --- SERIES (iterations/sec) ---
  EV::Future (unsafe)          7,692
  AnyEvent::cv (stack-safe)    4,717
  EV::Future (safe)            3,968
  Future::XS (chain)           1,241
  Promise::XS (chain)          1,157

=head2 Task form versus map form

C<bench/map_vs_task.pl>, 100 elements, unsafe mode, as cachegrind instruction
counts per call, which are deterministic where wall-clock timings on a loaded
machine are not:

  parallel,     task list reused        150,376
  parallel_map, worker reused           186,106     +24%
  parallel,     task list per call      264,389
  parallel_map, worker per call         186,193     -30%

Per element the map form is the more expensive of the two: it pushes the item
as well as C<done>, which costs around 360 instructions per element that the
task form does not pay.

It still wins in practice, because a task closure has to capture its own
element, so the task form has to rebuild the whole list on every call: about
1,140 instructions per element, roughly three times what the extra push costs.
The map form has nothing per-element to rebuild, which is why its two rows above
are within 0.05% of each other; hoisting the worker out of the call buys
nothing.

So the map form is about 30% cheaper in the usual case, where the list is built
at the call site, and about 24% dearer in the case where you can hoist a fixed
task list and reuse it across calls. Reach for the map form for its ergonomics,
and expect the performance to follow in the common case rather than always.

=head1 SEE ALSO

L<EV>, L<Future::XS>, L<Promise::XS>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
