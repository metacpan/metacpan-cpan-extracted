#!/usr/bin/env perl
# t/10-multi-arch.t - Test loading multiple architecture types

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($Bin);

use lib "$Bin/../blib/lib";
use lib "$Bin/../blib/arch";

use Lugh;

# Models directory
my $models_dir = "$Bin/data";

# Skip if no test models exist
unless (-d $models_dir && -f "$models_dir/tiny-llama.gguf") {
    plan skip_all => "Test models not found in $models_dir. Run tools/generate_test_models.py first.";
}

# Define expected properties for each architecture
my %expected = (
    'tiny-llama.gguf' => {
        architecture => 'llama',
        combined_qkv => 0,
        ffn_gate     => 1,
        post_norm    => 0,
        recurrent    => 0,
    },
    'tiny-qwen2.gguf' => {
        architecture => 'qwen2',
        combined_qkv => 1,
        ffn_gate     => 1,
        post_norm    => 0,
        recurrent    => 0,
    },
    'tiny-phi3.gguf' => {
        architecture => 'phi3',
        combined_qkv => 1,
        ffn_gate     => 0,
        post_norm    => 0,
        recurrent    => 0,
    },
    'tiny-gemma2.gguf' => {
        architecture => 'gemma2',
        combined_qkv => 0,
        ffn_gate     => 1,
        post_norm    => 1,
        recurrent    => 0,
    },
    'tiny-gpt2.gguf' => {
        architecture => 'gpt2',
        combined_qkv => 1,
        ffn_gate     => 0,
        post_norm    => 0,
        recurrent    => 0,
    },
    'tiny-falcon.gguf' => {
        architecture => 'falcon',
        combined_qkv => 1,
        ffn_gate     => 0,
        post_norm    => 0,
        recurrent    => 0,
    },
    'tiny-bloom.gguf' => {
        architecture => 'bloom',
        combined_qkv => 1,
        ffn_gate     => 0,
        post_norm    => 0,
        recurrent    => 0,
    },
    'tiny-starcoder.gguf' => {
        architecture => 'starcoder',
        combined_qkv => 1,
        ffn_gate     => 0,
        post_norm    => 0,
        recurrent    => 0,
    },
);

# Count available models
my @available_models;
for my $model_file (sort keys %expected) {
    my $path = File::Spec->catfile($models_dir, $model_file);
    push @available_models, $model_file if -f $path;
}

plan tests => scalar(@available_models) * 6;

for my $model_file (@available_models) {
    my $path = File::Spec->catfile($models_dir, $model_file);
    my $exp = $expected{$model_file};
    
    # Load model
    my $model = eval { Lugh::Model->new(model => $path) };
    ok($model, "$model_file: loaded successfully") or do {
        SKIP: {
            skip "$model_file: failed to load - $@", 5;
        }
        next;
    };
    
    # Check architecture
    is($model->architecture, $exp->{architecture}, 
       "$model_file: architecture is '$exp->{architecture}'");
    
    # Check combined QKV
    is($model->arch_has_combined_qkv, $exp->{combined_qkv},
       "$model_file: arch_has_combined_qkv is $exp->{combined_qkv}");
    
    # Check FFN gate
    is($model->arch_has_ffn_gate, $exp->{ffn_gate},
       "$model_file: arch_has_ffn_gate is $exp->{ffn_gate}");
    
    # Check post-norm
    is($model->arch_has_post_norm, $exp->{post_norm},
       "$model_file: arch_has_post_norm is $exp->{post_norm}");
    
    # Check recurrent
    is($model->arch_is_recurrent, $exp->{recurrent},
       "$model_file: arch_is_recurrent is $exp->{recurrent}");
}

done_testing();
