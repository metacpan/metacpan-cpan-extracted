
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mercury;
my $app = Mercury->new;

my @peers;
for my $i ( 0..2 ) {
    my $t = Test::Mojo->new( $app )->websocket_ok( '/bus/foo' );
    push @peers, $t;
}
push @peers, Test::Mojo->new( $app )->websocket_ok( '/bus/foo?echo=1' );

my $stranger_t = Test::Mojo->new( $app )->websocket_ok( '/bus/bar' );
$stranger_t->tx->on( message => sub {
    fail 'Stranger received message from wrong bus';
} );

subtest 'peer 0' => sub {
    $peers[0]->send_ok( { text => 'Hello 0' }, 'peer 0 sends message' );
    for my $i ( 1..3 ) {
        $peers[$i]
            ->message_ok( "peer $i received message" )
            ->message_is( 'Hello 0' );
    }
};

subtest 'peer 2' => sub {
    $peers[2]->send_ok( { text => 'Hello 2' }, 'peer 2 sends message' );
    for my $i ( 0, 1, 3 ) {
        $peers[$i]
            ->message_ok( "peer $i received message" )
            ->message_is( 'Hello 2' );
    }
};

# peer 3 has echo enabled, if the other senders had had it enabled they would
# fail the test following their send by receiving the message sent from the
# previous test
subtest 'peer 3' => sub {
    $peers[3]->send_ok( { text => 'Hello 3' }, 'peer 3 sends message' );
    for my $i ( 0 .. 3 ) {
        $peers[$i]
            ->message_ok( "peer $i received message" )
            ->message_is( 'Hello 3' );
    }
};

subtest 'post to bus' => sub {
    my $t = Test::Mojo->new( $app );
    $t->post_ok( '/bus/foo' => 'Hello 4' )
        ->status_is( 200 )
        ->content_is( '' )
        ;

    for my $i ( 0 .. 3 ) {
        $peers[$i]
            ->message_ok( "peer $i received message" )
            ->message_is( 'Hello 4' );
    }
};

for my $i ( 0..$#peers ) {
    $peers[$i]->finish_ok;
}
$stranger_t->finish_ok;

done_testing;
