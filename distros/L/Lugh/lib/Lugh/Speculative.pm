package Lugh::Speculative;
use strict;
use warnings;
use Lugh;

our $VERSION = '0.11';

=head1 NAME

Lugh::Speculative - Speculative decoding for faster LLM inference

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Model;
    use Lugh::Tokenizer;
    use Lugh::Inference;
    use Lugh::Speculative;

    # Load main (target) and draft models
    my $main_model  = Lugh::Model->new(model => 'llama-7b.gguf');
    my $draft_model = Lugh::Model->new(model => 'llama-68m.gguf');

    # Create tokenizer (use main model's tokenizer - they should be compatible)
    my $tokenizer = Lugh::Tokenizer->new(model => $main_model);

    # Create inference engines
    my $main_inf  = Lugh::Inference->new(model => $main_model, n_ctx => 512, n_threads => 4);
    my $draft_inf = Lugh::Inference->new(model => $draft_model, n_ctx => 512, n_threads => 4);

    # Create speculative decoder
    my $spec = Lugh::Speculative->new(
        inference   => $main_inf,    # Main/target model
        draft       => $draft_inf,   # Draft model (smaller, faster)
        k           => 4,            # Number of draft tokens per step
        temperature => 0.8,
        top_p       => 0.95,
    );

    # Tokenize prompt
    my @prompt_tokens = $tokenizer->encode("The future of AI is");

    # Seed C RNG for reproducible draft sampling
    Lugh::srand(42);

    # Generate tokens speculatively
    my $output = $spec->generate(\@prompt_tokens, 100);  # Generate up to 100 tokens

    # Decode output
    my $text = $tokenizer->decode($output);

    # Check acceptance rate
    printf "Acceptance rate: %.2f%%\n", $spec->acceptance_rate * 100;
    printf "Tokens drafted: %d\n", $spec->tokens_drafted;
    printf "Tokens accepted: %d\n", $spec->tokens_accepted;

=head1 DESCRIPTION

Lugh::Speculative implements speculative decoding, a technique for accelerating
LLM inference by using a smaller "draft" model to generate candidate tokens
that are then verified in parallel by the larger "main" model.

The key insight is that verifying multiple tokens in parallel with the main model
is much faster than generating them one at a time, as long as the draft model's
predictions are often correct. When the draft model makes a wrong prediction,
only the incorrect tokens need to be regenerated.

=head2 How It Works

=over 4

=item 1. B<Draft Phase>

The draft model generates K candidate tokens autoregressively.

=item 2. B<Verify Phase>

The main model processes all draft tokens in a single forward pass and
computes probabilities for each position.

=item 3. B<Accept/Reject>

Tokens are accepted if the main model assigns them sufficient probability.
The first rejected token and all subsequent tokens are discarded.

=item 4. B<Bonus Token>

After rejection, the main model can sample a corrected token from its
probability distribution, so at least one token is always accepted.

=back

=head2 Performance Benefits

Speculative decoding can provide 2-3x speedup depending on:

=over 4

=item * How well the draft model predicts the main model's outputs

=item * The relative sizes of the draft and main models

=item * The speculation depth K

=back

=head1 METHODS

=head2 new

    my $spec = Lugh::Speculative->new(%options);

Create a new speculative decoder.

Options:

=over 4

=item B<inference> (required)

The main/target Lugh::Inference object (larger model).
Alias: C<main>

=item B<draft> (required)

The draft Lugh::Inference object (smaller, faster model).
Alias: C<draft_inference>

=item B<k> (default: 4)

Speculation depth - number of draft tokens to generate per step.
Valid range: 1-16.
Alias: C<depth>

=item B<temperature> (default: 0.8)

Sampling temperature for both models.

=item B<top_p> (default: 0.95)

Top-p (nucleus) sampling threshold.

=back

=head2 generate

    my $tokens = $spec->generate(\@input_tokens, $max_tokens);

Generate tokens speculatively.

Arguments:

=over 4

=item B<input_tokens>

Array reference of input token IDs (the prompt).

=item B<max_tokens>

Maximum number of tokens to generate (default: 256).

=back

Returns an array reference of generated token IDs.

=head2 step

    my $accepted = $spec->step(\@current_tokens);

Perform one speculation step: draft K tokens, verify, return accepted.

Returns an array reference of accepted token IDs.

=head2 draft_tokens

    my $drafted = $spec->draft_tokens(\@input_tokens, $n_draft);

Generate N draft tokens using the draft model.

Returns an array reference of drafted token IDs.

=head2 verify_tokens

    my $accepted = $spec->verify_tokens(\@input_tokens, \@draft_tokens);

Verify draft tokens using the main model.

Returns an array reference of accepted token IDs.

=head2 init_caches

    my $ok = $spec->init_caches();

Initialize KV caches for both models. Called automatically by C<generate()>.

Returns 1 on success, croaks on failure.

=head2 Accessors

=over 4

=item B<k>

Returns the speculation depth.

=item B<temperature>

Returns the sampling temperature.

=item B<top_p>

Returns the top-p threshold.

=item B<n_vocab>

Returns the vocabulary size (shared between models).

=back

=head2 Statistics

=over 4

=item B<acceptance_rate>

Returns the ratio of accepted to drafted tokens (0.0 - 1.0).

=item B<tokens_drafted>

Returns the total number of tokens drafted.

=item B<tokens_accepted>

Returns the total number of tokens accepted.

=item B<total_steps>

Returns the total number of speculation steps.

=item B<reset_stats>

Reset all statistics counters to zero.

=back

=head1 REQUIREMENTS

=over 4

=item * Both models must have the same vocabulary size

=item * The draft model should be significantly smaller/faster than main model

=item * Models should be compatible (e.g., same tokenizer, similar training)

=back

=head1 SEE ALSO

L<Lugh>, L<Lugh::Inference>, L<Lugh::Model>, L<Lugh::KVCache>

=head1 REFERENCES

=over 4

=item * "Fast Inference from Transformers via Speculative Decoding" 
(Leviathan et al., 2022)

=item * "Accelerating Large Language Model Decoding with Speculative Sampling"
(Chen et al., 2023)

=back

=head1 AUTHOR

lnation C<< <email at example.com> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by lnation.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
