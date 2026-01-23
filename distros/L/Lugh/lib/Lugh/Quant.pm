package Lugh::Quant;
use strict;
use warnings;

our $VERSION = '0.12';

# @EXPORT_OK and %EXPORT_TAGS are populated by XS BOOT section

# XS-based import - no Exporter.pm dependency
sub import {
    my $class = shift;
    return unless @_;
    
    my $caller = caller;
    my @to_export;
    
    for my $sym (@_) {
        if ($sym =~ /^:(.+)$/) {
            # Handle tag
            my $tag = $1;
            my $tagged = $Lugh::Quant::EXPORT_TAGS{$tag}
                or Carp::croak("Unknown export tag ':$tag'");
            push @to_export, @$tagged;
        } else {
            # Handle individual symbol
            my %ok = map { $_ => 1 } @Lugh::Quant::EXPORT_OK;
            $ok{$sym} or Carp::croak("'$sym' is not exported by Lugh::Quant");
            push @to_export, $sym;
        }
    }
    
    no strict 'refs';
    for my $sym (@to_export) {
        *{"${caller}::${sym}"} = \&{"Lugh::Quant::${sym}"};
    }
}

require XSLoader;
XSLoader::load('Lugh::Quant', $VERSION);

1;

__END__

=head1 NAME

Lugh::Quant - Quantization utilities for Lugh tensors

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Quant;
    
    # Type constants
    my $type = Lugh::Quant::Q4_K;  # 12
    
    # Or import them
    use Lugh::Quant qw(Q4_K Q8_0 type_info);
    
    # Type information
    say Lugh::Quant::type_name($type);     # "q4_K"
    say Lugh::Quant::type_size($type);     # bytes per block
    say Lugh::Quant::blck_size($type);     # elements per block
    say Lugh::Quant::is_quantized($type);  # 1
    
    # Get all available types
    my @all_types = Lugh::Quant::all_types();
    my @quant_types = Lugh::Quant::all_quantized_types();
    
    # Detailed type info
    my $info = Lugh::Quant::type_info(Lugh::Quant::Q4_K);
    # { type => 12, name => "q4_K", size => 144, blck_size => 256, ... }
    
    # Quantize/dequantize are OO methods on Lugh::Tensor
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    my $f32_tensor = Lugh::Tensor->new_f32($ctx, 256);
    
    # Quantize F32 to Q4_K
    my $q4_tensor = $f32_tensor->quantize($ctx, Lugh::Quant::Q4_K);
    
    # Dequantize back to F32
    my $restored = $q4_tensor->dequantize($ctx);

=head1 DESCRIPTION

B<Lugh::Quant> provides type constants and utilities for working with 
quantized tensors in ggml. Quantization reduces model memory usage and 
can improve inference speed while maintaining acceptable accuracy.

The actual C<quantize()> and C<dequantize()> operations are OO methods
on L<Lugh::Tensor> - this module provides the type constants and 
introspection functions.

=head2 What is Quantization?

Quantization converts floating-point weights (typically F32 or F16) to lower
precision formats. Instead of using 4 bytes per weight (F32), quantized models
might use 4 bits (0.5 bytes) or less per weight.

Key trade-offs:

=over 4

=item * B<Memory> - Quantized models use 4-8x less memory

=item * B<Speed> - Can be faster due to reduced memory bandwidth

=item * B<Accuracy> - Small quality loss, usually imperceptible

=back

=head1 TYPE CONSTANTS

All GGML data types are exposed as constants:

=head2 Float Types

=over 4

=item * C<F32> - 32-bit floating point (4 bytes)

=item * C<F16> - 16-bit floating point (2 bytes)

=item * C<BF16> - Brain float 16 (2 bytes)

=item * C<F64> - 64-bit floating point (8 bytes)

=back

=head2 Integer Types

=over 4

=item * C<I8> - 8-bit signed integer

=item * C<I16> - 16-bit signed integer

=item * C<I32> - 32-bit signed integer

=item * C<I64> - 64-bit signed integer

=back

=head2 Basic Quantization (Legacy)

=over 4

=item * C<Q4_0> - 4-bit quantization, simple

