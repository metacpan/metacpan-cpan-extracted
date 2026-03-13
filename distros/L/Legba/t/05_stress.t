#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Test many slots
subtest 'many slots' => sub {
    package StressPkg1;
    
    my @slot_names = map { "stress_slot_$_" } 1..100;
    Legba->import(@slot_names);
    
    package main;
    
    # Set all slots
    for my $i (1..100) {
        my $setter = "StressPkg1::stress_slot_$i";
        no strict 'refs';
        &$setter($i * 10);
    }
    
    # Verify all slots
    for my $i (1..100) {
        my $getter = "StressPkg1::stress_slot_$i";
        no strict 'refs';
        is(&$getter(), $i * 10, "slot $i has correct value");
    }
};

# Test rapid get/set cycles
subtest 'rapid cycles' => sub {
    package StressPkg2;
    use Legba qw/cycle_slot/;
    
    package main;
    
    for my $round (1..100) {
        for my $val (1..100) {
            StressPkg2::cycle_slot($val);
            my $got = StressPkg2::cycle_slot();
            is($got, $val, "round $round val $val") or last;
        }
    }
    pass('completed 10000 get/set cycles');
};

# Test mixed operations
subtest 'mixed operations' => sub {
    Legba::_clear();
    
    # Interleave _set, accessor set, _get, accessor get
    for my $i (1..50) {
        my $slot_name = "mixed_$i";
        
        # Create accessor
        package MixedPkg;
        Legba->import($slot_name);
        
        package main;
        
        # Set via _set
        Legba::_set($slot_name, "value_$i");
        
        # Get via _get
        is(Legba::_get($slot_name), "value_$i", "_get mixed_$i");
        
        # Set via accessor
        no strict 'refs';
        &{"MixedPkg::$slot_name"}("accessor_$i");
        
        # Get via accessor
        is(&{"MixedPkg::$slot_name"}(), "accessor_$i", "accessor mixed_$i");
    }
};

# Test slot isolation
subtest 'slot isolation' => sub {
    package IsoPkg1;
    use Legba qw/iso_a iso_b iso_c/;
    
    package main;
    
    IsoPkg1::iso_a(1);
    IsoPkg1::iso_b(2);
    IsoPkg1::iso_c(3);
    
    # Modify one slot many times
    for (1..100) {
        IsoPkg1::iso_a($_);
    }
    
    # Other slots unaffected
    is(IsoPkg1::iso_b(), 2, 'iso_b unchanged');
    is(IsoPkg1::iso_c(), 3, 'iso_c unchanged');
    is(IsoPkg1::iso_a(), 100, 'iso_a has final value');
};

# Test concurrent-like access pattern
subtest 'interleaved access' => sub {
    package Interleave;
    use Legba qw/slot1 slot2 slot3/;
    
    package main;
    
    my @results;
    for my $i (1..100) {
        Interleave::slot1($i);
        Interleave::slot2($i * 2);
        Interleave::slot3($i * 3);
        
        push @results, [
            Interleave::slot1(),
            Interleave::slot2(),
            Interleave::slot3()
        ];
    }
    
    for my $i (0..99) {
        my $expected_i = $i + 1;
        is_deeply($results[$i], [$expected_i, $expected_i*2, $expected_i*3], 
                  "interleave step $expected_i");
    }
};

done_testing();
