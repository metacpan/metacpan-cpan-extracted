package Hyperman::Event::Kqueue;

use strict;
use warnings;

our $VERSION = '0.09';

require Hyperman;   # loads the shared XS (available())

1;

__END__

=head1 NAME

Hyperman::Event::Kqueue - kqueue readiness backend for Hyperman::Loop

=head1 SYNOPSIS

    use Hyperman::Event::Kqueue;
    Hyperman::Event::Kqueue->available;   # true on macOS / BSD

=head1 DESCRIPTION

The kqueue implementation of the L<Hyperman::Loop> backend interface:
C<add/modify/remove/wait> over C<kevent(2)>, with timers as C<EVFILT_TIMER>
and shutdown signals as C<EVFILT_SIGNAL>. The interface is a C vtable
(F<include/hyperman/hyperman.h>); this module reports availability and
documents the backend. C<< Hyperman::Loop->new >> selects it automatically
on platforms that have kqueue; L<Hyperman::Event::Epoll>,
L<Hyperman::Event::Poll>, and L<Hyperman::Event::IOUring> implement the
same vtable elsewhere.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software,
licensed under the Artistic License 2.0.

=cut
