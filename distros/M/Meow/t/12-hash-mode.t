#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(reftype blessed);

use_ok('Meow');

# =============================================================================
# Test -hash mode for full feature parity with slots mode
# Ensures optimizations to slots don't break hash mode
# =============================================================================

# -----------------------------------------------------------------------------
# Basic hash mode class
# -----------------------------------------------------------------------------
{
    package HashBasic;
    use Meow -hash;
    
    rw name => undef;
    rw value => Default(42);
    
    make_immutable;
}

subtest 'hash mode basic' => sub {
    my $obj = HashBasic->new(name => 'test');
    
    isa_ok($obj, 'HashBasic');
    is(reftype($obj), 'HASH', 'uses hash storage');
    is($obj->name, 'test', 'name set');
    is($obj->value, 42, 'default applied');
};

subtest 'hash mode internal structure' => sub {
    my $obj = HashBasic->new(name => 'peek');
    
    # Can access hash keys directly
    is($obj->{name}, 'peek', 'direct hash access works');
    is($obj->{value}, 42, 'default visible in hash');
    
    # Keys exist
    ok(exists $obj->{name}, 'name key exists');
    ok(exists $obj->{value}, 'value key exists');
};

subtest 'hash mode modification' => sub {
    my $obj = HashBasic->new(name => 'initial');
    
    $obj->name('modified');
    is($obj->name, 'modified', 'accessor modification works');
    is($obj->{name}, 'modified', 'visible in hash');
};

# -----------------------------------------------------------------------------
# Hash mode with all features
# -----------------------------------------------------------------------------
{
    package HashFull;
    use Meow -hash;
    use Basic::Types::XS qw/Str Int/;
    
    rw name => Default(Str, undef);  # Typed attr with undef default
    rw count => Default(Int, 0);
    rw triggered => undef;
    
    our $trigger_called = 0;
    rw with_trigger => Trigger(sub { $trigger_called++ });
    
    make_immutable;
}

subtest 'hash mode with types' => sub {
    my $obj = HashFull->new(name => 'typed');
    
    is($obj->name, 'typed', 'typed attr works');
    is($obj->count, 0, 'typed default works');
    
    # Type validation on set
    eval { $obj->count('not_int') };
    like($@, qr/type|constraint|Int/i, 'type constraint enforced');
};

subtest 'hash mode trigger' => sub {
    $HashFull::trigger_called = 0;
    my $obj = HashFull->new(name => 'test', with_trigger => 'init');
    is($HashFull::trigger_called, 1, 'trigger called on construct');
    
    $obj->with_trigger('changed');
    is($HashFull::trigger_called, 2, 'trigger called on set');
};

# -----------------------------------------------------------------------------
# Hash mode with read-only
# -----------------------------------------------------------------------------
{
    package HashRO;
    use Meow -hash;
    
    ro name => undef;
    ro value => Default(99);
    
    make_immutable;
}

subtest 'hash mode read-only' => sub {
    my $obj = HashRO->new(name => 'readonly');
    
    is($obj->name, 'readonly', 'ro attr reads');
    is($obj->value, 99, 'ro default works');
    
    eval { $obj->name('new') };
    like($@, qr/read.?only|cannot|modify/i, 'ro enforced in hash mode');
};

