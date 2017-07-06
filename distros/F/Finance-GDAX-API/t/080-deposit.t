use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Deposit');
}

my $deposit = new_ok('Finance::GDAX::API::Deposit');
can_ok($deposit, 'payment_method_id');
can_ok($deposit, 'coinbase_account_id');
can_ok($deposit, 'amount');
can_ok($deposit, 'currency');

dies_ok { $deposit->amount(-250.00) } 'amount dies good on bad value';
ok ($deposit->amount(250.00), 'amount can be set to known good value');
dies_ok { $deposit->from_payment } 'from_payment dies correctly if not all attributes set';
dies_ok { $deposit->from_coinbase } 'from_coinbase dies correctly if not all attributes set';
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 1 : 0 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($deposit->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $deposit->debug(1); # Make sure this is set to 1 or you'll use live data

     #ok (my $result = $deposit->initiate, 'can get all funding');
     #is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();
