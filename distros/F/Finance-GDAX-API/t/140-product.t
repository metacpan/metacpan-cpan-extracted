use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Product');
}

my $product = new_ok('Finance::GDAX::API::Product');
can_ok($product, 'id');
can_ok($product, 'level');
can_ok($product, 'start');
can_ok($product, 'end');
can_ok($product, 'granularity');
can_ok($product, 'list');
can_ok($product, 'order_book');
can_ok($product, 'ticker');
can_ok($product, 'historic_rates');

dies_ok { $product->level(8) } 'dies good on out of range level';
dies_ok { $product->order_book } 'dies good on order_book without product id';
dies_ok { $product->granularity(1.5) } 'dies good on bad granularity';
dies_ok { $product->historic_rates('BTC-USD') } 'dies good without necessary attributes to historic_rates';
ok ($product->granularity(600), 'can set good granularity to 600');
ok ($product->start('2017-06-01T00:00:00.000Z'), 'can set start');
ok ($product->end('2017-06-02T00:00:00.000Z'), 'can set end');
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 13 : 12 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($product->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $product->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $product->list, 'can get product list');
     is (ref $result, 'ARRAY', 'get returns array');

     ok ($result = $product->order_book('BTC-USD'), 'can get product order book');
     is (ref $result, 'HASH', 'order_book returns hash');
     
     ok ($result = $product->ticker('BTC-USD'), 'can get product ticker');
     is (ref $result, 'HASH', 'ticker returns hash');
     
     ok ($result = $product->trades('BTC-USD'), 'can get product trades');
     is (ref $result, 'ARRAY', 'trades returns array');

     ok ($result = $product->historic_rates('BTC-USD'), 'can get product historic rates');
     is (ref $result, 'ARRAY', 'historic rates returns array');

     ok ($result = $product->day_stats('BTC-USD'), 'can get product day_stats');
     is (ref $result, 'HASH', 'day_stats returns hash');
}

done_testing();
