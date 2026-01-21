#!/usr/bin/env perl
# t/1003-memory-inference.t - Memory leak tests for Lugh::Inference

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
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

# Setup
my $model = Lugh::Model->new(model => $model_file);
my $tokenizer = Lugh::Tokenizer->new(model => $model);
my @prompt_tokens = $tokenizer->encode("Once upon a time");

# Warmup
{
    my $inference = Lugh::Inference->new(model => $model);
    my @logits = $inference->forward_simple(\@prompt_tokens);
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

subtest 'Inference creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $inference = Lugh::Inference->new(model => $model);
            undef $inference;
        }
    } 'Inference lifecycle';
};

subtest 'forward_simple repeated' => sub {
    my $inference = Lugh::Inference->new(model => $model);
    leaks_stable {
        for (1..20) {
            my @logits = $inference->forward_simple(\@prompt_tokens);
        }
    } 'Repeated forward_simple';
};

subtest 'forward_all repeated' => sub {
    my $inference = Lugh::Inference->new(model => $model);
    leaks_stable {
        for (1..10) {
            my @all_logits = $inference->forward_all(tokens => \@prompt_tokens);
        }
    } 'Repeated forward_all';
};

subtest 'sample_top_p repeated' => sub {
    my $inference = Lugh::Inference->new(model => $model);
    Lugh::srand(42);
    leaks_stable {
        for (1..50) {
            my @logits = $inference->forward_simple(\@prompt_tokens);
            my $token = $inference->sample_top_p(\@logits, 0.9, 1.0);
        }
    } 'Repeated sampling';
};

subtest 'sample_top_k repeated' => sub {
    my $inference = Lugh::Inference->new(model => $model);
    Lugh::srand(42);
    leaks_stable {
        for (1..50) {
            my @logits = $inference->forward_simple(\@prompt_tokens);
            my $token = $inference->sample_top_k(\@logits, 40, 1.0);
        }
    } 'Repeated top-k sampling';
};

subtest 'Full generation loop' => sub {
    my $inference = Lugh::Inference->new(model => $model);
    Lugh::srand(42);
    leaks_stable {
        for (1..5) {
            my @tokens = @prompt_tokens;
            for my $step (1..5) {
                my @logits = $inference->forward_simple(\@tokens);
                my $next = $inference->sample_top_p(\@logits, 0.9, 1.0);
                push @tokens, $next;
            }
        }
    } 'Generation loop';
};

done_testing();
