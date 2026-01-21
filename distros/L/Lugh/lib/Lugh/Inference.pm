package Lugh::Inference;

use strict;
use warnings;
use Lugh;

=head1 NAME

Lugh::Inference - Transformer Forward Pass and Token Generation

=encoding utf8

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Lugh;
    
    # Load model and create inference engine
    my $model = Lugh::Model->new(model => '/path/to/model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);
    
    # Encode a prompt
    my @tokens = $tokenizer->encode("The capital of France is");
    
    # Run forward pass to get logits
    my @logits = $inference->forward(tokens => \@tokens);
    
    # Find the most likely next token (greedy)
    my $max_idx = 0;
    my $max_val = $logits[0];
    for my $i (1..$#logits) {
        if ($logits[$i] > $max_val) {
            $max_val = $logits[$i];
            $max_idx = $i;
        }
    }
    
    # Decode the predicted token
    my $next_token = $tokenizer->decode([$max_idx]);
    print "Next token: $next_token\n";  # " Paris"
    
    # Or use top-p sampling
    my $sampled = $inference->sample_top_p(
        \@logits,
        temperature => 0.8,
        top_p => 0.95
    );

=head1 DESCRIPTION

Lugh::Inference implements the transformer forward pass for autoregressive
language model inference. Given a sequence of input tokens, it computes
the probability distribution (logits) over the vocabulary for the next token.

=head2 Transformer Architecture

The forward pass implements the standard transformer decoder architecture
used by LLaMA, Mistral, and similar models:

    Input Tokens
         │
         ▼
    ┌─────────────┐
    │  Token      │
    │  Embeddings │
    └─────────────┘
         │
         ▼
    ┌─────────────────────────────────┐
    │  Transformer Layer (× N)        │
    │  ┌─────────────────────────────┐│
    │  │ RMSNorm                     ││
    │  │      ↓                      ││
    │  │ Multi-Head Attention (GQA)  ││
    │  │      ↓                      ││
    │  │ Residual Add                ││
    │  │      ↓                      ││
    │  │ RMSNorm                     ││
    │  │      ↓                      ││
    │  │ FFN (SwiGLU)                ││
    │  │      ↓                      ││
    │  │ Residual Add                ││
    │  └─────────────────────────────┘│
    └─────────────────────────────────┘
         │
         ▼
    ┌─────────────┐
    │  Final      │
    │  RMSNorm    │
    └─────────────┘
         │
         ▼
    ┌─────────────┐
    │  Output     │
    │  Projection │ → Logits [vocab_size]
    └─────────────┘

=head2 Key Components

=over 4

=item * B<RMSNorm> - Root Mean Square Layer Normalization

=item * B<RoPE> - Rotary Position Embeddings for position encoding

=item * B<GQA> - Grouped Query Attention (multiple Q heads per KV head)

=item * B<SwiGLU> - Gated activation in feed-forward network

=back

=head1 CONSTRUCTOR

=head2 new

    my $inference = Lugh::Inference->new(
        model      => $model,
        backend    => 'auto',  # optional, compute backend
        n_threads  => 4,       # optional, number of CPU threads
        flash_attn => 0,       # optional, use flash attention
    );

Creates a new Inference engine from a loaded model.

B<Parameters:>

=over 4

=item * C<model> (required) - A Lugh::Model object

=item * C<backend> (optional) - Compute backend to use. Defaults to 'auto'.

Available backends depend on your system:

=over 8

=item * C<'auto'> - Automatically select the best available (GPU preferred)

=item * C<'Metal'> - Apple Metal GPU (macOS only)

=item * C<'CUDA'> - NVIDIA GPU (if ggml built with CUDA)

=item * C<'Vulkan'> - Cross-platform GPU

=item * C<'CPU'> - CPU with SIMD (always available)

=back

Use C<Lugh::available_backends()> to see what's available on your system.

=item * C<n_threads> (optional) - Number of CPU threads for computation.
Defaults to 4. Only affects CPU backend.

=item * C<flash_attn> (optional) - Use flash attention if set to 1 (default: 0)

=back

B<Returns:> A Lugh::Inference object.

B<Throws:> Dies if no model is provided or if requested backend is unavailable.

B<Example:>

    my $model = Lugh::Model->new(model => 'model.gguf');
    
    # Auto-select best backend (recommended)
    my $inference = Lugh::Inference->new(model => $model);
    
    # Force Metal GPU on macOS
    my $gpu_inference = Lugh::Inference->new(
        model   => $model,
        backend => 'Metal',
    );
    
    # Force CPU with 8 threads
    my $cpu_inference = Lugh::Inference->new(
        model     => $model,
        backend   => 'CPU',
        n_threads => 8,
    );

=head1 METHODS

=head2 forward

    my @logits = $inference->forward(tokens => \@tokens);
    
    # With optional LoRA adapter
    my @logits = $inference->forward(
        tokens => \@tokens,
        lora   => $lora,
    );

Runs the transformer forward pass on input tokens.

B<Parameters:>

=over 4

=item * C<tokens> or C<\@tokens> - Array reference of token IDs (integers)

=item * C<lora> (optional) - A Lugh::LoRA adapter to apply during inference

=back

B<Returns:> A list of logits (one per vocabulary token).

B<Details:>

The forward pass:

=over 4

=item 1. Looks up token embeddings

=item 2. Applies N transformer layers with attention and FFN

=item 3. Applies final normalization

=item 4. Projects to vocabulary size

=item 5. Returns logits for the I<last> token position

=back

B<Performance Notes:>

=over 4

=item * Each call creates a new computation graph

=item * Memory is allocated and freed for each call

=item * For multi-token generation, consider batching

=back

B<Example:>

    my @tokens = (1, 450, 7483, 310, 3444, 338);  # "The capital of France is"
    my @logits = $inference->forward(tokens => \@tokens);
    
    # logits has 32000 elements (vocab size)
    print "Vocab size: ", scalar(@logits), "\n";

=head2 sample_top_p

    my $token_id = $inference->sample_top_p(
        \@logits,
        temperature => 0.8,
        top_p => 0.95
    );

Samples a token from logits using nucleus (top-p) sampling.

B<Parameters:>

=over 4

=item * C<\@logits> - Array reference of logits from forward()

=item * C<temperature> - Sampling temperature (default: 0.8)

=item * C<top_p> - Cumulative probability threshold (default: 0.95)

=back

B<Returns:> A single token ID.

B<Algorithm:>

=over 4

=item 1. Apply temperature scaling: logit / temperature

=item 2. Convert to probabilities via softmax

=item 3. Sort tokens by probability (descending)

=item 4. Keep tokens until cumulative probability >= top_p

=item 5. Randomly sample from this "nucleus"

=back

B<Temperature Effects:>

=over 4

=item * B<< temperature < 1 >> - More deterministic (sharper distribution)

=item * B<temperature = 1> - Use raw probabilities

=item * B<< temperature > 1 >> - More random (flatter distribution)

=item * B<temperature → 0> - Approaches greedy (argmax)

=back

B<Top-p Effects:>

=over 4

=item * B<top_p = 0.1> - Very focused, only most likely tokens

=item * B<top_p = 0.9> - Typical setting, good balance

=item * B<top_p = 1.0> - Consider all tokens (like top-k with k=all)

=back

B<Example:>

    my @logits = $inference->forward(tokens => \@tokens);
    
    # Creative generation
    my $token = $inference->sample_top_p(\@logits,
        temperature => 1.0,
        top_p => 0.95
    );
    
    # More focused generation
    my $token = $inference->sample_top_p(\@logits,
        temperature => 0.3,
        top_p => 0.5
    );

=head2 sample_top_k

    my $token_id = $inference->sample_top_k(
        \@logits,
        temperature => 0.8,
        top_k => 40
    );

Samples a token from logits using top-k sampling.

B<Parameters:>

=over 4

=item * C<\@logits> - Array reference of logits from forward()

=item * C<temperature> - Sampling temperature (default: 0.8)

=item * C<top_k> - Number of top tokens to consider (default: 40)

=back

B<Returns:> A single token ID.

B<Algorithm:>

=over 4

=item 1. Apply temperature scaling: logit / temperature

=item 2. Convert to probabilities via softmax

=item 3. Select top-k tokens by probability

=item 4. Renormalize probabilities

=item 5. Randomly sample from top-k tokens

=back

B<Example:>

    my @logits = $inference->forward(tokens => \@tokens);
    
    # Sample from top 50 tokens
    my $token = $inference->sample_top_k(\@logits,
        temperature => 0.9,
        top_k => 50
    );

=head2 generate

    my @tokens = $inference->generate(
        \@prompt_tokens,
        max_tokens  => 100,
        temperature => 0.8,
        top_p       => 0.95,
        top_k       => 40,
        greedy      => 0,
        eos_token   => 2,
        callback    => sub { ... },
    );

Generates multiple tokens autoregressively from a prompt.

B<Parameters:>

=over 4

=item * C<\@prompt_tokens> (required) - Array reference of prompt token IDs

=item * C<max_tokens> - Maximum tokens to generate (default: 128)

=item * C<temperature> - Sampling temperature (default: 0.8)

=item * C<top_p> - Top-p (nucleus) sampling threshold (default: 0.95)

=item * C<top_k> - Top-k sampling limit (default: 40). If < 1000, uses top_k; otherwise uses top_p

=item * C<greedy> - If true, use greedy decoding (argmax) (default: 0)

=item * C<eos_token> - Token ID to stop generation (default: from model, typically 2)

=item * C<callback> - Optional subroutine called for each generated token

=back

B<Returns:> A list of generated token IDs (not including the prompt).

B<Callback:>

The callback receives (token_id, count) and should return true to stop generation:

    callback => sub {
        my ($token, $count) = @_;
        print $tokenizer->decode([$token]);
        return 0;  # Continue (return 1 to stop)
    }

B<Stopping Conditions:>

Generation stops when:

=over 4

=item * max_tokens is reached

=item * EOS token is generated

=item * Callback returns true

=back

B<Example:>

    use Lugh;
    
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);
    
    my @prompt = $tokenizer->encode("Once upon a time");
    
    # Greedy generation
    my @tokens = $inference->generate(\@prompt,
        max_tokens => 50,
        greedy     => 1,
    );
    print $tokenizer->decode(\@tokens);
    
    # Creative generation with streaming
    @tokens = $inference->generate(\@prompt,
        max_tokens  => 100,
        temperature => 1.0,
        top_p       => 0.95,
        callback    => sub {
            my ($tok, $n) = @_;
            print $tokenizer->decode([$tok]);
            STDOUT->flush();
            return 0;
        },
    );

