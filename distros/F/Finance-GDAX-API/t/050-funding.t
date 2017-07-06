use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Funding');
}

my $funding = new_ok('Finance::GDAX::API::Funding');
can_ok($funding, 'get');
can_ok($funding, 'repay');
can_ok($funding, 'status');
can_ok($funding, 'amount');
can_ok($funding, 'currency');

dies_ok { $funding->status('badstatus') } 'status dies good on bad values';
dies_ok { $funding->amount(-250.00) } 'amount dies good on bad value';
ok ($funding->status('settled'), 'status can be set to known good value');
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 3 : 2 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($funding->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $funding->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $funding->get, 'can get all funding');
     is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();

