package Hyperman::Event::Epoll;

use strict;
use warnings;

our $VERSION = '0.16';

require Hyperman;   # loads the shared XS (available())

1;

__END__

=head1 NAME

Hyperman::Event::Epoll - epoll readiness backend for Hyperman::Loop

=head1 SYNOPSIS

    use Hyperman::Event::Epoll;
    Hyperman::Event::Epoll->available;   # true on Linux

=head1 DESCRIPTION

The Linux implementation of the L<Hyperman::Loop> backend interface: io
readiness via C<epoll(7)> with a combined per-fd
mask, timers via C<timerfd_create(2)>, and shutdown signals via
C<signalfd(2)> (the signals are blocked and read as data). Selected
automatically on Linux; force with C<HYPERMAN_BACKEND=epoll> or
C<< Hyperman::Loop->new('epoll') >>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software,
licensed under the Artistic License 2.0.

=cut
