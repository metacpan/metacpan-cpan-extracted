#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype blessed);

use_ok('Meow');

# =============================================================================
# Test constructor variants for optimization safety
# These tests ensure fast-path optimizations don't break edge cases
# =============================================================================

# -----------------------------------------------------------------------------
# Basic class with multiple attribute types
# -----------------------------------------------------------------------------
{
    package ConstructorTest;
    use Meow;
    
    rw name => undef;
    rw value => undef;
    rw count => Default(0);
    rw enabled => Default(1);
    
    make_immutable;
}

# -----------------------------------------------------------------------------
# Test: No-argument constructor (fast-path candidate)
# -----------------------------------------------------------------------------
subtest 'no-argument constructor' => sub {
    my $obj = ConstructorTest->new();
    
    isa_ok($obj, 'ConstructorTest');
    is(reftype($obj), 'ARRAY', 'uses slots storage');
    is($obj->name, undef, 'unset attr is undef');
    is($obj->value, undef, 'unset attr is undef');
    is($obj->count, 0, 'default value applied');
    is($obj->enabled, 1, 'default value applied');
};

# -----------------------------------------------------------------------------
# Test: Single argument pair
# -----------------------------------------------------------------------------
subtest 'single argument pair' => sub {
    my $obj = ConstructorTest->new(name => 'test');
    
    is($obj->name, 'test', 'single arg set');
    is($obj->value, undef, 'other attr still undef');
    is($obj->count, 0, 'default preserved');
};

# -----------------------------------------------------------------------------
# Test: All arguments provided
# -----------------------------------------------------------------------------
subtest 'all arguments provided' => sub {
    my $obj = ConstructorTest->new(
        name => 'full',
        value => 42,
        count => 100,
        enabled => 0,
    );
    
    is($obj->name, 'full', 'name set');
    is($obj->value, 42, 'value set');
    is($obj->count, 100, 'count overrides default');
    is($obj->enabled, 0, 'enabled overrides default');
};

# -----------------------------------------------------------------------------
# Test: Hashref argument style
# -----------------------------------------------------------------------------
subtest 'hashref argument style' => sub {
    my $obj = ConstructorTest->new({ name => 'hashref', value => 99 });
    
    is($obj->name, 'hashref', 'name from hashref');
    is($obj->value, 99, 'value from hashref');
    is($obj->count, 0, 'default applied');
};

# -----------------------------------------------------------------------------
# Test: Mixed order of arguments
# -----------------------------------------------------------------------------
subtest 'argument order independence' => sub {
    my $obj1 = ConstructorTest->new(name => 'a', value => 1);
    my $obj2 = ConstructorTest->new(value => 1, name => 'a');
    
    is($obj1->name, $obj2->name, 'name same regardless of order');
    is($obj1->value, $obj2->value, 'value same regardless of order');
};

# -----------------------------------------------------------------------------
# Test: Constructor with undef values
# -----------------------------------------------------------------------------
subtest 'explicit undef values' => sub {
    my $obj = ConstructorTest->new(name => undef);
    
    is($obj->name, undef, 'explicit undef stored for attr without default');
    # Note: Meow uses defaults even when explicit undef is passed
    # This documents current behavior
};

# -----------------------------------------------------------------------------
# Test: Constructor with reference values
# -----------------------------------------------------------------------------
subtest 'reference values in constructor' => sub {
    my $array = [1, 2, 3];
    my $hash = { a => 1 };
    my $code = sub { return 42 };
    
    my $obj = ConstructorTest->new(
        name => $array,
        value => $hash,
        count => $code,
    );
    
    is_deeply($obj->name, [1, 2, 3], 'arrayref stored');
    is_deeply($obj->value, { a => 1 }, 'hashref stored');
    is($obj->count->(), 42, 'coderef stored and callable');
};

# -----------------------------------------------------------------------------
# Test: Multiple object construction
# -----------------------------------------------------------------------------
subtest 'multiple objects are independent' => sub {
    my $obj1 = ConstructorTest->new(name => 'first', count => 1);
    my $obj2 = ConstructorTest->new(name => 'second', count => 2);
    my $obj3 = ConstructorTest->new(name => 'third', count => 3);
    
    is($obj1->name, 'first', 'obj1 name');
    is($obj2->name, 'second', 'obj2 name');
    is($obj3->name, 'third', 'obj3 name');
    
    is($obj1->count, 1, 'obj1 count');
    is($obj2->count, 2, 'obj2 count');
    is($obj3->count, 3, 'obj3 count');
    
    # Modify one, others unchanged
    $obj1->name('modified');
    is($obj1->name, 'modified', 'obj1 modified');
    is($obj2->name, 'second', 'obj2 unchanged');
    is($obj3->name, 'third', 'obj3 unchanged');
};

