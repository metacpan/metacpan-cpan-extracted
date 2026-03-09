package Linux::Event::Proactor::Backend;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

1;

__END__

=head1 NAME

Linux::Event::Proactor::Backend - Contract for completion backends used by Linux::Event::Proactor

=head1 DESCRIPTION

This module documents the contract implemented by completion backends for
L<Linux::Event::Proactor>.

A proactor backend submits operations to an underlying completion mechanism,
tracks backend tokens, delivers raw completions, and participates in
cancellation. The proactor engine itself owns operation objects, callback
queueing, result normalization, and settle-once guarantees.

=head1 REQUIRED METHODS

=head2 _new(%args)

Construct the backend. The C<loop> argument is required.

=head2 name()

Return a short backend name such as C<uring> or C<fake>.

=head2 _submit_read($op, %args)

=head2 _submit_write($op, %args)

=head2 _submit_recv($op, %args)

=head2 _submit_send($op, %args)

=head2 _submit_accept($op, %args)

=head2 _submit_connect($op, %args)

=head2 _submit_timeout($op, %args)

=head2 _submit_shutdown($op, %args)

=head2 _submit_close($op, %args)

Submit the operation and return a backend token suitable for registry and
cancellation bookkeeping.

=head2 _cancel_op($op)

Attempt to cancel the in-flight operation. Cancellation may complete
asynchronously. The backend must cooperate with the proactor's settle-once and
registry rules.

=head2 _complete_backend_events()

Drive backend completion processing once and return the number of processed
backend events when available.

=head1 COMPLETION RULES

A backend must never run user callbacks inline. It should report raw completion
facts back into the owning proactor so the proactor can normalize the result and
queue any callback.

For io_uring-style backends, a negative completion result is a negative errno.
The backend or the engine must normalize that into a positive errno and create a
L<Linux::Event::Error> object.

=head1 BUFFER LIFETIME

For operations that expose user buffers to the kernel, the backend must keep the
necessary Perl values alive until the kernel no longer needs them.

=head1 CANCELLATION AND RACES

Cancellation is inherently racy. A backend must be written so that an operation
cannot settle twice even when completion and cancellation race closely together.

=head1 SEE ALSO

L<Linux::Event::Proactor>,
L<Linux::Event::Proactor::Backend::Uring>,
L<Linux::Event::Proactor::Backend::Fake>,
L<Linux::Event::Operation>,
L<Linux::Event::Error>

=cut
