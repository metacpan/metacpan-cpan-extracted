
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mercury;
my $app = Mercury->new;

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

subtest 'topic hierarchy' => sub {
    my %subs;
    $subs{parent} = Test::Mojo->new( $app )->websocket_ok( '/sub/foo', 'parent subscriber' );
    $subs{child} = Test::Mojo->new( $app )->websocket_ok( '/sub/foo/bar', 'child subscriber' );

    subtest 'publish on child topic' => sub {
        my $pub_t = Test::Mojo->new( $app )->websocket_ok( '/pub/foo/bar', 'publish websocket' );

        $pub_t->send_ok({ text => 'Hello' });
        for my $sub_t ( values %subs ) {
            $sub_t
                ->message_ok( 'sub received message' )
                ->message_is( 'Hello' );
        }

        $pub_t->finish_ok;
    };

    subtest 'post on child topic' => sub {
        my $t = Test::Mojo->new( $app )->post_ok( '/pub/foo/bar' => 'Hello Post Child' )
            ->status_is( 200 )
            ->content_is( '' );

        for my $sub_t ( values %subs ) {
            $sub_t
                ->message_ok( sprintf 'sub %s received message', $sub_t->tx->req->url->path )
                ->message_is( 'Hello Post Child' );
        }
    };

    $subs{child}->tx->on( message => sub {
        fail "Got child message!";
    } );

    subtest 'publish on parent topic' => sub {
        my $pub_t = Test::Mojo->new( $app )->websocket_ok( '/pub/foo', 'publish websocket' );

        $pub_t->send_ok({ text => 'Hello' });
        $subs{parent}
            ->message_ok( 'sub received message' )
            ->message_is( 'Hello' );

        $pub_t->finish_ok;
    };

    subtest 'post on parent topic' => sub {
        my $t = Test::Mojo->new( $app )->post_ok( '/pub/foo', 'Hello Post Parent' );

        $subs{parent}
            ->message_ok( 'sub received message' )
            ->message_is( 'Hello Post Parent' );
    };

    for my $t ( values %subs ) {
        $t->finish_ok;
    }
};

done_testing;
