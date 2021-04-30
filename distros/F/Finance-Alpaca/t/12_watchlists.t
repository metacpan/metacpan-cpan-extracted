use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my @watchlists = $alpaca->watchlists();
isa_ok( $watchlists[0], 'Finance::Alpaca::Struct::Watchlist' );
my $watchlist = $alpaca->create_watchlist( 'Testing watchlist #' . int rand time, qw[MSFT TSLA] );
is( $alpaca->watchlist( $watchlist->id ), $watchlist, 'Retrieve watchlist by id' );
my $new_name = 'Changed|' . int rand time;
is(
    $alpaca->update_watchlist( $watchlist->id, name => $new_name )->name,
    $new_name, 'Update name of watchlist'
);
is(
    $alpaca->update_watchlist( $watchlist->id, symbols => [qw[MA V]] )->assets->[0]->symbol,
    'MA', 'Update assets on watchlist'
);
is(
    $alpaca->add_to_watchlist( $watchlist->id, 'TSLA' )->assets->[-1]->symbol,
    'TSLA', 'Add asset to watchlist'
);
is(
    $alpaca->remove_from_watchlist( $watchlist->id, 'TSLA' )->assets->[-1]->symbol,
    'V', 'Remove asset from watchlist'
);
ok( $alpaca->delete_watchlist( $watchlist->id ), 'Delete watchlist' );
done_testing;
1;
