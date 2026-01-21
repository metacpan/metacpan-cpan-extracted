#!/usr/bin/env perl
# t/1006-memory-speculative.t - Memory leak tests for Lugh::Speculative

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

# Setup - use same model as draft and main for testing
my $model = Lugh::Model->new(model => $model_file);
my $tokenizer = Lugh::Tokenizer->new(model => $model);
my $inference = Lugh::Inference->new(model => $model);
my @prompt_tokens = $tokenizer->encode("Once upon a time");

# Warmup
{
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 2,
    );
    Lugh::srand(42);
    my @result = $spec->generate(\@prompt_tokens, 3);
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

subtest 'Speculative creation/destruction' => sub {
    leaks_stable {
        for (1..5) {
            my $spec = Lugh::Speculative->new(
                inference => $inference,
                draft     => $inference,
                k         => 3,
            );
            undef $spec;
        }
    } 'Speculative lifecycle';
};

subtest 'Speculative generate' => sub {
    leaks_stable {
        for (1..3) {
            my $spec = Lugh::Speculative->new(
                inference => $inference,
                draft     => $inference,
                k         => 2,
            );
            Lugh::srand(42);
            my @result = $spec->generate(\@prompt_tokens, 5);
        }
    } 'Speculative generate cycle';
};

subtest 'Speculative accessors' => sub {
    leaks_stable {
        my $spec = Lugh::Speculative->new(
            inference => $inference,
            draft     => $inference,
            k         => 4,
        );
        for (1..50) {
            my $k = $spec->k;
            my $drafted = $spec->tokens_drafted;
            my $accepted = $spec->tokens_accepted;
            my $rate = $spec->acceptance_rate;
        }
    } 'Speculative accessor access';
};

subtest 'Speculative reset_stats' => sub {
    leaks_stable {
        my $spec = Lugh::Speculative->new(
            inference => $inference,
            draft     => $inference,
            k         => 3,
        );
        
        for (1..5) {
            Lugh::srand(42);
            my @result = $spec->generate(\@prompt_tokens, 3);
            $spec->reset_stats();
        }
    } 'Speculative reset_stats cycle';
};

done_testing();
