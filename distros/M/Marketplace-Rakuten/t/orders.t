#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 45;
use Data::Dumper;
use Marketplace::Rakuten;

my $rakuten = Marketplace::Rakuten->new(key => '123456789a123456789a123456789a12');

my @orders = $rakuten->get_pending_orders;

ok (scalar @orders);
print Dumper(\@orders);

my $order = shift @orders;
my $shipping_address = $order->shipping_address;
ok $shipping_address;
my $billing_address = $order->billing_address;
ok $billing_address, "Found billing address";

foreach my $method (qw/client_id gender first_name last_name address1
                       address2 zip city country email phone/) {
    ok($shipping_address->$method, "Got shipping address $method")
      and diag $shipping_address->$method;
    ok($billing_address->$method, "Got billing address $method")
      and diag $shipping_address->$method;

}

my @items = $order->items;
ok(scalar @items, "Found items");
my $item = shift @items;
foreach my $method (qw/quantity remote_shop_order_item
                       price subtotal rakuten_id
                       variant_id product_id sku/) {
    ok($item->$method, "Found item's $method") and diag $item->$method;
}


foreach my $method (qw/email first_name last_name comments
                       shipping_cost subtotal total_cost
                       number_of_items payment_method/) {
    ok($order->$method, "Found order's $method") and diag $order->$method;
}
ok $order->order_date->ymd, "Found order's date";
ok !$order->shipping_method, "No shipping method found";

