package Linux::Event::Backend;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.009';

1;

__END__

=head1 NAME

Linux::Event::Backend - Backend contract for Linux::Event::Loop

=head1 DESCRIPTION

This module documents the minimal backend interface expected by
L<Linux::Event::Loop>. Backends are intentionally duck-typed.

The loop owns scheduling policy (clock/timer/scheduler). The backend owns the
wait/dispatch mechanism (epoll now, io_uring later).

=head1 STATUS

As of version 0.006, the backend contract described here is considered stable.
New optional methods may be added in future releases, but required methods and callback ABI
will not change.

=head1 REQUIRED METHODS

=head2 new(%args)

Create the backend instance.

=head2 watch($fh, $mask, $cb, %opt) -> $fd

Register a filehandle for readiness notifications.

Callback signature (standardized by this project):

  $cb->($loop, $fh, $fd, $mask, $tag);

Where:

=over 4

=item * C<$loop> is the L<Linux::Event::Loop> instance

=item * C<$fh> is the watched filehandle

=item * C<$fd> is the integer file descriptor

=item * C<$mask> is an integer readiness mask (backend-defined bit layout,
standardized within this project)

=item * C<$tag> is an arbitrary user value (optional; may be undef)

=back

Backends may accept additional options in C<%opt>. This distribution uses:

=over 4

=item * C<_loop> - the loop reference to pass through to the callback

=item * C<tag> - the tag value to pass through to the callback

=back

=head2 unwatch($fh_or_fd) -> $bool

Remove a watcher by filehandle or file descriptor.

=head2 run_once($loop, $timeout_s=undef) -> $n

Block until events occur (or timeout) and dispatch them.

Return value is backend-defined; for now callers should not rely on it.

=head1 OPTIONAL METHODS

=head2 modify($fh_or_fd, $mask, %opt) -> $bool

Update an existing watcher registration (e.g. add/remove interest in writable).
If not implemented, the loop may fall back to unwatch+watch.

=head1 SEE ALSO

L<Linux::Event::Loop>, L<Linux::Event::Backend::Epoll>

=head1 SYNOPSIS

  # Internal. See L<Linux::Event::Loop>.

=head1 VERSION

This document describes Linux::Event::Backend version 0.006.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
