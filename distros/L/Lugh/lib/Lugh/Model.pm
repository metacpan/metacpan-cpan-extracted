package Lugh::Model;

use strict;
use warnings;
use Lugh;

=head1 NAME

Lugh::Model - GGUF Model Loading and Tensor Access

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

    use Lugh;
    
    # Load a GGUF model file
    my $model = Lugh::Model->new(
        model => '/path/to/model.gguf'
    );
    
    # Get model information
    print "Architecture: ", $model->architecture, "\n";
    print "Tensors: ", $model->n_tensors, "\n";
    print "Metadata keys: ", $model->n_kv, "\n";
    
    # Access model metadata
    my $n_layers = $model->get_kv('llama.block_count');
    my $n_embd = $model->get_kv('llama.embedding_length');
    my $vocab_size = $model->get_kv('llama.vocab_size');
    
    # List all tensors
    my @names = $model->tensor_names;
    
    # Get tensor information
    my ($type, $n_dims, @shape) = $model->tensor_info('token_embd.weight');
    
    # List all metadata keys
    my @keys = $model->kv_keys;

=head1 DESCRIPTION

Lugh::Model provides an interface for loading and inspecting GGUF model files.
GGUF (GPT-Generated Unified Format) is the standard format for storing 
large language models, used by llama.cpp and related projects.

The model object loads the entire model into memory, including all tensors
with their weights. This allows direct access to model parameters for
inference.

=head2 GGUF Format

GGUF files contain:

=over 4

=item * B<Header> - Magic number, version, tensor count, metadata count

=item * B<Metadata> - Key-value pairs describing the model architecture,
hyperparameters, tokenizer vocabulary, and other configuration

=item * B<Tensor Info> - Name, dimensions, type, and offset for each tensor

=item * B<Tensor Data> - The actual weight data, potentially quantized

=back

=head2 Supported Quantization Types

The model loader supports all ggml quantization types, including:

=over 4

=item * B<F32, F16, BF16> - Full/half precision floats

=item * B<Q4_0, Q4_1, Q4_K_S, Q4_K_M> - 4-bit quantization

=item * B<Q5_0, Q5_1, Q5_K_S, Q5_K_M> - 5-bit quantization

=item * B<Q8_0, Q8_1, Q8_K> - 8-bit quantization

=item * B<Q2_K, Q3_K_S, Q3_K_M, Q3_K_L> - 2-3 bit quantization

=item * B<Q6_K> - 6-bit quantization

=item * B<IQ1_S, IQ2_XXS, IQ2_XS, IQ2_S, IQ3_XXS, IQ3_XS, IQ3_S, IQ4_NL, IQ4_XS> - i-quants

=back

=head1 CONSTRUCTOR

=head2 new

    my $model = Lugh::Model->new(
        model => '/path/to/model.gguf'
    );

Creates a new Model object by loading a GGUF file.

B<Parameters:>

=over 4

=item * C<model> (required) - Path to the GGUF model file. Also accepts
C<file> or C<path> as aliases.

=item * C<use_mmap> (optional) - If true, use memory-mapped I/O to load the
model file. This allows the OS to share read-only pages across processes,
significantly reducing memory usage for multi-process deployments.
Defaults to false (0) for backward compatibility. Also accepts C<mmap>
as an alias.

=item * C<prefetch> (optional) - If true and C<use_mmap> is enabled, advise
the kernel to prefetch the entire file into memory during loading. This can
improve inference speed at the cost of longer initial load time.
Defaults to true (1).

=back

B<Returns:> A Lugh::Model object.

B<Throws:> Dies if the file cannot be loaded or is not a valid GGUF file.

B<Examples:>

    # Standard loading (copies file into memory)
    my $model = Lugh::Model->new(
        model => '/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf'
    );

    # Memory-mapped loading (shares pages across processes)
    my $model = Lugh::Model->new(
        model    => '/models/llama-7b.Q4_K_M.gguf',
        use_mmap => 1,
    );

    # Memory-mapped without prefetch (lazy loading)
    my $model = Lugh::Model->new(
        model    => '/models/llama-7b.Q4_K_M.gguf',
        use_mmap => 1,
        prefetch => 0,  # Pages loaded on demand
    );

=head1 METHODS

