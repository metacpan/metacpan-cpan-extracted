package Hyperman::Future;

use strict;
use warnings;

our $VERSION = '0.46';

# An external event loop may install an awaiter here so ->get/->await on a
# pending future pumps it; inside a running Hyperman loop it is not needed.
# Signature: $AWAIT->($future).
our $AWAIT;

require Hyperman;   # all methods are XS (xs/future.xs, include/hyperman/)

1;

__END__

=head1 NAME

Hyperman::Future - a fast, native, Future-compatible async result

=head1 SYNOPSIS

    use Hyperman::Future;

    my $f = Hyperman::Future->new;
    $f->then(sub { my $v = shift; ... });
    $f->done(42);

    my $all = Hyperman::Future->needs_all($f1, $f2);

    # inside a running Hyperman worker, awaiting pumps the loop:
    my @row = $db_future->get;

=head1 DESCRIPTION

An asynchronous result object with an API compatible with CPAN L<Future>:
C<done>/C<fail>/C<cancel>, C<on_ready>/C<on_done>/C<on_fail>/C<on_cancel>,
C<then>/C<else>/C<followed_by>/C<transform>, C<get>/C<await>, and the
convergent combinators C<wait_all>/C<wait_any>/C<needs_all>/C<needs_any>.

C<on_cancel> takes either a code reference, called with the future when it is
cancelled, or another future, which is cancelled with it. Registering on a
future that has already been cancelled runs the target at once; registering on
one that completed normally drops it, because that future will never cancel.

The implementation is entirely XS over an array-slot object: creation,
resolution, callback firing, chaining, and the combinators all run in C,
with continuations as C closures trampolined through a fire queue - long
C<then>-chains run iteratively with bounded stack depth. Cancelling a future
derived by C<then>/C<followed_by>/C<transform> propagates the cancellation
to its still-pending upstream.

C<get>/C<await> on a pending future inside a running Hyperman worker pump the
worker's own event loop re-entrantly, servicing other connections meanwhile.
Outside a Hyperman loop, an external loop may install
C<$Hyperman::Future::AWAIT> (a coderef receiving the future) to make awaiting
work; without either, awaiting a pending future croaks.

C<as_cpan_future> / C<from_future> convert to and from CPAN L<Future> objects
when interop with C<isa('Future')> code is needed. C<@ISA> is deliberately not
set to C<Future>: inherited Future methods would operate on its hash-based
internals, not this array-slot object.

=head1 ASYNC/AWAIT

This class implements the C<Future::AsyncAwait::Awaitable> API, so one of
these futures can be awaited directly:

    use Future::AsyncAwait;

    async sub handler {
        my $row = await $db_future;
        return [ 200, [], [ $row->{body} ] ];
    }

Whatever it awaited, an C<async sub> returns a CPAN L<Future> by default.
Naming this class at import makes it return one of these instead, which is
what a Hyperman worker parks a request on:

    use Future::AsyncAwait future_class => 'Hyperman::Future';

Cancelling the future an C<async sub> returned cancels whichever future it is
suspended on. The C<AWAIT_*> methods are that protocol; call the documented
names above rather than those.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
