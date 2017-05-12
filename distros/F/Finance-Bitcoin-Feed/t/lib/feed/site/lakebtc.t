use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockObject::Extends;
use Scalar::Util qw(isweak);

BEGIN {
    use_ok('Finance::Bitcoin::Feed::Site::LakeBtc');
		use_ok('Finance::Bitcoin::Feed::Site::LakeBtc::Socket');
}

my $obj = Finance::Bitcoin::Feed::Site::LakeBtc->new();

#testing connect fail...

my $socket = Finance::Bitcoin::Feed::Site::LakeBtc::Socket->new();
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

for (qw(json subscribe setup)) {
    ok( $socket->has_subscribers($_), "set $_ subscribe" );
}

my $ping_called;
my $ping_packet = [
    [
        'websocket_rails.ping',
        {
            'channel'      => undef,
            'result'       => undef,
            'success'      => undef,
            'server_token' => undef,
            'id'           => undef,
            'data'         => {},
            'user_id'      => undef
        }
    ]
];

$socket->on( 'websocket_rails.ping', sub { $ping_called = 1 } );
$socket->emit( 'json', $ping_packet );
ok($ping_called);

my $setup_called;
my $connected_packet = [
    [
        'client_connected',
        {
            'channel' => undef,
            'success' => undef,
            'result'  => undef,
            'data'    => {
                'connection_id' => undef
            },
            'user_id'      => undef,
            'id'           => undef,
            'server_token' => undef
        }
    ]
];

$socket->on( 'client_connected', sub { $setup_called = 1 } );
$socket->emit( 'json', $connected_packet );
ok($setup_called);

my $update_packet = [
    [
        'update',
        {
            'channel'      => 'ticker',
            'success'      => undef,
            'result'       => undef,
            'server_token' => 'Wn0DD3y79HtkaTZONFPNJw',
            'id'           => undef,
            'data'         => {
                'USD' => {
                    'last'   => '331.93',
                    'ask'    => '331.93',
                    'bid'    => '331.69',
                    'high'   => '338.85',
                    'low'    => '329.39',
                    'volume' => '3804.89602'
                },
                'CNY' => {
                    'bid'    => '2063.24',
                    'ask'    => '2063.24',
                    'high'   => '2111.08',
                    'volume' => '11423.7188',
                    'low'    => '2053.1',
                    'last'   => '2063.24'
                }
            },
            'user_id' => undef
        }
    ]
];
my @str;
$socket->owner->on( 'output', sub { shift, push @str, join " ", @_; } );
$socket->emit( 'json', $update_packet );
is_deeply( \@str, [ "LAKEBTC 0 CNYBTC 2063.24", "LAKEBTC 0 USDBTC 331.93" ],
    "get result" );

done_testing();
