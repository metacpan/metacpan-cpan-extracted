package EV::Future;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.02';

use EV ();
use base 'Exporter';
our @EXPORT = qw(parallel parallel_limit series);

require XSLoader;
XSLoader::load('EV::Future', $VERSION);

=head1 NAME

EV::Future - Minimalist and high-performance async control flow for EV

=head1 SYNOPSIS

  use EV;
  use EV::Future;

  my @watchers;
  parallel([
      sub { my $done = shift; push @watchers, EV::timer 0.1, 0, sub { print "Task 1 done\n"; $done->() } },
      sub { my $done = shift; push @watchers, EV::timer 0.2, 0, sub { print "Task 2 done\n"; $done->() } },
  ], sub {
      print "All parallel tasks finished\n";
  });

  parallel_limit([
      sub { my $done = shift; push @watchers, EV::timer 0.1, 0, sub { print "Task A\n"; $done->() } },
      sub { my $done = shift; push @watchers, EV::timer 0.2, 0, sub { print "Task B\n"; $done->() } },
      sub { my $done = shift; push @watchers, EV::timer 0.1, 0, sub { print "Task C\n"; $done->() } },
  ], 2, sub {
      print "All limited-parallel tasks finished\n";
  });

  series([
      sub { my $done = shift; print "Task 1 start\n"; $done->() },
      sub { my $done = shift; print "Task 2 start\n"; $done->() },
  ], sub {
      print "All series tasks finished\n";
  });

  EV::run;

=head1 DESCRIPTION

Focuses on performance and minimalism, offloading task management to XS.

All three functions (C<parallel>, C<parallel_limit>, C<series>) are exported
by default.

If C<\@tasks> is empty, C<final_cb> is called immediately. Non-coderef
elements in C<\@tasks> are treated as immediately-completed no-op tasks.

=head2 TASKS

Each task is a coderef that receives a single argument: a "done" callback. 
The task MUST call this callback exactly once when it is finished.

=head3 Exceptions

In safe mode (the default), if a task throws an exception (e.g., via C<die>),
the exception will be propagated immediately and internal memory is cleaned up
correctly. In unsafe mode, exceptions bypass cleanup and will leak memory.

=head3 Double-calls

Calling the C<done> callback more than once for a single task is considered
incorrect usage. In safe mode (the default), C<EV::Future> prevents
catastrophic failure:

=over 4

=item *

In C<parallel> and C<parallel_limit>, extra calls to a specific C<done>
callback are silently ignored.

=item *

In C<series>, extra calls to a specific C<done> callback are ignored. Only
the C<done> callback provided to the I<currently active> task can advance the
series.

=back

In unsafe mode, these protections are B<not active>. Double-calls will
corrupt the internal completion counter, which may cause C<final_cb> to be
invoked multiple times or trigger use-after-free.

=head1 FUNCTIONS

=head2 parallel(\@tasks, \&final_cb, [$unsafe])

Executes all tasks concurrently. The C<final_cb> is called once all tasks 
have invoked their C<done> callback.

If the optional C<$unsafe> flag is set to a true value, C<EV::Future> will skip 
evaluating tasks inside a C<eval> block and will reuse a single callback 
object for all tasks. This provides a massive performance boost (up to 100% 
faster) but bypasses per-task double-call protection and will cause issues 
if tasks throw exceptions. Use only when performance is critical and tasks 
are well-behaved.

=head2 parallel_limit(\@tasks, $limit, \&final_cb, [$unsafe])

Executes tasks concurrently, but with at most C<$limit> tasks in-flight at
any time. As each task completes, the next pending task is dispatched.

C<$limit> is clamped to the range C<1..scalar(@tasks)>. With C<$limit E<gt>= @tasks>
this behaves like C<parallel>; with C<$limit == 1> it runs tasks sequentially.

There is no cancellation mechanism for C<parallel_limit>; all dispatched
tasks must complete.

The C<$unsafe> flag has the same meaning as in C<parallel>.

=head2 series(\@tasks, \&final_cb, [$unsafe])

Executes tasks one by one. The next task is only started after the current 
task calls its C<done> callback.

If the optional C<$unsafe> flag is set to a true value, error-checking overhead 
is bypassed for maximum performance. See C<parallel> for warnings about exceptions.

To cancel the series and skip all subsequent tasks (in both safe and
unsafe modes), pass a true value to the C<done> callback:

  series([
      sub { my $d = shift; $d->(1) }, # Cancel here
      sub { die "This will never run" },
  ], sub {
      print "Series finished early\n";
  });

=head1 BENCHMARKS

1000 synchronous tasks, 5000 iterations (C<bench/benchmark.pl>):

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

Safe mode allocates a per-task CV for double-call protection and wraps
each dispatch in C<G_EVAL>. Unsafe mode reuses a single shared CV and
skips C<G_EVAL>, roughly doubling throughput.

=head1 SEE ALSO

L<EV>, L<Future::XS>, L<Promise::XS>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
