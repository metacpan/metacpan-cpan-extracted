#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use aliased 'Interchange6::Cart';
use aliased 'Interchange6::Cart::Product';

my ( $product, $cart );

lives_ok { $cart = Cart->new } "create new cart";

lives_ok {
    $cart->add( sku => "SKU01", name => "One", price => 10, quantity => 1 )
}
"add SKU01, One, price 10, qty 1";

lives_ok {
    $cart->add( sku => "SKU02", name => "Two", price => 20, quantity => 2 )
}
"add SKU02, Two, price 20, qty 2";

cmp_ok( $cart->subtotal, '==', 50, "subtotal is 50" );
cmp_ok( $cart->total,    '==', 50, "total is 50" );

$product = $cart->product_get(0);

lives_ok {
    $product->apply_cost( amount => -2, name => "discount", compound => 1 )
}
"apply compound fixed discount of -2 to 1st product";

cmp_ok( $product->cost(0),          '==', -2, "cost 0 is -2" );
cmp_ok( $product->cost("discount"), '==', -2, "cost discount is -2" );
cmp_ok( $cart->subtotal,            '==', 48, "subtotal is 48" );
cmp_ok( $cart->total,               '==', 48, "total is 48" );

lives_ok {
    $product->apply_cost(
        name      => "tax",
        amount    => 0.1,
        relative  => 1,
        inclusive => 1
      )
}
"apply 10% inclusive tax after discount";

cmp_ok( $product->cost(1),     '==', 0.8, "cost 1 is 0.8" );
cmp_ok( $product->cost("tax"), '==', 0.8, "cost tax is 0.8" );
cmp_ok( $cart->subtotal,       '==', 48,  "subtotal is 48" );
cmp_ok( $cart->total,          '==', 48,  "total is 48" );

$product = $cart->product_get(1);

lives_ok {
    $product->apply_cost(
        amount   => -0.1,
        relative => 1,
        name     => "discount",
        compound => 1
      )
}
"apply compound relative discount of -10% to 2nd product";

cmp_ok( $product->cost(0),          '==', -4, "cost 0 is -4" );
cmp_ok( $product->cost("discount"), '==', -4, "cost discount is -4" );
cmp_ok( $cart->subtotal,            '==', 44, "subtotal is 44" );
cmp_ok( $cart->total,               '==', 44, "total is 44" );

lives_ok {
    $product->apply_cost(
        name      => "tax",
        amount    => 0.2,
        relative  => 1,
        inclusive => 1
      )
}
"apply 20% inclusive tax after discount";

cmp_ok( $product->cost(1),     '==', 7.2, "cost 1 is 7.2" );
cmp_ok( $product->cost("tax"), '==', 7.2, "cost tax is 7.2" );
cmp_ok( $cart->subtotal,       '==', 44,  "subtotal is 44" );
cmp_ok( $cart->total,          '==', 44,  "total is 44" );

lives_ok { $cart->update( SKU02 => 1 ) } "change qty of 2nd product to 1";

cmp_ok( $product->cost(0),          '==', -2,  "cost 0 is -2" );
cmp_ok( $product->cost("discount"), '==', -2,  "cost discount is -2" );
cmp_ok( $product->cost(1),          '==', 3.6, "cost 1 is 3.6" );
cmp_ok( $product->cost("tax"),      '==', 3.6, "cost tax is 3.6" );
cmp_ok( $cart->subtotal,            '==', 26,  "subtotal is 26" );
cmp_ok( $cart->total,               '==', 26,  "total is 26" );

lives_ok {
    $cart->apply_cost( name => "handling", amount => 0.05, relative => 1 )
}
"add 5% handling charge to cart";

cmp_ok( $cart->cost(0),          '==', 1.3,  "cost 0 is 1.3" );
cmp_ok( $cart->cost("handling"), '==', 1.3,  "cost handling is 1.3" );
cmp_ok( $cart->subtotal,         '==', 26,   "subtotal is 26" );
cmp_ok( $cart->total,            '==', 27.3, "total is 27.3" );

lives_ok { $cart->update( SKU02 => 2 ) } "change qty of 2nd product to 2";

cmp_ok( $cart->cost(0),          '==', 2.2,  "cost 0 is 2.2" );
cmp_ok( $cart->cost("handling"), '==', 2.2,  "cost handling is 2.2" );
cmp_ok( $cart->subtotal,         '==', 44,   "subtotal is 44" );
cmp_ok( $cart->total,            '==', 46.2, "total is 46.2" );

lives_ok {
    $cart->apply_cost( name => "shipping", amount => "23" );
}
"add 23 fixed shipping charge to cart";

cmp_ok( $cart->cost(1),          '==', 23,   "cost 1 is 23" );
cmp_ok( $cart->cost("shipping"), '==', 23,   "cost shipping is 23" );
cmp_ok( $cart->subtotal,         '==', 44,   "subtotal is 44" );
cmp_ok( $cart->total,            '==', 69.2, "total is 69.2" );

done_testing;
