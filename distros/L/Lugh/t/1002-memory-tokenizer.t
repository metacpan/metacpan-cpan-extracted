#!/usr/bin/env perl
# t/1002-memory-tokenizer.t - Memory leak tests for Lugh::Tokenizer

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

# Warmup
my $model = Lugh::Model->new(model => $model_file);
{
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my @tokens = $tokenizer->encode("warmup");
    my $text = $tokenizer->decode(\@tokens);
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

subtest 'Tokenizer creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $tokenizer = Lugh::Tokenizer->new(model => $model);
            undef $tokenizer;
        }
    } 'Tokenizer lifecycle';
};

subtest 'Tokenizer encode' => sub {
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    leaks_stable {
        for (1..100) {
            my @tokens = $tokenizer->encode("Once upon a time");
        }
    } 'Repeated encode';
};

subtest 'Tokenizer decode' => sub {
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my @tokens = $tokenizer->encode("Hello world");
    leaks_stable {
        for (1..100) {
            my $text = $tokenizer->decode(\@tokens);
        }
    } 'Repeated decode';
};

subtest 'Tokenizer encode/decode cycle' => sub {
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    leaks_stable {
        for (1..50) {
            my @tokens = $tokenizer->encode("The quick brown fox jumps");
            my $text = $tokenizer->decode(\@tokens);
        }
    } 'Encode/decode cycle';
};

subtest 'Long text tokenization' => sub {
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $long_text = "Once upon a time " x 50;
    leaks_stable {
        for (1..10) {
            my @tokens = $tokenizer->encode($long_text);
            my $text = $tokenizer->decode(\@tokens);
        }
    } 'Long text processing';
};

subtest 'Vocabulary access' => sub {
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    leaks_stable {
        for (1..50) {
            my $vocab = $tokenizer->n_vocab;
        }
    } 'Vocabulary size access';
};

done_testing();
