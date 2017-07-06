use v5.20;
use warnings;
use Test::More;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::PaymentMethod');
}

my $pay_method = new_ok('Finance::GDAX::API::PaymentMethod');
can_ok($pay_method, 'get');
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 3 : 2 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($pay_method->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $pay_method->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $pay_method->get, 'can get all funding');
     is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();
