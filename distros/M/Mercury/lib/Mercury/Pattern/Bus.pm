package Mercury::Pattern::Bus;
our $VERSION = '0.016';
# ABSTRACT: A messaging pattern where all peers share messages

#pod =head1 SYNOPSIS
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base '-base';

#pod =attr peers
#pod
#pod The list of peers connected to this bus.
#pod
#pod =cut

has peers => sub { [] };

#pod =method add_peer
#pod
#pod     $pat->add_peer( $tx )
#pod
#pod Add the given connection as a peer to this bus.
#pod
#pod =cut

sub add_peer {
    my ( $self, $tx ) = @_;
    $tx->on( message => sub {
        my ( $tx, $msg ) = @_;
        $self->send_message( $msg, $tx );
    } );
    $tx->on( finish => sub {
        my ( $tx ) = @_;
        $self->remove_peer( $tx );
    } );
    push @{ $self->peers }, $tx;
    return;
}

#pod =method remove_peer
#pod
#pod Remove the connection from this bus. Called automatically by the C<finish>
#pod handler.
#pod
#pod =cut

sub remove_peer {
    my ( $self, $tx ) = @_;
    my @peers = @{ $self->peers };
    for my $i ( 0.. $#peers ) {
        if ( $peers[$i] eq $tx ) {
            splice @peers, $i, 1;
            return;
        }
    }
    return;
}

#pod =method send_message
#pod
#pod     $pat->send_message( $message, $from )
#pod
#pod Send a message to all the peers on this bus. If a C<$from> websocket is
#pod specified, will not send to that peer (they should know what they sent).
#pod
#pod =cut

sub send_message {
    my ( $self, $msg, $from_tx ) = @_;
    my @peers = @{ $self->peers };
    if ( $from_tx ) {
        @peers = grep { $_ ne $from_tx } @peers;
    }
    $_->send( $msg ) for @peers;
}


1;

__END__

=pod

=head1 NAME

Mercury::Pattern::Bus - A messaging pattern where all peers share messages

=head1 VERSION

version 0.016

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 peers

The list of peers connected to this bus.

=head1 METHODS

=head2 add_peer

    $pat->add_peer( $tx )

Add the given connection as a peer to this bus.

=head2 remove_peer

Remove the connection from this bus. Called automatically by the C<finish>
handler.

=head2 send_message

    $pat->send_message( $message, $from )

Send a message to all the peers on this bus. If a C<$from> websocket is
specified, will not send to that peer (they should know what they sent).

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
