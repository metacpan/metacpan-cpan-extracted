#!/usr/bin/env perl
# t/0035-mmap.t - Memory mapping tests for model loading
#
# mmap allows the OS to share read-only model weights across processes,
# significantly reducing memory usage for multi-process deployments.

use strict;
use warnings;
use Test::More;
use FindBin;
use Lugh;

# Check if mmap is supported on this platform
my $mmap_supported = Lugh::Model->mmap_supported();
diag("mmap support: " . ($mmap_supported ? "yes" : "no"));

# Use bundled test model
my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 14;

# Test 1: mmap_supported class method
ok(defined $mmap_supported, 'mmap_supported returns a value');
ok($mmap_supported == 0 || $mmap_supported == 1, 'mmap_supported returns 0 or 1');

# Test 2: Load model without mmap (default)
my $model_no_mmap = Lugh::Model->new(model => $model_file);
ok($model_no_mmap, 'Model loaded without mmap');
is($model_no_mmap->use_mmap, 0, 'use_mmap returns 0 for non-mmap model');
is($model_no_mmap->mmap_size, 0, 'mmap_size returns 0 for non-mmap model');

# Test 3: Load model with mmap enabled
SKIP: {
    skip "mmap not supported on this platform", 5 unless $mmap_supported;

    my $model_mmap = Lugh::Model->new(model => $model_file, use_mmap => 1);
    ok($model_mmap, 'Model loaded with mmap');
    is($model_mmap->use_mmap, 1, 'use_mmap returns 1 for mmap model');

    my $mmap_size = $model_mmap->mmap_size;
    ok($mmap_size > 0, "mmap_size returns positive value: $mmap_size bytes");

    # Verify the model works the same as non-mmap
    is($model_mmap->architecture, $model_no_mmap->architecture,
       'mmap model has same architecture');
    is($model_mmap->n_tensors, $model_no_mmap->n_tensors,
       'mmap model has same number of tensors');
}

# Test 4: mmap => 1 alias works
SKIP: {
    skip "mmap not supported on this platform", 2 unless $mmap_supported;

    my $model_alias = Lugh::Model->new(model => $model_file, mmap => 1);
    ok($model_alias, 'Model loaded with mmap alias');
    is($model_alias->use_mmap, 1, 'mmap alias enables mmap');
}

# Test 5: prefetch option
SKIP: {
    skip "mmap not supported on this platform", 2 unless $mmap_supported;

    # Load with prefetch disabled
    my $model_no_prefetch = Lugh::Model->new(
        model => $model_file,
        use_mmap => 1,
        prefetch => 0
    );
    ok($model_no_prefetch, 'Model loaded with mmap and no prefetch');
    is($model_no_prefetch->use_mmap, 1, 'mmap works without prefetch');
}

done_testing();
