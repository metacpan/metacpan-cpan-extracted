use v5.20;
use warnings;
use Test::More;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Currency');
}

my $currency = new_ok('Finance::GDAX::API::Currency');
can_ok($currency, 'list');
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 3 : 2 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($currency->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $currency->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $currency->list, 'can get currency list');
     is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();
