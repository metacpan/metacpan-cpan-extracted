package Mercury::Controller::Bus;
our $VERSION = '0.014';
# ABSTRACT: A messaging pattern where all subscribers share messages

#pod =head1 SYNOPSIS
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';
use Mercury::Pattern::Bus;

#pod =method connect
#pod
#pod Establish a WebSocket message bus to send/receive messages on the given
#pod C<topic>. All clients connected to the topic will receive all messages
#pod published on the topic.
#pod
#pod This is a shorter way of doing both C</pub/*topic> and C</sub/*topic>,
#pod without the hierarchical message passing.
#pod
#pod One difference is that by default a sender will not receive a message
#pod that they sent. To enable this behavior, pass a true value as the C<echo>
#pod query parameter when establishing the websocket.
#pod
#pod   $ua->websocket('/bus/foo?echo=1' => sub { ... });
#pod
#pod =cut

sub connect {
    my ( $c ) = @_;

    my $topic = $c->stash( 'topic' );
    my $pattern = $c->_pattern( $topic );
    $pattern->add_peer( $c->tx );
    if ( $c->param( 'echo' ) ) {
        $c->tx->on( message => sub {
            my ( $tx, $msg ) = @_;
            $tx->send( $msg );
        } );
    }

    $c->rendered( 101 );
};

#pod =method post
#pod
#pod Post a new message to the given topic without subscribing or
#pod establishing a WebSocket connection. This allows new messages to be
#pod pushed by any HTTP client.
#pod
#pod =cut

sub post {
    my ( $c ) = @_;
    my $topic = $c->stash( 'topic' );
    my $pattern = $c->_pattern( $topic );
    $pattern->send_message( $c->req->body );
    $c->render(
        status => 200,
        text => '',
    );
}

#=method _pattern
#
#   my $pattern = $c->_pattern( $topic );
#
# Get or create the L<Mercury::Pattern::Bus> object for the given
# topic.
#
#=cut

sub _pattern {
    my ( $c, $topic ) = @_;
    my $pattern = $c->mercury->pattern( Bus => $topic );
    if ( !$pattern ) {
        $pattern = Mercury::Pattern::Bus->new;
        $c->mercury->pattern( Bus => $topic => $pattern );
    }
    return $pattern;
}

1;

__END__

=pod

=head1 NAME

Mercury::Controller::Bus - A messaging pattern where all subscribers share messages

=head1 VERSION

version 0.014

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 connect

Establish a WebSocket message bus to send/receive messages on the given
C<topic>. All clients connected to the topic will receive all messages
published on the topic.

This is a shorter way of doing both C</pub/*topic> and C</sub/*topic>,
without the hierarchical message passing.

One difference is that by default a sender will not receive a message
that they sent. To enable this behavior, pass a true value as the C<echo>
query parameter when establishing the websocket.

  $ua->websocket('/bus/foo?echo=1' => sub { ... });

=head2 post

Post a new message to the given topic without subscribing or
establishing a WebSocket connection. This allows new messages to be
pushed by any HTTP client.

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