=item * C<Q4_1> - 4-bit quantization with offset

=item * C<Q5_0> - 5-bit quantization

=item * C<Q5_1> - 5-bit quantization with offset

=item * C<Q8_0> - 8-bit quantization

=item * C<Q8_1> - 8-bit quantization with offset

=back

=head2 K-Quant Types (Recommended)

K-quant types provide better quality than legacy types at similar sizes:

=over 4

=item * C<Q2_K> - 2-bit K-quant (~2.5 bits/weight)

=item * C<Q3_K> - 3-bit K-quant (~3.4 bits/weight)

=item * C<Q4_K> - 4-bit K-quant (~4.5 bits/weight) B<(Most Popular)>

=item * C<Q5_K> - 5-bit K-quant (~5.5 bits/weight)

=item * C<Q6_K> - 6-bit K-quant (~6.5 bits/weight)

=item * C<Q8_K> - 8-bit K-quant

=back

=head2 IQ Types (Importance Matrix)

IQ types use importance matrices for optimal quantization at very low bitrates:

=over 4

=item * C<IQ1_S> - 1-bit importance quant

=item * C<IQ1_M> - 1-bit importance quant (mixed)

=item * C<IQ2_XXS> - 2-bit importance quant (extra extra small)

=item * C<IQ2_XS> - 2-bit importance quant (extra small)

=item * C<IQ2_S> - 2-bit importance quant (small)

=item * C<IQ3_XXS> - 3-bit importance quant (extra extra small)

=item * C<IQ3_S> - 3-bit importance quant (small)

=item * C<IQ4_NL> - 4-bit importance quant (non-linear)

=item * C<IQ4_XS> - 4-bit importance quant (extra small)

=back

=head2 Experimental Types

=over 4

=item * C<TQ1_0> - Ternary quantization (1.6 bits/weight)

=item * C<TQ2_0> - Ternary quantization variant

=item * C<MXFP4> - Microscaling FP4 format

=back

=head1 FUNCTIONS

=head2 type_name

    my $name = Lugh::Quant::type_name($type);

Returns the string name of a type (e.g., "q4_K", "f32").

=head2 type_size

    my $bytes = Lugh::Quant::type_size($type);

Returns the size in bytes of one block of this type.

=head2 blck_size

    my $elements = Lugh::Quant::blck_size($type);

Returns the number of elements in one block. For quantized types this is
typically 32 or 256.

=head2 type_sizef

    my $bytes_per_element = Lugh::Quant::type_sizef($type);

Returns the effective size per element as a float (type_size / blck_size).
This is the actual "bits per weight" / 8.

=head2 is_quantized

    my $bool = Lugh::Quant::is_quantized($type);

Returns true if the type is a quantized format (not F32/F16/I32/etc).

=head2 requires_imatrix

    my $bool = Lugh::Quant::requires_imatrix($type);

Returns true if the type requires an importance matrix for optimal
quantization (IQ types).

=head2 row_size

    my $bytes = Lugh::Quant::row_size($type, $n_elements);

Returns the number of bytes needed to store a row of C<$n_elements>.

=head2 type_count

    my $count = Lugh::Quant::type_count();

Returns the total number of defined types (including removed types).

=head2 all_types

    my @types = Lugh::Quant::all_types();

Returns a list of all valid type IDs.

=head2 all_quantized_types

    my @types = Lugh::Quant::all_quantized_types();

Returns a list of all quantized type IDs.

=head2 type_from_name

    my $type = Lugh::Quant::type_from_name("q4_K");

Looks up a type by name. Returns -1 if not found.

=head2 type_info

    my $info = Lugh::Quant::type_info($type);
    # Returns hashref:
    # {
    #     type => 12,
    #     name => "q4_K",
    #     size => 144,
    #     blck_size => 256,
    #     sizef => 0.5625,
    #     is_quantized => 1,
    #     requires_imatrix => 0
    # }

Returns comprehensive information about a type as a hashref.

=head1 TENSOR METHODS

These methods are available on L<Lugh::Tensor> objects:

