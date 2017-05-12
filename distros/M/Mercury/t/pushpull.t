
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mercury;
my $app = Mercury->new;

my @pulls;
my @got;
for my $i ( 0, 1 ) {
    my $t = Test::Mojo->new( $app );
    $t->websocket_ok( '/pull/foo' );
    my $queue = $got[ $i ] = [];
    $t->tx->on( message => sub {
        push @$queue, $_[1];
    } );
    push @pulls, $t;
}

my $stranger_t = Test::Mojo->new( $app )->websocket_ok( '/pull/bar' );
$stranger_t->tx->on( message => sub {
    fail 'Stranger received message from wrong push';
} );

my $push_t = Test::Mojo->new( $app )->websocket_ok( '/push/foo' );

subtest 'first message' => sub {
    $push_t->send_ok({ text => 'Hello' });
    $pulls[ 0 ]
        ->message_ok( 'first puller got first message' )
        ->message_is( 'Hello' );
    shift @{ $got[ 0 ] };
    for my $i ( 1 ) {
        ok !@{ $got[ $i ] }, 'other pullers got no message';
    }
};

subtest 'second message' => sub {
    $push_t->send_ok({ text => 'Hello' });
    $pulls[ 1 ]
        ->message_ok( 'second puller got second message' )
        ->message_is( 'Hello' );
    shift @{ $got[ 1 ] };
    for my $i ( 0 ) {
        ok !@{ $got[ $i ] }, 'other pullers got no message';
    }
};

subtest 'third message' => sub {
    $push_t->send_ok({ text => 'Hello' });
    $pulls[ 0 ]
        ->message_ok( 'first puller got third message' )
        ->message_is( 'Hello' );
    shift @{ $got[ 0 ] };
};

subtest 'remove a puller' => sub {
    $pulls[1]->finish_ok;
};

subtest 'fourth message' => sub {
    $push_t->send_ok({ text => 'Hello' });
    $pulls[ 0 ]
        ->message_ok( 'first puller got third message' )
        ->message_is( 'Hello' );
    shift @{ $got[ 0 ] };
};

subtest 'add a puller' => sub {
    my $t = Test::Mojo->new( $app )->websocket_ok( '/pull/foo' );
    push @pulls, $t;
    my $queue = $got[ @got ] = [];
    $t->tx->on( message => sub {
        push @$queue, $_[1];
    } );
};

subtest 'fourth message' => sub {
    $push_t->send_ok({ text => 'Hello' });
    $pulls[ 0 ]
        ->message_ok( 'first puller got fourth message' )
        ->message_is( 'Hello' );
    shift @{ $got[ 0 ] };
    for my $i ( 2 ) {
        ok !@{ $got[ $i ] }, 'other pullers got no message';
    }
};

subtest 'fifth message' => sub {
    $push_t->send_ok({ text => 'Hello' });
    $pulls[ 2 ]
        ->message_ok( 'third puller got fifth message' )
        ->message_is( 'Hello' );
    shift @{ $got[ 2 ] };
    for my $i ( 0 ) {
        ok !@{ $got[ $i ] }, 'other pullers got no message';
    }
};

subtest 'remove all pullers' => sub {
    for my $i ( 0, 2 ) {
        $pulls[$i]->finish_ok;
    }
};

subtest 'start again' => sub {
    my $t = Test::Mojo->new( $app )->websocket_ok( '/pull/foo' );
    push @pulls, $t;
    my $queue = $got[ @got ] = [];
    $t->tx->on( message => sub {
        push @$queue, $_[1];
    } );
};

subtest 'sixth message' => sub {
    $push_t->send_ok({ text => 'Hello' });
    $pulls[ 3 ]
        ->message_ok( 'fourth puller got sixth message' )
        ->message_is( 'Hello' );
    shift @{ $got[ 3 ] };
};

subtest 'post to push' => sub {
    my $t = Test::Mojo->new( $app );
    $t->post_ok( '/push/foo' => 'Hello Push' )
        ->status_is( 200 )
        ->content_is( '' )
        ;

    $pulls[ 3 ]
        ->message_ok( "only puller received post (seventh) message" )
        ->message_is( 'Hello Push' );
};
$push_t->finish_ok;
$stranger_t->finish_ok;

done_testing;

