package Lugh::RoPE;

use strict;
use warnings;

use Lugh;

our $VERSION = '0.11';

1;

__END__

=head1 NAME

Lugh::RoPE - RoPE (Rotary Position Embedding) Scaling Configuration

=head1 SYNOPSIS

    use Lugh::RoPE;
    
    # Create a default (no scaling) config
    my $rope = Lugh::RoPE->new();
    
    # Linear scaling: extend 4K context to 16K
    my $rope = Lugh::RoPE->linear(4096, 16384);
    
    # YaRN scaling: extend 4K context to 32K
    my $rope = Lugh::RoPE->yarn(4096, 32768);
    
    # Use presets
    my $rope = Lugh::RoPE->linear_2x(4096);   # 4K -> 8K
    my $rope = Lugh::RoPE->linear_4x(4096);   # 4K -> 16K
    my $rope = Lugh::RoPE->yarn_32k(4096);    # 4K -> 32K
    my $rope = Lugh::RoPE->yarn_64k(4096);    # 4K -> 64K
    my $rope = Lugh::RoPE->yarn_128k(4096);   # 4K -> 128K
    
    # Manual configuration with all parameters
    my $rope = Lugh::RoPE->new(
        scaling_type => 'yarn',
        n_ctx_orig   => 4096,
        target_ctx   => 32768,
        freq_base    => 10000.0,
        ext_factor   => -1.0,     # -1 = auto-compute
        attn_factor  => 1.0,
        beta_fast    => 32.0,
        beta_slow    => 1.0,
    );
    
    # Use with inference
    $inference->forward($model, $tokens, { rope => $rope });
    
    # Query configuration
    say $rope->scaling_type_name;  # "yarn"
    say $rope->freq_scale;         # 0.125 (4096/32768)

=head1 DESCRIPTION

Lugh::RoPE provides configuration for RoPE (Rotary Position Embedding)
scaling, enabling models to handle context lengths beyond their training
limit.

=head2 Scaling Methods

=over 4

=item * B<none> - No scaling, use original context length

=item * B<linear> - Simple frequency interpolation. Works well for 2-4x extensions.

=item * B<yarn> - YaRN (Yet another RoPE extensioN). Combines NTK interpolation
with attention temperature scaling. Better for larger extensions (4-16x+).

=item * B<longrope> - LongRoPE method (experimental)

=back

=head1 CONSTRUCTORS

=head2 new

    my $rope = Lugh::RoPE->new(%options);

Create a new RoPE configuration with explicit parameters.

Options:

=over 4

=item scaling_type

Type of scaling: 'none', 'linear', 'yarn', or 'longrope'. Can also use
constants: ROPE_SCALING_NONE, ROPE_SCALING_LINEAR, etc.

=item n_ctx_orig

Original training context length.

=item target_ctx

Target extended context length.

=item freq_base