=head1 ATTENTION MECHANISM

=head2 Scaled Dot-Product Attention

    Attention(Q, K, V) = softmax(QK^T / √d_k) × V

Where:

=over 4

=item * Q - Query vectors [head_dim, n_tokens, n_heads]

=item * K - Key vectors [head_dim, n_tokens, n_kv_heads]

=item * V - Value vectors [head_dim, n_tokens, n_kv_heads]

=item * d_k - Head dimension (typically 64-128)

=back

=head2 Grouped Query Attention (GQA)

GQA uses fewer KV heads than query heads to reduce memory:

    Model       n_head  n_kv_head  Ratio
    LLaMA 7B    32      32         1:1 (MHA)
    LLaMA 2 70B 64      8          8:1 (GQA)
    TinyLlama   32      4          8:1 (GQA)
    Mistral 7B  32      8          4:1 (GQA)

The implementation broadcasts KV heads to match query heads using
ggml's native broadcasting.

=head2 Causal Masking

The attention uses causal (autoregressive) masking so each position
can only attend to itself and previous positions:

    Position:  0  1  2  3
    0          ✓  ✗  ✗  ✗
    1          ✓  ✓  ✗  ✗
    2          ✓  ✓  ✓  ✗
    3          ✓  ✓  ✓  ✓

