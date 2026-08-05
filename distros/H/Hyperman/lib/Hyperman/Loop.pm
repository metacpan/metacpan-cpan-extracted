package Hyperman::Loop;

use strict;
use warnings;

our $VERSION = '0.09';

require Hyperman;   # all methods are XS (xs/loop.xs, include/hyperman/)

1;

__END__

=head1 NAME

Hyperman::Loop - the per-worker event loop

=head1 SYNOPSIS

    use Hyperman::Loop;

    my $loop = Hyperman::Loop->new;          # backend picked per platform
    my $poll = Hyperman::Loop->new('poll');  # or forced by name

    my $w = $loop->watch_io($fh, 'r', sub { ... });  # persistent callback
    $loop->unwatch_io($w);
    $loop->timer(0.5, sub { ... });          # one-shot callback timer
    $loop->defer(sub { ... });               # run-soon queue

    my $f = $loop->timer_f(0.5);             # Futures resolved by the loop
    my $g = $loop->readable_f($fh);
    my $h = $loop->writable_f($fh);
    $loop->run_until($f);                    # pump until $f is ready
    $loop->run;                              # run until ->stop
    $loop->stop;

    $loop->install_await;                    # ->get pumps this loop

=head1 DESCRIPTION

The event loop at the core of L<Hyperman>, exposed
standalone and implemented entirely in XS. A worker created by
C<< Hyperman->run >> is this same loop with the PSGI server (listener, HTTP
machinery, shutdown signal watchers, timeout sweep) attached;
C<< Hyperman->loop >> returns it from inside a worker.

The OS readiness mechanism is a pluggable backend behind a C vtable
(add/modify/remove/wait): L<Hyperman::Event::Kqueue> on macOS/BSD,
L<Hyperman::Event::Epoll> on Linux, L<Hyperman::Event::Poll> everywhere, and
the opt-in L<Hyperman::Event::IOUring>. C<< $loop->backend >> names the one
in use; force a choice with C<HYPERMAN_BACKEND> or C<< new($name) >>.

C<run> is re-entrant: C<< $future->get >> inside a running worker calls
C<run_until> on the same loop, so awaiting services other connections instead
of blocking them. C<stop> stops the innermost running iteration.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software,
licensed under the Artistic License 2.0.

=cut
