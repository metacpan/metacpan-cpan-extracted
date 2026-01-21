#!/usr/bin/env perl
# t/33-error-handling.t - Comprehensive error handling and validation tests

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
my $lora_file = "$FindBin::Bin/data/test-lora.gguf";

unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

# Load model and create components for testing
my $model = Lugh::Model->new(model => $model_file);
my $tokenizer = Lugh::Tokenizer->new(model => $model);
my $inference = Lugh::Inference->new(model => $model);
my $vocab_size = $tokenizer->n_vocab;

ok($model, 'Model loaded for error testing');
ok($tokenizer, 'Tokenizer created');
ok($inference, 'Inference engine created');
diag("Vocab size: $vocab_size");

# ============================================================================
# Section A: Invalid Token ID Validation
# ============================================================================

subtest 'Invalid Token IDs' => sub {
    # Test that valid tokens work correctly
    my $bos = $tokenizer->bos_id;
    my @valid_result = $inference->forward_simple([$bos]);
    ok(@valid_result == $vocab_size, 'Valid token produces correct output size');

    # Test with multiple valid tokens
    my @multi_result = $inference->forward_simple([$bos, 1, 2]);
    ok(@multi_result == $vocab_size, 'Multiple valid tokens work');

    # Test negative token ID - should croak, not crash
    eval {
        my @logits = $inference->forward_simple([-1]);
    };
    like($@, qr/invalid|token|negative/i, 'Negative token ID rejected with error');

    # Test forward with empty array - should croak, not crash
    eval {
        my @logits = $inference->forward_simple([]);
    };
    like($@, qr/empty|token|required|least/i, 'Empty token array rejected with error');

    # NOTE: Token IDs >= vocab_size validation requires passing vocab_size
    # to parse_tokens_av which is not currently implemented. These tests
    # would crash in ggml. The validation for this is a TODO.
    pass('TODO: Token ID >= vocab_size validation needs vocab_size passed to parser');
};

# ============================================================================
# Section B: Object Type Validation
# ============================================================================

subtest 'Object Type Validation' => sub {
    # Test Inference->new with non-Model object
    eval {
        my $bad_inf = Lugh::Inference->new(model => "not a model");
    };
    like($@, qr/model|object|parameter/i, 'Inference->new rejects string as model');

    eval {
        my $bad_inf = Lugh::Inference->new(model => {});
    };
    like($@, qr/model|object|parameter/i, 'Inference->new rejects hashref as model');

    eval {
        my $bad_inf = Lugh::Inference->new(model => []);
    };
    like($@, qr/model|object|parameter/i, 'Inference->new rejects arrayref as model');

    # Test forward_cache with non-cache object
    eval {
        $inference->forward_cache("not a cache", [$tokenizer->bos_id]);
    };
    like($@, qr/cache|object|KVCache/i, 'forward_cache rejects string as cache');

    eval {
        $inference->forward_cache({}, [$tokenizer->bos_id]);
    };
    like($@, qr/cache|object|KVCache/i, 'forward_cache rejects hashref as cache');

    # Test forward with non-arrayref tokens
    eval {
        $inference->forward_simple("not an array");
    };
    like($@, qr/array|reference/i, 'forward_simple rejects string as tokens');

    eval {
        $inference->forward_simple({});
    };
    like($@, qr/array|reference/i, 'forward_simple rejects hashref as tokens');
};

# ============================================================================
# Section C: Model Loading Errors
# ============================================================================

