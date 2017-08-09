package Mercury::Pattern::PushPull;
our $VERSION = '0.014';
# ABSTRACT: Manage a push/pull pattern for a single topic

#pod =head1 SYNOPSIS
#pod
#pod     # Connect the pusher
#pod     my $push_ua = Mojo::UserAgent->new;
#pod     my $push_tx = $ua->websocket( '/push/foo' );
#pod
#pod     # Connect the puller socket
#pod     my $pull_ua = Mojo::UserAgent->new;
#pod     my $pull_tx = $ua->websocket( '/pull/foo' );
#pod
#pod     # Connect the two sockets using push/pull
#pod     my $pattern = Mercury::Pattern::PushPull->new;
#pod     $pattern->add_pusher( $push_tx );
#pod     $pattern->add_puller( $pull_tx );
#pod
#pod     # Send a message
#pod     $pull_tx->on( message => sub {
#pod         my ( $tx, $msg ) = @_;
#pod         print $msg; # Hello, World!
#pod     } );
#pod     $push_tx->send( 'Hello, World!' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This pattern connects pushers, which send messages, to pullers, which
#pod recieve messages. Each message sent by a pusher will be received by
#pod a single puller. This pattern is useful for dealing out jobs to workers.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Mercury::Controller::PushPull>
#pod
#pod =item L<Mercury>
#pod
#pod =back
#pod
#pod =cut

use Mojo::Base 'Mojo';

#pod =attr pullers
#pod
#pod Connected websockets ready to receive messages.
#pod
#pod =cut

has pullers => sub { [] };

#pod =attr pushers
#pod
#pod Connected websockets who will be pushing messages.
#pod
#pod =cut

has pushers => sub { [] };

#pod =attr current_puller_index
#pod
#pod The puller we will use to send the next message from a pusher.
#pod
#pod =cut

has current_puller_index => sub { 0 };

#pod =method add_puller
#pod
#pod     $pat->add_puller( $tx );
#pod
#pod Add a puller to this broker. Pullers are given messages in a round-robin, one
#pod at a time, by pushers.
#pod
#pod =cut

sub add_puller {
    my ( $self, $tx ) = @_;
    $tx->on( finish => sub {
        my ( $tx ) = @_;
        $self->remove_puller( $tx );
    } );
    push @{ $self->pullers }, $tx;
    return;
}

#pod =method add_pusher
#pod
#pod     $pat->add_pusher( $tx );
#pod
#pod Add a pusher to this broker. Pushers send messages to be processed by pullers.
#pod
#pod =cut

sub add_pusher {
    my ( $self, $tx ) = @_;
    $tx->on( message => sub {
        my ( $tx, $msg ) = @_;
        $self->send_message( $msg );
    } );
    $tx->on( finish => sub {
        my ( $tx ) = @_;
        $self->remove_pusher( $tx );
    } );
    push @{ $self->pushers }, $tx;
    return;
}

#pod =method send_message
#pod
#pod     $pat->send_message( $msg );
#pod
#pod Send the given message to the next puller in line.
#pod
#pod =cut

sub send_message {
    my ( $self, $msg ) = @_;
    my $i = $self->current_puller_index;
    my @pullers = @{ $self->pullers };
    $pullers[ $i ]->send( $msg );
    $self->current_puller_index( ( $i + 1 ) % @pullers );
    return;
}

#pod =method remove_puller
#pod
#pod     $pat->remove_puller( $tx );
#pod
#pod Remove a puller from the list. Called automatically when the puller socket
#pod is closed.
#pod
#pod =cut

sub remove_puller {
    my ( $self, $tx ) = @_;
    my @pullers = @{ $self->pullers };
    for my $i ( 0.. $#pullers ) {
        if ( $pullers[$i] eq $tx ) {
            splice @{ $self->pullers }, $i, 1;
            my $current_puller_index = $self->current_puller_index;
            if ( $i > 0 && $current_puller_index >= $i ) {
                $self->current_puller_index( $current_puller_index - 1 );
            }
            return;
        }
    }
}

#pod =method remove_pusher
#pod
#pod     $pat->remove_pusher( $tx );
#pod
#pod Remove a pusher from the list. Called automatically when the pusher socket
#pod is closed.
#pod
#pod =cut

sub remove_pusher {
    my ( $self, $tx ) = @_;
    my @pushers = @{ $self->pushers };
    for my $i ( 0.. $#pushers ) {
        if ( $pushers[$i] eq $tx ) {
            splice @pushers, $i, 1;
            return;
        }
    }
}

1;

__END__

=pod

=head1 NAME

Mercury::Pattern::PushPull - Manage a push/pull pattern for a single topic

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    # Connect the pusher
    my $push_ua = Mojo::UserAgent->new;
    my $push_tx = $ua->websocket( '/push/foo' );

    # Connect the puller socket
    my $pull_ua = Mojo::UserAgent->new;
    my $pull_tx = $ua->websocket( '/pull/foo' );

    # Connect the two sockets using push/pull
    my $pattern = Mercury::Pattern::PushPull->new;
    $pattern->add_pusher( $push_tx );
    $pattern->add_puller( $pull_tx );

    # Send a message
    $pull_tx->on( message => sub {
        my ( $tx, $msg ) = @_;
        print $msg; # Hello, World!
    } );
    $push_tx->send( 'Hello, World!' );

=head1 DESCRIPTION

This pattern connects pushers, which send messages, to pullers, which
recieve messages. Each message sent by a pusher will be received by
a single puller. This pattern is useful for dealing out jobs to workers.

=head1 ATTRIBUTES

=head2 pullers

Connected websockets ready to receive messages.

=head2 pushers

Connected websockets who will be pushing messages.

=head2 current_puller_index

The puller we will use to send the next message from a pusher.

=head1 METHODS

=head2 add_puller

    $pat->add_puller( $tx );

Add a puller to this broker. Pullers are given messages in a round-robin, one
at a time, by pushers.

=head2 add_pusher

    $pat->add_pusher( $tx );

Add a pusher to this broker. Pushers send messages to be processed by pullers.

=head2 send_message

    $pat->send_message( $msg );

Send the given message to the next puller in line.

=head2 remove_puller

    $pat->remove_puller( $tx );

Remove a puller from the list. Called automatically when the puller socket
is closed.

=head2 remove_pusher

    $pat->remove_pusher( $tx );

Remove a pusher from the list. Called automatically when the pusher socket
is closed.

=head1 SEE ALSO

=over

=item L<Mercury::Controller::PushPull>

=item L<Mercury>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
