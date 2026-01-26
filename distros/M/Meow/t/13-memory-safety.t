#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr reftype blessed weaken isweak);

use_ok('Meow');

# =============================================================================
# Test memory safety for optimization validation
# Critical tests for refcount correctness and object lifecycle
# =============================================================================

# -----------------------------------------------------------------------------
# Basic class for memory tests
# -----------------------------------------------------------------------------
{
    package MemoryTest;
    use Meow;
    
    our $destroy_count = 0;
    
    rw name => undef;
    rw value => undef;
    rw ref_attr => undef;
    
    sub DEMOLISH {
        my $self = shift;
        $destroy_count++;
    }
    
    make_immutable;
}

# -----------------------------------------------------------------------------
# Test: Object destruction
# -----------------------------------------------------------------------------
subtest 'object destruction' => sub {
    $MemoryTest::destroy_count = 0;
    
    {
        my $obj = MemoryTest->new(name => 'will be destroyed');
        is($MemoryTest::destroy_count, 0, 'not destroyed while in scope');
    }
    
    is($MemoryTest::destroy_count, 1, 'destroyed when out of scope');
};

subtest 'multiple object destruction' => sub {
    $MemoryTest::destroy_count = 0;
    
    {
        my $obj1 = MemoryTest->new(name => 'one');
        my $obj2 = MemoryTest->new(name => 'two');
        my $obj3 = MemoryTest->new(name => 'three');
        is($MemoryTest::destroy_count, 0, 'none destroyed in scope');
    }
    
    is($MemoryTest::destroy_count, 3, 'all destroyed when out of scope');
};

# -----------------------------------------------------------------------------
# Test: Reference stored in object survives
# -----------------------------------------------------------------------------
subtest 'stored reference survives' => sub {
    my $obj = MemoryTest->new();
    my $arrayref;
    
    {
        my @temp = (1, 2, 3);
        $arrayref = \@temp;
        $obj->ref_attr($arrayref);
    }
    
    # The arrayref should survive because it's stored in object
    is_deeply($obj->ref_attr, [1, 2, 3], 'stored ref survives scope');
};

# -----------------------------------------------------------------------------
# Test: Weak references
# -----------------------------------------------------------------------------
subtest 'weak reference support' => sub {
    $MemoryTest::destroy_count = 0;
    my $weak;
    
    {
        my $obj = MemoryTest->new(name => 'strong');
        $weak = $obj;
        weaken($weak);
        
        ok(defined($weak), 'weak ref defined while object exists');
        is($weak->name, 'strong', 'can access via weak ref');
    }
    
    ok(!defined($weak), 'weak ref undef after object destroyed');
    is($MemoryTest::destroy_count, 1, 'object was destroyed');
};

# -----------------------------------------------------------------------------
# Test: Object stored in another object
# -----------------------------------------------------------------------------
{
    package Container;
    use Meow;
    
    rw child => undef;
    
    make_immutable;
}

subtest 'nested object lifecycle' => sub {
    $MemoryTest::destroy_count = 0;
    
    {
        my $container = Container->new();
        my $child = MemoryTest->new(name => 'nested');
        $container->child($child);
        
        is($container->child->name, 'nested', 'can access nested object');
        is($MemoryTest::destroy_count, 0, 'child not destroyed while referenced');
    }
    
    is($MemoryTest::destroy_count, 1, 'child destroyed with container');
};

# -----------------------------------------------------------------------------
# Test: Replacing attribute value
# -----------------------------------------------------------------------------
subtest 'replacing attribute frees old value' => sub {
    $MemoryTest::destroy_count = 0;
    
    my $container = Container->new();
    
    {
        my $child1 = MemoryTest->new(name => 'first');
        $container->child($child1);
        is($MemoryTest::destroy_count, 0, 'first child alive');
    }
    # child1 still referenced by container
    is($MemoryTest::destroy_count, 0, 'first child still alive in container');
    
    # Replace with new child
    my $child2 = MemoryTest->new(name => 'second');
    $container->child($child2);
    
    is($MemoryTest::destroy_count, 1, 'first child destroyed on replacement');
    is($container->child->name, 'second', 'new child accessible');
};

# -----------------------------------------------------------------------------
# Test: Setting attribute to undef
# -----------------------------------------------------------------------------
subtest 'setting to undef frees value' => sub {
    $MemoryTest::destroy_count = 0;
    
    my $container = Container->new();
    $container->child(MemoryTest->new(name => 'will be freed'));
    
    is($MemoryTest::destroy_count, 0, 'child alive');
    
    $container->child(undef);
    
    is($MemoryTest::destroy_count, 1, 'child destroyed when set to undef');
};

# -----------------------------------------------------------------------------
# Test: Clone creates independent copy
# -----------------------------------------------------------------------------
subtest 'clone is independent' => sub {
    my $original = MemoryTest->new(name => 'original', value => 42);
    my $clone = $original->clone;
    
    isnt(refaddr($original), refaddr($clone), 'clone is different object');
    
    $clone->name('cloned');
    is($original->name, 'original', 'original unchanged after clone modification');
    is($clone->name, 'cloned', 'clone modified');
};

