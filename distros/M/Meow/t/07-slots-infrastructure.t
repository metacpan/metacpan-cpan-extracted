#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test slot index registry

use_ok('Meow');

# Test 1: Default mode (slots) registers slot indices
{
    package TestSlots;
    use Meow;
    use Basic::Types::XS qw/Str Num/;
    
    ro name => Str;
    ro value => Num;
    
    make_immutable;
    1;
}

# Check slot indices were registered
my $slot_indices = \%Meow::_SLOT_INDICES;
ok(exists $slot_indices->{TestSlots}, 'TestSlots has slot indices registered');
is($slot_indices->{TestSlots}{name}, 0, 'name is slot 0');
is($slot_indices->{TestSlots}{value}, 1, 'value is slot 1');

my $slot_counts = \%Meow::_SLOT_COUNTS;
is($slot_counts->{TestSlots}, 2, 'TestSlots has 2 slots');

# Test 2: -hash mode does NOT register slot indices
{
    package TestHash;
    use Meow -hash;
    use Basic::Types::XS qw/Str/;
    
    ro label => Str;
    
    make_immutable;
    1;
}

my $hash_mode = \%Meow::_HASH_MODE;
ok($hash_mode->{TestHash}, 'TestHash is in hash mode');
ok(!exists $slot_indices->{TestHash} || !exists $slot_indices->{TestHash}{label}, 
   'TestHash does not have slot indices');

# Test 3: Objects still work in both modes (for now, using hash storage)
my $slots_obj = TestSlots->new(name => 'test', value => 42);
is($slots_obj->name, 'test', 'slots mode object accessor works');
is($slots_obj->value, 42, 'slots mode object accessor works');

my $hash_obj = TestHash->new(label => 'hello');
is($hash_obj->label, 'hello', 'hash mode object accessor works');

# Test 4: Slot indices stored in attribute spec
SKIP: {
    my $spec = Meow::_get_spec_from_cv('TestSlots');
    skip "Spec retrieval not available", 2 unless $spec && ref($spec) eq 'HASH';
    is($spec->{name}{slot_index}, 0, 'name has slot_index 0 in spec');
    is($spec->{value}{slot_index}, 1, 'value has slot_index 1 in spec');
}

done_testing();
