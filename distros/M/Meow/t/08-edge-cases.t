#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype blessed);

use_ok('Meow');

# =============================================================================
# Phase 6.1: BUILDARGS - Transform constructor arguments
# =============================================================================

{
    package TestBuildargs;
    use Meow;
    
    ro name => undef;
    ro value => undef;
    
    sub BUILDARGS {
        my ($class, @args) = @_;
        # Transform positional args to named args
        if (@args == 2 && !ref $args[0]) {
            return { name => $args[0], value => $args[1] };
        }
        # Default: return hashref from named args
        return { @args };
    }
    
    make_immutable;
}

subtest 'BUILDARGS transforms positional to named' => sub {
    my $obj = TestBuildargs->new('foo', 42);
    is($obj->name, 'foo', 'BUILDARGS: name from positional');
    is($obj->value, 42, 'BUILDARGS: value from positional');
    is(reftype($obj), 'ARRAY', 'BUILDARGS: still uses slots');
};

subtest 'BUILDARGS passthrough for hash args' => sub {
    my $obj = TestBuildargs->new(name => 'bar', value => 99);
    is($obj->name, 'bar', 'BUILDARGS: name from hash');
    is($obj->value, 99, 'BUILDARGS: value from hash');
};

# =============================================================================
# Phase 6.2: BUILD - Called after construction with $self
# =============================================================================

{
    package TestBuild;
    use Meow;
    use Scalar::Util qw(reftype);
    
    ro name => undef;
    rw initialized => undef;
    
    our $build_called = 0;
    our $build_self_type;
    
    sub BUILD {
        my ($self, $args) = @_;
        $build_called++;
        $build_self_type = reftype($self);
        $self->initialized(1);
    }
    
    make_immutable;
}

subtest 'BUILD is called after construction' => sub {
    $TestBuild::build_called = 0;
    my $obj = TestBuild->new(name => 'test');
    is($TestBuild::build_called, 1, 'BUILD: called once');
    is($TestBuild::build_self_type, 'ARRAY', 'BUILD: $self is arrayref');
    is($obj->initialized, 1, 'BUILD: can modify object');
    is($obj->name, 'test', 'BUILD: original attrs preserved');
};

# =============================================================================
# Phase 6.3: DEMOLISH - Called on destruction
# =============================================================================

{
    package TestDemolish;
    use Meow;
    use Scalar::Util qw(reftype);
    
    ro name => undef;
    
    our $demolish_called = 0;
    our $demolish_self_type;
    
    sub DEMOLISH {
        my ($self) = @_;
        $demolish_called++;
        $demolish_self_type = reftype($self);
    }
    
    make_immutable;
}

subtest 'DEMOLISH is called on destruction' => sub {
    $TestDemolish::demolish_called = 0;
    {
        my $obj = TestDemolish->new(name => 'temp');
        is($obj->name, 'temp', 'DEMOLISH: object created');
    }
    is($TestDemolish::demolish_called, 1, 'DEMOLISH: called once');
    is($TestDemolish::demolish_self_type, 'ARRAY', 'DEMOLISH: $self is arrayref');
};

# =============================================================================
# Phase 6.4: Attribute introspection
# =============================================================================

{
    package TestIntrospection;
    use Meow;
    use Basic::Types::XS qw/Str Num/;
    
    ro name => Str;
    rw age => Num;
    rw status => undef;
    
    make_immutable;
}

subtest 'Attribute introspection' => sub {
    # Check slot indices are accessible
    my $slot_indices = $Meow::_SLOT_INDICES{TestIntrospection};
    ok($slot_indices, 'Introspection: slot indices available');
    is(scalar keys %$slot_indices, 3, 'Introspection: 3 attributes registered');
    ok(exists $slot_indices->{name}, 'Introspection: name slot exists');
    ok(exists $slot_indices->{age}, 'Introspection: age slot exists');
    ok(exists $slot_indices->{status}, 'Introspection: status slot exists');
};

# =============================================================================
# Phase 6.5: Object cloning
# =============================================================================

{
    package TestClone;
    use Meow;
    
    ro name => undef;
    rw value => undef;
    
    make_immutable;
}

subtest 'Object cloning' => sub {
    my $orig = TestClone->new(name => 'original', value => 100);
    
    # Test clone method if it exists
    SKIP: {
        skip 'clone method not implemented', 4 unless TestClone->can('clone');
        
        my $copy = $orig->clone;
        isnt($copy, $orig, 'Clone: different object reference');
        is($copy->name, 'original', 'Clone: name copied');
        is($copy->value, 100, 'Clone: value copied');
        
        $copy->value(200);
        is($orig->value, 100, 'Clone: modifying copy does not affect original');
    }
};

# =============================================================================
# Phase 7.1: _dump debugging method
# =============================================================================

{
    package TestDump;
    use Meow;
    
    ro name => undef;
    rw value => undef;
    
    make_immutable;
}

subtest '_dump debugging method' => sub {
    my $obj = TestDump->new(name => 'test', value => 42);
    
    SKIP: {
        skip '_dump method not implemented', 2 unless TestDump->can('_dump');
        
        my $dump = $obj->_dump;
        ok($dump, '_dump: returns something');
        like($dump, qr/name.*test|test.*name/, '_dump: contains attribute data');
    }
};

# =============================================================================
# Phase 7.2: Stringification overload (optional)
# =============================================================================

subtest 'Stringification' => sub {
    my $obj = TestDump->new(name => 'test', value => 42);
    my $str = "$obj";
    ok($str, 'Stringification: object can be stringified');
    # Default should show class and address
    like($str, qr/TestDump/, 'Stringification: shows class name');
};

# =============================================================================
# Additional edge case tests
# =============================================================================

subtest 'Slots mode with hash mode together' => sub {
    {
        package SlotClass;
        use Meow;
        ro x => undef;
        make_immutable;
    }
    {
        package HashClass;
        use Meow -hash;
        ro y => undef;
        make_immutable;
    }
    
    my $slot_obj = SlotClass->new(x => 1);
    my $hash_obj = HashClass->new(y => 2);
    
    is(reftype($slot_obj), 'ARRAY', 'Mixed: slot class is ARRAY');
    is(reftype($hash_obj), 'HASH', 'Mixed: hash class is HASH');
    is($slot_obj->x, 1, 'Mixed: slot accessor works');
    is($hash_obj->y, 2, 'Mixed: hash accessor works');
};

done_testing;
