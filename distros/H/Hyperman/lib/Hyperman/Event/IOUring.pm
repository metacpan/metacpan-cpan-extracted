package Hyperman::Event::IOUring;

use strict;
use warnings;

our $VERSION = '0.15';

require Hyperman;   # loads the shared XS (available())

1;

__END__

=head1 NAME

Hyperman::Event::IOUring - io_uring backend for Hyperman::Loop

=head1 SYNOPSIS

    use Hyperman::Event::IOUring;
    Hyperman::Event::IOUring->available;   # true on Linux >= 5.4 (and permitted)

    HYPERMAN_BACKEND=io_uring plackup -s Hyperman app.psgi

=head1 DESCRIPTION

An io_uring implementation of the L<Hyperman::Loop> backend interface, built
on B<liburing>. This first cut drives the ring in poll mode -
C<IORING_OP_POLL_ADD> readiness completions, re-armed for persistent
watchers - with timers as C<IORING_OP_TIMEOUT> and shutdown signals via a
signalfd polled on the ring. Completion-based read/write submission comes
later.

liburing is detected at build time (C<pkg-config>, or a C<-luring> compile
probe); when it is not installed the backend is compiled out and this
module's C<available> returns false, leaving epoll/poll in place. Install
your distribution's C<liburing-dev> (or C<liburing-devel>) and rebuild to
enable it.

B<Opt-in>: auto-selection remains kqueue E<gt> epoll E<gt> poll until this
backend is benchmarked; force it with C<HYPERMAN_BACKEND=io_uring> or
C<< Hyperman::Loop->new('io_uring') >>. Even when built in, C<available> is
false where the running kernel lacks io_uring or seccomp forbids it (e.g.
default Docker profiles).

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software,
licensed under the Artistic License 2.0.

=cut
