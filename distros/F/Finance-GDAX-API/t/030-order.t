use v5.20;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Order');
}

my $order = new_ok('Finance::GDAX::API::Order');
# Attributes
can_ok($order, 'client_oid');
can_ok($order, 'type');
can_ok($order, 'side');
can_ok($order, 'product_id');
can_ok($order, 'stp');
can_ok($order, 'price');
can_ok($order, 'size');
can_ok($order, 'time_in_force');
can_ok($order, 'cancel_after');
can_ok($order, 'post_only');
can_ok($order, 'funds');
can_ok($order, 'overdraft_enabled');
can_ok($order, 'funding_amount');
# Methods
can_ok($order, 'initiate');
can_ok($order, 'get');
can_ok($order, 'list');
can_ok($order, 'cancel');
can_ok($order, 'cancel_all');
can_ok($order, 'initiate');

dies_ok { $order->price(-45) } 'bad price dies ok';
dies_ok { $order->size(0) } 'bad size dies ok';
dies_ok { $order->type('BAD') } 'bad type dies ok';
dies_ok { $order->side('foolish') } 'bad side dies ok';
dies_ok { $order->stp('xx') } 'bad stp dies ok';
dies_ok { $order->time_in_force('UGH') } 'bad time_in_force dies ok';
dies_ok { $order->post_only('String') } 'bad post_only dies ok';

# Set up limit order
ok $order->side('buy'), 'buy side set';
ok $order->product_id('BTC-USD'), 'product_id set';
ok $order->price(500.23), 'price set';
ok $order->size(0.5), 'size set';
 
 SKIP: {
     my $secret = GDAX_environment_vars();
     my $skipnum = 0;
     if ($secret) { $skipnum = $secret ne 'RAW ENVARS' ? 6 : 5 };
     skip 'GDAX_* environment variables not set', $skipnum unless $secret;

     unless ($secret eq 'RAW ENVARS') {
	 ok($order->external_secret($$secret[0], $$secret[1]), 'external secrets');
     }
     
     $order->debug(1); # Make sure this is set to 1 or you'll use live data

     ok (my $result = $order->initiate, 'limit order initiated');

     # Order Lists
     warn "Trying API Keys again...\n";
     my $order = Finance::GDAX::API::Order->new;
     unless ($secret eq 'RAW ENVARS') {
	 $order->external_secret($$secret[0], $$secret[1]);
     }
     ok (my $list   = $order->list, 'list of orders');
     ok ($list = $order->list(['active','pending']), 'list with multiple status');
     ok ($list = $order->list(undef, 'BTC-USD'), 'list of product_id');
     ok ($list = $order->list(['active','pending'], 'BTC-USD'), 'list with multiple status with product_id');

}

done_testing();

