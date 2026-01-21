#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Test Lugh::Quant - Quantization utilities

BEGIN { use_ok('Lugh') }
BEGIN { use_ok('Lugh::Quant') }

# =============================================================================
# Type Constants
# =============================================================================

subtest 'Type constants are defined' => sub {
    # Float types
    ok(defined Lugh::Quant::F32, 'F32 defined');
    ok(defined Lugh::Quant::F16, 'F16 defined');
    ok(defined Lugh::Quant::BF16, 'BF16 defined');
    ok(defined Lugh::Quant::F64, 'F64 defined');
    
    # Integer types
    ok(defined Lugh::Quant::I8, 'I8 defined');
    ok(defined Lugh::Quant::I16, 'I16 defined');
    ok(defined Lugh::Quant::I32, 'I32 defined');
    ok(defined Lugh::Quant::I64, 'I64 defined');
    
    # Basic quant types
    ok(defined Lugh::Quant::Q4_0, 'Q4_0 defined');
    ok(defined Lugh::Quant::Q4_1, 'Q4_1 defined');
    ok(defined Lugh::Quant::Q5_0, 'Q5_0 defined');
    ok(defined Lugh::Quant::Q5_1, 'Q5_1 defined');
    ok(defined Lugh::Quant::Q8_0, 'Q8_0 defined');
    ok(defined Lugh::Quant::Q8_1, 'Q8_1 defined');
    
    # K-quant types
    ok(defined Lugh::Quant::Q2_K, 'Q2_K defined');
    ok(defined Lugh::Quant::Q3_K, 'Q3_K defined');
    ok(defined Lugh::Quant::Q4_K, 'Q4_K defined');
    ok(defined Lugh::Quant::Q5_K, 'Q5_K defined');
    ok(defined Lugh::Quant::Q6_K, 'Q6_K defined');
    ok(defined Lugh::Quant::Q8_K, 'Q8_K defined');
    
    # IQ types
    ok(defined Lugh::Quant::IQ1_S, 'IQ1_S defined');
    ok(defined Lugh::Quant::IQ1_M, 'IQ1_M defined');
    ok(defined Lugh::Quant::IQ2_XXS, 'IQ2_XXS defined');
    ok(defined Lugh::Quant::IQ2_XS, 'IQ2_XS defined');
    ok(defined Lugh::Quant::IQ2_S, 'IQ2_S defined');
    ok(defined Lugh::Quant::IQ3_XXS, 'IQ3_XXS defined');
    ok(defined Lugh::Quant::IQ3_S, 'IQ3_S defined');
    ok(defined Lugh::Quant::IQ4_NL, 'IQ4_NL defined');
    ok(defined Lugh::Quant::IQ4_XS, 'IQ4_XS defined');
    
    # Ternary types
    ok(defined Lugh::Quant::TQ1_0, 'TQ1_0 defined');
    ok(defined Lugh::Quant::TQ2_0, 'TQ2_0 defined');
    
    # Microscaling
    ok(defined Lugh::Quant::MXFP4, 'MXFP4 defined');
    
    # Type count
    ok(defined Lugh::Quant::TYPE_COUNT, 'TYPE_COUNT defined');
    cmp_ok(Lugh::Quant::TYPE_COUNT, '>=', 30, 'TYPE_COUNT is reasonable');
};

# =============================================================================
# Type Information Functions
# =============================================================================

subtest 'type_name' => sub {
    is(Lugh::Quant::type_name(Lugh::Quant::F32), 'f32', 'F32 name');
    is(Lugh::Quant::type_name(Lugh::Quant::F16), 'f16', 'F16 name');
    is(Lugh::Quant::type_name(Lugh::Quant::Q4_0), 'q4_0', 'Q4_0 name');
    is(Lugh::Quant::type_name(Lugh::Quant::Q4_K), 'q4_K', 'Q4_K name');
    is(Lugh::Quant::type_name(Lugh::Quant::Q8_0), 'q8_0', 'Q8_0 name');
    is(Lugh::Quant::type_name(Lugh::Quant::IQ2_XS), 'iq2_xs', 'IQ2_XS name');
    is(Lugh::Quant::type_name(-1), 'unknown', 'invalid type returns unknown');
    is(Lugh::Quant::type_name(9999), 'unknown', 'out of range returns unknown');
};

subtest 'type_size' => sub {
    is(Lugh::Quant::type_size(Lugh::Quant::F32), 4, 'F32 is 4 bytes');
    is(Lugh::Quant::type_size(Lugh::Quant::F16), 2, 'F16 is 2 bytes');
    is(Lugh::Quant::type_size(Lugh::Quant::I32), 4, 'I32 is 4 bytes');
    
    # Quantized types have block sizes
    cmp_ok(Lugh::Quant::type_size(Lugh::Quant::Q4_0), '>', 0, 'Q4_0 has size');
    cmp_ok(Lugh::Quant::type_size(Lugh::Quant::Q4_K), '>', 0, 'Q4_K has size');
};

