#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Test basic import and accessor creation
subtest 'import creates accessors' => sub {
    package TestPkg1;
    use Legba qw/foo bar/;
    
    package main;
    can_ok('TestPkg1', 'foo');
    can_ok('TestPkg1', 'bar');
};

# Test set and get
subtest 'set and get' => sub {
    package TestPkg2;
    use Legba qw/myslot/;
    
    my $result = myslot(42);
    Test::More::is($result, 42, 'setter returns value');
    
    my $got = myslot();
    Test::More::is($got, 42, 'getter returns stored value');
};

# Test different data types
subtest 'data types' => sub {
    package TestPkg3;
    use Legba qw/scalar_slot array_slot hash_slot code_slot/;
    
    # Scalar
    scalar_slot("hello");
    Test::More::is(scalar_slot(), "hello", 'string scalar');
    
    scalar_slot(3.14159);
    Test::More::is(scalar_slot(), 3.14159, 'float scalar');
    
    # Array ref
    array_slot([1, 2, 3]);
    Test::More::is_deeply(array_slot(), [1, 2, 3], 'array ref');
    
    # Hash ref
    hash_slot({ a => 1, b => 2 });
    Test::More::is_deeply(hash_slot(), { a => 1, b => 2 }, 'hash ref');
    
    # Code ref
    code_slot(sub { return 'invoked' });
    Test::More::is(ref(code_slot()), 'CODE', 'code ref stored');
    Test::More::is(code_slot()->(), 'invoked', 'code ref callable');
};

# Test global nature of slots
subtest 'slots are global' => sub {
    package PkgA;
    use Legba qw/shared_slot/;
    shared_slot('from A');
    
    package PkgB;
    use Legba qw/shared_slot/;
    
    package main;
    is(PkgA::shared_slot(), 'from A', 'PkgA sees value');
    is(PkgB::shared_slot(), 'from A', 'PkgB sees same value');
    
    PkgB::shared_slot('from B');
    is(PkgA::shared_slot(), 'from B', 'PkgA sees update from B');
};

# Test undef
subtest 'undef handling' => sub {
    package TestPkg4;
    use Legba qw/undef_slot/;
    
    undef_slot(undef);
    Test::More::ok(!defined undef_slot(), 'undef stored and retrieved');
    
    undef_slot("not undef");
    Test::More::is(undef_slot(), "not undef", 'can overwrite');
};

# Test internal utility functions
subtest 'utility functions' => sub {
    Legba::_set('util_test', 'value');
    is(Legba::_get('util_test'), 'value', '_get/_set work');
    
    ok(Legba::_exists('util_test'), '_exists returns true');
    ok(!Legba::_exists('nonexistent'), '_exists returns false for missing');
    
    Legba::_delete('util_test');
    ok(!defined Legba::_get('util_test') || Legba::_get('util_test') eq '', '_delete clears slot');
};

# Test _keys
subtest '_keys' => sub {
    Legba::_clear();
    Legba::_set('slot_a', 1);
    Legba::_set('slot_b', 2);
    Legba::_set('slot_c', 3);
    
    my @keys = sort(Legba::_keys());
    # Keys should include our new slots (might have others from earlier tests)
    ok(grep { $_ eq 'slot_a' } @keys, 'slot_a in keys');
    ok(grep { $_ eq 'slot_b' } @keys, 'slot_b in keys');
    ok(grep { $_ eq 'slot_c' } @keys, 'slot_c in keys');
};

done_testing();
