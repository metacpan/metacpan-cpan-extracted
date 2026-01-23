#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use FindBin;
use File::Spec;

use lib 'blib/lib', 'blib/arch';

use_ok('Lugh');

# Skip unless model available
my $model_path = File::Spec->catfile($FindBin::Bin, 'data', 'test-model.gguf');
unless (-f $model_path) {
    plan skip_all => "Test model not found at $model_path";
}

# Load base model
my $model = Lugh::Model->new(file => $model_path);
ok($model, 'Model loaded');

subtest 'create trainable LoRA' => sub {
    my $lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 8,
        alpha   => 16.0,
        targets => [qw(attn_q attn_v)],
    );
    
    ok($lora, 'Trainable LoRA created');
    ok($lora->trainable, 'LoRA is trainable');
    is($lora->alpha, 16.0, 'Alpha value correct');
    is($lora->scale, 1.0, 'Default scale is 1.0');
    is($lora->format, 'trainable', 'Format is trainable');
    cmp_ok($lora->n_weights, '>', 0, 'Has LoRA weights');
    
    my @names = $lora->weight_names;
    cmp_ok(scalar(@names), '>', 0, 'Has weight names');
    
    # Check that weight names follow expected pattern
    my $has_attn_q = grep { /attn_q/ } @names;
    my $has_attn_v = grep { /attn_v/ } @names;
    ok($has_attn_q, 'Has attn_q weights');
    ok($has_attn_v, 'Has attn_v weights');
};

subtest 'get weight tensors' => sub {
    my $lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 4,
        alpha   => 8.0,
        targets => [qw(attn_q)],
    );
    
    my @names = $lora->weight_names;
    my $first_name = $names[0];
    
    # Get A matrix
    my $tensor_a = $lora->get_weight_tensor($first_name, 'a');
    ok($tensor_a, 'Got tensor A');
    isa_ok($tensor_a, 'Lugh::Autograd::Tensor');
    ok($tensor_a->requires_grad, 'Tensor A requires_grad');
    
    # Get B matrix  
    my $tensor_b = $lora->get_weight_tensor($first_name, 'b');
    ok($tensor_b, 'Got tensor B');
    isa_ok($tensor_b, 'Lugh::Autograd::Tensor');
    ok($tensor_b->requires_grad, 'Tensor B requires_grad');
    
    # B should be initialized to zeros
    my @b_data = $tensor_b->get_data;
    my $all_zero = 1;
    for (@b_data) {
        if ($_ != 0) { $all_zero = 0; last; }
    }
    ok($all_zero, 'B matrix initialized to zeros (standard LoRA init)');
    
    # A should have non-zero values (Kaiming init)
    my @a_data = $tensor_a->get_data;
    my $has_nonzero = grep { $_ != 0 } @a_data;
    ok($has_nonzero, 'A matrix has non-zero values (Kaiming init)');
};

subtest 'LoRA with different targets' => sub {
    # Test with all attention targets
    my $lora_all_attn = Lugh::LoRA->create(
        model   => $model,
        rank    => 4,
        targets => [qw(attn_q attn_k attn_v attn_output)],
    );
    
    my @names = $lora_all_attn->weight_names;
    ok(scalar(@names) > 0, 'Created LoRA with all attention targets');
    
    # Test with FFN targets
    my $lora_ffn = Lugh::LoRA->create(
        model   => $model,
        rank    => 4,
        targets => [qw(ffn_up ffn_down)],
    );
    
    @names = $lora_ffn->weight_names;
    my $has_ffn = grep { /ffn/ } @names;
    ok($has_ffn, 'Created LoRA with FFN targets');
};

subtest 'LoRA rank validation' => sub {
    # Valid ranks
    for my $rank (1, 4, 8, 16, 32, 64, 128, 256) {
        my $lora = eval {
            Lugh::LoRA->create(
                model => $model,
                rank  => $rank,
            );
        };
        ok($lora, "LoRA with rank=$rank created successfully");
    }
    
    # Invalid rank (0)
    eval {
        Lugh::LoRA->create(
            model => $model,
            rank  => 0,
        );
    };
    like($@, qr/rank must be between 1 and 256/, 'Rejects rank=0');
    
    # Invalid rank (too large)
    eval {
        Lugh::LoRA->create(
            model => $model,
            rank  => 512,
        );
    };
    like($@, qr/rank must be between 1 and 256/, 'Rejects rank=512');
};

subtest 'save trainable LoRA' => sub {
    my $lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 8,
        alpha   => 16.0,
        targets => [qw(attn_q attn_v)],
    );
    
    my ($fh, $temp_path) = tempfile(SUFFIX => '.gguf', UNLINK => 1);
    close($fh);
    
    # Save to GGUF
    eval { $lora->save($temp_path); };
    is($@, '', 'Save completed without error');
    ok(-f $temp_path, 'GGUF file created');
    ok(-s $temp_path > 0, 'GGUF file has content');
    
    # Verify it's a valid GGUF file
    open(my $verify_fh, '<', $temp_path) or die "Cannot open: $!";
    my $magic;
    read($verify_fh, $magic, 4);
    close($verify_fh);
    is($magic, 'GGUF', 'File has GGUF magic number');
};

subtest 'save path validation' => sub {
    my $lora = Lugh::LoRA->create(
        model => $model,
        rank  => 4,
    );
    
    # Must end with .gguf
    eval { $lora->save('/tmp/test.safetensors'); };
    like($@, qr/must end with \.gguf/, 'Rejects non-GGUF path');
    
    eval { $lora->save('/tmp/test'); };
    like($@, qr/must end with \.gguf/, 'Rejects path without extension');
};

subtest 'gradient access' => sub {
    my $lora = Lugh::LoRA->create(
        model => $model,
        rank  => 4,
    );
    
    my @names = $lora->weight_names;
    my $first = $names[0];
    
    my $tensor = $lora->get_weight_tensor($first, 'a');
    ok($tensor->requires_grad, 'Tensor requires_grad is set');
    
    my $grad = $tensor->grad;
    ok(defined $grad, 'Can access gradient');
    
    # Gradient should be zeros initially
    my @grad_data = @$grad;
    my $sum = 0;
    $sum += abs($_) for @grad_data;
    is($sum, 0, 'Gradient initialized to zeros');
};

subtest 'loaded LoRA is not trainable' => sub {
    # Find an existing LoRA adapter if available
    my $adapter_path = File::Spec->catfile($FindBin::Bin, 'data', 'test-lora.gguf');
    
    SKIP: {
        skip "Test LoRA adapter not found", 3 unless -f $adapter_path;
        
        my $loaded_lora = Lugh::LoRA->new(
            adapter => $adapter_path,
            model   => $model,
        );
        
        ok($loaded_lora, 'Loaded LoRA adapter');
        ok(!$loaded_lora->trainable, 'Loaded LoRA is NOT trainable');
        
        eval { $loaded_lora->get_weight_tensor('blk.0.attn_q.weight', 'a'); };
        like($@, qr/only available on trainable/, 'get_weight_tensor fails on loaded LoRA');
    }
};

subtest 'scale adjustment' => sub {
    my $lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 4,
        scale   => 0.5,
    );
    
    is($lora->scale, 0.5, 'Initial scale set correctly');
    
    $lora->scale(2.0);
    is($lora->scale, 2.0, 'Scale updated');
    
    $lora->scale(0.0);
    is($lora->scale, 0.0, 'Scale can be set to 0 (disable)');
};

done_testing();
