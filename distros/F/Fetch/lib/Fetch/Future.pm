package Fetch::Future;

use strict;
use warnings;

our $VERSION = '0.09';

# An external event loop may install an awaiter here so ->get/->await on a
# pending future pumps it when we are not already inside a running loop.
# Signature: $AWAIT->($future).
our $AWAIT;

require Fetch;

1;

__END__

=head1 NAME

Fetch::Future - a fast, native, Future-compatible async result

=head1 SYNOPSIS

    my $f = Fetch::Future->new;
    $f->on_done(sub { my $v = shift; ... });
    $f->done(42);

    my $all = Fetch::Future->needs_all($f1, $f2);
    my @v   = $f->get;   # pumps the active loop (or Standalone) until ready

=head1 DESCRIPTION

An asynchronous result with an API compatible with CPAN L<Future>:
C<done>/C<fail>/C<cancel>, C<on_ready>/C<on_done>/C<on_fail>,
C<then>/C<else>/C<followed_by>/C<transform>, C<get>/C<await>, and the
convergent combinators C<wait_all>/C<wait_any>/C<needs_all>/C<needs_any>.

The implementation is entirely XS over an array-slot object; continuations are
C closures trampolined through a fire queue, so long C<then>-chains run
iteratively with bounded stack depth.

C<get>/C<await> on a pending future pump the current event loop re-entrantly.
Outside a running loop, an external loop may install C<$Fetch::Future::AWAIT>
(a coderef receiving the future) to make awaiting work.

C<as_cpan_future> / C<from_future> convert to and from CPAN L<Future> objects
for interop with C<isa('Future')> code.

=head1 CONSTRUCTORS

=head2 new

    my $f = Fetch::Future->new;

A new pending future.

=head2 done_future(@values) / fail_future(@failure)

    my $f = Fetch::Future->done_future(42);
    my $f = Fetch::Future->fail_future("nope\n");

An already-resolved future, done with C<@values> or failed with C<@failure>.

=head1 RESOLVING

=head2 done(@values)

Mark a pending future done with C<@values>; fires its ready/done callbacks.
Returns the future.

=head2 fail($message, @details)

Mark a pending future failed. Returns the future.

=head2 cancel

Cancel a pending future.

=head1 STATE

=head2 is_ready / is_done / is_failed / is_cancelled

Booleans: whether the future has settled at all, and how.

=head1 CALLBACKS

=head2 on_ready($cb)

Call C<< $cb->($future) >> when the future settles (done, failed or
cancelled). Returns the future.

=head2 on_done($cb) / on_fail($cb)

Call C<< $cb->(@values) >> on success, or C<< $cb->(@failure) >> on failure.
Return the future.

=head1 CHAINING

Each returns a new future and flattens a future returned by the callback, so
long chains compose without nesting.

=head2 then($on_done) / then($on_done, $on_fail)

Run C<$on_done> with the values when this future succeeds; its result (a value
list or a future) becomes the new future's result. Failure passes through
unless C<$on_fail> is given.

=head2 else($on_fail)

Like C<then> but for the failure branch.

=head2 followed_by($cb)

Call C<< $cb->($future) >> once this future settles either way, and adopt the
future it returns.

=head2 transform(done => $cb, fail => $cb)

Map the done values and/or failure through the given coderefs.

=head1 AWAITING

=head2 get / result

    my @values = $f->get;      # or a scalar in scalar context

Block until the future is ready, pumping the active event loop (the Standalone
loop if none), then return its values - or rethrow its failure.

=head2 await

Block until ready (pumping the loop) and return the future itself.

=head2 failure

The failure of a failed future (the first failure value), or undef.

=head1 COMBINATORS

Each takes a list of futures and returns one future.

=head2 needs_all(@futures)

Done when all succeed (with their combined values); fails as soon as any fails.

=head2 needs_any(@futures)

Done as soon as any succeeds; fails only if all fail.

=head2 wait_all(@futures)

Done when all have settled, whatever the outcome.

=head2 wait_any(@futures)

Done as soon as any has settled.

=head1 INTEROP

=head2 as_cpan_future

A real CPAN L<Future> that settles when this one does, for code expecting
C<< isa('Future') >>.

=head2 from_future($cpan_future)

    my $f = Fetch::Future->from_future($cpan_future);

A Fetch::Future that mirrors the given CPAN L<Future>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
