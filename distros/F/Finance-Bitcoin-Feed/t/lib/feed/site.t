use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Finance::Bitcoin::Feed::Site');
}

my $obj = Finance::Bitcoin::Feed::Site->new( site => 'testsite' );

isa_ok( $obj, 'Finance::Bitcoin::Feed::Site' );
can_ok( $obj, 'go' );
ok( $obj->has_subscribers('timeout'), 'has timeout subscribe' );
is( $obj->started,          0, 'test not started' );
is( $obj->last_activity_at, 0, 'no activity yet' );
lives_ok( sub { $obj->go; }, "go!" );
is( $obj->started, 1, 'test started' );
ok( $obj->last_activity_at != 0, 'has activity now' );
ok( !$obj->is_timeout,           'not timeout yet' );
my $on_output_called = 0;
my $str              = '';
lives_ok(
    sub {
        $obj->last_activity_at(0);
        $obj->on( 'output',
            sub { shift; $on_output_called = 1; $str = join ' ', @_ } );
        $obj->emit( 'data_out', 'btcbtc', '1.00' );
    },
    'prepare and call go again'
);
ok( $obj->last_activity_at != 0, 'on_data_out will update last_activity' );
ok( $on_output_called,           'on_output be called' );
is( $str, 'testsite btcbtc 1.00' );
lives_ok(
    sub {
        $obj->set_timeout();
    },
    'set timeout'
);
ok( $obj->is_timeout(), 'timeoute is set' );
done_testing();
