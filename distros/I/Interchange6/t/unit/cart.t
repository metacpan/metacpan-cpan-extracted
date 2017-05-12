#! perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warnings 0.005;

use Interchange6::Cart;
use Interchange6::Cart::Product;

my ( $cart, $product, $products, @products, %args );

lives_ok { $cart = Interchange6::Cart->new } "cart with no args";

# immutable attrs

lives_ok {
    $product = Interchange6::Cart::Product->new( name => "One", sku => "SKU01", price => 10 )
}
"create a product";

dies_ok { $cart->id(1) } "id is immutable";
dies_ok { $cart->name("name") } "name is immutable";
dies_ok { $cart->products( [$product] ) } "products is immutable";
dies_ok { $cart->sessions_id(1) } "sessions_id is immutable";
dies_ok { $cart->subtotal(1) } "subtotal is immutable";
dies_ok { $cart->users_id("1") } "users_id is immutable";
dies_ok { $cart->weight(1) } "weight is immutable";

# id

$args{id} = undef;
throws_ok { $cart = Interchange6::Cart->new(%args) } qr/id/, "fail new with undef id";

$args{id} = '34w';
lives_ok { $cart = Interchange6::Cart->new(%args) } "ok new with defined id";

throws_ok { $cart->set_id(undef) } qr/id/, "fail set_id(undef)";

lives_ok { $cart->set_id(12) } "ok set_id(12)";

# name

$args{name} = undef;
throws_ok { $cart = Interchange6::Cart->new(%args) } qr/name/, "fail new with undef name";

$args{name} = '';
throws_ok { $cart = Interchange6::Cart->new(%args) } qr/name/, "fail new with empty name";

$args{name} = "Cart";
lives_ok { $cart = Interchange6::Cart->new(%args) } "ok new with name Cart";

throws_ok { $cart->rename(undef) } qr/name/, "fail rename(undef)";

throws_ok { $cart->rename('') } qr/name/, "fail rename('')";

lives_ok { $cart->rename( "NewName" ) } "ok rename('NewName')";

# products

cmp_ok( ref( $cart->products ),
    'eq', 'ARRAY', "products is an array reference" );

ok( $cart->is_empty, "cart is_empty" );

cmp_ok( $cart->count, '==', 0, "count is 0" );

lives_ok {
    $product = Interchange6::Cart::Product->new(
        name     => "One",
        sku      => "SKU01",
        price    => 10,
        weight   => 2,
        quantity => 1
      )
}
"create a product";

$args{products} = [$product];

# passing value to products is ignored
lives_ok { $cart = Interchange6::Cart->new(%args) } "new cart with 1 product";

ok( $cart->is_empty, "cart is_empty" );

cmp_ok( $cart->count, '==', 0, "count is 0" );

delete $args{products};

ok !defined $cart->find('SKU01'), "find SKU01 returns undef (not yet added)";

lives_ok { $cart->product_push($product) } "ok product_push";

lives_ok { $product = $cart->find('SKU01') } "find SKU01 lives";
isa_ok $product, 'Interchange6::Cart::Product', 'product';
cmp_ok $product->sku, 'eq', 'SKU01', 'product sku is SKU01';

ok( !$cart->is_empty,     "not cart is_empty" );
ok( !$cart->has_subtotal, "not has_subtotal" );
ok( !$cart->has_total,    "not has_total" );
ok( !$cart->has_weight,   "not has_weight" );

cmp_ok( $cart->count,    '==', 1,  "count is 1" );
cmp_ok( $cart->quantity, '==', 1,  "quantity is 1" );
cmp_ok( $cart->subtotal, '==', 10, "subtotal is 10" );
cmp_ok( $cart->total,    '==', 10, "total is 10" );
cmp_ok( $cart->weight,   '==', 2,  "weight is 2" );

ok( $cart->has_subtotal, "has_subtotal" );
ok( $cart->has_total,    "has_total" );
ok( $cart->has_weight,   "has_weight" );

lives_ok {
    $product = Interchange6::Cart::Product->new(
        name     => "Two",
        sku      => "SKU02",
        price    => 20,
        weight   => 4,
        quantity => 2
      )
}
"create another product";

