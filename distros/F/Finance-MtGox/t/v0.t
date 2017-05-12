use strict;
use warnings;

use Finance::MtGox;
use Test::More;

my $key    = $ENV{MTGOX_KEY};
my $secret = $ENV{MTGOX_SECRET};
my $currency = $ENV{MTGOX_CURRENCY};

if ( $key && $secret ) {
    plan tests => 13;
}
else {
    plan skip_all => "Author only tests";
}

my $mtgox = Finance::MtGox->new({
    key    => $key,
    secret => $secret,
});
ok( $mtgox, 'Finance::MtGox object created' );

# unauthenticated API calls
my $depth = $mtgox->call('getDepth');
is( ref $depth, 'HASH', 'getDepth response is a hashref');
is( $depth->{error}, undef, 'no getDepth errors' );
cmp_ok( scalar @{ $depth->{asks} }, '>', 0, 'MtGox has some ask orders' );
cmp_ok( scalar @{ $depth->{bids} }, '>', 0, 'MtGox has some bid orders' );

# authenticated API calls
my $info = $mtgox->call_auth('info');
is( ref $info, 'HASH', 'info response is a hashref');
is( $info->{error}, undef, 'no info errors' );
cmp_ok( $info->{Wallets}{BTC}, '>=', 0, 'info has some BTC funds' );
cmp_ok( $info->{Wallets}{$currency}, '>=', 0, "info has some $currency funds" );

# convenience methods built on the core API
my ( $btcs, $other ) = $mtgox->balances($currency);
cmp_ok( $other, '>=', 0, 'balances() has some $currency funds' );
cmp_ok( $btcs, '>=', 0, 'balances() has some BTC funds' );
my $rate = $mtgox->clearing_rate( 'asks', 200, 'BTC' );
cmp_ok( $rate, '>', 0, 'has a BTC ask side clearing rate' );
$rate    = $mtgox->clearing_rate( 'bids',  42, 'USD' );
cmp_ok( $rate, '>', 0, 'has a USD bid side clearing rate' );