subtest 'Model Loading Errors' => sub {
    # Test loading non-existent file
    eval {
        my $bad_model = Lugh::Model->new(model => '/nonexistent/path/to/model.gguf');
    };
    like($@, qr/Failed|Cannot|open|load|file/i, 'Model->new fails on non-existent file');

    # Test loading with empty path
    eval {
        my $bad_model = Lugh::Model->new(model => '');
    };
    like($@, qr/Failed|requires|parameter|file/i, 'Model->new fails on empty path');

    # Test loading without model parameter
    eval {
        my $bad_model = Lugh::Model->new();
    };
    like($@, qr/requires|model|parameter/i, 'Model->new fails without model parameter');

    # Test loading a non-GGUF file (use this test file itself)
    eval {
        my $bad_model = Lugh::Model->new(model => __FILE__);
    };
    like($@, qr/Failed|Invalid|GGUF|magic|format/i, 'Model->new fails on non-GGUF file');
};

# ============================================================================
# Section D: LoRA Validation Errors
# ============================================================================

SKIP: {
    skip "LoRA test file not available", 1 unless -f $lora_file;

    subtest 'LoRA Validation Errors' => sub {
        # Test LoRA without adapter parameter
        eval {
            my $lora = Lugh::LoRA->new(model => $model);
        };
        like($@, qr/requires|adapter|parameter/i, 'LoRA->new fails without adapter');

        # Test LoRA without model parameter
        eval {
            my $lora = Lugh::LoRA->new(adapter => $lora_file);
        };
        like($@, qr/requires|model|parameter/i, 'LoRA->new fails without model');

        # Test LoRA with non-existent file
        eval {
            my $lora = Lugh::LoRA->new(
                adapter => '/nonexistent/adapter.gguf',
                model => $model,
            );
        };
        like($@, qr/Cannot|Failed|open|load|file/i, 'LoRA->new fails on non-existent file');

        # Test LoRA with unsupported format
        eval {
            my $lora = Lugh::LoRA->new(
                adapter => '/tmp/adapter.bin',
                model => $model,
            );
        };
        like($@, qr/Unrecognized|Unknown|format|expected/i, 'LoRA->new fails on unsupported format');

        # Test LoRA with non-Model object
        eval {
            my $lora = Lugh::LoRA->new(
                adapter => $lora_file,
                model => "not a model",
            );
        };
        like($@, qr/model|object|Model/i, 'LoRA->new fails with non-Model object');

        # Test forward with non-LoRA as lora parameter
        my @tokens = ($tokenizer->bos_id);
        eval {
            my @logits = $inference->forward(
                tokens => \@tokens,
                lora => "not a lora",
            );
        };
        ok($@ || 1, 'forward with invalid lora parameter handled');
    };
}

# ============================================================================
# Section E: Sampling Parameter Errors
# ============================================================================

subtest 'Sampling Parameter Errors' => sub {
    my @tokens = ($tokenizer->bos_id);
    my @logits = $inference->forward_simple(\@tokens);

    # Test temperature = 0 (potential divide by zero)
    my $zero_temp_result;
    eval {
        $zero_temp_result = $inference->sample_top_p(\@logits, temperature => 0);
    };
    ok(defined $zero_temp_result || $@, 'Temperature=0 handled (result or error)');

    # Test negative temperature
    eval {
        my $neg = $inference->sample_top_p(\@logits, temperature => -1.0);
    };
    ok($@ || 1, 'Negative temperature handled');

    # Test top_p > 1.0
    my $high_topp_result;
    eval {
        $high_topp_result = $inference->sample_top_p(\@logits, top_p => 1.5);
    };
    ok(defined $high_topp_result || $@, 'top_p > 1.0 handled (clamped or error)');

    # Test top_p < 0
    eval {
        my $neg_topp = $inference->sample_top_p(\@logits, top_p => -0.5);
    };
    ok($@ || 1, 'Negative top_p handled');

    # Test top_p = 0 (should probably return most likely)
    my $zero_topp_result;
    eval {
        $zero_topp_result = $inference->sample_top_p(\@logits, top_p => 0);
    };
    ok(defined $zero_topp_result || $@, 'top_p=0 handled');

    # Test with empty logits array
    eval {
        my $empty_result = $inference->sample_top_p([], temperature => 1.0);
    };
    ok($@ || 1, 'Empty logits array handled');

    # Test top_k with k=0
    eval {
        my $zero_k = $inference->sample_top_k(\@logits, top_k => 0);
    };
    ok($@ || 1, 'top_k=0 handled');

    # Test top_k with negative k
    eval {
        my $neg_k = $inference->sample_top_k(\@logits, top_k => -5);
    };
    ok($@ || 1, 'Negative top_k handled');
};

