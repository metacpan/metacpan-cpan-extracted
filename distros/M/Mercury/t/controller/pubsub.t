
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mercury::Controller::PubSub;
{
    package MyApp;
    use Mojo::Base 'Mojolicious';
    sub startup {
        my ( $app ) = @_;
        $app->plugin( 'Mercury' );
        my $r = $app->routes;
        $r->websocket( '/pub/*topic' )->to( controller => 'PubSub', action => 'publish' );
        $r->websocket( '/sub/*topic' )->to( controller => 'PubSub', action => 'subscribe' );
    }
}

my $app = MyApp->new;

subtest 'exact topic' => sub {
    my $pub_t = Test::Mojo->new( $app )->websocket_ok( '/pub/foo', 'publish websocket' );

    my @subs;
    push @subs, Test::Mojo->new( $app )->websocket_ok( '/sub/foo', 'subscriber one' );
    push @subs, Test::Mojo->new( $app )->websocket_ok( '/sub/foo', 'subscriber two' );

    $pub_t->send_ok({ text => 'Hello' });
    for my $sub_t ( @subs ) {
        $sub_t
            ->message_ok( 'sub received message' )
            ->message_is( 'Hello' );
    }

    for my $t ( $pub_t, @subs ) {
        $t->finish_ok;
    }
};

done_testing;
