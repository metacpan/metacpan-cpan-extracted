package Lugh::Model;

use strict;
use warnings;

=head1 NAME

Lugh::Model - GGUF Model Loading and Tensor Access

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.05';

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

=back

B<Returns:> A Lugh::Model object.

B<Throws:> Dies if the file cannot be loaded or is not a valid GGUF file.

B<Example:>

    my $model = Lugh::Model->new(
        model => '/models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf'
    );

=head1 METHODS

=head2 filename

    my $path = $model->filename;

Returns the path to the loaded GGUF file.

=head2 architecture

    my $arch = $model->architecture;

Returns the model architecture string (e.g., "llama", "gpt2", "falcon").
Returns "unknown" if the architecture is not specified in the model.

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

=item * C<general.architecture> - Model architecture (e.g., "llama")

=item * C<general.name> - Model name

=item * C<general.quantization_version> - Quantization format version

=back

=head2 Architecture-specific (llama)

=over 4

=item * C<llama.block_count> - Number of transformer layers

=item * C<llama.embedding_length> - Hidden dimension (n_embd)

=item * C<llama.attention.head_count> - Number of attention heads

=item * C<llama.attention.head_count_kv> - Number of KV heads (for GQA)

=item * C<llama.attention.layer_norm_rms_epsilon> - RMSNorm epsilon

=item * C<llama.context_length> - Maximum context length

=item * C<llama.feed_forward_length> - FFN intermediate dimension

=item * C<llama.vocab_size> - Vocabulary size

=item * C<llama.rope.dimension_count> - RoPE rotation dimensions

=item * C<llama.rope.freq_base> - RoPE frequency base (10000 for llama)

=back

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

=over 4

=item * C<token_embd.weight> - Token embedding matrix [n_embd, n_vocab]

=item * C<output.weight> - Output projection [n_vocab, n_embd]

=item * C<output_norm.weight> - Final layer norm

=item * C<blk.N.attn_norm.weight> - Attention layer norm for layer N

=item * C<blk.N.attn_q.weight> - Query projection for layer N

=item * C<blk.N.attn_k.weight> - Key projection for layer N

=item * C<blk.N.attn_v.weight> - Value projection for layer N

=item * C<blk.N.attn_output.weight> - Attention output projection

=item * C<blk.N.ffn_norm.weight> - FFN layer norm

=item * C<blk.N.ffn_gate.weight> - FFN gate projection (SwiGLU)

=item * C<blk.N.ffn_up.weight> - FFN up projection

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