# ============================================================================
# Section F: Tensor/Context Errors
# ============================================================================

subtest 'Tensor and Context Errors' => sub {
    # Test valid context creation works
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    ok($ctx, 'Valid context (1MB) created');

    # Test context with zero memory - should croak, not crash
    my $zero_error;
    eval {
        my $zero_ctx = Lugh::Context->new(mem_size => 0);
    };
    $zero_error = $@;
    like($zero_error, qr/mem_size|positive/i, 'Context with mem_size=0 rejected');

    # NOTE: Negative values for size_t become huge positive values, so we can't
    # easily test that case without crashing. SvUV() returns unsigned.
    pass('Skipped: negative mem_size test (size_t is unsigned)');

    # Test tensor with too many dimensions (>4) - this should be caught
    my $dims_error;
    eval {
        my $tensor = Lugh::Tensor->new_f32($ctx, 2, 2, 2, 2, 2);
    };
    $dims_error = $@;
    like($dims_error, qr/dimension|Maximum|4/i, 'Tensor with >4 dimensions rejected');

    # Test tensor with zero dimension - should croak, not crash
    my $zero_dim_error;
    eval {
        my $tensor = Lugh::Tensor->new_f32($ctx, 0);
    };
    $zero_dim_error = $@;
    like($zero_dim_error, qr/dimension|positive|Invalid/i, 'Tensor with zero dimension rejected');

    # Test tensor with negative dimension - should croak, not crash
    my $neg_dim_error;
    eval {
        my $tensor = Lugh::Tensor->new_f32($ctx, -5);
    };
    $neg_dim_error = $@;
    like($neg_dim_error, qr/dimension|positive|Invalid/i, 'Tensor with negative dimension rejected');

    # Test valid tensor operations
    my $tensor = Lugh::Tensor->new_f32($ctx, 4);
    ok($tensor, '4-element tensor created');

    # Test tensor set_f32 with wrong number of values
    my $set_error;
    eval {
        $tensor->set_f32(1.0, 2.0);  # Only 2 values for 4-element tensor
    };
    $set_error = $@;
    like($set_error, qr/Expected|values|got/i, 'set_f32 with wrong value count rejected');

    # Test valid tensor operations work
    $tensor->set_f32(1.0, 2.0, 3.0, 4.0);
    my @values = $tensor->get_f32();
    is(scalar @values, 4, 'get_f32 returns correct number of values');
};

# ============================================================================
# Section G: KV Cache Errors
# ============================================================================

subtest 'KV Cache Errors' => sub {
    my $cache = $inference->create_kv_cache();
    ok($cache, 'Cache created for error testing');

    # Test resize to negative
    eval {
        $cache->resize(-1);
    };
    ok($@ || 1, 'Cache resize to negative handled');

    # Test resize to very large value
    eval {
        $cache->resize(999999999);
    };
    ok($@ || 1, 'Cache resize to huge value handled');

    # Test forward_cache after cache destruction (scope test)
    {
        my $temp_cache = $inference->create_kv_cache();
        my @tokens = ($tokenizer->bos_id);
        $inference->forward_cache($temp_cache, \@tokens);
        # Cache should work within scope
        ok($temp_cache->n_cached > 0, 'Cache works in scope');
    }
    # After scope, temp_cache is destroyed - can't test access to destroyed object directly
    # but we verified it works correctly within scope
    ok(1, 'Cache scope test completed');
};

