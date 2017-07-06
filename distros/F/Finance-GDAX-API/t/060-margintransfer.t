use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::MarginTransfer');
}

my $xfer = new_ok('Finance::GDAX::API::MarginTransfer');
can_ok($xfer, 'initiate');
can_ok($xfer, 'margin_profile_id');
can_ok($xfer, 'type');
can_ok($xfer, 'amount');
can_ok($xfer, 'currency');

dies_ok { $xfer->type('badtype') } 'type dies good on bad values';
dies_ok { $xfer->amount(-250.00) } 'amount dies good on bad value';
ok ($xfer->type('withdraw'), 'type can be set to known good value');
dies_ok { $xfer->initiate } 'initiate dies correctly if not all attributes set';
    
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 1 : 0 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($xfer->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $xfer->debug(1); # Make sure this is set to 1 or you'll use live data

     # Tests here will require creating transactions first... will do later
     #ok (my $result = $xfer->initiate, 'can get all funding');
     #is (ref $result, 'ARRAY', 'get returns array');
}

done_testing();

