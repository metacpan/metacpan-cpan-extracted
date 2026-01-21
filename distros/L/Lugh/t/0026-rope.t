#!perl
use strict;
use warnings;
use Test::More;

use_ok('Lugh::RoPE');

# Test constants
subtest 'scaling type constants' => sub {
    is(Lugh::RoPE::ROPE_SCALING_NONE(), 0, 'ROPE_SCALING_NONE = 0');
    is(Lugh::RoPE::ROPE_SCALING_LINEAR(), 1, 'ROPE_SCALING_LINEAR = 1');
    is(Lugh::RoPE::ROPE_SCALING_YARN(), 2, 'ROPE_SCALING_YARN = 2');
    is(Lugh::RoPE::ROPE_SCALING_LONGROPE(), 3, 'ROPE_SCALING_LONGROPE = 3');
};

# Test default constructor
subtest 'new() with defaults' => sub {
    my $rope = Lugh::RoPE->new();
    isa_ok($rope, 'Lugh::RoPE');
    is($rope->scaling_type, Lugh::RoPE::ROPE_SCALING_NONE(), 'default scaling_type is NONE');
    is($rope->scaling_type_name, 'none', 'scaling_type_name is "none"');
    is($rope->freq_scale, 1.0, 'default freq_scale is 1.0');
    is($rope->attn_factor, 1.0, 'default attn_factor is 1.0');
    is($rope->ext_factor, -1.0, 'default ext_factor is -1.0 (auto)');
    is($rope->beta_fast, 32.0, 'default beta_fast is 32.0');
    is($rope->beta_slow, 1.0, 'default beta_slow is 1.0');
};

# Test constructor with explicit parameters
subtest 'new() with parameters' => sub {
    my $rope = Lugh::RoPE->new(
        scaling_type => 'yarn',
        n_ctx_orig   => 4096,
        target_ctx   => 32768,
        beta_fast    => 16.0,
        beta_slow    => 2.0,
    );
    isa_ok($rope, 'Lugh::RoPE');
    is($rope->scaling_type, Lugh::RoPE::ROPE_SCALING_YARN(), 'scaling_type is YARN');
    is($rope->scaling_type_name, 'yarn', 'scaling_type_name is "yarn"');
    is($rope->n_ctx_orig, 4096, 'n_ctx_orig is 4096');
    is($rope->target_ctx, 32768, 'target_ctx is 32768');
    # freq_scale should be auto-computed: 4096/32768 = 0.125
    cmp_ok(abs($rope->freq_scale - 0.125), '<', 0.001, 'freq_scale auto-computed to 0.125');
    is($rope->beta_fast, 16.0, 'beta_fast is 16.0');
    is($rope->beta_slow, 2.0, 'beta_slow is 2.0');
};

# Test none() constructor
subtest 'none()' => sub {
    my $rope = Lugh::RoPE->none();
    isa_ok($rope, 'Lugh::RoPE');
    is($rope->scaling_type, Lugh::RoPE::ROPE_SCALING_NONE(), 'scaling_type is NONE');
    is($rope->scaling_type_name, 'none', 'scaling_type_name is "none"');
    is($rope->freq_scale, 1.0, 'freq_scale is 1.0');
};

# Test linear() constructor
subtest 'linear()' => sub {
    my $rope = Lugh::RoPE->linear(4096, 16384);
    isa_ok($rope, 'Lugh::RoPE');
    is($rope->scaling_type, Lugh::RoPE::ROPE_SCALING_LINEAR(), 'scaling_type is LINEAR');
    is($rope->scaling_type_name, 'linear', 'scaling_type_name is "linear"');
    is($rope->n_ctx_orig, 4096, 'n_ctx_orig is 4096');
    is($rope->target_ctx, 16384, 'target_ctx is 16384');
    # freq_scale = 4096/16384 = 0.25
    cmp_ok(abs($rope->freq_scale - 0.25), '<', 0.001, 'freq_scale is 0.25');
    is($rope->ext_factor, 0.0, 'ext_factor is 0 for linear');
};

# Test yarn() constructor
subtest 'yarn()' => sub {
    my $rope = Lugh::RoPE->yarn(4096, 32768);
    isa_ok($rope, 'Lugh::RoPE');
    is($rope->scaling_type, Lugh::RoPE::ROPE_SCALING_YARN(), 'scaling_type is YARN');
    is($rope->scaling_type_name, 'yarn', 'scaling_type_name is "yarn"');
    is($rope->n_ctx_orig, 4096, 'n_ctx_orig is 4096');
    is($rope->target_ctx, 32768, 'target_ctx is 32768');
    # freq_scale = 4096/32768 = 0.125
    cmp_ok(abs($rope->freq_scale - 0.125), '<', 0.001, 'freq_scale is 0.125');
    is($rope->ext_factor, -1.0, 'ext_factor is -1.0 (auto)');
    is($rope->beta_fast, 32.0, 'default beta_fast');
    is($rope->beta_slow, 1.0, 'default beta_slow');
};

