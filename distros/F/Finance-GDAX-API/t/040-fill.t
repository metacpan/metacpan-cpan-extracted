use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Fill');
}

my $fill = new_ok('Finance::GDAX::API::Fill');
can_ok($fill, 'get');
can_ok($fill, 'order_id');
can_ok($fill, 'product_id');

 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 3 : 2 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($fill->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $fill->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $fill->get, 'can get all fills');
     is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();

