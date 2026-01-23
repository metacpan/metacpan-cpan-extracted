#!/usr/bin/env perl
# t/2000-threads-basic.t - Basic thread safety tests for Lugh

use strict;
use warnings;
use Test::More;
use FindBin;

BEGIN {
    eval {
        require threads;
        require threads::shared;
    };
    if ($@) {
        plan skip_all => 'threads not available';
    }
}

use threads;
use threads::shared;
use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

# Test 1: Thread-local models work independently
subtest 'Thread-local models' => sub {
    plan tests => 4;
    
    my @results :shared;
    my @threads;
    
    for my $i (1..4) {
        push @threads, threads->create(sub {
            my $model = Lugh::Model->new(model => $model_file);
            my $arch = $model->architecture;
            return defined($arch) ? 1 : 0;
        });
    }
    
    for my $t (@threads) {
        push @results, $t->join;
    }
    
    for my $i (0..3) {
        ok($results[$i], "Thread $i loaded model successfully");
    }
};

# Test 2: Thread-local tokenizers work independently
subtest 'Thread-local tokenizers' => sub {
    plan tests => 4;
    
    my @results :shared;
    my @threads;
    
    for my $i (1..4) {
        push @threads, threads->create(sub {
            my $model = Lugh::Model->new(model => $model_file);
            my $tokenizer = Lugh::Tokenizer->new(model => $model);
            my @tokens = $tokenizer->encode("Hello from thread $i");
            return scalar(@tokens);
        });
    }
    
    for my $t (@threads) {
        push @results, $t->join;
    }
    
    for my $i (0..3) {
        ok($results[$i] > 0, "Thread $i tokenized successfully: $results[$i] tokens");
    }
};

# Test 3: Thread-local inference engines work independently
subtest 'Thread-local inference' => sub {
    plan tests => 4;
    
    my @results :shared;
    my @threads;
    
    for my $i (1..4) {
        push @threads, threads->create(sub {
            my $model = Lugh::Model->new(model => $model_file);
            my $tokenizer = Lugh::Tokenizer->new(model => $model);
            my $inference = Lugh::Inference->new(model => $model);
            
            my @tokens = $tokenizer->encode("Once upon");
            my @logits = $inference->forward_simple(\@tokens);
            return scalar(@logits);
        });
    }
    
    for my $t (@threads) {
        push @results, $t->join;
    }
    
    for my $i (0..3) {
        ok($results[$i] > 0, "Thread $i got $results[$i] logits");
    }
};

# Test 4: Thread-local context creation
subtest 'Thread-local contexts' => sub {
    plan tests => 4;
    
    my @results :shared;
    my @threads;
    
    for my $i (1..4) {
        push @threads, threads->create(sub {
            my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
            # Use new_f32 which is the actual XS method
            my $tensor = Lugh::Tensor->new_f32($ctx, 10, 10);
            return $tensor->nelements;
        });
    }
    
    for my $t (@threads) {
        push @results, $t->join;
    }
    
    for my $i (0..3) {
        is($results[$i], 100, "Thread $i created 100-element tensor");
    }
};

done_testing();
