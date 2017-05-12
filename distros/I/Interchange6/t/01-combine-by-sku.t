#!perl

use strict;
use warnings;

use Test::Exception;
use Test::More;

use aliased 'Interchange6::Cart';
use aliased 'Interchange6::Cart::Product';

my ( $product1, $product2, $cart );

lives_ok { $cart = Cart->new } "create new cart";

lives_ok {
   $cart->add( sku => "SKU01", name => "One", price => 10, quantity => 1 );
}
"1. add SKU01, One, price 10, qty 1";

is( $cart->count, 1, 'only a single item in the Cart' );

$product1 = $cart->product_get(0);
is( $product1->combine, 1, 'combine set to 1 by default' );

# add a product with the same SKU, but combine set to 0
lives_ok {
   $cart->add( sku => "SKU01", name => "One", price => 10, quantity => 1, combine => 0 );
}
"2. add SKU01, One, price 10, qty 1";

$product2 = $cart->product_get(1);
is( $cart->count, 2, 'two products now exist in the Cart' );
is( $product1->sku, $product2->sku, 'both products in the Cart have the same sku' );

# add a product with the same SKU, but with combine set to 1
lives_ok {
   $cart->add( sku => "SKU01", name => "One", price => 10, quantity => 1, combine => 1 );
}
"3. add SKU01, One, price 10, qty 1";

is( $cart->count, 2, 'two products still exist in the Cart' );
is( $cart->quantity, 3, 'quantity is now 3, two products with the same sku were combined' );

# add a product with the same SKU, but with combine set to a custom CodeRef
lives_ok {
   $cart->add( sku => "SKU01", name => "One", price => 10, quantity => 1, combine => sub { return 0 }, );
}
"4. add SKU01, One, price 10, qty 1";

is( $cart->count, 3, 'three products now exist in the Cart' );
is( $cart->quantity, 4, 'quantity is now 4' );

done_testing();
