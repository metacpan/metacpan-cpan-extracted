#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Fresh start
Legba::_clear();

# Test _set and _get
subtest '_set and _get' => sub {
    Legba::_set('util_slot1', 'value1');
    is(Legba::_get('util_slot1'), 'value1', 'basic set/get');
    
    Legba::_set('util_slot1', 'value2');
    is(Legba::_get('util_slot1'), 'value2', 'overwrite with _set');
    
    # Set with complex value
    Legba::_set('util_complex', { a => [1,2,3] });
    is_deeply(Legba::_get('util_complex'), { a => [1,2,3] }, 'complex value');
};

# Test _get on nonexistent
subtest '_get nonexistent' => sub {
    my $val = Legba::_get('nonexistent_slot_xyz');
    ok(!defined $val || $val eq '', '_get returns undef/empty for nonexistent');
};

# Test _exists
subtest '_exists' => sub {
    Legba::_set('exists_test', 'yes');
    ok(Legba::_exists('exists_test'), '_exists returns true');
    ok(!Legba::_exists('does_not_exist_xyz'), '_exists returns false');
    
    # Even after setting to undef, slot exists
    Legba::_set('exists_undef', undef);
    ok(Legba::_exists('exists_undef'), 'slot exists even with undef value');
};

# Test _delete
subtest '_delete' => sub {
    Legba::_set('delete_test', 'will be deleted');
    is(Legba::_get('delete_test'), 'will be deleted', 'value before delete');
    
    Legba::_delete('delete_test');
    my $after = Legba::_get('delete_test');
    ok(!defined $after || $after eq '', 'value undefined after delete');
    
    # Slot still exists in index but value is undef
    ok(Legba::_exists('delete_test'), 'slot still exists after _delete');
};

# Test _keys
subtest '_keys' => sub {
    # Create fresh slots with unique names
    Legba::_set('keys_test_a', 1);
    Legba::_set('keys_test_b', 2);
    Legba::_set('keys_test_c', 3);
    
    my @keys = Legba::_keys();
    my %key_set = map { $_ => 1 } @keys;
    
    ok($key_set{'keys_test_a'}, '_keys contains keys_test_a');
    ok($key_set{'keys_test_b'}, '_keys contains keys_test_b');
    ok($key_set{'keys_test_c'}, '_keys contains keys_test_c');
};

# Test _clear
subtest '_clear' => sub {
    Legba::_set('clear_a', 'a');
    Legba::_set('clear_b', 'b');
    
    is(Legba::_get('clear_a'), 'a', 'before clear');
    
    Legba::_clear();
    
    my $a = Legba::_get('clear_a');
    my $b = Legba::_get('clear_b');
    ok(!defined $a || $a eq '', '_clear clears values');
    ok(!defined $b || $b eq '', '_clear clears all');
    
    # Keys still exist
    ok(Legba::_exists('clear_a'), 'key exists after _clear');
};

# Test _registry
subtest '_registry' => sub {
    my $reg = Legba::_registry();
    ok(defined $reg, '_registry returns defined');
    
    # Should be same each time
    my $reg2 = Legba::_registry();
    ok(defined $reg2, 'second call returns defined');
};

# Test _slot_ptr
subtest '_slot_ptr' => sub {
    Legba::_set('ptr_slot', 'test');
    
    my $ptr = Legba::_slot_ptr('ptr_slot');
    ok($ptr > 0, '_slot_ptr returns positive');
    
    # Same slot, same pointer
    my $ptr2 = Legba::_slot_ptr('ptr_slot');
    is($ptr2, $ptr, 'same slot returns same pointer');
    
    # Even after value change
    Legba::_set('ptr_slot', 'changed');
    my $ptr3 = Legba::_slot_ptr('ptr_slot');
    is($ptr3, $ptr, 'pointer stable after value change');
};

# Test _make_get_op / _make_set_op
subtest 'make ops' => sub {
    my $get_op = Legba::_make_get_op('op_slot');
    my $set_op = Legba::_make_set_op('op_slot');
    
    ok($get_op > 0, '_make_get_op returns positive');
    ok($set_op > 0, '_make_set_op returns positive');
    ok($get_op != $set_op, 'get and set ops are different');
    
    # Creating op also creates slot
    ok(Legba::_exists('op_slot'), 'creating op creates slot');
};

# Test chained operations
subtest 'chained operations' => sub {
    Legba::_clear();
    
    # Chain of operations
    Legba::_set('chain', 0);
    for (1..10) {
        my $v = Legba::_get('chain');
        Legba::_set('chain', ($v || 0) + 1);
    }
    is(Legba::_get('chain'), 10, 'chained inc works');
    
    Legba::_delete('chain');
    Legba::_set('chain', 'reset');
    is(Legba::_get('chain'), 'reset', 'reset after delete works');
};

done_testing();
