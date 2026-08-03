package Fetch::Loop::Standalone;

use strict;
use warnings;

our $VERSION = '0.06';

require Fetch;

sub install_await {
    my ($self) = @_;
    $Fetch::Future::AWAIT = sub { $self->run_until($_[0]) };
    return $self;
}

1;

__END__

=head1 NAME

Fetch::Loop::Standalone - Fetch's own vendored C event loop

=head1 SYNOPSIS

    my $loop = Fetch::Loop::Standalone->new;   # best backend for the platform
    $loop->timer(0.1, sub { print "tick\n" });
    $loop->run_until($future);

=head1 DESCRIPTION

The default event loop used when no framework loop (Hyperman, IO::Async,
AnyEvent) is active. It wraps a pluggable readiness backend (kqueue on
macOS/BSD, epoll on Linux, io_uring when available, poll everywhere) behind
C<watch_io>/C<unwatch_io>/C<timer>, and pumps with C<run>/C<run_until>/C<stop>.

=head2 new([$backend])

Create a loop; pass a backend name (C<kqueue>/C<epoll>/C<poll>/C<iouring>) to
force one, otherwise the best available is chosen.

=head2 watch_io($fh, $mode, $cb) / unwatch_io($fh, $mode)

Register/remove a persistent readiness callback; C<$mode> contains C<r> and/or
C<w>. C<$fh> is a filehandle or a bare fd number.

=head2 timer($secs, $cb)

Run C<$cb> once after C<$secs>.

=head2 run / run_until($future) / stop

Pump the loop until C<stop>, or until C<$future> resolves.

=head2 backend

The name of the readiness backend in use.

=head2 install_await

Install C<$Fetch::Future::AWAIT> so a bare C<< $future->get >> pumps this loop.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