# -----------------------------------------------------------------------------
# Test: Class with many attributes
# -----------------------------------------------------------------------------
{
    package ManyAttrs;
    use Meow;
    
    rw attr_1 => undef;
    rw attr_2 => undef;
    rw attr_3 => undef;
    rw attr_4 => undef;
    rw attr_5 => undef;
    rw attr_6 => undef;
    rw attr_7 => undef;
    rw attr_8 => undef;
    rw attr_9 => undef;
    rw attr_10 => undef;
    
    make_immutable;
}

subtest 'many attributes constructor' => sub {
    my %args;
    $args{"attr_$_"} = $_ for 1..10;
    my $obj = ManyAttrs->new(%args);
    
    for my $i (1..10) {
        my $method = "attr_$i";
        is($obj->$method, $i, "attr_$i set correctly");
    }
};

# -----------------------------------------------------------------------------
# Test: Empty string vs undef distinction
# -----------------------------------------------------------------------------
subtest 'empty string vs undef' => sub {
    my $obj1 = ConstructorTest->new(name => '');
    my $obj2 = ConstructorTest->new(name => undef);
    my $obj3 = ConstructorTest->new();
    
    is($obj1->name, '', 'empty string stored');
    ok(defined($obj1->name), 'empty string is defined');
    
    is($obj2->name, undef, 'explicit undef stored');
    ok(!defined($obj2->name), 'explicit undef is not defined');
    
    is($obj3->name, undef, 'implicit undef');
    ok(!defined($obj3->name), 'implicit undef is not defined');
};

# -----------------------------------------------------------------------------
# Test: Numeric zero in various forms
# -----------------------------------------------------------------------------
subtest 'numeric zero values' => sub {
    my $obj = ConstructorTest->new(
        name => 0,
        value => 0.0,
        count => '0',
    );
    
    is($obj->name, 0, 'integer zero');
    ok(defined($obj->name), 'integer zero is defined');
    
    is($obj->value, 0.0, 'float zero');
    ok(defined($obj->value), 'float zero is defined');
    
    is($obj->count, '0', 'string zero');
    ok(defined($obj->count), 'string zero is defined');
};

# -----------------------------------------------------------------------------
# Test: Subclass constructor
# -----------------------------------------------------------------------------
{
    package ConstructorChild;
    use Meow;
    extends 'ConstructorTest';
    
    rw extra => Default('child');
    
    make_immutable;
}

subtest 'subclass constructor' => sub {
    my $obj = ConstructorChild->new(name => 'parent', extra => 'override');
    
    isa_ok($obj, 'ConstructorChild');
    isa_ok($obj, 'ConstructorTest');
    is($obj->name, 'parent', 'parent attr via child constructor');
    is($obj->extra, 'override', 'child attr set');
    is($obj->count, 0, 'parent default applied');
};

# -----------------------------------------------------------------------------
# Test: Constructor called on object (clone-like behavior)
# -----------------------------------------------------------------------------
subtest 'constructor via object reference' => sub {
    my $obj1 = ConstructorTest->new(name => 'original');
    
    # Call new on the class name derived from object
    my $class = ref($obj1);
    my $obj2 = $class->new(name => 'new');
    
    is($obj1->name, 'original', 'original unchanged');
    is($obj2->name, 'new', 'new object created');
    isnt($obj1, $obj2, 'different objects');
};

# -----------------------------------------------------------------------------
# Test: Attribute with and without defaults
# -----------------------------------------------------------------------------
{
    package AttrDefaults;
    use Meow;
    
    rw required_attr => undef;  # No default - should be undef if not provided
    rw optional_attr => Default('has_default');
    
    make_immutable;
}

subtest 'attributes with and without defaults' => sub {
    # Attr without default is undef if not provided
    my $obj = AttrDefaults->new();
    is($obj->required_attr, undef, 'attr without default is undef');
    is($obj->optional_attr, 'has_default', 'attr with default has value');
    
    # Can provide value for attr without default
    my $obj2 = AttrDefaults->new(required_attr => 'provided');
    is($obj2->required_attr, 'provided', 'attr without default can be set');
};

# -----------------------------------------------------------------------------
# Test: Type-constrained constructor
# -----------------------------------------------------------------------------
{
    package TypedConstructor;
    use Meow;
    use Basic::Types::XS qw/Str Int/;
    
    rw name => Default(Str, 'default_name');
    rw count => Default(Int, 0);
    
    make_immutable;
}

subtest 'typed constructor valid' => sub {
    my $obj = TypedConstructor->new(name => 'valid', count => 42);
    is($obj->name, 'valid', 'string type accepted');
    is($obj->count, 42, 'int type accepted');
};

subtest 'typed constructor invalid' => sub {
    eval { TypedConstructor->new(name => 'ok', count => 'not_an_int') };
    like($@, qr/type|constraint|Int/i, 'invalid type throws');
};

done_testing;