lives_ok { $cart->product_push($product) } "ok product_push";

cmp_ok( $cart->count,    '==', 2,  "count is 2" );
cmp_ok( $cart->quantity, '==', 3,  "quantity is 3" );
cmp_ok( $cart->subtotal, '==', 50, "subtotal is 50" );
cmp_ok( $cart->total,    '==', 50, "total is 50" );
cmp_ok( $cart->weight,   '==', 10, "weight is 10" );

lives_ok { $product = $cart->product_get(0) } "ok product_get(0)";

cmp_ok( $product->name, 'eq', 'One', "product name is One" );

lives_ok { $product = $cart->product_get(1) } "ok product_get(1)";

cmp_ok( $product->name, 'eq', 'Two', "product name is Two" );

lives_ok { $product = $cart->product_get(2) } "ok product_get(2)";

ok( !defined $product, "not defined" );

lives_ok {
    $product = Interchange6::Cart::Product->new(
        name     => "Three",
        sku      => "SKU03",
        price    => 30,
        weight   => 6,
        quantity => 3
      )
}
"create product Three";

lives_ok { $cart->product_push($product) } "ok product_push";

cmp_ok( $cart->count,    '==', 3,   "count is 3" );
cmp_ok( $cart->quantity, '==', 6,   "quantity is 6" );
cmp_ok( $cart->subtotal, '==', 140, "subtotal is 140" );
cmp_ok( $cart->total,    '==', 140, "total is 140" );
cmp_ok( $cart->weight,   '==', 28,  "weight is 28" );

lives_ok { $cart->product_delete(1) } "ok product_delete(1)";

cmp_ok( $cart->count,    '==', 2,   "count is 2" );
cmp_ok( $cart->quantity, '==', 4,   "quantity is 4" );
cmp_ok( $cart->subtotal, '==', 100, "subtotal is 100" );
cmp_ok( $cart->total,    '==', 100, "total is 100" );
cmp_ok( $cart->weight,   '==', 20,  "weight is 20" );

lives_ok { $product = $cart->product_get(1) } "ok product_get(1)";

cmp_ok( $product->name, 'eq', 'Three', "product name is Three" );

lives_ok {
    $product = Interchange6::Cart::Product->new(
        name     => "Four",
        sku      => "SKU04",
        price    => 40,
        weight   => 8,
        quantity => 4
      )
}
"create product Four";

lives_ok { $cart->product_set( 1, $product ) } 'ok product_set(1, $product)';

cmp_ok( $cart->count,    '==', 2,   "count is 2" );
cmp_ok( $cart->quantity, '==', 5,   "quantity is 5" );
cmp_ok( $cart->subtotal, '==', 170, "subtotal is 170" );
cmp_ok( $cart->total,    '==', 170, "total is 170" );
cmp_ok( $cart->weight,   '==', 34,  "weight is 34" );

lives_ok { $product = $cart->product_get(1) } "ok product_get(1)";

cmp_ok( $product->name, 'eq', 'Four', "product name is Four" );

cmp_ok( $cart->product_index( sub { $_->name eq 'One' } ),
    '==', 0, "search for One using product_index" );

cmp_ok( $cart->product_index( sub { $_->name eq 'Four' } ),
    '==', 1, "search for Four using product_index" );

lives_ok { @products = $cart->products_array } "get products_array";

cmp_ok( scalar @products, '==', 2, "two products in array" );

cmp_ok( $products[0]->name, 'eq', 'One', "1st product in array is One" );

lives_ok { $cart->clear } "ok clear";

ok( $cart->is_empty, "cart is empty" );

ok( $cart->is_empty,      "cart is_empty" );
ok( !$cart->has_subtotal, "not has_subtotal" );
ok( !$cart->has_total,    "not has_total" );
ok( !$cart->has_weight,   "not has_weight" );

