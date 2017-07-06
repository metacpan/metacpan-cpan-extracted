use v5.20;
use warnings;
use Test::More;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Account');
}

my $account = new_ok('Finance::GDAX::API::Account');
can_ok($account, 'get_all');
can_ok($account, 'get');
can_ok($account, 'history');
can_ok($account, 'holds');
 
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 11 : 10 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($account->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
          
     $account->debug(1); # Make sure this is set to 1 or you'll use live data
     
     ok(my $response = $account->get_all, 'get_all accounts list');
     my $rc = $account->response_code;
     warn 'ERROR: '.$account->error if $account->error;
     is($rc, 200, 'Good 200 response code from accounts list');
     is(ref($response), 'ARRAY', 'get_all accounts returned an array');
     my $found;
     my $account_id;
     foreach (@$response) {
	 if ($$_{currency} eq 'BTC') {
	     $found = 1;
	     $account_id = $$_{id};
	     last;
	 }
     }
     ok($found, 'get_all accounts returns a BTC account');

     ok(my $info = $account->get($account_id), 'get BTC account');
     ok(defined $$info{balance}, 'BTC account has balance defined');

     ok(my $history = $account->history($account_id), 'get BTC account history');
     is(ref $history, 'ARRAY', 'get BTC account history is an array');
     ok(my $holds = $account->holds($account_id), 'get BTC account holds');
     is(ref $history, 'ARRAY', 'get BTC account holds is an array');
}

done_testing();

