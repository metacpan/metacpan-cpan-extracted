package Linux::Event::Reactor::Backend;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

1;

__END__

=head1 NAME

Linux::Event::Reactor::Backend - Contract for readiness backends used by Linux::Event::Reactor

=head1 DESCRIPTION

This module documents the contract implemented by readiness backends for
L<Linux::Event::Reactor>.

A reactor backend owns the kernel registration and wait mechanism. The reactor
engine owns watcher replacement policy, timer integration, dispatch order,
signal integration, wakeups, and pidfd policy.

Backends are duck-typed, but they are expected to implement the method surface
and callback semantics documented here.

=head1 REQUIRED METHODS

=head2 new(%args)

Construct the backend object.

=head2 name()

Return a short backend name such as C<epoll>.

=head2 watch($fh, $mask, $cb, %opt)

Register readiness interest for C<$fh> and return the integer file descriptor.

The callback ABI is:

  $cb->($loop, $fh, $fd, $mask, $tag)

Where C<$loop> and C<$tag> come from C<%opt> if provided.

=head2 unwatch($fh_or_fd)

Remove an existing registration. Return true if a registration was removed.

=head2 run_once($loop, $timeout_s = undef)

Enter the backend wait once, dispatch native readiness callbacks, and return the
number of processed events when available.

=head1 OPTIONAL METHODS

=head2 modify($fh_or_fd, $mask, %opt)

Update an existing registration without a delete-and-add cycle. The reactor can
fall back to C<unwatch> plus C<watch> when this method is absent.

=head1 READINESS MASKS

The reactor uses these bit flags:

  READABLE => 0x01
  WRITABLE => 0x02
  PRIO     => 0x04
  RDHUP    => 0x08
  ET       => 0x10
  ONESHOT  => 0x20
  ERR      => 0x40
  HUP      => 0x80

The backend is responsible for translating between these masks and the native
kernel representation.

=head1 CALLBACK RULES

Backend callbacks may run inline from C<run_once>. That is normal for the
reactor model.

A backend must not reinterpret watcher policy. In particular, it must not
change the dispatch order chosen by the reactor engine.

=head1 FILEHANDLE OWNERSHIP

A reactor backend observes filehandles. It does not take ownership of them.
Closing a filehandle remains the caller's responsibility.

=head1 SEE ALSO

L<Linux::Event::Reactor>,
L<Linux::Event::Reactor::Backend::Epoll>,
L<Linux::Event::Proactor::Backend>

=cut