cmp_ok( $cart->count,    '==', 0, "count is 0" );
cmp_ok( $cart->quantity, '==', 0, "quantity is 0" );
cmp_ok( $cart->subtotal, '==', 0, "subtotal is 0" );
cmp_ok( $cart->total,    '==', 0, "total is 0" );
cmp_ok( $cart->weight,   '==', 0, "weight is 0" );

# sessions_id

$args{sessions_id} = undef;
throws_ok { $cart = Interchange6::Cart->new(%args) } qr/sessions_id/,
  "fail new with undef sessions_id";

$args{sessions_id} = '34w';
lives_ok { $cart = Interchange6::Cart->new(%args) } "ok new with defined sessions_id";

throws_ok { $cart->set_sessions_id(undef) } qr/sessions_id/,
  "fail set_sessions_id(undef)";

lives_ok { $cart->set_sessions_id(12) } "ok set_sessions_id(12)";

cmp_ok( $cart->sessions_id, 'eq', "12", "sessions_id is 12" );

lives_ok { $cart->clear_sessions_id } "ok clear_sessions_id";

ok( !defined $cart->sessions_id, "sessions_id is undef" );

# users_id

$args{users_id} = undef;
throws_ok { $cart = Interchange6::Cart->new(%args) } qr/users_id/,
  "fail new with undef users_id";

$args{users_id} = '34w';
lives_ok { $cart = Interchange6::Cart->new(%args) } "ok new with defined users_id";

throws_ok { $cart->set_users_id(undef) } qr/users_id/,
  "fail set_users_id(undef)";

lives_ok { $cart->set_users_id(12) } "ok set_users_id(12)";

cmp_ok( $cart->users_id, 'eq', "12", "users_id is 12" );

# add

lives_ok { $cart = Interchange6::Cart->new } "create empty cart";

throws_ok { $cart->add } qr/undefined arg/i, "fail add with no args";

throws_ok { $cart->add(undef) } qr/undefined/i, "fail add undef";

throws_ok { $cart->add('') } qr/Single parameters to new\(\) must be a HASH/,
  "fail add scalar";

{
    package TestObj;
    use Moo;
    has id => ( is => 'ro' );
}

throws_ok { $cart->add( TestObj->new ) }
qr/Single parameters to new\(\) must be a HASH/, "add non-Product object";

lives_ok {
    $product = Interchange6::Cart::Product->new(
        name     => "One",
        sku      => "SKU01",
        price    => 10,
        weight   => 2,
        quantity => 1
      )
}
"create a product";

lives_ok { $cart->add($product) } "add product obj";

cmp_ok( $cart->count,    '==', 1,  "count is 1" );
cmp_ok( $cart->quantity, '==', 1,  "quantity is 1" );
cmp_ok( $cart->subtotal, '==', 10, "subtotal is 10" );
cmp_ok( $cart->total,    '==', 10, "total is 10" );
cmp_ok( $cart->weight,   '==', 2,  "weight is 2" );

# adding the same object with different attributes values would mean we
# change the product that is already in the cart and that is not a valid
# scenario so create new object
lives_ok {
    $product = Interchange6::Cart::Product->new(
        name     => "One",
        sku      => "SKU01",
        price    => 10,
        weight   => 2,
        quantity => 2
      )
}
"create a product";

lives_ok { $cart->add($product) } "add same product qty 2";

cmp_ok( $cart->count,    '==', 1,  "count is 1" );
cmp_ok( $cart->quantity, '==', 3,  "quantity is 3" );
cmp_ok( $cart->subtotal, '==', 30, "subtotal is 30" );
cmp_ok( $cart->total,    '==', 30, "total is 30" );
cmp_ok( $cart->weight,   '==', 6,  "weight is 6" );

lives_ok {
    $cart->add(
        name     => "Two",
        sku      => "SKU02",
        price    => 20,
        weight   => 4,
        quantity => 2
      )
}
"Add product Two qty 2 as hash";

cmp_ok( $cart->count,    '==', 2,  "count is 2" );
cmp_ok( $cart->quantity, '==', 5,  "quantity is 5" );
cmp_ok( $cart->subtotal, '==', 70, "subtotal is 70" );
cmp_ok( $cart->total,    '==', 70, "total is 70" );
cmp_ok( $cart->weight,   '==', 14, "weight is 14" );