This is implemented using C<ggml_diag_mask_inf> which sets the upper
triangle to -infinity before softmax.

=head2 RoPE (Rotary Position Embeddings)

Position information is encoded by rotating Q and K vectors:

    RoPE(x, pos) = x × cos(pos × θ) + rotate(x) × sin(pos × θ)

Where θ depends on the dimension and base frequency (typically 10000).

Parameters are read from model metadata:

=over 4

=item * C<llama.rope.dimension_count> - Dimensions to rotate

=item * C<llama.rope.freq_base> - Base frequency

=item * C<llama.context_length> - Original context length

=back

=head1 FEED-FORWARD NETWORK

The FFN uses SwiGLU activation:

    FFN(x) = down(gate(x) × SiLU(up(x)))

Where:

=over 4

=item * gate, up - Linear projections to intermediate dimension

=item * SiLU - Sigmoid Linear Unit: x × sigmoid(x)

=item * down - Linear projection back to model dimension

=back

Typical dimensions:

    Model       n_embd  FFN_dim   Ratio
    TinyLlama   2048    5632      2.75×
    LLaMA 7B    4096    11008     2.69×
    LLaMA 13B   5120    13824     2.70×

=head1 GENERATION LOOP

The C<generate()> method handles the complete generation loop internally.
For simple use cases:

    use Lugh;
    
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);
    
    my @prompt = $tokenizer->encode("Once upon a time");
    my @generated = $inference->generate(\@prompt,
        max_tokens  => 100,
        temperature => 0.8,
        top_p       => 0.95,
    );
    print $tokenizer->decode(\@generated);

