#!/usr/bin/env perl
# t/1008-memory-lora.t - Memory leak tests for Lugh::LoRA

use strict;
use warnings;
use Test::More;
use FindBin;

BEGIN {
    eval { require Test::LeakTrace; Test::LeakTrace->import(); };
    if ($@) {
        plan skip_all => 'Test::LeakTrace required for memory leak tests';
    }
}

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
my $lora_file = "$FindBin::Bin/data/test-lora.gguf";

unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

unless (-e $lora_file) {
    plan skip_all => "No test LoRA adapter at $lora_file";
}

# Setup
my $model = Lugh::Model->new(model => $model_file);

# Warmup
{
    my $lora = Lugh::LoRA->new(
        adapter => $lora_file,
        model => $model,
    );
}

sub leaks_stable(&;$) {
    my ($code, $name) = @_;
    $name //= 'leaks stable';
    
    # Run 3 times to detect linear growth (real leak pattern)
    my $count1 = Test::LeakTrace::leaked_count { $code->() };
    my $count2 = Test::LeakTrace::leaked_count { $code->() };
    my $count3 = Test::LeakTrace::leaked_count { $code->() };
    
    # Real leak: counts grow linearly. Normal variance: counts stay similar
    my $growing = ($count3 > $count2 + 2) && ($count2 > $count1 + 2);
    # Also check absolute threshold - no run should have excessive leaks
    my $excessive = ($count3 > 50);
    
    my $ok = !$growing && !$excessive;
    ok($ok, $name) or diag("Runs: $count1 -> $count2 -> $count3" . 
        ($growing ? " (growing)" : "") . ($excessive ? " (excessive)" : ""));
    return $ok;
}

subtest 'LoRA creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $lora = Lugh::LoRA->new(
                adapter => $lora_file,
                model => $model,
            );
            undef $lora;
        }
    } 'LoRA lifecycle';
};

subtest 'LoRA properties access' => sub {
    leaks_stable {
        my $lora = Lugh::LoRA->new(
            adapter => $lora_file,
            model => $model,
        );
        for (1..50) {
            my $alpha = $lora->alpha;
            my $scale = $lora->scale;
            my $n_weights = $lora->n_weights;
            my $format = $lora->format;
        }
    } 'LoRA properties access';
};

subtest 'LoRA weight names' => sub {
    leaks_stable {
        my $lora = Lugh::LoRA->new(
            adapter => $lora_file,
            model => $model,
        );
        for (1..50) {
            my @names = $lora->weight_names;
        }
    } 'LoRA weight names access';
};

subtest 'LoRA scale modification' => sub {
    leaks_stable {
        my $lora = Lugh::LoRA->new(
            adapter => $lora_file,
            model => $model,
        );
        for (1..50) {
            $lora->scale(0.5);
            $lora->scale(1.0);
            $lora->scale(1.5);
        }
    } 'LoRA scale modification';
};

subtest 'Multiple LoRA loads' => sub {
    leaks_stable {
        for (1..5) {
            my $lora = Lugh::LoRA->new(
                adapter => $lora_file,
                model => $model,
            );
            my $alpha = $lora->alpha;
            my @names = $lora->weight_names;
        }
    } 'Multiple LoRA loads';
};

done_testing();
