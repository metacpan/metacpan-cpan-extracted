use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Report');
}

my $report = new_ok('Finance::GDAX::API::Report');
can_ok($report, 'type');
can_ok($report, 'start_date');
can_ok($report, 'end_date');
can_ok($report, 'product_id');
can_ok($report, 'account_id');
can_ok($report, 'format');
can_ok($report, 'email');
can_ok($report, 'report_id');
can_ok($report, 'get');
can_ok($report, 'create');

ok($report->start_date('2017-06-01T00:00:00.000Z'), 'can set start_date');
ok($report->end_date('2017-06-15T00:00:00.000Z'), 'can set end_date');

is($report->format, 'pdf', 'Default format is good');
dies_ok { $report->format('badformat') } 'format dies on bad value';
ok($report->format('csv'), 'format sets on good value');
   
dies_ok { $report->type('badvalue') } 'bad type dies ok';
ok($report->type('fills'), 'type sets ok to fills');

dies_ok { $report->create } 'dies good when type is fills and no product_id';
ok($report->type('account'), 'type sets ok to account');
dies_ok { $report->create } 'dies good when type is account and no account_id';
ok($report->product_id('BTC-USD'), 'product ID can be set');

 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 7 : 6 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret ;

     unless ($secret eq 'RAW ENVARS') {
	 ok($report->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $report->debug(1); # Make sure this is set to 1 or you'll use live data

     $report->type('fills');
     ok (my $result = $report->create, 'can create fills BTC-USD report');
     is (ref $result, 'HASH', 'create returns hash');
     ok (defined $$result{id}, 'got a report id back');

     $report = Finance::GDAX::API::Report->new;
     unless ($secret eq 'RAW ENVARS') {
	 warn "Need access to secrets again for new request\n";
	 $report->external_secret($$secret[0], $$secret[1]);
     }
     ok ($report->report_id($$result{id}), 'can assign report_id for getting');
     ok (my $get_result = $report->get, 'Can get report status that was created');
     is (ref $get_result, 'HASH', 'get returns hash');
}

done_testing();
