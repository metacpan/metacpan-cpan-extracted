use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use Test::MockObject::Extends;
use Scalar::Util qw(isweak);

BEGIN {
    use_ok('Finance::Bitcoin::Feed::Site::BitStamp');
		use_ok('Finance::Bitcoin::Feed::Site::BitStamp::Socket');
}

my $obj = Finance::Bitcoin::Feed::Site::BitStamp->new();

my $socket = Finance::Bitcoin::Feed::Site::BitStamp::Socket->new($obj);
$socket = Test::MockObject::Extends->new($socket);
$socket->set_true('go');
$socket->fake_new('Finance::Bitcoin::Feed::Site::BitStamp::Socket');
lives_ok(
    sub {
        $obj->go;
    },
    'go!'
);
ok($socket->called('go'), 'socket go is called');
is($socket->{owner}, $obj, "socket's owner is set ");
ok(isweak($socket->{owner}), "socket's owner is weak");

my $str = '';

lives_ok(
    sub {
        $obj->on('output', sub { shift; $str = join " ", @_ });
    },
    'set output event'
);

lives_ok(sub { $obj->socket->trade({price => 1}) }, 'call trade');
is($str, 'BITSTAMP 0 BTCUSD 1');

done_testing();
