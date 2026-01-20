package Lugh;

use 5.008003;
use strict;
use warnings;

=head1 NAME

Lugh - Pure C LLM Inference Engine for Perl (built on ggml)

=encoding utf8

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Lugh', $VERSION);

=head1 SYNOPSIS

    use Lugh;
    
    # === High-Level API: LLM Inference ===
    
    # Load a GGUF model
    my $model = Lugh::Model->new(
        model => '/path/to/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf'
    );
    
    # Create tokenizer and inference engine
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);
    
    # Encode a prompt
    my @tokens = $tokenizer->encode("The capital of France is");
    
    # Run forward pass to get logits
    my @logits = $inference->forward(\@tokens);
    
    # Find most likely next token (greedy decoding)
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
    
    # === Low-Level API: Tensor Operations ===
    
    # Create a ggml context
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    # Create tensors
    my $a = Lugh::Tensor->new_f32($ctx, 4);
    my $b = Lugh::Tensor->new_f32($ctx, 4);
    
    # Set values
    $a->set_f32(1.0, 2.0, 3.0, 4.0);
    $b->set_f32(5.0, 6.0, 7.0, 8.0);
    
    # Create computation graph
    my $c = Lugh::Ops::add($ctx, $a, $b);
    
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($c);
    $graph->compute($ctx, 4);  # 4 threads
    
    # Get results
    my @result = $c->get_f32();
    print "Result: @result\n";  # 6.0 8.0 10.0 12.0

=head1 DESCRIPTION

Lugh is a pure C LLM inference engine for Perl, built on the ggml tensor
library. It provides both high-level APIs for running large language model
inference and low-level tensor operations for building custom neural
network computations.

Named after the Celtic god of skill and craftsmanship, Lugh aims to provide
complete understanding and control over LLM inference - letting you see
exactly how transformers work under the hood.

=head2 Features

=over 4

=item * B<GGUF Model Loading> - Load quantized models in the standard GGUF format

=item * B<BPE Tokenization> - Encode text to tokens and decode tokens to text

=item * B<Transformer Inference> - Full forward pass with attention, RoPE, FFN

=item * B<Grouped Query Attention> - Support for GQA models (LLaMA 2, Mistral, etc.)

=item * B<Quantization Support> - Run Q4, Q5, Q8 quantized models efficiently

=item * B<Metal GPU Acceleration> - Uses Apple Metal on macOS

=item * B<BLAS Acceleration> - Uses Accelerate/OpenBLAS for matrix operations

=back

=head2 Supported Model Architectures

Lugh automatically detects model architecture from GGUF metadata and adapts
inference accordingly. Supported architectures include:

=over 4

=item * B<LLaMA Family> - LLaMA, LLaMA 2, LLaMA 3, TinyLlama, OpenLLaMA, Mistral, Mixtral

=item * B<Qwen Family> - Qwen, Qwen2 (combined QKV projections)

=item * B<Phi Family> - Phi-2, Phi-3 (combined QKV, GELU activation)

=item * B<Gemma Family> - Gemma, Gemma2 (post-normalization support)

=item * B<GPT Family> - GPT-2, GPT-J, GPT-NeoX

=item * B<Other Architectures> - Falcon, BLOOM, MPT, StarCoder, StableLM, 
InternLM, DeepSeek, Command-R, BERT, T5

=back

The architecture is detected from the C<general.architecture> key in the GGUF
file, and appropriate handling is applied for:

=over 4

=item * B<Combined QKV> - Phi, Qwen, BLOOM, GPT-2, GPT-J use a single QKV tensor

=item * B<FFN Activation> - SiLU/GELU based on architecture (no gate for GPT-2, Phi)

=item * B<Post-Normalization> - Gemma2 applies additional layer norms

=item * B<Recurrent Models> - MAMBA, RWKV identified (inference WIP)

=back