# update

lives_ok { $cart->update } "update with no args does nothing";

throws_ok { $cart->update( "badsku" => 1 ) } qr/badsku not found in cart/,
  "fail update with bad sku";

throws_ok { $cart->update("SKU01") }
qr/quantity argument to update must be defined/, "fail update no quantity";

throws_ok { $cart->update(undef) } qr/sku not defined/, "fail update sku undef";

# NOTE: this is the test which fails if we simply use 'isa => PositiveInt'
# for Cart::Products's quantity attribute.
# https://github.com/interchange/Interchange6/issues/28
throws_ok { $cart->update( SKU01 => 2.3 ) } qr/Must be a positive integer/,
  "fail update with non-integer quantity"
  or diag(
    "SKU01 quantity set 2.3 is: ",
    $cart->product_get( $cart->product_index( sub { $_->sku eq 'SKU01' } ) )
      ->quantity
  );

lives_ok { @products = $cart->update( SKU01 => 3 ) }
"set SKU01 qty to what it already is in cart";

cmp_ok( @products, '==', 0, "no products returned" );

lives_ok { @products = $cart->update( SKU01 => 1 ) } "set SKU01 qty to 1";

cmp_ok( @products,       '==', 1,  "1 product returned" );
cmp_ok( $cart->count,    '==', 2,  "count is 2" );
cmp_ok( $cart->quantity, '==', 3,  "quantity is 3" );
cmp_ok( $cart->subtotal, '==', 50, "subtotal is 50" );
cmp_ok( $cart->total,    '==', 50, "total is 50" );
cmp_ok( $cart->weight,   '==', 10, "weight is 10" );

lives_ok { @products = $cart->update( SKU01 => 1, SKU02 => 1 ) }
"set SKU01 qty to 1 and SKU02 qty to 1";

cmp_ok( @products,    '==', 1, "1 product returned (qty unchanged for SKU01)" );
cmp_ok( $cart->count, '==', 2, "count is 2" );
cmp_ok( $cart->quantity, '==', 2,  "quantity is 2" );
cmp_ok( $cart->subtotal, '==', 30, "subtotal is 30" );
cmp_ok( $cart->total,    '==', 30, "total is 30" );
cmp_ok( $cart->weight,   '==', 6,  "weight is 6" );

lives_ok { @products = $cart->update( SKU01 => 2, SKU02 => 2 ) }
"set SKU01 qty to 2 and SKU02 qty to 2";

cmp_ok( @products,       '==', 2,  "2 products returned" );
cmp_ok( $cart->count,    '==', 2,  "count is 2" );
cmp_ok( $cart->quantity, '==', 4,  "quantity is 4" );
cmp_ok( $cart->subtotal, '==', 60, "subtotal is 60" );
cmp_ok( $cart->total,    '==', 60, "total is 60" );
cmp_ok( $cart->weight,   '==', 12, "weight is 12" );

lives_ok { @products = $cart->update( SKU01 => 0 ) } "set SKU01 qty to 0";

cmp_ok( @products,       '==', 0,  "0 products returned" );
cmp_ok( $cart->count,    '==', 1,  "count is 1" );
cmp_ok( $cart->quantity, '==', 2,  "quantity is 2" );
cmp_ok( $cart->subtotal, '==', 40, "subtotal is 40" );
cmp_ok( $cart->total,    '==', 40, "total is 40" );
cmp_ok( $cart->weight,   '==', 8,  "weight is 8" );

lives_ok {
    $cart->add(
        name    => "One",
        sku     => "SKU01",
        price   => 10,
        combine => 0,
      )
}
"Add product SKU01 with combine => 0";

lives_ok {
    $cart->add(
        id      => 1,
        name    => "One",
        sku     => "SKU01",
        price   => 10,
        combine => 1,
      )
}
"Add product SKU01 with combine => 1";

cmp_ok( $cart->quantity, '==', 4,  "cart quantity is 4" );

