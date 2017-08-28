package Mercury::Pattern::PubSub;
our $VERSION = '0.015';
# ABSTRACT: Manage a pub/sub pattern for a single topic

#pod =head1 SYNOPSIS
#pod
#pod     # Connect the publisher
#pod     my $pub_ua = Mojo::UserAgent->new;
#pod     my $pub_tx = $ua->websocket( '/pub/foo' );
#pod
#pod     # Connect the subscriber socket
#pod     my $sub_ua = Mojo::UserAgent->new;
#pod     my $sub_tx = $ua->websocket( '/sub/foo' );
#pod
#pod     # Connect the two sockets using pub/sub
#pod     my $pattern = Mercury::Pattern::PubSub->new;
#pod     $pattern->add_publisher( $pub_tx );
#pod     $pattern->add_subscriber( $sub_tx );
#pod
#pod     # Send a message
#pod     $sub_tx->on( message => sub {
#pod         my ( $tx, $msg ) = @_;
#pod         print $msg; # Hello, World!
#pod     } );
#pod     $pub_tx->send( 'Hello, World!' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This pattern connects publishers, which send messages, to subscribers,
#pod which recieve messages. Each message sent by a publisher will be
#pod received by all connected subscribers. This pattern is useful for
#pod sending notification events and logging.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Mercury::Controller::PubSub>
#pod
#pod =item L<Mercury>
#pod
#pod =back
#pod
#pod =cut

use Mojo::Base 'Mojo';

#pod =attr subscribers
#pod
#pod Arrayref of connected websockets ready to receive messages
#pod
#pod =cut

has subscribers => sub { [] };

#pod =attr publishers
#pod
#pod Arrayref of connected websockets ready to publish messages
#pod
#pod =cut

has publishers => sub { [] };

#pod =method add_subscriber
#pod
#pod     $pat->add_subscriber( $tx );
#pod
#pod Add the connection as a subscriber. Subscribers will receive all messages
#pod sent by publishers.
#pod
#pod =cut

sub add_subscriber {
    my ( $self, $tx ) = @_;
    $tx->on( finish => sub {
        my ( $tx ) = @_;
        $self->remove_subscriber( $tx );
    } );
    push @{ $self->subscribers }, $tx;
    return;
}

#pod =method remove_subscriber
#pod
#pod     $pat->remove_subscriber( $tx );
#pod
#pod Remove a subscriber. Called automatically when a subscriber socket is
#pod closed.
#pod
#pod =cut

sub remove_subscriber {
    my ( $self, $tx ) = @_;
    my @subs = @{ $self->subscribers };
    for my $i ( 0.. $#subs ) {
        if ( $subs[$i] eq $tx ) {
            splice @subs, $i, 1;
            return;
        }
    }
}

#pod =method add_publisher
#pod
#pod     $pat->add_publisher( $tx );
#pod
#pod Add a publisher to this topic. Publishers send messages to all
#pod subscribers.
#pod
#pod =cut

sub add_publisher {
    my ( $self, $tx ) = @_;
    $tx->on( message => sub {
        my ( $tx, $msg ) = @_;
        $self->send_message( $msg );
    } );
    $tx->on( finish => sub {
        my ( $tx ) = @_;
        $self->remove_publisher( $tx );
    } );
    push @{ $self->publishers }, $tx;
    return;
}

#pod =method remove_publisher
#pod
#pod     $pat->remove_publisher( $tx );
#pod
#pod Remove a publisher from the list. Called automatically when the
#pod publisher socket is closed.
#pod
#pod =cut

sub remove_publisher {
    my ( $self, $tx ) = @_;
    my @pubs = @{ $self->publishers };
    for my $i ( 0.. $#pubs ) {
        if ( $pubs[$i] eq $tx ) {
            splice @pubs, $i, 1;
            return;
        }
    }
}

#pod =method send_message
#pod
#pod     $pat->send_message( $message );
#pod
#pod Send a message to all subscribers.
#pod
#pod =cut

sub send_message {
    my ( $self, $message ) = @_;
    $_->send( $message ) for @{ $self->subscribers };
    return;
}

1;

__END__

=pod

=head1 NAME

Mercury::Pattern::PubSub - Manage a pub/sub pattern for a single topic

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    # Connect the publisher
    my $pub_ua = Mojo::UserAgent->new;
    my $pub_tx = $ua->websocket( '/pub/foo' );

    # Connect the subscriber socket
    my $sub_ua = Mojo::UserAgent->new;
    my $sub_tx = $ua->websocket( '/sub/foo' );

    # Connect the two sockets using pub/sub
    my $pattern = Mercury::Pattern::PubSub->new;
    $pattern->add_publisher( $pub_tx );
    $pattern->add_subscriber( $sub_tx );

    # Send a message
    $sub_tx->on( message => sub {
        my ( $tx, $msg ) = @_;
        print $msg; # Hello, World!
    } );
    $pub_tx->send( 'Hello, World!' );

=head1 DESCRIPTION

This pattern connects publishers, which send messages, to subscribers,
which recieve messages. Each message sent by a publisher will be
received by all connected subscribers. This pattern is useful for
sending notification events and logging.

=head1 ATTRIBUTES

=head2 subscribers

Arrayref of connected websockets ready to receive messages

=head2 publishers

Arrayref of connected websockets ready to publish messages

=head1 METHODS

=head2 add_subscriber

    $pat->add_subscriber( $tx );

Add the connection as a subscriber. Subscribers will receive all messages
sent by publishers.

=head2 remove_subscriber

    $pat->remove_subscriber( $tx );

Remove a subscriber. Called automatically when a subscriber socket is
closed.

=head2 add_publisher

    $pat->add_publisher( $tx );

Add a publisher to this topic. Publishers send messages to all
subscribers.

=head2 remove_publisher

    $pat->remove_publisher( $tx );

Remove a publisher from the list. Called automatically when the
publisher socket is closed.

=head2 send_message

    $pat->send_message( $message );

Send a message to all subscribers.

=head1 SEE ALSO

=over

=item L<Mercury::Controller::PubSub>

=item L<Mercury>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
