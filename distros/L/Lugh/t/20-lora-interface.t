#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;

# Test the Lugh::LoRA module interface

BEGIN {
    use_ok('Lugh') or BAIL_OUT("Cannot load Lugh");
    use_ok('Lugh::LoRA') or BAIL_OUT("Cannot load Lugh::LoRA");
}

# Test that the module can be loaded
ok(1, 'Lugh::LoRA module loads correctly');

# Test that the XS methods exist
can_ok('Lugh::LoRA', qw(new alpha scale n_weights format weight_names));

# Test new() without required parameters
eval {
    my $lora = Lugh::LoRA->new();
};
like($@, qr/requires|parameter/i, 'Croaks when parameters missing');

# Test new() without model parameter
eval {
    my $lora = Lugh::LoRA->new(adapter => '/tmp/adapter.gguf');
};
like($@, qr/model.*parameter|requires.*model/i, 'Croaks when model parameter missing');

# Find the test files
my $model_path = File::Spec->catfile('t', 'data', 'test-model.gguf');
my $gguf_lora_path = File::Spec->catfile('t', 'data', 'test-lora.gguf');
my $st_lora_path = File::Spec->catfile('t', 'data', 'test-lora.safetensors');
my $model;

SKIP: {
    skip "Test model not available", 20 unless -f $model_path;
    
    # Load the test model
    eval { $model = Lugh::Model->new(file => $model_path); };
    skip "Cannot load test model: $@", 20 if $@;
    
    ok($model, 'Test model loaded');
    is($model->architecture, 'llama', 'Model architecture is llama');
    
    # Test new() with missing adapter file
    eval {
        my $lora = Lugh::LoRA->new(
            adapter => '/nonexistent/adapter.gguf',
            model => $model,
        );
    };
    like($@, qr/Cannot open|Failed|file|init/i, 'Croaks on missing GGUF file');
    
    eval {
        my $lora = Lugh::LoRA->new(
            adapter => '/nonexistent/adapter.safetensors',
            model => $model,
        );
    };
    like($@, qr/Cannot open|Failed|file/i, 'Croaks on missing SafeTensors file');
    
    # Test new() with unsupported format
    eval {
        my $lora = Lugh::LoRA->new(
            adapter => '/tmp/adapter.bin',
            model => $model,
        );
    };
    like($@, qr/Unrecognized|Unknown|format/i, 'Croaks on unsupported file format');

    # ============================================
    # Test GGUF LoRA loading
    # ============================================
    SKIP: {
        skip "GGUF LoRA test file not available", 7 unless -f $gguf_lora_path;
        
        my $lora;
        eval { $lora = Lugh::LoRA->new(adapter => $gguf_lora_path, model => $model); };
        ok(!$@, 'GGUF LoRA loads without error') or diag($@);
        
        SKIP: {
            skip "GGUF LoRA failed to load", 6 unless $lora;
            
            is($lora->format, 'gguf', 'Format is gguf');
            cmp_ok($lora->alpha, '==', 16, 'Alpha is 16');
            cmp_ok($lora->scale, '==', 1, 'Default scale is 1');
            cmp_ok($lora->n_weights, '==', 4, 'Has 4 weight pairs');
            
            my @names = $lora->weight_names;
            is(scalar @names, 4, 'weight_names returns 4 names');
            ok(grep(/blk\.0\.attn_q\.weight/, @names), 'Contains blk.0.attn_q.weight');
        }
    }
    
    # ============================================
    # Test SafeTensors LoRA loading
    # ============================================
    SKIP: {
        skip "SafeTensors LoRA test file not available", 7 unless -f $st_lora_path;
        
        my $lora;
        eval { $lora = Lugh::LoRA->new(adapter => $st_lora_path, model => $model); };
        ok(!$@, 'SafeTensors LoRA loads without error') or diag($@);
        
        SKIP: {
            skip "SafeTensors LoRA failed to load", 6 unless $lora;
            
            is($lora->format, 'safetensors', 'Format is safetensors');
            cmp_ok($lora->alpha, '>=', 0, 'Alpha is set');
            cmp_ok($lora->scale, '==', 1, 'Default scale is 1');
            cmp_ok($lora->n_weights, '==', 4, 'Has 4 weight pairs');
            
            my @names = $lora->weight_names;
            is(scalar @names, 4, 'weight_names returns 4 names');
            ok(grep(/blk\.0\.attn_q\.weight/, @names), 'Contains blk.0.attn_q.weight');
        }
    }
    
    # ============================================
    # Test scale setter
    # ============================================
    SKIP: {
        skip "GGUF LoRA test file not available", 3 unless -f $gguf_lora_path;
        
        my $lora = Lugh::LoRA->new(adapter => $gguf_lora_path, model => $model);
        cmp_ok($lora->scale, '==', 1, 'Initial scale is 1');
        
        $lora->scale(0.5);
        cmp_ok($lora->scale, '==', 0.5, 'Scale updated to 0.5');
        
        $lora->scale(2.0);
        cmp_ok($lora->scale, '==', 2.0, 'Scale updated to 2.0');
    }
}

# Test the module's version
like($Lugh::LoRA::VERSION, qr/^\d+\.\d+/, 'Module has version');

done_testing();