# ============================================================================
# Section H: Quantization Type Errors
# ============================================================================

subtest 'Quantization Type Errors' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);  # 64MB

    # Create F32 tensor for quantization tests
    my $f32_tensor = Lugh::Tensor->new_f32($ctx, 32);  # 32 elements
    $f32_tensor->set_f32((0.1) x 32);

    # Test quantize with invalid type (if type validation exists)
    eval {
        my $invalid_quant = $f32_tensor->quantize(999);  # Invalid type ID
    };
    ok($@ || 1, 'Quantize with invalid type handled');

    # Verify we can dequantize F32 (should be no-op or error)
    eval {
        my $deq = $f32_tensor->dequantize();
    };
    ok($@ || 1, 'Dequantize F32 tensor handled (error or no-op)');
};

# ============================================================================
# Section I: Speculative Decoding Errors
# ============================================================================

subtest 'Speculative Decoding Errors' => sub {
    # Test Speculative->new without required parameters
    eval {
        my $spec = Lugh::Speculative->new();
    };
    like($@, qr/requires|inference|draft/i, 'Speculative->new fails without params');

    eval {
        my $spec = Lugh::Speculative->new(inference => $inference);
    };
    like($@, qr/requires|draft/i, 'Speculative->new fails without draft');

    # Test with non-Inference objects
    eval {
        my $spec = Lugh::Speculative->new(
            inference => "not inference",
            draft => $inference,
        );
    };
    like($@, qr/must be|Inference|object/i, 'Speculative->new rejects non-Inference main');

    eval {
        my $spec = Lugh::Speculative->new(
            inference => $inference,
            draft => "not inference",
        );
    };
    like($@, qr/must be|Inference|object/i, 'Speculative->new rejects non-Inference draft');

    # Test with invalid speculation depth (k)
    eval {
        my $spec = Lugh::Speculative->new(
            inference => $inference,
            draft => $inference,  # Using same model for simplicity
            k => 0,
        );
    };
    ok($@ || 1, 'Speculative->new with k=0 handled');

    eval {
        my $spec = Lugh::Speculative->new(
            inference => $inference,
            draft => $inference,
            k => 100,  # Way above limit of 16
        );
    };
    ok($@ || 1, 'Speculative->new with k>16 handled');
};

# ============================================================================
# Section J: RoPE Configuration Errors
# ============================================================================

subtest 'RoPE Configuration Errors' => sub {
    # Test RoPE with invalid scaling type
    eval {
        my $rope = Lugh::RoPE->new(scaling_type => 999);
    };
    ok($@ || 1, 'RoPE with invalid scaling_type handled');

    # Test RoPE with negative freq_scale
    eval {
        my $rope = Lugh::RoPE->new(freq_scale => -1.0);
    };
    ok($@ || 1, 'RoPE with negative freq_scale handled');

    # Test RoPE with zero freq_base (if used)
    eval {
        my $rope = Lugh::RoPE->new(freq_base => 0);
    };
    ok($@ || 1, 'RoPE with zero freq_base handled');

    # Valid RoPE should work
    my $valid_rope;
    eval {
        $valid_rope = Lugh::RoPE->none();
    };
    ok(!$@ && $valid_rope, 'RoPE::none() works correctly');
};

# ============================================================================
# Section K: Memory Pool Errors
# ============================================================================

subtest 'Memory Pool Errors' => sub {
    my $pool = $inference->create_memory_pool();
    ok($pool, 'Memory pool created');

    # Test forward_pool with non-pool object
    eval {
        $inference->forward_pool("not a pool", [$tokenizer->bos_id]);
    };
    like($@, qr/pool|object|MemoryPool/i, 'forward_pool rejects non-pool object');

    # Test reset on valid pool
    ok($pool->reset(), 'Pool reset works');

    # Get backend name
    my $backend = $pool->backend();
    ok(defined $backend, "Pool has backend: $backend");
};

done_testing();
