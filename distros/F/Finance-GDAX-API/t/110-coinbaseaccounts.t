use v5.20;
use warnings;
use Test::More;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::CoinbaseAccount');
}

my $coinbase_acct = new_ok('Finance::GDAX::API::CoinbaseAccount');
can_ok($coinbase_acct, 'get');

 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 3 : 2 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($coinbase_acct->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $coinbase_acct->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $coinbase_acct->get, 'can get all funding');
     is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();