# Test yarn() with custom params
subtest 'yarn() with custom params' => sub {
    my $rope = Lugh::RoPE->yarn(4096, 32768,
        ext_factor  => 0.5,
        attn_factor => 0.9,
        beta_fast   => 24.0,
        beta_slow   => 1.5,
    );
    is($rope->ext_factor, 0.5, 'custom ext_factor');
    cmp_ok(abs($rope->attn_factor - 0.9), '<', 0.001, 'custom attn_factor');
    is($rope->beta_fast, 24.0, 'custom beta_fast');
    cmp_ok(abs($rope->beta_slow - 1.5), '<', 0.001, 'custom beta_slow');
};

# Test presets
subtest 'linear_2x()' => sub {
    my $rope = Lugh::RoPE->linear_2x(4096);
    isa_ok($rope, 'Lugh::RoPE');
    is($rope->scaling_type_name, 'linear', 'is linear');
    is($rope->n_ctx_orig, 4096, 'n_ctx_orig correct');
    is($rope->target_ctx, 8192, 'target_ctx is 2x');
    cmp_ok(abs($rope->freq_scale - 0.5), '<', 0.001, 'freq_scale is 0.5');
};

subtest 'linear_4x()' => sub {
    my $rope = Lugh::RoPE->linear_4x(2048);
    is($rope->n_ctx_orig, 2048, 'n_ctx_orig correct');
    is($rope->target_ctx, 8192, 'target_ctx is 4x');
    cmp_ok(abs($rope->freq_scale - 0.25), '<', 0.001, 'freq_scale is 0.25');
};

subtest 'yarn_32k()' => sub {
    my $rope = Lugh::RoPE->yarn_32k(4096);
    isa_ok($rope, 'Lugh::RoPE');
    is($rope->scaling_type_name, 'yarn', 'is yarn');
    is($rope->target_ctx, 32768, 'target_ctx is 32K');
};

subtest 'yarn_64k()' => sub {
    my $rope = Lugh::RoPE->yarn_64k(4096);
    is($rope->target_ctx, 65536, 'target_ctx is 64K');
};

subtest 'yarn_128k()' => sub {
    my $rope = Lugh::RoPE->yarn_128k(8192);
    is($rope->n_ctx_orig, 8192, 'n_ctx_orig correct');
    is($rope->target_ctx, 131072, 'target_ctx is 128K');
};

# Test scaling_type with integer constant
subtest 'new() with integer scaling_type' => sub {
    my $rope = Lugh::RoPE->new(
        scaling_type => Lugh::RoPE::ROPE_SCALING_LINEAR(),
        n_ctx_orig   => 2048,
        target_ctx   => 4096,
    );
    is($rope->scaling_type, Lugh::RoPE::ROPE_SCALING_LINEAR(), 'accepts integer constant');
};

# Test object destruction (no crash)
subtest 'destruction' => sub {
    {
        my $rope = Lugh::RoPE->yarn(4096, 32768);
        isa_ok($rope, 'Lugh::RoPE');
    }
    # If we get here without crashing, DESTROY works
    pass('object destroyed without crash');
};

# Test multiple objects
subtest 'multiple objects' => sub {
    my $rope1 = Lugh::RoPE->linear(4096, 8192);
    my $rope2 = Lugh::RoPE->yarn(4096, 32768);
    my $rope3 = Lugh::RoPE->none();
    
    is($rope1->scaling_type_name, 'linear', 'rope1 is linear');
    is($rope2->scaling_type_name, 'yarn', 'rope2 is yarn');
    is($rope3->scaling_type_name, 'none', 'rope3 is none');
    
    # Ensure they're independent
    isnt($rope1->freq_scale, $rope2->freq_scale, 'different freq_scale');
};

# Test invalid scaling_type string
subtest 'invalid scaling_type' => sub {
    eval {
        Lugh::RoPE->new(scaling_type => 'invalid');
    };
    like($@, qr/Unknown scaling_type/, 'rejects invalid scaling_type');
};

# Test from_model() constructor
subtest 'from_model()' => sub {
    # Load a model to extract RoPE config from
    my $model_file = 't/data/test_model.gguf';
    SKIP: {
        skip "Test model not found", 5 unless -f $model_file;
        
        use Lugh::Model;
        my $model = Lugh::Model->new(file => $model_file);
        my $rope = Lugh::RoPE->from_model($model);
        
        isa_ok($rope, 'Lugh::RoPE');
        ok(defined $rope->scaling_type, 'has scaling_type');
        ok(defined $rope->n_ctx_orig, 'has n_ctx_orig');
        ok(defined $rope->freq_scale, 'has freq_scale');
        cmp_ok($rope->n_ctx_orig, '>', 0, 'n_ctx_orig > 0');
    }
};

done_testing();
