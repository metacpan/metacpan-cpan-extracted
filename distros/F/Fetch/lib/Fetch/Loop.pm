package Fetch::Loop;

use strict;
use warnings;

our $VERSION = '0.09';

use Exporter 'import';

use constant {
    FT_READ  => 0x1,
    FT_WRITE => 0x2,
};
our @EXPORT_OK = qw(FT_READ FT_WRITE);

sub _fh_for_fd {
    my ($self, $fd) = @_;
    open my $fh, '+<&', $fd or die "Fetch::Loop: cannot alias fd $fd: $!";
    return $fh;
}

1;

__END__

=head1 NAME

Fetch::Loop - the event-loop adapter interface Fetch drives

=head1 DESCRIPTION

Fetch's C core owns the sockets and the request state machine; a loop only has
to tell it when a socket is readable or writable. An adapter is any object with
a single method:

=head2 _ft_arm($fd, $mask, $cv)

Reconcile the readiness interest registered for the bare descriptor C<$fd> so
that exactly the directions in C<$mask> are watched, each firing C<$cv> (a
Perl coderef, called with no arguments) when the descriptor is ready. C<$mask>
is a bitmask of C<FT_READ> (C<0x1>) and C<FT_WRITE> (C<0x2>); C<$mask == 0>
removes all interest for C<$fd>. C<$cv> is the same coderef across calls for a
given connection, so adapters may key their bookkeeping on C<$fd> alone.

The C core calls this whenever a connection needs a different readiness
direction, and once more with C<$mask == 0> when the connection closes.

Adapters also provide C<install_await>, which sets C<$Fetch::Future::AWAIT> so
a bare C<< $future->get >> pumps the underlying loop until the future is ready.

=head1 ADAPTERS

L<Fetch::Loop::Standalone> (the vendored C loop, the default),
L<Fetch::Loop::Hyperman>, L<Fetch::Loop::IOAsync>, L<Fetch::Loop::AnyEvent>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
