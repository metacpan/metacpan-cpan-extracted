package Lugh::Tokenizer;

use strict;
use warnings;
use Lugh;

=head1 NAME

Lugh::Tokenizer - BPE Tokenizer for Text Encoding and Decoding

=encoding utf8

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Lugh;
    
    # Create tokenizer from a model
    my $model = Lugh::Model->new(model => '/path/to/model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    
    # Encode text to tokens
    my @tokens = $tokenizer->encode("Hello, world!");
    # Returns: (1, 15043, 29892, 3186, 29991)
    #          BOS, Hello, ",", world, "!"
    
    # Encode without BOS token
    my @tokens = $tokenizer->encode("Hello", add_bos => 0);
    
    # Decode tokens back to text
    my $text = $tokenizer->decode(@tokens);
    my $text = $tokenizer->decode(\@tokens);  # Array ref also works
    
    # Get vocabulary information
    my $vocab_size = $tokenizer->n_vocab;  # 32000 for LLaMA
    my $bos = $tokenizer->bos_id;          # 1
    my $eos = $tokenizer->eos_id;          # 2

=head1 DESCRIPTION

Lugh::Tokenizer provides text tokenization using BPE (Byte Pair Encoding)
with vocabulary loaded from a GGUF model file. It supports encoding text
to token IDs and decoding token IDs back to text.

The tokenizer uses a greedy longest-match algorithm for encoding, which
is efficient but may not produce optimal tokenization in all cases. For
most use cases with LLaMA-style models, this produces correct results.

=head2 SentencePiece Compatibility

The tokenizer handles SentencePiece's special underscore prefix (▁) which
represents a word boundary (space before the word). When encoding:

    "Hello world" → tokens for "▁Hello" and "▁world"

When decoding, the ▁ prefix is converted back to a space:

    token "▁Paris" → " Paris"

=head2 Special Tokens

Most models include special tokens:

=over 4

=item * B<BOS> (Beginning of Sequence) - Added at start of input

=item * B<EOS> (End of Sequence) - Indicates generation should stop

=item * B<UNK> (Unknown) - Used for characters not in vocabulary

=back

These are typically:

    <s>   - BOS (ID 1)
    </s>  - EOS (ID 2)
    <unk> - UNK (ID 0)

=head1 CONSTRUCTOR

=head2 new

    my $tokenizer = Lugh::Tokenizer->new(
        model => $model
    );

Creates a new Tokenizer from a loaded model.

B<Parameters:>

=over 4

=item * C<model> (required) - A Lugh::Model object

=back

B<Returns:> A Lugh::Tokenizer object.

B<Throws:> Dies if no model is provided or if the model has no vocabulary.

B<Example:>

    my $model = Lugh::Model->new(model => 'model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);

=head1 METHODS

=head2 encode

    my @tokens = $tokenizer->encode($text);
    my @tokens = $tokenizer->encode($text, add_bos => 0);

Encodes text into a sequence of token IDs.

B<Parameters:>

=over 4

=item * C<$text> - The text string to encode

=item * C<add_bos> - Whether to prepend BOS token (default: 1)

=back

B<Returns:> A list of token IDs.

B<Algorithm:>

The encoder uses greedy longest-match tokenization:

=over 4

=item 1. Start at the beginning of the text

=item 2. Try to match the longest possible token

=item 3. For word boundaries (after space/start), try with ▁ prefix first

=item 4. If no match found, emit UNK and skip one character

=item 5. Repeat until end of text

=back

B<Example:>

    my @tokens = $tokenizer->encode("The capital of France is");
    # Returns: (1, 450, 7483, 310, 3444, 338)
    #          BOS, The, capital, of, France, is
    
    # Without BOS:
    my @tokens = $tokenizer->encode("Paris", add_bos => 0);
    # Returns: (3681)  # Just "▁Paris"

=head2 decode

    my $text = $tokenizer->decode(@token_ids);
    my $text = $tokenizer->decode(\@token_ids);

Decodes a sequence of token IDs back to text.

B<Parameters:>

=over 4

=item * C<@token_ids> - List of token IDs, or an array reference

=back

B<Returns:> The decoded text string.

B<Notes:>

=over 4

=item * Special tokens (C<< <s> >>, C<< </s> >>, etc.) are skipped

=item * SentencePiece ▁ prefix is converted to space

=item * Unknown token IDs return empty string for that position

=back

B<Example:>

    my $text = $tokenizer->decode(3681);
    # Returns: " Paris"
    
    my $text = $tokenizer->decode(1, 15043, 29892, 3186);
    # Returns: "Hello, world"  (BOS token skipped)
    
    # Array reference syntax:
    my $text = $tokenizer->decode([3681, 338]);
    # Returns: " Paris is"

=head2 n_vocab

    my $size = $tokenizer->n_vocab;

Returns the vocabulary size.

B<Example:>

    print "Vocabulary: ", $tokenizer->n_vocab, " tokens\n";
    # Vocabulary: 32000 tokens

=head2 bos_id

    my $id = $tokenizer->bos_id;

Returns the BOS (Beginning of Sequence) token ID.

=head2 eos_id

    my $id = $tokenizer->eos_id;

Returns the EOS (End of Sequence) token ID.

=head1 TOKEN TYPES

Different types of tokens in the vocabulary:

=head2 Regular Tokens

Normal subword units:

    "hello"  → Single token
    "▁world" → Word with space prefix
    "ing"    → Common suffix

=head2 Special Tokens

Control tokens with special meaning:

    <s>     → BOS (beginning of sequence)
    </s>    → EOS (end of sequence)
    <unk>   → Unknown token
    <pad>   → Padding token

=head2 Byte Fallback Tokens

For characters not in vocabulary (LLaMA models):

    <0x00> through <0xFF>  → Raw byte tokens

This allows encoding any UTF-8 text, even with unseen characters.

=head1 COMMON PATTERNS

=head2 Basic Tokenization

    my $model = Lugh::Model->new(model => $path);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    
    my @tokens = $tokenizer->encode("Hello, world!");
    print "Tokens: @tokens\n";
    
    my $decoded = $tokenizer->decode(@tokens);
    print "Decoded: $decoded\n";

=head2 Token Inspection

    # See what each token represents
    my @tokens = $tokenizer->encode("The quick brown fox");
    for my $id (@tokens) {
        my $text = $tokenizer->decode([$id]);
        printf "Token %5d: '%s'\n", $id, $text;
    }

=head2 Chat Template

    # Build a chat prompt (LLaMA 2 format)
    my $prompt = "<s>[INST] <<SYS>>
    You are a helpful assistant.
    <</SYS>>
    
    What is the capital of France? [/INST]";
    
    my @tokens = $tokenizer->encode($prompt, add_bos => 0);

=head2 Streaming Decode

    # Decode one token at a time (for streaming output)
    for my $token (@generated_tokens) {
        my $text = $tokenizer->decode([$token]);
        print $text;
        STDOUT->flush();
    }

=head1 LIMITATIONS

=over 4

=item * B<Greedy Algorithm> - May not produce optimal BPE tokenization

=item * B<No Merge Rules> - Does not use BPE merge rules, just vocabulary lookup

=item * B<UTF-8 Only> - Input text must be valid UTF-8

=item * B<No Normalization> - Does not perform Unicode normalization

=back

For most LLM inference use cases, these limitations do not significantly
impact results.

=head1 THREAD SAFETY

Lugh::Tokenizer objects are NOT thread-safe. Each Perl thread must
create its own Tokenizer object (though they can share the same Model
if created separately in each thread).

=head1 SEE ALSO

L<Lugh>, L<Lugh::Model>, L<Lugh::Inference>

L<https://github.com/google/sentencepiece> - SentencePiece tokenizer

L<https://arxiv.org/abs/1508.07909> - BPE paper

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