# -----------------------------------------------------------------------------
# Hash mode with coerce
# -----------------------------------------------------------------------------
{
    package HashCoerce;
    use Meow -hash;
    
    rw trimmed => Coerce(sub { my $v = shift; $v =~ s/^\s+|\s+$//g; $v });
    
    make_immutable;
}

subtest 'hash mode coerce' => sub {
    my $obj = HashCoerce->new(trimmed => '  spaces  ');
    is($obj->trimmed, 'spaces', 'coerce applied on construct');
    
    $obj->trimmed('  more  ');
    is($obj->trimmed, 'more', 'coerce applied on set');
};

# -----------------------------------------------------------------------------
# Hash mode with builder
# -----------------------------------------------------------------------------
{
    package HashBuilder;
    use Meow -hash;
    
    our $built = 0;
    rw computed => Builder(sub { $built++; return 'computed' });
    rw provided => undef;
    
    make_immutable;
}

subtest 'hash mode builder' => sub {
    $HashBuilder::built = 0;
    my $obj = HashBuilder->new();
    
    is($obj->computed, 'computed', 'builder provides value');
    is($HashBuilder::built, 1, 'builder called once');
    
    # Builder not called if value provided
    $HashBuilder::built = 0;
    my $obj2 = HashBuilder->new(computed => 'manual');
    is($obj2->computed, 'manual', 'provided value used');
    is($HashBuilder::built, 0, 'builder not called when value provided');
};

# -----------------------------------------------------------------------------
# Hash mode inheritance
# -----------------------------------------------------------------------------
{
    package HashParent;
    use Meow -hash;
    
    rw parent_attr => Default('parent');
    
    make_immutable;
}

{
    package HashChild;
    use Meow -hash;
    extends 'HashParent';
    
    rw child_attr => Default('child');
    
    make_immutable;
}

subtest 'hash mode inheritance' => sub {
    my $obj = HashChild->new();
    
    isa_ok($obj, 'HashChild');
    isa_ok($obj, 'HashParent');
    is(reftype($obj), 'HASH', 'still hash storage');
    
    is($obj->parent_attr, 'parent', 'inherited attr works');
    is($obj->child_attr, 'child', 'child attr works');
    
    # Both visible in hash
    is($obj->{parent_attr}, 'parent', 'parent in hash');
    is($obj->{child_attr}, 'child', 'child in hash');
};

# -----------------------------------------------------------------------------
# Hash mode with clone
# -----------------------------------------------------------------------------
subtest 'hash mode clone' => sub {
    my $obj = HashBasic->new(name => 'original', value => 100);
    my $clone = $obj->clone;
    
    isa_ok($clone, 'HashBasic');
    is(reftype($clone), 'HASH', 'clone is hash');
    
    is($clone->name, 'original', 'clone has same name');
    is($clone->value, 100, 'clone has same value');
    
    # Independent
    $clone->name('cloned');
    is($obj->name, 'original', 'original unchanged');
    is($clone->name, 'cloned', 'clone modified');
};

# -----------------------------------------------------------------------------
# Hash mode with _dump
# -----------------------------------------------------------------------------
subtest 'hash mode _dump' => sub {
    my $obj = HashBasic->new(name => 'debug', value => 123);
    my $dump = $obj->_dump;
    
    like($dump, qr/name/, 'dump contains name');
    like($dump, qr/debug/, 'dump contains name value');
    like($dump, qr/value/, 'dump contains value');
    like($dump, qr/123/, 'dump contains value value');
};

# -----------------------------------------------------------------------------
# Hash mode is registered correctly
# -----------------------------------------------------------------------------
subtest 'hash mode registration' => sub {
    my $hash_mode = \%Meow::_HASH_MODE;
    
    ok($hash_mode->{HashBasic}, 'HashBasic registered as hash mode');
    ok($hash_mode->{HashFull}, 'HashFull registered as hash mode');
    ok($hash_mode->{HashParent}, 'HashParent registered as hash mode');
    ok($hash_mode->{HashChild}, 'HashChild registered as hash mode');
    
    # Slots mode packages should not be in hash mode
    ok(!$hash_mode->{AccessorTest}, 'slots class not in hash mode') 
        if exists $hash_mode->{AccessorTest};
};

# -----------------------------------------------------------------------------
# Compare slots vs hash behavior
# -----------------------------------------------------------------------------
{
    package CompareSlots;
    use Meow;  # Default is slots
    rw name => Default('slots');
    make_immutable;
}

{
    package CompareHash;
    use Meow -hash;
    rw name => Default('hash');
    make_immutable;
}

subtest 'slots vs hash comparison' => sub {
    my $slots = CompareSlots->new();
    my $hash = CompareHash->new();
    
    is(reftype($slots), 'ARRAY', 'slots is array');
    is(reftype($hash), 'HASH', 'hash is hash');
    
    # Both have same API
    can_ok($slots, 'name');
    can_ok($hash, 'name');
    
    is($slots->name, 'slots', 'slots default');
    is($hash->name, 'hash', 'hash default');
    
    # Both can be modified
    $slots->name('modified');
    $hash->name('modified');
    is($slots->name, 'modified', 'slots modified');
    is($hash->name, 'modified', 'hash modified');
};

done_testing;