Query architecture information at runtime:

    my $model = Lugh::Model->new(model => 'model.gguf');
    
    print "Architecture: ", $model->architecture, "\n";
    print "Arch type: ", $model->arch_type, "\n";
    print "Has combined QKV: ", $model->arch_has_combined_qkv, "\n";
    print "Has FFN gate: ", $model->arch_has_ffn_gate, "\n";
    print "Has post-norm: ", $model->arch_has_post_norm, "\n";

=head1 PACKAGES

Lugh provides two levels of API:

=head2 High-Level: LLM Inference

=over 4

=item * L<Lugh::Model> - Load GGUF model files and access tensors/metadata

=item * L<Lugh::Tokenizer> - BPE tokenization (encode text, decode tokens)

=item * L<Lugh::Inference> - Transformer forward pass and sampling

=back

=head2 Low-Level: Tensor Operations

=over 4

=item * L<Lugh::Context> - Memory context for tensor allocation

=item * L<Lugh::Tensor> - N-dimensional tensors with various data types

=item * L<Lugh::Ops> - Tensor operations (add, mul, matmul, softmax, etc.)

=item * L<Lugh::Graph> - Computation graph for lazy evaluation

=back

=head1 QUICK START

=head2 Running Inference

    use Lugh;
    
    # Load model
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);
    
    # Generate text
    my @tokens = $tokenizer->encode("Once upon a time");
    
    for (1..50) {  # Generate 50 tokens
        my @logits = $inference->forward(\@tokens);
        
        # Sample next token (greedy)
        my $next = 0;
        my $max = $logits[0];
        for my $i (1..$#logits) {
            if ($logits[$i] > $max) {
                $max = $logits[$i];
                $next = $i;
            }
        }
        
        last if $next == $tokenizer->eos_id;
        
        push @tokens, $next;
        print $tokenizer->decode([$next]);
    }

=head2 Inspecting a Model

    use Lugh;
    
    my $model = Lugh::Model->new(model => 'model.gguf');
    
    print "Architecture: ", $model->architecture, "\n";
    print "Layers: ", $model->get_kv('llama.block_count'), "\n";
    print "Hidden dim: ", $model->get_kv('llama.embedding_length'), "\n";
    print "Heads: ", $model->get_kv('llama.attention.head_count'), "\n";
    print "Vocab: ", $model->get_kv('llama.vocab_size'), "\n";
    
    # List tensors
    for my $name ($model->tensor_names) {
        my ($type, $dims, @shape) = $model->tensor_info($name);
        print "$name: [@shape]\n";
    }

=head1 ARCHITECTURE

    ┌─────────────────────────────────────────────────────┐
    │                    Perl Layer                        │
    │                                                      │
    │  Lugh::Model    Lugh::Tokenizer    Lugh::Inference  │
    │       │               │                  │          │
    └───────┼───────────────┼──────────────────┼──────────┘
            │               │                  │
    ┌───────┼───────────────┼──────────────────┼──────────┐
    │       │         XS Bindings              │          │
    │       ▼               ▼                  ▼          │
    │  GGUF Parser    BPE Tokenizer      Forward Pass     │
    │  Tensor Access  Vocab Lookup       Attention+FFN    │
    │                                                      │
    └─────────────────────────────────────────────────────┘
            │               │                  │
    ┌───────┼───────────────┼──────────────────┼──────────┐
    │       ▼               ▼                  ▼          │
    │                    ggml Library                      │
    │                                                      │
    │  Tensor Ops    RoPE    Attention    Quantization    │
    │                                                      │
    │              Metal GPU    Accelerate BLAS           │
    └─────────────────────────────────────────────────────┘

=head1 TRANSFORMER COMPONENTS

Lugh implements the standard transformer decoder:

=head2 Token Embeddings

Converts token IDs to dense vectors by looking up rows in the
embedding matrix.

=head2 RMSNorm

Root Mean Square Layer Normalization - normalizes without centering:

    RMSNorm(x) = x / sqrt(mean(x²) + ε)

