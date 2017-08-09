package Mercury::Controller::PushPull;
our $VERSION = '0.014';
# ABSTRACT: Push/pull message pattern controller

#pod =head1 SYNOPSIS
#pod
#pod     # myapp.pl
#pod     use Mojolicious::Lite;
#pod     plugin 'Mercury';
#pod     websocket( '/push/*topic' )
#pod       ->to( controller => 'PushPull', action => 'push' );
#pod     websocket( '/pull/*topic' )
#pod       ->to( controller => 'PushPull', action => 'pull' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This controller enables a L<pushE<sol>pull pattern|Mercury::Pattern::PushPull> on
#pod a pair of endpoints (L<push|/push> and L<pull|/pull>.
#pod
#pod For more information on the push/pull pattern, see L<Mercury::Pattern::PushPull>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Mercury::Pattern::PushPull>
#pod
#pod =item L<Mercury>
#pod
#pod =back
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Controller';
use Mercury::Pattern::PushPull;

#pod =method push
#pod
#pod     $app->routes->websocket( '/push/*topic' )
#pod       ->to( controller => 'PushPull', action => 'push' );
#pod
#pod Controller action to connect a websocket to a push endpoint. A push client
#pod sends messages through the socket. The message will be sent to one of the
#pod connected pull clients in a round-robin fashion.
#pod
#pod This endpoint requires a C<topic> in the stash.
#pod
#pod =cut

sub push {
    my ( $c ) = @_;
    my $pattern = $c->_pattern( $c->stash( 'topic' ) );
    $pattern->add_pusher( $c->tx );
    $c->rendered( 101 );
}

#pod =method pull
#pod
#pod     $app->routes->websocket( '/pull/*topic' )
#pod       ->to( controller => 'PushPull', action => 'pull' );
#pod
#pod Controller action to connect a websocket to a pull endpoint. A pull
#pod client will recieve messages from push clients in a round-robin fashion.
#pod One message from a pusher will be received by exactly one puller.
#pod
#pod This endpoint requires a C<topic> in the stash.
#pod
#pod =cut

sub pull {
    my ( $c ) = @_;
    my $pattern = $c->_pattern( $c->stash( 'topic' ) );
    $pattern->add_puller( $c->tx );
    $c->rendered( 101 );
}

#pod =method post
#pod
#pod Post a new message to the given topic without subscribing or
#pod establishing a WebSocket connection. This allows new messages to be
#pod easily pushed by any HTTP client.
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
# Get or create the L<Mercury::Pattern::PushPull> object for the given
# topic.
#
#=cut

sub _pattern {
    my ( $c, $topic ) = @_;
    my $pattern = $c->mercury->pattern( PushPull => $topic );
    if ( !$pattern ) {
        $pattern = Mercury::Pattern::PushPull->new;
        $c->mercury->pattern( PushPull => $topic => $pattern );
    }
    return $pattern;
}

1;

__END__

=pod

=head1 NAME

Mercury::Controller::PushPull - Push/pull message pattern controller

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    # myapp.pl
    use Mojolicious::Lite;
    plugin 'Mercury';
    websocket( '/push/*topic' )
      ->to( controller => 'PushPull', action => 'push' );
    websocket( '/pull/*topic' )
      ->to( controller => 'PushPull', action => 'pull' );

=head1 DESCRIPTION

This controller enables a L<pushE<sol>pull pattern|Mercury::Pattern::PushPull> on
a pair of endpoints (L<push|/push> and L<pull|/pull>.

For more information on the push/pull pattern, see L<Mercury::Pattern::PushPull>.

=head1 METHODS

=head2 push

    $app->routes->websocket( '/push/*topic' )
      ->to( controller => 'PushPull', action => 'push' );

Controller action to connect a websocket to a push endpoint. A push client
sends messages through the socket. The message will be sent to one of the
connected pull clients in a round-robin fashion.

This endpoint requires a C<topic> in the stash.

=head2 pull

    $app->routes->websocket( '/pull/*topic' )
      ->to( controller => 'PushPull', action => 'pull' );

Controller action to connect a websocket to a pull endpoint. A pull
client will recieve messages from push clients in a round-robin fashion.
One message from a pusher will be received by exactly one puller.

This endpoint requires a C<topic> in the stash.

=head2 post

Post a new message to the given topic without subscribing or
establishing a WebSocket connection. This allows new messages to be
easily pushed by any HTTP client.

=head1 SEE ALSO

=over

=item L<Mercury::Pattern::PushPull>

=item L<Mercury>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
