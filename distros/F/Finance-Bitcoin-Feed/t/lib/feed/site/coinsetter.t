use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockObject::Extends;
use Scalar::Util qw(isweak);

BEGIN {
    use_ok('Finance::Bitcoin::Feed::Site::CoinSetter');
		use_ok('Finance::Bitcoin::Feed::Site::CoinSetter::Socket');
}

my $obj = Finance::Bitcoin::Feed::Site::CoinSetter->new();

#testing first phrase connect fail...
my $tx1 = Test::MockObject::Extends->new();
$tx1->set_false('success');
$tx1->mock( 'error', sub { { message => "mock error" } } );
my $ua_mock = Test::MockObject::Extends->new();
$ua_mock->fake_new('Mojo::UserAgent');
$ua_mock->mock( 'get', sub { $tx1 } );

lives_ok( sub { $obj->go; }, 'run go' );
ok( $obj->started,    'super::go is called, the program is running' );
ok( $obj->is_timeout, 'set timeout' );

#testing second phrase connect fail
$tx1->set_true('success');
my $res1 = Test::MockObject::Extends->new();
$res1->mock(
    'text',
    sub {
'f_P7lQkhkg4JD5Xq0LCl:60:60:websocket,htmlfile,xhr-polling,jsonp-polling';
    }
);
$tx1->mock( 'res', sub { $res1 } );

my $socket = Finance::Bitcoin::Feed::Site::CoinSetter::Socket->new();
$socket = Test::MockObject::Extends->new($socket);
$socket->set_false('is_websocket');

my $url = '';
$ua_mock->mock(
    'websocket',
    sub {
        shift;
        $url = shift;
        my $cb = shift;
        $cb->( $ua_mock, $socket );
    }
);

lives_ok( sub { $obj->go; }, 'run go' );
ok( $ua_mock->called('websocket') );
ok( $obj->is_timeout, 'set timeout' );
is( $url,
    'wss://plug.coinsetter.com:3000/socket.io/1/websocket/f_P7lQkhkg4JD5Xq0LCl'
);

#testing connect success
$obj->started(0);
$socket->set_true('is_websocket');
lives_ok( sub { $obj->go; }, 'run go again' );
is( $socket->owner, $obj, 'set owner of socket' );
ok( isweak( $socket->{owner} ), 'owner is weak' );

#test configure and parse
# test connect packate
my $get_setup = 0;
lives_ok(
    sub {
        $socket->on( 'setup', sub { $get_setup = 1; } );
        $socket->emit( 'text', '1:::' );
    },
    'parse connect'
);
ok( $get_setup, 'get setup event' );

#test event packet
my $str = '';
lives_ok(
    sub {
        $socket->owner->on( 'output', sub { shift, $str = join " ", @_; } );
        $socket->emit( 'text',
'5:::{"name":"last","args":[{"price":367,"size":0.03,"exchangeId":"COINSETTER","timeStamp":1417382915802,"tickId":14667678802537,"volume":14.86,"volume24":102.43}]}'
        );
    },
    'parse connect'
);

is( $str, 'COINSETTER 1417382915802 BTCUSD 367' );
done_testing();
