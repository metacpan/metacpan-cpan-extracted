#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr reftype blessed);

use_ok('Meow');

# =============================================================================
# Test accessor edge cases for optimization safety
# These tests ensure that optimizations (like SvREFCNT_inc vs newSVsv,
# AvARRAY direct access) don't break accessor behavior
# =============================================================================

# -----------------------------------------------------------------------------
# Basic accessor class for testing
# -----------------------------------------------------------------------------
{
    package AccessorTest;
    use Meow;
    
    rw name => undef;
    rw value => undef;
    rw count => Default(0);
    
    make_immutable;
}

# -----------------------------------------------------------------------------
# Test: Return value integrity (critical for refcount optimization)
# -----------------------------------------------------------------------------
subtest 'return value integrity' => sub {
    my $obj = AccessorTest->new(name => 'test', value => 42);
    
    # Get the same value multiple times - should be equal
    my $v1 = $obj->name;
    my $v2 = $obj->name;
    is($v1, $v2, 'consecutive reads return same value');
    
    # Modify returned value - should NOT affect stored value
    my $val = $obj->name;
    $val = 'modified';
    is($obj->name, 'test', 'modifying returned scalar does not affect object');
};

subtest 'reference value integrity' => sub {
    my $arrayref = [1, 2, 3];
    my $hashref = { a => 1, b => 2 };
    
    my $obj = AccessorTest->new(name => $arrayref, value => $hashref);
    
    # Get reference values
    my $got_array = $obj->name;
    my $got_hash = $obj->value;
    
    is_deeply($got_array, [1, 2, 3], 'arrayref retrieved correctly');
    is_deeply($got_hash, { a => 1, b => 2 }, 'hashref retrieved correctly');
    
    # References should be the same object (not copies)
    is(refaddr($got_array), refaddr($obj->name), 'arrayref is same reference');
    is(refaddr($got_hash), refaddr($obj->value), 'hashref is same reference');
    
    # Modifying original should affect stored value (shared reference)
    push @$arrayref, 4;
    is_deeply($obj->name, [1, 2, 3, 4], 'original ref modification visible');
};

# -----------------------------------------------------------------------------
# Test: Undef handling
# -----------------------------------------------------------------------------
subtest 'undef handling' => sub {
    my $obj = AccessorTest->new();
    
    # Uninitialized attributes should return undef
    is($obj->name, undef, 'uninitialized attr returns undef');
    ok(!defined($obj->name), 'uninitialized attr is not defined');
    
    # Set to undef explicitly
    $obj->name('something');
    is($obj->name, 'something', 'set to value works');
    $obj->name(undef);
    is($obj->name, undef, 'set to undef works');
    ok(!defined($obj->name), 'undef is not defined');
    
    # Set to empty string (different from undef)
    $obj->name('');
    is($obj->name, '', 'empty string is stored');
    ok(defined($obj->name), 'empty string is defined');
};

# -----------------------------------------------------------------------------
# Test: Numeric edge cases
# -----------------------------------------------------------------------------
subtest 'numeric edge cases' => sub {
    my $obj = AccessorTest->new();
    
    # Zero
    $obj->value(0);
    is($obj->value, 0, 'zero stored correctly');
    ok(defined($obj->value), 'zero is defined');
    
    # Negative
    $obj->value(-42);
    is($obj->value, -42, 'negative stored correctly');
    
    # Float
    $obj->value(3.14159);
    is($obj->value, 3.14159, 'float stored correctly');
    
    # Large number
    $obj->value(9999999999);
    is($obj->value, 9999999999, 'large number stored correctly');
    
    # Scientific notation
    $obj->value(1e10);
    is($obj->value, 1e10, 'scientific notation stored correctly');
};

# -----------------------------------------------------------------------------
# Test: String edge cases
# -----------------------------------------------------------------------------
subtest 'string edge cases' => sub {
    my $obj = AccessorTest->new();
    
    # String "0" (false but defined)
    $obj->name("0");
    is($obj->name, "0", 'string zero stored correctly');
    ok(defined($obj->name), 'string zero is defined');
    
    # Unicode
    $obj->name("café");
    is($obj->name, "café", 'unicode stored correctly');
    
    # Long string
    my $long = 'x' x 10000;
    $obj->name($long);
    is(length($obj->name), 10000, 'long string stored correctly');
    
    # String with null bytes
    $obj->name("hello\0world");
    is($obj->name, "hello\0world", 'string with null byte stored correctly');
    is(length($obj->name), 11, 'string with null byte has correct length');
};

# -----------------------------------------------------------------------------
# Test: Multiple attributes interaction
# -----------------------------------------------------------------------------
subtest 'multiple attributes independence' => sub {
    my $obj = AccessorTest->new(name => 'a', value => 'b', count => 10);
    
    is($obj->name, 'a', 'attr 1 correct');
    is($obj->value, 'b', 'attr 2 correct');
    is($obj->count, 10, 'attr 3 correct');
    
    # Modify one, others unchanged
    $obj->name('changed');
    is($obj->name, 'changed', 'attr 1 changed');
    is($obj->value, 'b', 'attr 2 unchanged');
    is($obj->count, 10, 'attr 3 unchanged');
};

# -----------------------------------------------------------------------------
# Test: Rapid read/write cycles
# -----------------------------------------------------------------------------
subtest 'rapid read/write cycles' => sub {
    my $obj = AccessorTest->new(count => 0);
    
    for my $i (1..1000) {
        $obj->count($i);
        is($obj->count, $i, "iteration $i") if $i <= 5 || $i >= 996;
    }
    is($obj->count, 1000, 'final value correct after 1000 iterations');
};

# -----------------------------------------------------------------------------
# Test: Read-only accessor behavior
# -----------------------------------------------------------------------------
{
    package ROAccessorTest;
    use Meow;
    
    ro name => undef;
    ro value => Default(99);
    
    make_immutable;
}

subtest 'read-only accessors' => sub {
    my $obj = ROAccessorTest->new(name => 'readonly');
    
    is($obj->name, 'readonly', 'ro attr reads correctly');
    is($obj->value, 99, 'ro attr with default reads correctly');
    
    # Attempt to write should fail
    eval { $obj->name('newvalue') };
    like($@, qr/read.?only|cannot|modify/i, 'writing to ro attr throws');
    is($obj->name, 'readonly', 'ro attr unchanged after failed write');
};

# -----------------------------------------------------------------------------
# Test: Default value preservation
# -----------------------------------------------------------------------------
subtest 'default value preservation' => sub {
    my $obj1 = AccessorTest->new();
    my $obj2 = AccessorTest->new();
    
    is($obj1->count, 0, 'default value for obj1');
    is($obj2->count, 0, 'default value for obj2');
    
    # Modify one, other's default unchanged
    $obj1->count(100);
    is($obj1->count, 100, 'obj1 modified');
    is($obj2->count, 0, 'obj2 default unchanged');
};

# -----------------------------------------------------------------------------
# Test: Chained accessor calls
# -----------------------------------------------------------------------------
subtest 'accessor in expressions' => sub {
    my $obj = AccessorTest->new(value => 10);
    
    # Use in arithmetic
    my $result = $obj->value * 2 + $obj->value;
    is($result, 30, 'accessor in arithmetic expression');
    
    # Use in string operations
    $obj->name('hello');
    my $str = $obj->name . ' ' . $obj->name;
    is($str, 'hello hello', 'accessor in string expression');
};

done_testing;
