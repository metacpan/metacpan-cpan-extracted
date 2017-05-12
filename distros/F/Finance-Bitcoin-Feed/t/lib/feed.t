use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Finance::Bitcoin::Feed');
}

my $feed = Finance::Bitcoin::Feed->new();
can_ok( $feed, 'run' );
can_ok( $feed, 'sites' );
is_deeply( $feed->sites, [qw(Hitbtc BtcChina CoinSetter LakeBtc BitStamp)], 'default sites' );
isa_ok( $feed, 'Finance::Bitcoin::Feed' );
isa_ok( $feed, 'Mojo::EventEmitter' );
ok( $feed->has_subscribers('output') );
dies_ok( sub { Finance::Bitcoin::Feed->new( sites => 'hello' )->run },
    'will die if site name error' );

done_testing();