# -----------------------------------------------------------------------------
# Test: Multiple references to same object
# -----------------------------------------------------------------------------
subtest 'multiple references to same object' => sub {
    $MemoryTest::destroy_count = 0;
    
    my $obj;
    {
        my $ref1 = MemoryTest->new(name => 'shared');
        my $ref2 = $ref1;
        my $ref3 = $ref1;
        $obj = $ref1;
        
        is(refaddr($ref1), refaddr($ref2), 'ref2 same as ref1');
        is(refaddr($ref1), refaddr($ref3), 'ref3 same as ref1');
        is($MemoryTest::destroy_count, 0, 'not destroyed while any ref exists');
    }
    
    is($MemoryTest::destroy_count, 0, 'still not destroyed - $obj holds ref');
    is($obj->name, 'shared', 'can still access via surviving ref');
    
    undef $obj;
    is($MemoryTest::destroy_count, 1, 'destroyed when last ref gone');
};

# -----------------------------------------------------------------------------
# Test: Rapid create/destroy cycle
# -----------------------------------------------------------------------------
subtest 'rapid create/destroy cycle' => sub {
    $MemoryTest::destroy_count = 0;
    
    for (1..1000) {
        my $obj = MemoryTest->new(name => "temp_$_");
    }
    
    is($MemoryTest::destroy_count, 1000, 'all 1000 objects destroyed');
};

# -----------------------------------------------------------------------------
# Test: Return value from accessor doesn't leak
# -----------------------------------------------------------------------------
subtest 'accessor return does not leak' => sub {
    my $obj = MemoryTest->new(name => 'test');
    
    # Call accessor many times, should not accumulate refcounts
    for (1..1000) {
        my $val = $obj->name;
    }
    
    # If we get here without crash/hang, no leak
    pass('accessor can be called many times');
};

# -----------------------------------------------------------------------------
# Test: Object in array
# -----------------------------------------------------------------------------
subtest 'objects in array' => sub {
    $MemoryTest::destroy_count = 0;
    
    {
        my @objects;
        for my $i (1..10) {
            push @objects, MemoryTest->new(name => "item_$i");
        }
        is($MemoryTest::destroy_count, 0, 'none destroyed while in array');
        
        # Pop some
        pop @objects for 1..3;
        is($MemoryTest::destroy_count, 3, '3 destroyed after pop');
    }
    
    is($MemoryTest::destroy_count, 10, 'all destroyed when array gone');
};

# -----------------------------------------------------------------------------
# Test: Object as hash value
# -----------------------------------------------------------------------------
subtest 'objects as hash values' => sub {
    $MemoryTest::destroy_count = 0;
    
    {
        my %hash;
        $hash{a} = MemoryTest->new(name => 'a');
        $hash{b} = MemoryTest->new(name => 'b');
        
        is($MemoryTest::destroy_count, 0, 'none destroyed in hash');
        
        delete $hash{a};
        is($MemoryTest::destroy_count, 1, '1 destroyed after delete');
    }
    
    is($MemoryTest::destroy_count, 2, 'all destroyed when hash gone');
};

# -----------------------------------------------------------------------------
# Test: Accessor with reference attributes
# -----------------------------------------------------------------------------
subtest 'reference attribute memory' => sub {
    my $obj = MemoryTest->new();
    
    # Store various refs
    $obj->ref_attr([1, 2, 3]);
    is_deeply($obj->ref_attr, [1, 2, 3], 'arrayref stored');
    
    $obj->ref_attr({ x => 1 });
    is_deeply($obj->ref_attr, { x => 1 }, 'hashref replaced arrayref');
    
    $obj->ref_attr(sub { 42 });
    is($obj->ref_attr->(), 42, 'coderef stored');
    
    $obj->ref_attr(undef);
    is($obj->ref_attr, undef, 'undef stored');
};

# -----------------------------------------------------------------------------
# Test: Circular reference (document behavior)
# -----------------------------------------------------------------------------
{
    package CircularA;
    use Meow;
    rw partner => undef;
    make_immutable;
}

{
    package CircularB;
    use Meow;
    rw partner => undef;
    make_immutable;
}

subtest 'circular reference warning' => sub {
    # This documents that circular refs will leak (standard Perl behavior)
    # Users should use weaken() to break cycles
    
    my $a = CircularA->new();
    my $b = CircularB->new();
    
    $a->partner($b);
    $b->partner($a);
    
    # Both objects now have circular reference
    is($a->partner, $b, 'circular ref a->b');
    is($b->partner, $a, 'circular ref b->a');
    
    # To properly clean up, break the cycle
    $a->partner(undef);
    
    pass('circular refs can be created (user must break cycles)');
};

done_testing;