=head2 filename

    my $path = $model->filename;

Returns the path to the loaded GGUF file.

=head2 architecture

    my $arch = $model->architecture;

Returns the model architecture string (e.g., "llama", "qwen2", "phi3", "gemma2").
Returns "unknown" if the architecture is not specified in the model.

=head2 use_mmap

    my $is_mmap = $model->use_mmap;

Returns true (1) if the model was loaded with memory mapping enabled,
false (0) otherwise.

B<Example:>

    if ($model->use_mmap) {
        print "Model is memory-mapped (fork-safe)\n";
    }

=head2 mmap_size

    my $size = $model->mmap_size;

Returns the size in bytes of the memory-mapped region, or 0 if the model
was not loaded with mmap.

B<Example:>

    my $size = $model->mmap_size;
    printf "Mapped region: %.2f MB\n", $size / (1024 * 1024) if $size;

=head2 mmap_supported

    my $supported = Lugh::Model->mmap_supported;

Class method that returns true (1) if memory mapping is supported on the
current platform, false (0) otherwise. mmap is supported on POSIX systems
(Linux, macOS, *BSD) and Windows.

B<Example:>

    if (Lugh::Model->mmap_supported) {
        print "mmap is available on this platform\n";
    }

=head2 arch_type

    my $type = $model->arch_type;

Returns the numeric architecture type code for optimized dispatch.
This is used internally to determine which inference path to use.

Architecture type codes include:

    0  - UNKNOWN      11 - MPT
    1  - LLAMA        12 - STARCODER  
    2  - QWEN         13 - STABLELM
    3  - QWEN2        14 - INTERNLM
    4  - PHI          15 - DEEPSEEK
    5  - GEMMA        16 - COMMAND_R
    6  - GEMMA2       17 - MAMBA
    7  - GPT2         18 - RWKV
    8  - GPTJ         19 - BERT
    9  - GPTNEOX      20 - T5
    10 - FALCON       21 - BLOOM

B<Example:>

    if ($model->arch_type == 4) {
        print "This is a Phi model\n";
    }

=head2 arch_has_combined_qkv

    my $has_combined = $model->arch_has_combined_qkv;

Returns true (1) if the model architecture uses combined Q/K/V projection
weights in a single tensor, false (0) otherwise.

Models with combined QKV: Phi, Qwen, Qwen2, BLOOM, GPT-2, GPT-J

B<Example:>

    if ($model->arch_has_combined_qkv) {
        print "Model uses combined QKV projections\n";
    }

=head2 arch_has_ffn_gate

    my $has_gate = $model->arch_has_ffn_gate;

Returns true (1) if the model architecture uses a gated FFN (SwiGLU),
false (0) if it uses a standard 2-layer FFN with GELU activation.

Models without FFN gate (use GELU): GPT-2, GPT-J, GPT-NeoX, BLOOM, Falcon, MPT, Phi

B<Example:>

    if (!$model->arch_has_ffn_gate) {
        print "Model uses GELU FFN (no gate)\n";
    }

=head2 arch_has_post_norm

    my $has_post = $model->arch_has_post_norm;

Returns true (1) if the model architecture applies post-normalization
after attention and FFN blocks, false (0) otherwise.

Currently only Gemma2 uses post-normalization.

B<Example:>

    if ($model->arch_has_post_norm) {
        print "Model uses post-normalization (Gemma2-style)\n";
    }

=head2 arch_is_recurrent

    my $is_recurrent = $model->arch_is_recurrent;

Returns true (1) if the model is a recurrent architecture (MAMBA, RWKV),
false (0) for standard transformer architectures.

Note: Recurrent model inference is identified but not yet fully implemented.

B<Example:>

    if ($model->arch_is_recurrent) {
        warn "Recurrent models not yet fully supported\n";
    }

=head2 n_tensors

    my $count = $model->n_tensors;

Returns the number of tensors in the model.

=head2 n_kv

    my $count = $model->n_kv;

Returns the number of metadata key-value pairs in the model.

=head2 tensor_names

    my @names = $model->tensor_names;

Returns a list of all tensor names in the model.

B<Example:>

    my @names = $model->tensor_names;
    # Returns: ('token_embd.weight', 'blk.0.attn_norm.weight', ...)