subtest 'blck_size' => sub {
    is(Lugh::Quant::blck_size(Lugh::Quant::F32), 1, 'F32 block size is 1');
    is(Lugh::Quant::blck_size(Lugh::Quant::F16), 1, 'F16 block size is 1');
    
    # Quantized types have larger block sizes
    cmp_ok(Lugh::Quant::blck_size(Lugh::Quant::Q4_0), '>=', 32, 'Q4_0 block size');
    cmp_ok(Lugh::Quant::blck_size(Lugh::Quant::Q4_K), '>=', 32, 'Q4_K block size');
};

subtest 'type_sizef' => sub {
    is(Lugh::Quant::type_sizef(Lugh::Quant::F32), 4.0, 'F32 sizef is 4.0');
    is(Lugh::Quant::type_sizef(Lugh::Quant::F16), 2.0, 'F16 sizef is 2.0');
    
    # Q4 should be around 0.5 bytes per element (4 bits)
    my $q4_sizef = Lugh::Quant::type_sizef(Lugh::Quant::Q4_0);
    cmp_ok($q4_sizef, '>', 0.4, 'Q4_0 sizef > 0.4');
    cmp_ok($q4_sizef, '<', 1.0, 'Q4_0 sizef < 1.0');
};

subtest 'is_quantized' => sub {
    ok(!Lugh::Quant::is_quantized(Lugh::Quant::F32), 'F32 is not quantized');
    ok(!Lugh::Quant::is_quantized(Lugh::Quant::F16), 'F16 is not quantized');
    ok(!Lugh::Quant::is_quantized(Lugh::Quant::I32), 'I32 is not quantized');
    
    ok(Lugh::Quant::is_quantized(Lugh::Quant::Q4_0), 'Q4_0 is quantized');
    ok(Lugh::Quant::is_quantized(Lugh::Quant::Q4_K), 'Q4_K is quantized');
    ok(Lugh::Quant::is_quantized(Lugh::Quant::Q8_0), 'Q8_0 is quantized');
    ok(Lugh::Quant::is_quantized(Lugh::Quant::IQ2_XS), 'IQ2_XS is quantized');
};

subtest 'requires_imatrix' => sub {
    ok(!Lugh::Quant::requires_imatrix(Lugh::Quant::F32), 'F32 no imatrix');
    ok(!Lugh::Quant::requires_imatrix(Lugh::Quant::Q4_0), 'Q4_0 no imatrix');
    ok(!Lugh::Quant::requires_imatrix(Lugh::Quant::Q4_K), 'Q4_K no imatrix');
    
    # IQ types may require importance matrix
    # Note: behavior may vary by ggml version
};

subtest 'row_size' => sub {
    is(Lugh::Quant::row_size(Lugh::Quant::F32, 100), 400, 'F32 100 elements = 400 bytes');
    is(Lugh::Quant::row_size(Lugh::Quant::F16, 100), 200, 'F16 100 elements = 200 bytes');
    
    # Quantized row sizes should be smaller
    my $q4_row = Lugh::Quant::row_size(Lugh::Quant::Q4_0, 256);
    my $f32_row = Lugh::Quant::row_size(Lugh::Quant::F32, 256);
    cmp_ok($q4_row, '<', $f32_row, 'Q4_0 row smaller than F32');
};

# =============================================================================
# Type Discovery Functions
# =============================================================================

subtest 'type_count' => sub {
    my $count = Lugh::Quant::type_count();
    cmp_ok($count, '>=', 30, 'type_count is reasonable');
    is($count, Lugh::Quant::TYPE_COUNT, 'type_count matches TYPE_COUNT constant');
};

subtest 'all_types' => sub {
    my @types = Lugh::Quant::all_types();
    cmp_ok(scalar @types, '>=', 20, 'got at least 20 types');
    
    # Should include standard types
    ok((grep { $_ == Lugh::Quant::F32 } @types), 'includes F32');
    ok((grep { $_ == Lugh::Quant::Q4_K } @types), 'includes Q4_K');
};

subtest 'all_quantized_types' => sub {
    my @quant_types = Lugh::Quant::all_quantized_types();
    cmp_ok(scalar @quant_types, '>=', 15, 'got at least 15 quantized types');
    
    # All should be quantized
    for my $type (@quant_types) {
        ok(Lugh::Quant::is_quantized($type), 
           Lugh::Quant::type_name($type) . ' is quantized');
    }
    
    # Should NOT include float types
    ok(!(grep { $_ == Lugh::Quant::F32 } @quant_types), 'excludes F32');
    ok(!(grep { $_ == Lugh::Quant::F16 } @quant_types), 'excludes F16');
};

