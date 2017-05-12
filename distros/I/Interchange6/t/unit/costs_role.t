#! perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Interchange6::Cart::Cost;

{
    package CostsConsumer;
    use Moo;
    with 'Interchange6::Role::Costs';
    use namespace::clean;

    has subtotal => ( is => 'ro' );
}

my ( $obj, $cost, @costs );

lives_ok { $obj = CostsConsumer->new( subtotal => 10 ) }
"create object with subtotal 10";

cmp_ok( $obj->subtotal, '==', 10, "subtotal is 10" );
cmp_ok( $obj->total,    '==', 10, "total is 10" );

lives_ok { $obj = CostsConsumer->new( subtotal => 20 ) }
"create object with subtotal 20";

cmp_ok( $obj->subtotal, '==', 20, "subtotal is 20" );
ok( !$obj->has_total, "has_total false" );
cmp_ok( $obj->total, '==', 20, "total is 20" );
ok( $obj->has_total, "has_total true" );

cmp_ok( $obj->cost_count,       '==', 0, "cost_count is 0" );
cmp_ok( scalar $obj->get_costs, '==', 0, "get_costs is empty list" );

throws_ok { $obj->apply_cost } qr/argument to apply_cost undefined/,
  "fail apply_cost with no args";

throws_ok { $obj->apply_cost($obj) }
qr{Single parameters to new\(\) must be a HASH ref data},
  "fail apply_cost bad obj as arg";

lives_ok { $cost = Interchange6::Cart::Cost->new( name => "Cost1", amount => 12 ) }
"create a Cost object with name 'Cost1' and amount 12";

lives_ok { $obj->apply_cost($cost) } "apply_cost Cost object";
ok( !$obj->has_total, "has_total false" );

cmp_ok( $obj->subtotal,   '==', 20, "subtotal is 20" );
cmp_ok( $obj->total,      '==', 32, "total is 32" );
cmp_ok( $obj->cost_count, '==', 1,  "cost_count is 1" );

lives_ok { $cost = Interchange6::Cart::Cost->new( name => "Cost2", amount => 0.1, relative => 1 ) }
"create a Cost object with name 'Cost2', amount 0.1 and relative => 1";

lives_ok { $obj->apply_cost($cost) } "cost_push Cost object";
ok( !$obj->has_total, "has_total false" );

cmp_ok( $obj->subtotal,   '==', 20, "subtotal is 20" );
cmp_ok( $obj->total,      '==', 34, "total is 34" );
cmp_ok( $obj->cost_count, '==', 2,  "cost_count is 2" );

lives_ok { $cost = $obj->cost_get(0) } "get cost at index 0";
cmp_ok( $cost->current_amount, '==', 12,      "current_amount is 12" );
cmp_ok( $cost->name,           'eq', "Cost1", "name is Cost1" );

lives_ok { $cost = $obj->cost_get(1) } "get cost at index 1";
cmp_ok( $cost->current_amount, '==', 2,       "current_amount is 2" );
cmp_ok( $cost->name,           'eq', "Cost2", "name is Cost2" );

lives_ok {
    $cost = Interchange6::Cart::Cost->new(
        name      => "Cost3",
        amount    => 0.1,
        relative  => 1,
        inclusive => 1
      )
}
"create Cost obj with name 'Cost3', amount 0.1, relative => 1, inclusive => 1";

lives_ok { $obj->cost_set( 1, $cost ) } "set_cost at index 1 to Cost3 obj";
ok( !$obj->has_total, "has_total false" );

cmp_ok( $obj->subtotal,   '==', 20, "subtotal is 20" );
cmp_ok( $obj->total,      '==', 32, "total is 32" );
cmp_ok( $obj->cost_count, '==', 2,  "cost_count is 2" );
ok( $obj->has_total, "has_total true" );

lives_ok { @costs = $obj->get_costs } "get_costs";
isa_ok( $costs[0], 'Interchange6::Cart::Cost', "obj at index 0" );
cmp_ok( $costs[0]->name, 'eq', "Cost1", "obj at index 0 name is Cost1" );
isa_ok( $costs[1], 'Interchange6::Cart::Cost', "obj at index 1" );
cmp_ok( $costs[1]->name, 'eq', "Cost3", "obj at index 1 name is Cost3" );

lives_ok { $obj->clear_costs } "clear_costs";
ok( !$obj->has_total, "has_total false" );
cmp_ok( $obj->subtotal, '==', 20, "subtotal is 20" );
cmp_ok( $obj->total,    '==', 20, "total is 20" );
ok( $obj->has_total, "has_total true" );
lives_ok { $obj->clear_total } "clear_total";
ok( !$obj->has_total, "has_total false" );
cmp_ok( $obj->total, '==', 20, "total is 20" );

lives_ok { $obj->apply_cost( { name => "New1", amount => 5 } ) }
"apply_cost with args as hashref";

lives_ok { $obj->apply_cost( name => "New2", amount => 2 ) }
"apply_cost with args as hash";

cmp_ok( $obj->cost_count, '==', 2,  "cost_count is 2" );
cmp_ok( $obj->total,      '==', 27, "total is 27" );

lives_ok { $cost = $obj->cost("New1") } "call cost New1";
cmp_ok( $cost, "==", 5, "amount is good" );

lives_ok { $cost = $obj->cost(1) } "call cost 1";
cmp_ok( $cost, "==", 2, "amount is good" );

throws_ok { $obj->cost } qr/position or name required/,
  "fail call cost with no args";

throws_ok { $obj->cost(2) } qr/Bad argument to cost/,
  "fail call cost with index that doesn't exist";

throws_ok { $obj->cost("") } qr/Bad argument to cost/,
  "fail call cost with empty name";

throws_ok { $obj->cost("BadName") } qr/Bad argument to cost/,
  "fail call cost with name that doesn't exist";

lives_ok { $obj->clear_costs } "clear_costs";

lives_ok { $obj->apply_cost( name => "Discount", amount => -5, compound => 1 ) }
"apply_cost Discount -5 compound";

cmp_ok( $obj->total, '==', 15, "total is 15" );

lives_ok { $obj->apply_cost( name => "Shipping", amount => 2, compound => 1 ) }
"apply_cost Shipping 2 compound";

cmp_ok( $obj->total, '==', 17, "total is 17" );

lives_ok {
    $obj->apply_cost(
        name      => "Tax",
        amount    => 0.20,
        relative  => 1,
      )
}
"apply_cost Tax 0.20 relative";

cmp_ok( $obj->total, '==', 20.40, "total is 20.40" );

done_testing;