throws_ok { $cart->update( SKU01 => 2 ) }
qr/More than one product in cart with sku SKU01/, "update SKU01 dies";

throws_ok { $cart->update( { sku => 'SKU01', quantity => 2 } ) }
qr/More than one product found in cart for update/,
  "update SKU01 using hashref args dies";

throws_ok { $cart->update( {} ) }
qr/Args to update must include index, id or sku/,
  "update with empty hashref dies";

throws_ok { $cart->update( [] ) } qr/Unexpected ARRAY argument to update/,
  "update with arrayref as arg dies";

throws_ok { $cart->update( { index => 'F', quantity => 1 } ) }
qr/bad index for update/, "update with string value to index dies";

lives_ok { $cart->update( { index => 0, quantity => 3 } ) }
"update index 0 with quantity 3 lives";

cmp_ok( $cart->quantity, '==', 5,  "cart quantity is 5" );

throws_ok { $cart->update( { index => 0 } ) }
qr/quantity argument to update must be defined/,
  "update index 0 with no quantity dies";

throws_ok { $cart->update( { id => 7 } ) }
qr/Product not found in cart for update/,
  "update non-existant id 7 dies";

lives_ok { $cart->update( { id => 1, quantity => 2 } ) }
  "update id 1 to quantity 2 lives";

cmp_ok( $cart->quantity, '==', 6,  "cart quantity is 6" );

throws_ok { $cart->update({index => 0, quantity => []}) }
qr/quantity argument to update must be defined/,
"update with value of quantity as arrayref dies";

throws_ok { $cart->update({index => 4}) }
qr/Product not found for update/,
"update with non-existant index dies";

lives_ok { $cart->remove({ index => 2 }) } "remove product at index 2";
lives_ok { $cart->remove({ index => 1 }) } "remove product at index 1";

# remove

throws_ok { $cart->remove } qr/no argument/i, "fail remove with no args";
cmp_ok( $cart->count, '==', 1, "count is 1" );

throws_ok { $cart->remove(undef) } qr/no argument/i,
  "fail remove with undef arg";
cmp_ok( $cart->count, '==', 1, "count is 1" );

throws_ok { $cart->remove("badsku") } qr/sku badsku not found in cart/,
  "fail remove non-existant sku";
cmp_ok( $cart->count, '==', 1, "count is 1" );

lives_ok { $product = $cart->remove("SKU02") } "ok remove SKU02";
cmp_ok( $cart->count,    '==', 0,       "count is 0" );
cmp_ok( $cart->quantity, '==', 0,       "quantity is 0" );
cmp_ok( $cart->subtotal, '==', 0,       "subtotal is 0" );
cmp_ok( $cart->total,    '==', 0,       "total is 0" );
cmp_ok( $cart->weight,   '==', 0,       "weight is 0" );
cmp_ok( $product->sku,   'eq', "SKU02", "product SKU02 returned" );

lives_ok {
    $cart->add(
        name    => "One",
        sku     => "SKU01",
        price   => 10,
        combine => 0,
      )
}
"Add product One with combine => 0";

lives_ok {
    $cart->add(
        id      => 1,
        name    => "One",
        sku     => "SKU01",
        price   => 10,
        combine => 1,
      )
}
"Add product One with combine => 1";

lives_ok {
    $cart->add(
        id    => 1,
        name  => "Two",
        sku   => "SKU02",
        price => 20,
      )
}
"Add product Two";

cmp_ok( $cart->count,    '==', 3, "count is 3" );
cmp_ok( $cart->quantity, '==', 3, "quantity is 3" );

throws_ok { $cart->remove('SKU01') }
qr/Cannot remove product with non-unique sku/, "remove SKU01 dies";

throws_ok { $cart->remove( { sku => 'SKU01' } ) }
qr/Cannot remove product with non-unique sku/, "remove sku => SKU01 dies";

throws_ok { $cart->remove( { id => 2 } ) }
qr/Product with id 2 not found in cart/, "remove id => 2 dies";

throws_ok { $cart->remove( { id => 1 } ) }
qr/Cannot remove product with non-unique id/, "remove id => 1 dies";