subtest 'type_from_name' => sub {
    is(Lugh::Quant::type_from_name('f32'), Lugh::Quant::F32, 'find f32');
    is(Lugh::Quant::type_from_name('f16'), Lugh::Quant::F16, 'find f16');
    is(Lugh::Quant::type_from_name('q4_K'), Lugh::Quant::Q4_K, 'find q4_K');
    is(Lugh::Quant::type_from_name('q8_0'), Lugh::Quant::Q8_0, 'find q8_0');
    is(Lugh::Quant::type_from_name('nonexistent'), -1, 'unknown returns -1');
};

subtest 'type_info' => sub {
    my $info = Lugh::Quant::type_info(Lugh::Quant::Q4_K);
    
    is(ref $info, 'HASH', 'returns hashref');
    is($info->{type}, Lugh::Quant::Q4_K, 'type field');
    is($info->{name}, 'q4_K', 'name field');
    ok(exists $info->{size}, 'has size');
    ok(exists $info->{blck_size}, 'has blck_size');
    ok(exists $info->{sizef}, 'has sizef');
    is($info->{is_quantized}, 1, 'is_quantized field');
    ok(exists $info->{requires_imatrix}, 'has requires_imatrix');
    
    # F32 info
    my $f32_info = Lugh::Quant::type_info(Lugh::Quant::F32);
    is($f32_info->{name}, 'f32', 'F32 name');
    is($f32_info->{is_quantized}, 0, 'F32 not quantized');
    is($f32_info->{size}, 4, 'F32 size is 4');
    is($f32_info->{blck_size}, 1, 'F32 blck_size is 1');
};

# =============================================================================
# Tensor Methods
# =============================================================================

subtest 'Tensor type methods' => sub {
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    my $tensor = Lugh::Tensor->new_f32($ctx, 100);
    
    is($tensor->type(), Lugh::Quant::F32, 'type() returns F32');
    is($tensor->type_name(), 'f32', 'type_name()');
    is($tensor->type_size(), 4, 'type_size() is 4');
    is($tensor->blck_size(), 1, 'blck_size() is 1');
    ok(!$tensor->is_quantized(), 'is_quantized() is false');
    is($tensor->nbytes(), 400, 'nbytes() is 100 * 4');
};

# =============================================================================
# Quantize/Dequantize
# =============================================================================

subtest 'quantize and dequantize' => sub {
    my $ctx = Lugh::Context->new(mem_size => 10 * 1024 * 1024);
    
    # Create F32 tensor with block-aligned size (Q4_K uses 256-element blocks)
    my $f32 = Lugh::Tensor->new_f32($ctx, 256);
    
    # Set some values
    my @values = map { sin($_ * 0.1) } 0..255;
    $f32->set_f32(@values);
    
    # Quantize to Q8_0 (OO method on tensor)
    my $q8 = $f32->quantize($ctx, Lugh::Quant::Q8_0);
    ok($q8, 'quantize succeeded');
    is($q8->type(), Lugh::Quant::Q8_0, 'quantized type is Q8_0');
    is($q8->type_name(), 'q8_0', 'quantized type name');
    ok($q8->is_quantized(), 'is_quantized() true');
    cmp_ok($q8->nbytes(), '<', $f32->nbytes(), 'quantized is smaller');
    
    # Dequantize back (OO method on tensor)
    my $restored = $q8->dequantize($ctx);
    ok($restored, 'dequantize succeeded');
    is($restored->type(), Lugh::Quant::F32, 'restored type is F32');
    is($restored->type_name(), 'f32', 'restored type name');
    is($restored->nelements(), 256, 'restored element count');
    
    # Check values are approximately correct (Q8 should be very accurate)
    my @restored_values = $restored->get_f32();
    my $max_diff = 0;
    for my $i (0..255) {
        my $diff = abs($values[$i] - $restored_values[$i]);
        $max_diff = $diff if $diff > $max_diff;
    }
    cmp_ok($max_diff, '<', 0.1, "max quantization error < 0.1 (was $max_diff)");
};

subtest 'quantize to Q4_K' => sub {
    my $ctx = Lugh::Context->new(mem_size => 10 * 1024 * 1024);
    
    # Q4_K needs 256-element blocks
    my $f32 = Lugh::Tensor->new_f32($ctx, 256);
    my @values = map { sin($_ * 0.1) } 0..255;
    $f32->set_f32(@values);
    
    my $q4k = $f32->quantize($ctx, Lugh::Quant::Q4_K);
    ok($q4k, 'quantize to Q4_K succeeded');
    is($q4k->type_name(), 'q4_K', 'type is q4_K');
    
    # Q4_K should be about 1/8 the size of F32
    my $ratio = $f32->nbytes() / $q4k->nbytes();
    cmp_ok($ratio, '>', 1.5, "compression ratio > 1.5 (was $ratio)");
    
    # Dequantize and check
    my $restored = $q4k->dequantize($ctx);
    is($restored->nelements(), 256, 'restored element count');
};

