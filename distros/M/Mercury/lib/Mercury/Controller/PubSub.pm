package Mercury::Controller::PubSub;
our $VERSION = '0.012';
# ABSTRACT: Pub/sub message pattern controller

#pod =head1 SYNOPSIS
#pod
#pod     # myapp.pl
#pod     use Mojolicious::Lite;
#pod     plugin 'Mercury';
#pod     websocket( '/pub/*topic' )
#pod       ->to( controller => 'PubSub', action => 'pub' );
#pod     websocket( '/sub/*topic' )
#pod       ->to( controller => 'PubSub', action => 'sub' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This controller enables a L<pub/sub pattern|Mercury::Pattern::PubSub> on
#pod a pair of endpoints (L<publish|/publish> and L<subscribe|/subscribe>.
#pod
#pod For more information on the pub/sub pattern, see L<Mercury::Pattern::PubSub>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Mercury::Pattern::PubSub>
#pod
#pod =item L<Mercury::Controller::PubSub::Cascade>
#pod
#pod =item L<Mercury>
#pod
#pod =back
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';
use Mercury::Pattern::PubSub;

#pod =method publish
#pod
#pod     $app->routes->websocket( '/pub/*topic' )
#pod       ->to( controller => 'PubSub', action => 'publish' );
#pod
#pod Controller action to connect a websocket as a publisher. A publish
#pod client sends messages through the socket. The message will be sent to
#pod all of the connected subscribers.
#pod
#pod This endpoint requires a C<topic> in the stash.
#pod
#pod =cut

sub publish {
    my ( $c ) = @_;
    my $pattern = $c->_pattern( $c->stash( 'topic' ) );
    $pattern->add_publisher( $c->tx );
    $c->rendered( 101 );
}

#pod =method subscribe
#pod
#pod     $app->routes->websocket( '/sub/*topic' )
#pod       ->to( controller => 'PubSub', action => 'subscribe' );
#pod
#pod Controller action to connect a websocket as a subscriber. A subscriber
#pod will recieve every message sent by publishers.
#pod
#pod This endpoint requires a C<topic> in the stash.
#pod
#pod =cut

sub subscribe {
    my ( $c ) = @_;
    my $pattern = $c->_pattern( $c->stash( 'topic' ) );
    $pattern->add_subscriber( $c->tx );
    $c->rendered( 101 );
}

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
# Get or create the L<Mercury::Pattern::PubSub> object for the given
# topic.
#
#=cut

sub _pattern {
    my ( $c, $topic ) = @_;
    my $pattern = $c->mercury->pattern( PubSub => $topic );
    if ( !$pattern ) {
        $pattern = Mercury::Pattern::PubSub->new;
        $c->mercury->pattern( PubSub => $topic => $pattern );
    }
    return $pattern;
}

1;

__END__

=pod

=head1 NAME

Mercury::Controller::PubSub - Pub/sub message pattern controller

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    # myapp.pl
    use Mojolicious::Lite;
    plugin 'Mercury';
    websocket( '/pub/*topic' )
      ->to( controller => 'PubSub', action => 'pub' );
    websocket( '/sub/*topic' )
      ->to( controller => 'PubSub', action => 'sub' );

=head1 DESCRIPTION

This controller enables a L<pub/sub pattern|Mercury::Pattern::PubSub> on
a pair of endpoints (L<publish|/publish> and L<subscribe|/subscribe>.

For more information on the pub/sub pattern, see L<Mercury::Pattern::PubSub>.

=head1 METHODS

=head2 publish

    $app->routes->websocket( '/pub/*topic' )
      ->to( controller => 'PubSub', action => 'publish' );

Controller action to connect a websocket as a publisher. A publish
client sends messages through the socket. The message will be sent to
all of the connected subscribers.

This endpoint requires a C<topic> in the stash.

=head2 subscribe

    $app->routes->websocket( '/sub/*topic' )
      ->to( controller => 'PubSub', action => 'subscribe' );

Controller action to connect a websocket as a subscriber. A subscriber
will recieve every message sent by publishers.

This endpoint requires a C<topic> in the stash.

=head2 post

Post a new message to the given topic without subscribing or
establishing a WebSocket connection. This allows new messages to be
pushed by any HTTP client.

=head1 SEE ALSO

=over

=item L<Mercury::Pattern::PubSub>

=item L<Mercury::Controller::PubSub::Cascade>

=item L<Mercury>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