=head2 tensor_info

    my ($type, $n_dims, $ne0, $ne1, $ne2, $ne3) = $model->tensor_info($name);

Returns information about a specific tensor.

B<Parameters:>

=over 4

=item * C<$name> - The tensor name

=back

B<Returns:> A list containing:

=over 4

=item * C<$type> - The ggml type code (0=F32, 1=F16, etc.)

=item * C<$n_dims> - Number of dimensions (1-4)

=item * C<$ne0, $ne1, $ne2, $ne3> - Size of each dimension

=back

Returns an empty list if the tensor is not found.

B<Example:>

    my ($type, $dims, @shape) = $model->tensor_info('token_embd.weight');
    # For TinyLlama: (2, 2, 2048, 32000, 1, 1)
    # Type 2 = Q4_K, 2D tensor, shape [2048, 32000]

=head2 kv_keys

    my @keys = $model->kv_keys;

Returns a list of all metadata keys in the model.

B<Example:>

    my @keys = $model->kv_keys;
    # Returns: ('general.architecture', 'llama.block_count', ...)

=head2 get_kv

    my $value = $model->get_kv($key);

Returns the value of a metadata key.

B<Parameters:>

=over 4

=item * C<$key> - The metadata key name

=back

B<Returns:> The value as a scalar (string, number, or boolean), or an
array reference for array values. Returns C<undef> if the key is not found.

B<Example:>

    my $n_layers = $model->get_kv('llama.block_count');  # 22 for TinyLlama
    my $n_embd = $model->get_kv('llama.embedding_length');  # 2048
    my $vocab = $model->get_kv('tokenizer.ggml.tokens');  # ['<unk>', '<s>', ...]

=head1 COMMON METADATA KEYS

=head2 General

=over 4

=item * C<general.architecture> - Model architecture (e.g., "llama", "qwen2", "phi3")

=item * C<general.name> - Model name

=item * C<general.quantization_version> - Quantization format version

=back

=head2 Architecture-specific Keys

Metadata keys are prefixed with the architecture name. The architecture is
auto-detected from C<general.architecture> and used to lookup parameters:

B<LLaMA-style (llama, mistral, etc.):>

=over 4

=item * C<{arch}.block_count> - Number of transformer layers

=item * C<{arch}.embedding_length> - Hidden dimension (n_embd)

=item * C<{arch}.attention.head_count> - Number of attention heads

=item * C<{arch}.attention.head_count_kv> - Number of KV heads (for GQA)

=item * C<{arch}.attention.layer_norm_rms_epsilon> - RMSNorm epsilon

=item * C<{arch}.context_length> - Maximum context length

=item * C<{arch}.feed_forward_length> - FFN intermediate dimension

=item * C<{arch}.vocab_size> - Vocabulary size

=item * C<{arch}.rope.dimension_count> - RoPE rotation dimensions

=item * C<{arch}.rope.freq_base> - RoPE frequency base (10000 for llama)

=back

Where C<{arch}> is the architecture name (e.g., "llama", "qwen2", "phi3", "gemma2").

B<Example for different architectures:>

    # LLaMA model
    my $layers = $model->get_kv('llama.block_count');
    
    # Qwen2 model  
    my $layers = $model->get_kv('qwen2.block_count');
    
    # Phi-3 model
    my $layers = $model->get_kv('phi3.block_count');
    
    # Or use architecture() to build the key dynamically
    my $arch = $model->architecture;
    my $layers = $model->get_kv("$arch.block_count");

=head2 Tokenizer

=over 4

=item * C<tokenizer.ggml.model> - Tokenizer type (e.g., "llama", "gpt2")

=item * C<tokenizer.ggml.tokens> - Vocabulary tokens (array)

=item * C<tokenizer.ggml.scores> - Token scores (array)

=item * C<tokenizer.ggml.token_type> - Token types (array)

=item * C<tokenizer.ggml.bos_token_id> - Beginning of sequence token ID

=item * C<tokenizer.ggml.eos_token_id> - End of sequence token ID

=item * C<tokenizer.ggml.unknown_token_id> - Unknown token ID

=item * C<tokenizer.ggml.padding_token_id> - Padding token ID

=back

=head1 TENSOR NAMING CONVENTION

