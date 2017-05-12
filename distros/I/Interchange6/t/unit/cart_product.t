#! perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Interchange6::Cart;
use Interchange6::Cart::Product;

my ( $product, %args );

throws_ok { $product = Interchange6::Cart::Product->new(%args) } qr/missing required arguments/i,
  "fail empty args";

$args{name} = "some name";
throws_ok { $product = Interchange6::Cart::Product->new(%args) } qr/missing required arguments/i,
  "fail no price or sku";

$args{sku} = "SKU001";
throws_ok { $product = Interchange6::Cart::Product->new(%args) } qr/missing required arguments/i,
  "fail no price";

$args{price} = 23.45;
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "product created";

$args{name} = '';
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail empty name";

$args{name} = "My Name";
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok name My Name";

$args{price} = 0;
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok price 0";

$args{price} = -1;
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail negative price";

$args{price} = "w";
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail non-numeric price";

$args{price} = 23.45;

$args{sku} = '';
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail sku empty";

$args{sku} = "SKU01";
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok sku SKU01";

dies_ok { $product->id("new") } "id is immutable";
dies_ok { $product->cart("new") } "cart is immutable";
dies_ok { $product->name("new") } "name is immutable";
dies_ok { $product->price(10) } "price is immutable";
dies_ok { $product->selling_price(10) } "selling_price is immutable";
dies_ok { $product->discount_percent(10) } "discount_percent is immutable";
dies_ok { $product->quantity(10) } "quantity is immutable";
dies_ok { $product->sku("new") } "sku is immutable";
dies_ok { $product->canonical_sku("new") } "canonical_sku is immutable";
dies_ok { $product->subtotal("new") } "subtotal is immutable";
dies_ok { $product->uri("new") } "uri is immutable";
dies_ok { $product->weight(10) } "weight is immutable";

$args{id} = "ww";
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail id not numeric";

$args{id} = 12.3;
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail id not int";

delete $args{id};

$args{cart} = "banana";
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail bad cart type";

$args{cart} = Interchange6::Cart->new;
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok good cart type";

lives_ok { $product->set_cart( $args{cart} ) } "ok set_cart";

dies_ok { $product->set_cart("banana") } "fail set_cart bad type";

delete $args{cart};

lives_ok { $product->set_price(20) } "ok set_price";

dies_ok { $product->set_price(-1) } "fail set_price(-1)";

dies_ok { $product->set_price("new") } "fail set_price('new')";

cmp_ok( $product->selling_price, '==', 20, "selling price same as price" );

$args{selling_price} = undef;
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail undef selling_price";

$args{selling_price} = -1;
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail -1 selling_price";

$args{selling_price} = "new";
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail non-numeric selling_price";

$args{selling_price} = 10;
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok good selling_price";

cmp_ok( $product->selling_price, '==', 10, "selling price now 10" );

dies_ok { $product->set_selling_price("new") }
"fail set_selling_price('new')";

dies_ok { $product->set_selling_price(-1) } "fail set_selling_price(-1)";

dies_ok { $product->set_selling_price(undef) } "fail set_selling_price(undef)";

lives_ok { $product->set_selling_price(20) } "ok set_selling_price(20)";
cmp_ok( $product->selling_price, '==', 20, "selling price now 20" );

lives_ok { $product->set_price(20) } "ok set_price(20)";
cmp_ok( $product->price, '==', 20, "price is 20" );

cmp_ok( $product->discount_percent, '==', 0, "discount is 0%" );

lives_ok { $product->set_selling_price(15) } "ok set_selling_price(15)";
cmp_ok( $product->selling_price, '==', 15, "selling price now 15" );

cmp_ok( $product->discount_percent, '==', 25, "discount is 25%" );

lives_ok { $product->set_price(15) } "ok set_price(15)";
cmp_ok( $product->price, '==', 15, "price is 15" );

cmp_ok( $product->discount_percent, '==', 0, "discount is 0%" );

cmp_ok( $product->quantity, '==', 1, "default quantity is 1" );

cmp_ok( $product->subtotal, '==', 15, "subtotal is 15" );

%args = (
    name     => "my Product",
    sku      => "SKU001",
    price    => 20,
    quantity => 2,
);
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok new product quantity 2";

cmp_ok( $product->quantity, '==', 2,  "quantity is 2" );
cmp_ok( $product->subtotal, '==', 40, "subtotal is 40" );
cmp_ok( $product->total,    '==', 40, "total is 40" );

dies_ok { $product->set_quantity(undef) } "fail set_quantity(undef)";

dies_ok { $product->set_quantity(-1) } "fail set_quantity(-1)";

dies_ok { $product->set_quantity(3.3) } "fail set_quantity(3.3)";

lives_ok { $product->set_quantity(3) } "ok set_quantity(3)";

cmp_ok( $product->quantity, '==', 3,  "quantity is 3" );
cmp_ok( $product->subtotal, '==', 60, "subtotal is 60" );
cmp_ok( $product->total,    '==', 60, "total is 60" );

$args{uri} = "someuri";
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok uri someuri";

$args{weight} = "w";
dies_ok { $product = Interchange6::Cart::Product->new(%args) } "fail weight non-numeric";

$args{weight} = 12.34;
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok weight 12.34";

ok( $product->is_canonical, "product is_canonical" );
ok( !$product->is_variant,  "not product is_variant" );

$args{canonical_sku} = "SKU2";
lives_ok { $product = Interchange6::Cart::Product->new(%args) } "ok product with canonical_sku";

ok( !$product->is_canonical, "not product is_canonical" );
ok( $product->is_variant,    "product is_variant" );

cmp_ok( ref( $product->extra ), 'eq', 'HASH', "extra is a hash reference" );

lives_ok { $product->set_extra( one => 1 ) } "add one key to extra";
lives_ok { $product->set_extra( two => 2, three => 3 ) } "add 2 keys to extra";

cmp_ok( keys( %{ $product->extra } ), '==', 3, "extra has 3 keys" );
cmp_ok( $product->keys_extra,         '==', 3, "keys_extra has 3 keys" );
cmp_ok( $product->get_extra('three'), '==', 3, "three => 3" );
ok( $product->exists_extra('three'), "key three exists" );

lives_ok { $product->delete_extra('three') } "delete three from extra";
ok( !$product->exists_extra('three'), "key three does not exist" );

lives_ok { $product->set_extra( undef => undef ) }
"add undef => undef to extra";
ok( $product->exists_extra('undef'),   "key undef exists" );
ok( !$product->defined_extra('undef'), "!defined_extra('undef')" );

lives_ok { $product->clear_extra } "ok clear_extra";
cmp_ok( $product->keys_extra, '==', 0, "keys_extra has 0 keys" );

done_testing;
