package IPC::Manager::Role::Client::Connection;
use strict;
use warnings;

our $VERSION = '0.000035';

use Time::HiRes qw/time/;

use Role::Tiny;

requires qw{
    _connections
    _close_connection
};

sub has_connection {
    my $self = shift;
    my ($peer) = @_;
    return exists $self->_connections->{$peer} ? 1 : 0;
}

sub connections {
    my $self = shift;
    return sort keys %{$self->_connections};
}

sub disconnect_connection {
    my $self = shift;
    my ($peer) = @_;
    my $cons = $self->_connections;
    return 0 unless exists $cons->{$peer};
    $self->_close_connection($peer);
    return 1;
}

sub last_activity {
    my $self = shift;
    my ($peer) = @_;
    my $entry = $self->_connections->{$peer} or return undef;
    return $entry->{last_active};
}

sub close_idle_connections {
    my $self = shift;
    my ($max_idle) = @_;

    my $cutoff = time - $max_idle;
    my $cons   = $self->_connections;

    my $closed = 0;
    for my $peer (keys %$cons) {
        my $la = $cons->{$peer}->{last_active} // next;
        next if $la >= $cutoff;
        $self->_close_connection($peer);
        $closed++;
    }

    return $closed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Role::Client::Connection - Per-connection management for connection-oriented clients

=head1 DESCRIPTION

A L<Role::Tiny> role for IPC clients that maintain a per-peer set of live
connections (e.g. L<IPC::Manager::Client::ConnectionUnix>, and a planned
TCP-based C<ConnectionIP>).  It provides a small API for inspecting and
terminating individual connections, and for reaping connections that have been
idle for too long.

=head1 REQUIRED METHODS

The consuming class must provide:

=over 4

=item $hashref = $self->_connections

Returns the underlying connection cache as a hashref keyed by peer id.  Each
value is a hashref with at least:

=over 4

=item fh

The live filehandle / socket for that peer.

=item last_active

A C<Time::HiRes::time> epoch updated whenever the consuming class successfully
sends or receives bytes on that connection.

=back

The role only reads C<last_active> and the set of keys; the structure is
otherwise opaque to it.

=item $self->_close_connection($peer_id)

Closes the underlying handle for C<$peer_id> and removes the entry from the
connection cache.  May be called from inside C<close_idle_connections>; safe
to no-op if the connection is already gone.

=back

=head1 PROVIDED METHODS

=over 4

=item $bool = $self->has_connection($peer_id)

True iff there is a cached connection to C<$peer_id>.

=item @peer_ids = $self->connections

Sorted list of peer ids that have an active cached connection.

=item $bool = $self->disconnect_connection($peer_id)

Closes the connection to C<$peer_id> if any, returning true if a connection
was present.

=item $epoch = $self->last_activity($peer_id)

Returns the C<Time::HiRes> epoch at which the connection to C<$peer_id> last
sent or received bytes.  Returns C<undef> if no such connection exists.

=item $count = $self->close_idle_connections($max_idle_seconds)

Closes every cached connection whose C<last_active> is older than C<time -
$max_idle_seconds>.  Returns the number of connections closed.

This method is caller-driven: the role does not run any background timer.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