Base frequency for RoPE. Default 0 (use model's value).

=item freq_scale

Frequency scaling factor. Auto-computed from n_ctx_orig/target_ctx if not set.

=item ext_factor

YaRN extension factor. -1.0 = auto-compute.

=item attn_factor

YaRN attention temperature factor. Default 1.0.

=item beta_fast

YaRN high-frequency boundary. Default 32.0.

=item beta_slow

YaRN low-frequency boundary. Default 1.0.

=back

=head2 none

    my $rope = Lugh::RoPE->none();

Create a no-scaling configuration. Uses model's original context.

=head2 linear

    my $rope = Lugh::RoPE->linear($n_ctx_orig, $target_ctx);

Create linear scaling configuration.

=head2 yarn

    my $rope = Lugh::RoPE->yarn($n_ctx_orig, $target_ctx, %yarn_opts);

Create YaRN scaling configuration. Optional YaRN parameters:

    my $rope = Lugh::RoPE->yarn(4096, 32768,
        beta_fast => 16.0,
        beta_slow => 2.0,
    );

=head1 PRESETS

Convenient methods for common configurations:

=head2 linear_2x

    my $rope = Lugh::RoPE->linear_2x($n_ctx_orig);

Linear scaling to 2x original context.

=head2 linear_4x

    my $rope = Lugh::RoPE->linear_4x($n_ctx_orig);

Linear scaling to 4x original context.

=head2 yarn_32k

    my $rope = Lugh::RoPE->yarn_32k($n_ctx_orig);

YaRN scaling to 32K context.

=head2 yarn_64k

    my $rope = Lugh::RoPE->yarn_64k($n_ctx_orig);

YaRN scaling to 64K context.

=head2 yarn_128k

    my $rope = Lugh::RoPE->yarn_128k($n_ctx_orig);

YaRN scaling to 128K context.

=head2 from_model

    my $rope = Lugh::RoPE->from_model($model);

Extract RoPE configuration from a model's GGUF metadata. This reads all
RoPE-related parameters that were stored when the model was created,
including:

=over 4

=item * Scaling type (none, linear, yarn, longrope)

=item * Original and target context lengths

=item * Frequency base and scale

=item * YaRN parameters (ext_factor, attn_factor, beta_fast, beta_slow)

=back

Example:

    use Lugh::Model;
    use Lugh::RoPE;
    
    my $model = Lugh::Model->new(file => 'model.gguf');
    my $rope = Lugh::RoPE->from_model($model);
    
    say "Model uses ", $rope->scaling_type_name, " scaling";
    say "Original context: ", $rope->n_ctx_orig;
    
    # Use extracted config (or override with forward())
    $inference->forward(tokens => \@tokens, rope => $rope);

=head1 ACCESSORS

All accessors are read-only:

=over 4

=item scaling_type - Returns integer constant

=item scaling_type_name - Returns string: 'none', 'linear', 'yarn', 'longrope'

=item n_ctx_orig - Original context length

=item target_ctx - Target context length

=item freq_base - Base frequency

=item freq_scale - Frequency scale factor

=item ext_factor - YaRN extension factor

=item attn_factor - YaRN attention factor

=item beta_fast - YaRN beta fast

=item beta_slow - YaRN beta slow

=back

=head1 CONSTANTS

    use Lugh::RoPE;
    
    Lugh::RoPE::ROPE_SCALING_NONE()      # 0
    Lugh::RoPE::ROPE_SCALING_LINEAR()    # 1
    Lugh::RoPE::ROPE_SCALING_YARN()      # 2
    Lugh::RoPE::ROPE_SCALING_LONGROPE()  # 3

=head1 TECHNICAL DETAILS

=head2 Linear Scaling

Simple frequency interpolation:

    freq_scale = n_ctx_orig / target_ctx

The RoPE frequencies are divided by the scale factor, allowing positions
beyond the training length to map to the trained frequency range.

=head2 YaRN Scaling

YaRN (Yet another RoPE extensioN) uses a more sophisticated approach:

=over 4

=item 1. NTK-aware interpolation that preserves high-frequency components

=item 2. Attention temperature scaling to compensate for entropy changes

=item 3. Smooth blending between scaled and unscaled frequencies

=back

Parameters:

=over 4

=item * B<ext_factor>: Controls interpolation strength. -1 = auto-compute based
on scale ratio.

=item * B<attn_factor>: Attention temperature scaling. 1.0 = no scaling.

=item * B<beta_fast>: High-frequency boundary (above this, minimal scaling)

=item * B<beta_slow>: Low-frequency boundary (below this, full scaling)

=back

=head1 SEE ALSO

L<Lugh>, L<Lugh::Inference>, L<Lugh::Model>

Paper references:

=over 4

=item * YaRN: L<https://arxiv.org/abs/2309.00071>

=item * NTK-aware: L<https://arxiv.org/abs/2306.15595>

=back

=head1 AUTHOR

Lugh Authors

=head1 LICENSE

Same as Perl itself.

=cut
