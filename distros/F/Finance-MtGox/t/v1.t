use strict;
use warnings;

use Finance::MtGox;
use Test::More;

my $key    = $ENV{MTGOX_KEY};
my $secret = $ENV{MTGOX_SECRET};
my $currency = $ENV{MTGOX_CURRENCY};

if ( $key && $secret ) {
    plan tests => 8;
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
my $ticker = $mtgox->call('BTCUSD/ticker');
is( ref $ticker, 'HASH', 'BTCUSD/ticker response is a hashref');
is( $ticker->{result}, 'success', 'no BTCUSD/ticker errors' );
is( $ticker->{return}{vol}{currency}, 'BTC', 'BTCUSD/ticker response');

# authenticated API calls
my $info = $mtgox->call_auth('generic/info');
is( ref $info, 'HASH', 'generic/info response is a hashref');
is( $info->{result}, 'success', 'no generic/info errors' );
cmp_ok( $info->{return}{Wallets}{BTC}{Balance}{value}, '>=', 0, 'info has some BTC funds' );
cmp_ok( $info->{return}{Wallets}{$currency}{Balance}{value}, '>=', 0, "info has some $currency funds" );