For streaming output:

    my @generated = $inference->generate(\@prompt,
        max_tokens  => 100,
        temperature => 0.8,
        callback    => sub {
            my ($token, $count) = @_;
            print $tokenizer->decode([$token]);
            STDOUT->flush();
            return 0;  # Continue
        },
    );

For manual control (building your own loop):

    my @tokens = $tokenizer->encode($prompt);
    my @generated;
    
    for (1..$max_tokens) {
        my @logits = $inference->forward(tokens => \@tokens);
        my $next = $inference->sample_top_p(\@logits,
            temperature => 0.8,
            top_p => 0.9
        );
        
        last if $next == $tokenizer->eos_id;
        
        push @tokens, $next;
        push @generated, $next;
        
        print $tokenizer->decode([$next]);
        STDOUT->flush();
    }

=head1 PERFORMANCE

=head2 Computation

A single forward pass performs approximately:

    FLOPs ≈ 2 × n_params × n_tokens

For TinyLlama (1.1B params) with 6 tokens:

    2 × 1.1e9 × 6 ≈ 13 GFLOPs

=head2 Memory

During inference, memory is needed for:

=over 4

=item * Model weights (quantized) - Depends on model size and quantization

=item * Activations - O(n_tokens × n_embd × n_layers)

=item * Attention scores - O(n_tokens² × n_heads × n_layers)

=back

=head2 Optimizations

Current implementation:

=over 4

=item * Uses ggml's Metal GPU backend on macOS

=item * Uses Accelerate BLAS for matrix operations

=item * Quantized weights stay quantized during computation

=item * KV cache for incremental decoding (see C<create_kv_cache>)

=item * Memory pools for efficient repeated inference

=item * Batch processing for multiple sequences

=back

=head1 ADVANCED METHODS

=head2 create_memory_pool

    my $pool = $inference->create_memory_pool();

Creates a reusable memory pool for efficient repeated forward passes.
The pool caches backend and allocator resources, avoiding per-call
allocation overhead.

B<Returns:> A Lugh::MemoryPool object.

B<Example:>

    my $pool = $inference->create_memory_pool();
    
    # Efficient repeated forward passes
    for my $text (@texts) {
        my @tokens = $tokenizer->encode($text);
        my @logits = $inference->forward_pool($pool, \@tokens);
        # Process logits...
    }
    
    # Pool automatically cleaned up on destruction
    # Or manually reset for next batch:
    $pool->reset();

=head2 forward_pool

    # Positional form
    my @logits = $inference->forward_pool($pool, \@tokens);
    
    # Named parameter form (required for LoRA)
    my @logits = $inference->forward_pool(
        pool   => $pool,
        tokens => \@tokens,
        lora   => $lora,        # optional: Lugh::LoRA adapter
    );

Runs forward pass using a pre-allocated memory pool. More efficient
than C<forward()> for repeated inference on different inputs.

B<Parameters:>

=over 4

=item * C<pool> or C<$pool> - A Lugh::MemoryPool from C<create_memory_pool()>

=item * C<tokens> or C<\@tokens> - Array reference of token IDs

=item * C<lora> (optional) - A Lugh::LoRA adapter to apply during inference

=back

B<Returns:> A list of logits (one per vocabulary token).

B<Example:>

    my $pool = $inference->create_memory_pool();
    
    # Much more efficient than calling forward() repeatedly
    for my $prompt (@prompts) {
        my @tokens = $tokenizer->encode($prompt);
        my @logits = $inference->forward_pool($pool, \@tokens);
        my $next_token = $inference->sample_top_p(\@logits, top_p => 0.9);
        print $tokenizer->decode([$next_token]), "\n";
    }
    
    # With LoRA adapter
    my $lora = Lugh::LoRA->new(adapter => 'adapter.gguf', model => $model);
    for my $prompt (@prompts) {
        my @tokens = $tokenizer->encode($prompt);
        my @logits = $inference->forward_pool(
            pool   => $pool,
            tokens => \@tokens,
            lora   => $lora,
        );
        # ...
    }

=head2 forward_batch

    # Positional form
    my $results = $inference->forward_batch(\@sequences);
    
    # Named parameter form (required for LoRA or per-sequence caches)
    my $results = $inference->forward_batch(
        sequences => \@sequences,
        lora      => $lora,      # optional: Lugh::LoRA adapter
        caches    => \@caches,   # optional: per-sequence KV caches
    );

Processes multiple token sequences, returning logits for each.
Each sequence is processed independently with shared backend resources.

