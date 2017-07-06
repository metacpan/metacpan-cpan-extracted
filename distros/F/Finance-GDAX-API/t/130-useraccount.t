use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::UserAccount');
}

my $account = new_ok('Finance::GDAX::API::UserAccount');
can_ok($account, 'trailing_volume');
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 3 : 2 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($account->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $account->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $account->trailing_volume, 'can get trailing volume');
     is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();
