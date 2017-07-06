use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Withdrawl');
}

my $withdrawl = new_ok('Finance::GDAX::API::Withdrawl');
can_ok($withdrawl, 'payment_method_id');
can_ok($withdrawl, 'coinbase_account_id');
can_ok($withdrawl, 'crypto_address');
can_ok($withdrawl, 'amount');
can_ok($withdrawl, 'currency');
can_ok($withdrawl, 'to_payment');
can_ok($withdrawl, 'to_coinbase');
can_ok($withdrawl, 'to_crypto');

dies_ok { $withdrawl->amount(-250.00) } 'amount dies good on bad value';
ok ($withdrawl->amount(250.00), 'amount can be set to known good value');
dies_ok { $withdrawl->to_payment } 'to_payment dies correctly if not all attributes set';
dies_ok { $withdrawl->to_coinbase } 'to_coinbase dies correctly if not all attributes set';
dies_ok { $withdrawl->to_crypto } 'to_crypto dies correctly if not all attributes set';
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 1 : 0 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($withdrawl->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $withdrawl->debug(1); # Make sure this is set to 1 or you'll use live data

     #ok (my $result = $withdrawl->initiate, 'can get all funding');
     #is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();
