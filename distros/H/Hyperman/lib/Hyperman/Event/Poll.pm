package Hyperman::Event::Poll;

use strict;
use warnings;

our $VERSION = '0.09';

require Hyperman;   # loads the shared XS (available())

1;

__END__

=head1 NAME

Hyperman::Event::Poll - portable poll(2) backend for Hyperman::Loop

=head1 SYNOPSIS

    use Hyperman::Event::Poll;
    Hyperman::Event::Poll->available;   # always true

=head1 DESCRIPTION

The portability floor for the L<Hyperman::Loop> backend interface: io
readiness via C<poll(2)>, timers as a deadline
list against the monotonic clock, signals via a self-pipe. Used when neither
kqueue nor epoll is available; force with C<HYPERMAN_BACKEND=poll> or
C<< Hyperman::Loop->new('poll') >> (useful for exercising the portable path
in tests).

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software,
licensed under the Artistic License 2.0.

=cut
