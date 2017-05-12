use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockObject::Extends;
use Scalar::Util qw(isweak);

BEGIN {
    use_ok('Finance::Bitcoin::Feed::Site::BtcChina');
		use_ok('Finance::Bitcoin::Feed::Site::BtcChina::Socket');
}

my $obj = Finance::Bitcoin::Feed::Site::BtcChina->new();

#testing connect fail...

my $socket = Finance::Bitcoin::Feed::Site::BtcChina::Socket->new();
$socket = Test::MockObject::Extends->new($socket);
$socket->set_false('is_websocket');
my $ua_mock = Test::MockObject->new();
$ua_mock->fake_new('Mojo::UserAgent');
$ua_mock->mock(
    'websocket',
    sub {
        shift;
        shift;
        my $cb = shift;
        $cb->( $ua_mock, $socket );
    }
);

lives_ok( sub { $obj->go; }, 'run go' );
ok( $obj->started,    'super::go is called, the program is running' );
ok( $obj->is_timeout, 'set timeout' );

#testing connect success
$obj->started(0);
$socket->set_true('is_websocket');
lives_ok( sub { $obj->go; }, 'run go again' );
is( $socket->owner, $obj, 'set owner of socket' );
ok( isweak( $socket->{owner} ), 'owner is weak' );

for (qw(text subscribe setup trade ping)) {
    ok( $socket->has_subscribers($_), "set $_ subscribe" );
}

isa_ok( $socket->timer, 'EV::Timer', 'set timer' );

# test parse;
# test connect succeed
my $get_setup = 0;
my $time1     = time();
lives_ok(
    sub {
        $socket->on( 'setup', sub { $get_setup = 1; } );
        $socket->emit( 'text',
'0{"sid":"Sq32tfzyEo3dX7ivAC8h","upgrades":[],"pingInterval":25000,"pingTimeout":60000}'
        );
    },
    'parse connect'
);
my $time2 = time();
is( $socket->ping_interval, 25000, 'set ping_interval' );
is( $socket->ping_timeout,  60000, 'set ping_timeout' );
ok( $socket->last_ping_at >= $time1 && $socket->last_ping_at <= $time2,
    'set last_ping_at' );
ok( $socket->last_pong_at >= $time1 && $socket->last_pong_at <= $time2,
    'set last_pong_at' );
ok( $get_setup, 'get setup event' );

#test pong
$time1 = time();
lives_ok(
    sub {
        $socket->emit( 'text', '3' );
    },
    'send pong'
);
$time2 = time();
ok( $socket->last_pong_at >= $time1 && $socket->last_pong_at <= $time2,
    'set last_pong_at' );
lives_ok(
    sub {
        $socket->emit( 'text', '41' );
    },
    'receive disconnect'
);
ok( $socket->owner->is_timeout, 'set timeout' );
my $str = '';
lives_ok(
    sub {
        $socket->owner->on( 'output', sub { shift, $str = join " ", @_; } );
        $socket->emit( 'text',
'42["trade",{"trade_id":13717874,"type":"sell","price":"2327.05","amount":"1.45510000","date":1417673447,"market":"btccny"}]'
        );
    },
    'receive data'
);

is( $str, 'BTCCHINA 1417673447000 BTCCNY 2327.05', 'get correct result' );

done_testing();