lives_ok { $cart->remove( { index => 1 } ) } "remove index => 1 lives";

cmp_ok( $cart->count,    '==', 2, "count is 2" );
cmp_ok( $cart->quantity, '==', 2, "quantity is 2" );

lives_ok { $cart->remove( { id => 1 } ) } "remove id => 1 lives";

cmp_ok( $cart->count,    '==', 1, "count is 1" );
cmp_ok( $cart->quantity, '==', 1, "quantity is 1" );

throws_ok { $cart->remove( { index => 2.2 } ) }
qr/bad index supplied to remove/,
  "remove index => 2.2 dies";

throws_ok { $cart->remove( { index => 'F' } ) }
qr/bad index supplied to remove/,
  "remove index => 'F' dies";

throws_ok { $cart->remove( { index => -1 } ) }
qr/bad index supplied to remove/,
  "remove index => -1 dies";

throws_ok { $cart->remove( { foo => 'bar' } ) }
qr/Args to remove must include one of: index, id or sku/,
  "remove foo => bar dies";

# seed

lives_ok { $cart = Interchange6::Cart->new } "new cart";

throws_ok {
    $cart->seed(
        { sku => 'ONE', name => "One", price => 1, quantity => 1, weight => 2 }
      )
}
qr/argument to seed must be an array reference/,
  "fail adding arg that is not array reference";

cmp_ok( $cart->count,    '==', 0, "count is 0" );
cmp_ok( $cart->quantity, '==', 0, "quantity is 0" );
cmp_ok( $cart->subtotal, '==', 0, "subtotal is 0" );
cmp_ok( $cart->total,    '==', 0, "total is 0" );
cmp_ok( $cart->weight,   '==', 0, "weight is 0" );

$products = [
    { sku => 'ONE', name => "One", price => 1, quantity => 1,   weight => 2 },
    { sku => 'TWO', name => "Two", price => 2, quantity => 2.2, weight => 4 },
];

throws_ok { $cart->seed($products) } qr/quantity/,
  "fail seed with 1 good and 1 bad product";

cmp_ok( $cart->count,    '==', 0, "count is 0" );
cmp_ok( $cart->quantity, '==', 0, "quantity is 0" );
cmp_ok( $cart->subtotal, '==', 0, "subtotal is 0" );
cmp_ok( $cart->total,    '==', 0, "total is 0" );
cmp_ok( $cart->weight,   '==', 0, "weight is 0" );

$products = [
    { sku => 'ONE', name => "One", price => 1, quantity => 1, weight => 2 },
    { sku => 'TWO', name => "Two", price => 2, quantity => 2, weight => 4 },
];

lives_ok { $cart->seed($products) } "seed 2 good products";

cmp_ok( $cart->count,    '==', 2,  "count is 2" );
cmp_ok( $cart->quantity, '==', 3,  "quantity is 3" );
cmp_ok( $cart->subtotal, '==', 5,  "subtotal is 5" );
cmp_ok( $cart->total,    '==', 5,  "total is 5" );
cmp_ok( $cart->weight,   '==', 10, "weight is 10" );

lives_ok { $cart = Interchange6::Cart->new } "new cart";

lives_ok { $cart->add( sku => "old", name => "old", price => 50 ) }
"add a product which seed should remove";

cmp_ok( $cart->count,    '==', 1,  "count is 1" );
cmp_ok( $cart->quantity, '==', 1,  "quantity is 1" );
cmp_ok( $cart->subtotal, '==', 50, "subtotal is 50" );
cmp_ok( $cart->total,    '==', 50, "total is 50" );

lives_ok { $cart->seed($products) } "seed 2 good products";

cmp_ok( $cart->count,    '==', 2,  "count is 2" );
cmp_ok( $cart->quantity, '==', 3,  "quantity is 3" );
cmp_ok( $cart->subtotal, '==', 5,  "subtotal is 5" );
cmp_ok( $cart->total,    '==', 5,  "total is 5" );
cmp_ok( $cart->weight,   '==', 10, "weight is 10" );

done_testing;