B<Parameters:>

=over 4

=item * C<sequences> or C<\@sequences> - Array reference of array references of token IDs

=item * C<lora> (optional) - A Lugh::LoRA adapter to apply during inference

=item * C<caches> (optional) - Array reference of KV caches, one per sequence.
Must have the same count as sequences. Each sequence will use its corresponding
cache for incremental decoding, allowing parallel continuation of multiple
conversations.

=back

B<Returns:> Array reference of array references of logits.

B<Example:>

    my @seq1 = $tokenizer->encode("Hello");
    my @seq2 = $tokenizer->encode("World");
    my @seq3 = $tokenizer->encode("Test");
    
    my $results = $inference->forward_batch([\@seq1, \@seq2, \@seq3]);
    
    # $results->[0] is logits for seq1
    # $results->[1] is logits for seq2
    # $results->[2] is logits for seq3
    
    for my $i (0 .. $#$results) {
        my @logits = @{$results->[$i]};
        my $next = $inference->sample_top_p(\@logits, top_p => 0.9);
        print "Sequence $i next token: ", $tokenizer->decode([$next]), "\n";
    }
    
    # With LoRA adapter
    my $lora = Lugh::LoRA->new(adapter => 'adapter.gguf', model => $model);
    my $results = $inference->forward_batch(
        sequences => [\@seq1, \@seq2, \@seq3],
        lora      => $lora,
    );
    
    # With per-sequence caches for incremental decoding
    my $cache1 = $inference->create_kv_cache();
    my $cache2 = $inference->create_kv_cache();
    
    # First pass - encode prompts
    my $results = $inference->forward_batch(
        sequences => [\@seq1, \@seq2],
        caches    => [$cache1, $cache2],
    );
    
    # Each cache now contains the KV state for its sequence
    # Continue decoding with new tokens
    my @next1 = ($inference->sample_top_p($results->[0], top_p => 0.9));
    my @next2 = ($inference->sample_top_p($results->[1], top_p => 0.9));
    
    my $results2 = $inference->forward_batch(
        sequences => [\@next1, \@next2],
        caches    => [$cache1, $cache2],
    );

=head2 Convenience Methods

The following convenience methods are thin wrappers around the unified
C<_forward_unified()> function, providing simpler APIs for common use cases:

=head3 forward_simple

    my @logits = $inference->forward_simple(\@tokens);

Simplest forward pass - just tokens, no cache, pool, or adapters.

=head3 forward_pool

    my @logits = $inference->forward_pool($pool, \@tokens);
    my @logits = $inference->forward_pool($pool, \@tokens, lora => $lora);

Forward pass using a memory pool for efficient compute resource reuse.

=head3 forward_cache

    my @logits = $inference->forward_cache($cache, \@tokens);
    my @logits = $inference->forward_cache($cache, \@tokens, rope => $rope);

Forward pass with KV cache for incremental decoding.

=head3 forward_cache_pool

    my @logits = $inference->forward_cache_pool($cache, $pool, \@tokens);

Forward pass combining KV cache and memory pool for maximum efficiency.

=head3 forward_batch_pool

    my $results = $inference->forward_batch_pool($pool, \@sequences);

Batch processing with memory pool for high-throughput inference.

=head2 Unified Forward API

For full control, use the unified C<_forward_unified()> XS function directly:

    my @logits = $inference->_forward_unified(
        tokens    => \@tokens,      # OR sequences => \@seqs
        cache     => $cache,        # optional
        pool      => $pool,         # optional
        rope      => $rope,         # optional
        lora      => $lora,         # optional
    );

=head1 MEMORY POOL

The Lugh::MemoryPool class provides reusable compute resources:

=head2 reset

    $pool->reset();

Resets the memory pool for reuse. Frees and reallocates the
compute context. Called automatically by C<forward_pool()>.

B<Returns:> True on success.

=head2 backend

    my $backend_name = $pool->backend();

Returns the name of the backend used by this pool (e.g., "Metal", "CPU").

=head1 THREAD SAFETY

Lugh::Inference objects are NOT thread-safe. Each Perl thread must
create its own Inference object.

=head1 SEE ALSO

L<Lugh>, L<Lugh::Model>, L<Lugh::Tokenizer>

L<https://arxiv.org/abs/1706.03762> - "Attention Is All You Need"

L<https://arxiv.org/abs/2104.09864> - RoPE paper

L<https://arxiv.org/abs/2002.05202> - SwiGLU activation

L<https://arxiv.org/abs/2305.13245> - GQA paper

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