=head2 Type Inspection

    my $tensor = ...;  # from model or created
    
    say $tensor->type();         # numeric type ID
    say $tensor->type_name();    # "q4_K", "f32", etc.
    say $tensor->type_size();    # bytes per block
    say $tensor->blck_size();    # elements per block
    say $tensor->is_quantized(); # 1 or 0
    say $tensor->nbytes();       # total bytes

=head2 quantize

    my $quantized = $f32_tensor->quantize($ctx, $dest_type);

Quantizes an F32 tensor to the specified quantized type. Returns a new
tensor. The source tensor must be F32.

    use Lugh::Quant qw(Q4_K);
    my $q4 = $tensor->quantize($ctx, Q4_K);

Note: For best results with IQ types, an importance matrix should be used.
This method uses NULL for the importance matrix, which works but may not
give optimal quality for IQ types.

=head2 dequantize

    my $f32_tensor = $quantized_tensor->dequantize($ctx);

Dequantizes a quantized tensor back to F32. Also works with F16 and BF16.
Returns a new F32 tensor.

    my $restored = $q4_tensor->dequantize($ctx);

=head1 QUANTIZATION GUIDE

=head2 Choosing a Quantization Type

For most users, we recommend:

=over 4

=item * B<Q4_K> - Best balance of size and quality (default choice)

=item * B<Q5_K> - Slightly better quality, ~10% larger

=item * B<Q8_0> - Best quality, 2x size of Q4_K

=item * B<Q2_K> or B<IQ2_XS> - Extreme compression, quality loss

=back

=head2 Memory Comparison

For a 7B parameter model:

    F32:   28.0 GB (unquantized)
    F16:   14.0 GB
    Q8_0:   7.0 GB
    Q6_K:   5.5 GB
    Q5_K:   4.8 GB
    Q4_K:   4.0 GB
    Q3_K:   3.4 GB
    Q2_K:   2.7 GB
    IQ2_XS: 2.1 GB

=head2 Quality vs Size Trade-off

    Quality (perplexity):  IQ1 < Q2 < IQ2 < Q3 < Q4 < Q5 < Q6 < Q8 < F16 < F32
    Size (bits/weight):    ~1.5  2.5  2.3   3.4  4.5  5.5  6.5  8.0  16   32

=head1 EXAMPLES

=head2 Inspect Model Quantization

    use Lugh;
    use Lugh::Quant;
    
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $inf = Lugh::Inference->new(model => $model);
    
    # Get tensor info
    my @tensors = $model->tensor_names();
    for my $name (@tensors) {
        my $tensor = $inf->get_tensor($name);
        printf "%s: %s (%d elements, %d bytes)\n",
            $name,
            $tensor->type_name(),
            $tensor->nelements(),
            $tensor->nbytes();
    }

=head2 List All Quantized Types

    use Lugh::Quant;
    
    for my $type (Lugh::Quant::all_quantized_types()) {
        my $info = Lugh::Quant::type_info($type);
        printf "%-10s: %.2f bits/weight%s\n",
            $info->{name},
            $info->{sizef} * 8,
            $info->{requires_imatrix} ? " (needs imatrix)" : "";
    }

=head2 Manual Quantization

    use Lugh;
    use Lugh::Quant qw(Q4_K);
    
    my $ctx = Lugh::Context->new(mem_size => 10 * 1024 * 1024);
    
    # Create F32 tensor with random data
    my $f32 = Lugh::Tensor->new_f32($ctx, 256, 256);  # 256x256 matrix
    # ... fill with data ...
    
    # Quantize to Q4_K (OO style)
    my $q4k = $f32->quantize($ctx, Q4_K);
    
    printf "F32:  %d bytes\n", $f32->nbytes();   # 262144 bytes
    printf "Q4_K: %d bytes\n", $q4k->nbytes();   # ~147456 bytes
    
    # Dequantize back
    my $restored = $q4k->dequantize($ctx);

=head1 SEE ALSO

L<Lugh>, L<Lugh::Model>, L<Lugh::Tensor>

=head1 REFERENCES

=over 4

=item * L<GGML types|https://github.com/ggerganov/ggml/blob/master/include/ggml.h>

=back

=head1 AUTHOR

Robert Acock

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
