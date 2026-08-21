package Hyperman::Future;

use strict;
use warnings;

our $VERSION = '0.32';

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
C<done>/C<fail>/C<cancel>, C<on_ready>/C<on_done>/C<on_fail>, C<then>/C<else>/
C<followed_by>/C<transform>, C<get>/C<await>, and the convergent combinators
C<wait_all>/C<wait_any>/C<needs_all>/C<needs_any>.

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

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
