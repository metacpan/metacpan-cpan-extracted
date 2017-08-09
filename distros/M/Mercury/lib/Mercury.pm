package Mercury;
our $VERSION = '0.014';
# ABSTRACT: Main broker application class

#pod =head1 SYNOPSIS
#pod
#pod     # Start the broker
#pod     $ mercury broker
#pod
#pod     # To get help
#pod     $ mercury help broker
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the main broker application class. This is the standard broker
#pod application that is started when you use C<mercury broker>.
#pod
#pod To learn how to use this application to broker messages, see L<the main
#pod Mercury documentation|mercury>. For how to start the broker application,
#pod see L<the mercury broker command documentation|Mercury::Command::mercury::broker>
#pod or run C<mercury help broker>.
#pod
#pod To learn how to create a custom message broker to integrate authentication,
#pod logging, and other customizations, see L<Mojolicious::Plugin::Mercury>.
#pod
#pod =cut

use Mojo::Base 'Mojolicious';
use Scalar::Util qw( weaken refaddr );
use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir );
use Mojo::WebSocket 'WS_PING';

sub startup {
    my ( $app ) = @_;
    $app->plugin( 'Config', { default => { broker => { } } } );
    $app->commands->namespaces( [ 'Mercury::Command::mercury' ] );

    my $r = $app->routes;
    if ( my $origin = $app->config->{broker}{allow_origin} ) {
        # Allow only '*' for wildcards
        my @origin = map { quotemeta } ref $origin eq 'ARRAY' ? @$origin : $origin;
        s/\\\*/.*/g for @origin;

        $r = $r->under( '/' => sub {
            #say "Got origin: " . $_[0]->req->headers->origin;
            #say "Checking against: @origin";
            my $origin = $_[0]->req->headers->origin;
            if ( !$origin || !grep { $origin =~ /$_/ } @origin ) {
                $_[0]->render(
                    status => '401',
                    text => 'Origin check failed',
                );
                return;
            }
            return 1;
        } );
    }

    $app->hook( before_dispatch => sub {
        my ( $c ) = @_;
        if ( $c->tx->is_websocket ) {
            weaken $c;
            my $id = Mojo::IOLoop->recurring( 300, sub {
                return unless $c;
                $c->tx->send([1, 0, 0, 0, WS_PING, 'Still alive!']);
            } );
            $c->tx->once( finish => sub { Mojo::IOLoop->remove( $id ) } );
        }
    } );

    $app->plugin( 'Mercury' );
    $r->websocket( '/push/*topic' )
      ->to( controller => 'PushPull', action => 'push' )
      ->name( 'push' );
    $r->post( '/push/*topic' )
      ->to( controller => 'PushPull', action => 'post' )
      ->name( 'push_post' );
    $r->websocket( '/pull/*topic' )
      ->to( controller => 'PushPull', action => 'pull' )
      ->name( 'pull' );

    $r->websocket( '/pub/*topic' )
      ->to( controller => 'PubSub::Cascade', action => 'publish' )
      ->name( 'pub' );
    $r->post( '/pub/*topic' )
      ->to( controller => 'PubSub::Cascade', action => 'post' )
      ->name( 'pub_post' );
    $r->websocket( '/sub/*topic' )
      ->to( controller => 'PubSub::Cascade', action => 'subscribe' )
      ->name( 'sub' );

    $r->websocket( '/bus/*topic' )
      ->to( controller => 'Bus', action => 'connect' )
      ->name( 'bus' );
    $r->post( '/bus/*topic' )
      ->to( controller => 'Bus', action => 'post' )
      ->name( 'bus_post' );

    if ( $app->mode eq 'development' ) {
        # Enable the example app
        my $root = catdir( dirname( __FILE__ ), 'Mercury' );
        $app->static->paths->[0] = catdir( $root, 'public' );
        $app->renderer->paths->[0] = catdir( $root, 'templates' );
        $app->routes->any( '/' )->to( cb => sub { shift->render( 'index' ) } );
    }
}

1;

__END__

=pod

=head1 NAME

Mercury - Main broker application class

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    # Start the broker
    $ mercury broker

    # To get help
    $ mercury help broker

=head1 DESCRIPTION

This is the main broker application class. This is the standard broker
application that is started when you use C<mercury broker>.

To learn how to use this application to broker messages, see L<the main
Mercury documentation|mercury>. For how to start the broker application,
see L<the mercury broker command documentation|Mercury::Command::mercury::broker>
or run C<mercury help broker>.

To learn how to create a custom message broker to integrate authentication,
logging, and other customizations, see L<Mojolicious::Plugin::Mercury>.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