=head2 Rotary Position Embeddings (RoPE)

Encodes position by rotating Q and K vectors. Allows the model to
understand relative positions of tokens.

=head2 Grouped Query Attention (GQA)

Multi-head attention where multiple query heads share fewer key/value
heads, reducing memory and computation:

    # TinyLlama: 32 query heads, 4 KV heads (8:1 ratio)
    Attention(Q, K, V) = softmax(QK^T / √d) × V

=head2 SwiGLU FFN

Feed-forward network with gated activation:

    FFN(x) = down(gate(x) × SiLU(up(x)))

=head1 PERFORMANCE

=head2 Backend Selection

Lugh supports multiple compute backends through the ggml library:

    # List available backends on your system
    my @backends = Lugh::available_backends();
    # Returns: ('Metal', 'BLAS', 'CPU', 'auto')
    
    # Check which backend is best for GPU acceleration
    my $best = Lugh::best_backend();
    # Returns: 'Metal' on macOS with GPU, 'CPU' otherwise
    
    # Get detailed info about a backend
    my $info = Lugh::backend_info('Metal');
    # Returns: { name => 'Metal', type => 'GPU', is_gpu => 1, 
    #            description => 'Apple M1', device_count => 1 }
    
    # Check if a specific backend is available
    if (Lugh::backend_available('Metal')) {
        print "Metal GPU acceleration available!\n";
    }
    
    # Select backend for inference
    my $inference = Lugh::Inference->new(
        model   => $model,
        backend => 'auto',     # auto-select best (default)
        # backend => 'Metal',  # force Metal GPU
        # backend => 'CPU',    # force CPU
    );

Available backends depend on your system and ggml installation:

=over 4

=item * B<Metal> - Apple GPU (macOS only)

=item * B<CUDA> - NVIDIA GPU (requires ggml with CUDA)

=item * B<Vulkan> - Cross-platform GPU

=item * B<BLAS> - Accelerate/OpenBLAS for fast matrix ops

=item * B<CPU> - Always available, uses SIMD

=item * B<auto> - Automatically select the best available

=back

=head2 Backend API Functions

=over 4

=item * C<available_backends()> - List all available backend names

=item * C<backend_count()> - Number of registered backends

=item * C<backend_device_count()> - Total number of available devices

=item * C<backend_info($name)> - Get detailed info about a backend

=item * C<backend_available($name)> - Check if a backend is available

=item * C<best_backend()> - Get the name of the best available backend

=item * C<has_metal()> - Check if Metal is compiled in (macOS)

=item * C<metal_available()> - Check if Metal GPU is available at runtime

=back

=head2 Memory Usage

Memory depends on model size and quantization:

    TinyLlama 1.1B Q4_K_M:  ~650 MB
    LLaMA 7B Q4_K_M:        ~4 GB
    LLaMA 13B Q4_K_M:       ~7.5 GB

=head2 Speed

On Apple Silicon (M1/M2/M3), expect:

    TinyLlama:  ~20-50 tokens/second
    LLaMA 7B:   ~10-20 tokens/second

Speed depends on context length and batch size.

=head1 SEE ALSO

=over 4

=item * L<Lugh::Model> - Model loading

=item * L<Lugh::Tokenizer> - Text tokenization

=item * L<Lugh::Inference> - Forward pass

=item * L<Lugh::Context> - Memory management

=item * L<Lugh::Tensor> - Tensor operations

=item * L<Lugh::Ops> - Math operations

=item * L<Lugh::Graph> - Computation graphs

=back

External resources:

=over 4

=item * L<https://github.com/ggerganov/ggml> - The ggml tensor library

=back

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lugh at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lugh>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc Lugh
    perldoc Lugh::Model
    perldoc Lugh::Tokenizer
    perldoc Lugh::Inference

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by lnation E<lt>email@lnation.orgE<gt>.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Lugh