subtest 'quantize error handling' => sub {
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    my $f32 = Lugh::Tensor->new_f32($ctx, 256);
    
    # Invalid type
    eval { $f32->quantize($ctx, -1) };
    like($@, qr/Invalid destination type/, 'invalid type error');
    
    # Non-quantized destination
    eval { $f32->quantize($ctx, Lugh::Quant::F32) };
    like($@, qr/not a quantized type/, 'F32 not quantized error');
};

subtest 'dequantize error handling' => sub {
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    my $f32 = Lugh::Tensor->new_f32($ctx, 100);
    
    # Try to dequantize already-F32 tensor
    eval { $f32->dequantize($ctx) };
    like($@, qr/not quantized/, 'F32 dequantize error');
};

# =============================================================================
# Quantization Loss Test - Compare original vs round-trip values
# =============================================================================

subtest 'Quantization loss measurement' => sub {
    my $ctx = Lugh::Context->new(mem_size => 10 * 1024 * 1024);
    
    # Create F32 tensor with known pattern (simulating weights)
    # Use 256 elements (minimum for K-quant block size)
    my $n = 256;
    my $original = Lugh::Tensor->new_f32($ctx, $n);
    
    # Fill with values in typical weight range (-1 to 1)
    my @original_values;
    for my $i (0 .. $n - 1) {
        # Mix of values: sine wave + noise-like pattern
        my $val = sin($i * 0.1) * 0.5 + cos($i * 0.7) * 0.3;
        push @original_values, $val;
    }
    $original->set_f32(@original_values);
    
    diag("\nQuantization loss comparison (256 elements, range ~ -0.8 to 0.8):");
    diag(sprintf("  %-10s  %12s  %12s  %12s", 
        "Type", "Max Error", "Mean Error", "RMSE"));
    diag("-" x 55);
    
    # Test various quantization types
    my @types_to_test = (
        [Lugh::Quant::Q8_0, 'Q8_0'],
        [Lugh::Quant::Q4_K, 'Q4_K'],
        [Lugh::Quant::Q4_0, 'Q4_0'],
        [Lugh::Quant::Q2_K, 'Q2_K'],
    );
    
    my %results;
    
    for my $spec (@types_to_test) {
        my ($type, $name) = @$spec;
        
        # Quantize
        my $quantized = $original->quantize($ctx, $type);
        
        # Dequantize back
        my $restored = $quantized->dequantize($ctx);
        
        # Get all restored values
        my @restored_values = $restored->get_f32();
        
        # Calculate errors
        my $max_err = 0;
        my $sum_err = 0;
        my $sum_sq_err = 0;
        
        for my $i (0 .. $n - 1) {
            my $orig_val = $original_values[$i];
            my $rest_val = $restored_values[$i];
            my $err = abs($orig_val - $rest_val);
            
            $max_err = $err if $err > $max_err;
            $sum_err += $err;
            $sum_sq_err += $err * $err;
        }
        
        my $mean_err = $sum_err / $n;
        my $rmse = sqrt($sum_sq_err / $n);
        
        $results{$name} = {
            max_err => $max_err,
            mean_err => $mean_err,
            rmse => $rmse,
        };
        
        diag(sprintf("  %-10s  %12.8f  %12.8f  %12.8f",
            $name, $max_err, $mean_err, $rmse));
        
        # Verify there IS some loss (not zero)
        ok($max_err > 0, "$name has quantization loss (max_err > 0)");
        
        # Verify loss is reasonable (not catastrophic)
        ok($max_err < 1.0, "$name max error < 1.0 (reasonable loss)");
    }
    
    # Verify ordering: Q8 should be more accurate than Q4 which is more accurate than Q2
    ok($results{'Q8_0'}{rmse} < $results{'Q4_K'}{rmse}, 
        'Q8_0 more accurate than Q4_K');
    ok($results{'Q4_K'}{rmse} < $results{'Q2_K'}{rmse}, 
        'Q4_K more accurate than Q2_K');
    
    diag("\nConclusion: Higher bit quantization = lower error (as expected)");
};

# =============================================================================
# All Types Information
# =============================================================================

subtest 'List all quantized types info' => sub {
    diag("\nQuantized types available:");
    for my $type (sort { $a <=> $b } Lugh::Quant::all_quantized_types()) {
        my $info = Lugh::Quant::type_info($type);
        my $bits = $info->{sizef} * 8;
        diag(sprintf("  %-10s: %5.2f bits/weight, blk=%3d%s",
            $info->{name},
            $bits,
            $info->{blck_size},
            $info->{requires_imatrix} ? " (imatrix)" : ""
        ));
    }
    pass('listed all quantized types');
};

done_testing();
