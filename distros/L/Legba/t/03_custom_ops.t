#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Test custom op creation
subtest 'make_get_op' => sub {
    my $op_ptr = Legba::_make_get_op('op_test_get');
    ok($op_ptr > 0, '_make_get_op returns non-zero pointer');
    
    # Set a value first
    Legba::_set('op_test_get', 'hello');
    
    # Different slot gets different op
    my $op_ptr2 = Legba::_make_get_op('op_test_get2');
    ok($op_ptr2 != $op_ptr, 'different slots get different ops');
};

subtest 'make_set_op' => sub {
    my $op_ptr = Legba::_make_set_op('op_test_set');
    ok($op_ptr > 0, '_make_set_op returns non-zero pointer');
    
    # Different from getter
    my $get_op = Legba::_make_get_op('op_test_set');
    ok($op_ptr != $get_op, 'setter op different from getter op');
};

# Test slot pointer
subtest 'slot_ptr' => sub {
    my $ptr = Legba::_slot_ptr('ptr_test');
    ok($ptr > 0, '_slot_ptr returns non-zero pointer');
    
    # Same slot returns same pointer
    my $ptr2 = Legba::_slot_ptr('ptr_test');
    is($ptr2, $ptr, 'same slot returns same pointer');
    
    # Different slot returns different pointer
    my $ptr3 = Legba::_slot_ptr('ptr_test_other');
    ok($ptr3 != $ptr, 'different slot returns different pointer');
};

# Test ops share underlying slot
subtest 'ops share slot' => sub {
    package OpPkg1;
    use Legba qw/op_shared/;
    
    package main;
    
    # Create ops
    my $get_op = Legba::_make_get_op('op_shared');
    my $set_op = Legba::_make_set_op('op_shared');
    
    # Set via accessor
    OpPkg1::op_shared('via accessor');
    
    # Value should be visible to all paths
    is(Legba::_get('op_shared'), 'via accessor', 'op slot visible via _get');
    
    # Set via _set
    Legba::_set('op_shared', 'via _set');
    is(OpPkg1::op_shared(), 'via _set', 'accessor sees _set value');
};

# Test registry access
subtest 'registry' => sub {
    my $reg = Legba::_registry();
    ok(defined $reg, '_registry returns defined value');
};

# Test multiple ops for same slot
subtest 'multiple ops same slot' => sub {
    my @ops;
    for (1..10) {
        push @ops, Legba::_make_get_op('multi_op_slot');
    }
    
    # All ops should work (same underlying slot)
    Legba::_set('multi_op_slot', 'multi');
    
    # Each op points to same slot
    my $ptr = Legba::_slot_ptr('multi_op_slot');
    ok($ptr > 0, 'slot pointer valid after multiple ops');
};

done_testing();
