use strict;
use warnings;
use Test::More 0.96;

use_ok("Finance::Crypto::Exchange::Kraken");

# The data here can https://docs.kraken.com/api/docs/guides/spot-rest-auth
# and we validate the expected API-Sign listed on the page in this file
my $secret   = 'kQH5HW/8p1uGOVjbgWA7FunAmGO8lsSUXNsu3eow76sz84Q18fWxnyRzBHCd3pd5nE9qa99HAZtuZuj6F1huXg==';
my $api_sign = '4/dpxb3iT4tp/ZCVEwSnEsLxx0bqyhLpdfOpc6fn7OR8+UClSV5n9E6aSS8MPtnRfp32bAb0nmbRn6H8ndwLUQ==';
my $nonce    = 1616492376594;
my $path     = '/0/private/AddOrder';
my $content  = "nonce=$nonce&ordertype=limit&pair=XBTUSD&price=37500&type=buy&volume=1.25";

my $kraken = Finance::Crypto::Exchange::Kraken->new(
    key    => 'foo',
    secret => $secret,
);

is(
  $api_sign,
  $kraken->_hmac($path, $nonce, $content),
  'API-Sign correctly calculated'
);

done_testing;