Tensor names follow a standard convention:

=head2 Embedding and Output

=over 4

=item * C<token_embd.weight> - Token embedding matrix [n_embd, n_vocab]

=item * C<output.weight> - Output projection [n_vocab, n_embd]

=item * C<output_norm.weight> - Final layer norm

=back

=head2 Attention Tensors (per layer N)

B<Separate Q/K/V (LLaMA, Mistral, Gemma, etc.):>

=over 4

=item * C<blk.N.attn_norm.weight> - Attention layer norm

=item * C<blk.N.attn_q.weight> - Query projection

=item * C<blk.N.attn_k.weight> - Key projection

=item * C<blk.N.attn_v.weight> - Value projection

=item * C<blk.N.attn_output.weight> - Attention output projection

=back

B<Combined QKV (Phi, Qwen, BLOOM, GPT-2, GPT-J):>

=over 4

=item * C<blk.N.attn_qkv.weight> - Combined Q/K/V projection [3*n_embd, n_embd]

=back

B<Post-normalization (Gemma2):>

=over 4

=item * C<blk.N.attn_post_norm.weight> - Post-attention layer norm

=item * C<blk.N.ffn_post_norm.weight> - Post-FFN layer norm

=back

=head2 FFN Tensors (per layer N)

B<Gated FFN / SwiGLU (LLaMA, Mistral, Qwen, Gemma):>

=over 4

=item * C<blk.N.ffn_norm.weight> - FFN layer norm

=item * C<blk.N.ffn_gate.weight> - FFN gate projection (SwiGLU)

=item * C<blk.N.ffn_up.weight> - FFN up projection

=item * C<blk.N.ffn_down.weight> - FFN down projection

=back

B<Standard FFN / GELU (GPT-2, Falcon, BLOOM, Phi):>

=over 4

=item * C<blk.N.ffn_up.weight> - FFN up projection (no gate)

=item * C<blk.N.ffn_down.weight> - FFN down projection

=back

=head1 THREAD SAFETY

Lugh::Model objects are NOT thread-safe. Each Perl thread must create
its own Model object. The XS code uses a registry pattern with mutex
locks for the global registry, but individual model contexts should
not be shared across threads.

=head1 MEMORY USAGE

Loading a model allocates memory for all tensors. Memory usage depends
on the quantization:

    Model Size    Q4_K_M     Q8_0       F16
    7B params     4.0 GB     7.0 GB     14 GB
    13B params    7.4 GB     13 GB      26 GB
    1.1B params   0.6 GB     1.1 GB     2.2 GB

The memory is freed when the Model object goes out of scope.

=head2 Memory-Mapped Loading

When C<use_mmap =E<gt> 1> is specified, the model file is memory-mapped
instead of being copied into heap memory. This provides several benefits
for multi-process deployments:

=over 4

=item * B<Shared Pages> - The OS can share read-only pages across processes.
If you fork() after loading a model with mmap, child processes share the
same physical memory pages for model weights.

=item * B<Reduced Memory> - Multiple processes loading the same model file
will share physical memory pages, reducing total memory usage.

=item * B<Copy-on-Write> - Forked processes only allocate new memory for
modified pages, not the entire model.

=item * B<Lazy Loading> - With C<prefetch =E<gt> 0>, pages are loaded on
demand as they're accessed, reducing initial load time.

=back

B<Example: Multi-process inference with shared model>

    # Parent process loads model with mmap
    my $model = Lugh::Model->new(
        model    => 'llama-7b.gguf',
        use_mmap => 1,
    );

    # Fork workers - they share model memory pages
    for my $i (1..4) {
        my $pid = fork();
        if ($pid == 0) {
            # Child: model weights are shared via mmap
            my $tokenizer = Lugh::Tokenizer->new(model => $model);
            my $inference = Lugh::Inference->new(model => $model);
            # ... process requests ...
            exit(0);
        }
    }

Note: While model weights are shared, each process still needs its own
Tokenizer and Inference objects, as well as KV caches.

=head1 SEE ALSO

L<Lugh>, L<Lugh::Tokenizer>, L<Lugh::Inference>

L<https://github.com/ggerganov/ggml/blob/master/docs/gguf.md> - GGUF specification

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
