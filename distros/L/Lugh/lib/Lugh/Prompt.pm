package Lugh::Prompt;

use strict;
use warnings;

our $VERSION = '0.12';

require XSLoader;
XSLoader::load('Lugh::Prompt', $VERSION);

1;

__END__

=head1 NAME

Lugh::Prompt - Chat Template Formatting for LLM Conversations

=head1 VERSION

Version 0.12

=head1 SYNOPSIS

    use Lugh::Prompt;
    
    # Create prompt formatter for a specific format
    my $prompt = Lugh::Prompt->new(format => 'chatml');
    
    # Or auto-detect from model architecture
    my $prompt = Lugh::Prompt->new(model => $model);
    
    # Format messages into a prompt string
    my $text = $prompt->apply(
        { role => 'system', content => 'You are a helpful assistant.' },
        { role => 'user',   content => 'Hello!' },
    );
    # Returns: "<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n..."
    
    # Shortcut functions
    my $text = Lugh::Prompt::chatml(
        { role => 'user', content => 'Hello!' }
    );
    my $text = Lugh::Prompt::llama3(
        { role => 'user', content => 'Hello!' }
    );

=head1 DESCRIPTION

Lugh::Prompt provides XS-based chat template formatting for various LLM 
chat formats. It converts a list of messages (with role and content) into the 
specific token format expected by different model families.

=head2 Supported Formats

=over 4

=item * B<chatml> - ChatML format used by Qwen, Phi, Yi, and many others

=item * B<llama2> - Llama 2 chat format with [INST] tags

=item * B<llama3> - Llama 3 format with special tokens

=item * B<gemma> - Google Gemma format

=item * B<mistral> - Mistral Instruct format

=item * B<zephyr> - Zephyr format with |role| tags

=item * B<alpaca> - Alpaca instruction format

=item * B<vicuna> - Vicuna chat format

=item * B<raw> - No formatting, just concatenate content

=back

=head1 CONSTRUCTOR

=head2 new

    my $prompt = Lugh::Prompt->new(%options);

Creates a new prompt formatter.

B<Options:>

=over 4

=item * C<format> - Format name (chatml, llama2, llama3, mistral, gemma, etc.)

=item * C<model> - Lugh::Model object to auto-detect format from architecture

=back

=head1 METHODS

=head2 format_name

    my $name = $prompt->format_name;

Returns the name of the format being used.

=head2 apply

    my $text = $prompt->apply(@messages, %options);

Formats a list of messages into a prompt string.

B<Messages:> Each message is a hashref with:

=over 4

=item * C<role> - 'system', 'user', or 'assistant'

=item * C<content> - The message text

=back

B<Options:>

=over 4

=item * C<add_generation_prompt> - Add tokens to prompt assistant response (default: 1)

=item * C<add_bos> - Add BOS token at start (default: 1)

=back

=head2 format_message

    my $text = $prompt->format_message($role, $content);

Formats a single message with its role-specific prefix and suffix.

=head1 CLASS METHODS

=head2 available_formats

    my @formats = Lugh::Prompt->available_formats;

Returns a list of all available format names.

=head2 format_for_architecture

    my $format = Lugh::Prompt->format_for_architecture($arch);

Returns the recommended chat format for a given model architecture.

=head2 has_format

    my $bool = Lugh::Prompt->has_format($name);

Returns true if the named format exists.

=head2 get_format

    my $info = Lugh::Prompt->get_format($name);

Returns a hashref with format details (prefixes, suffixes, tokens).

=head1 SHORTCUT FUNCTIONS

=head2 chatml, llama2, llama3, mistral, gemma, zephyr, alpaca, vicuna, raw

    my $text = Lugh::Prompt::chatml(@messages, %opts);
    my $text = Lugh::Prompt::llama3(@messages, %opts);
    # etc.

Shortcut functions for each format.

=head1 SEE ALSO

L<Lugh>, L<Lugh::Model>, L<Lugh::Inference>

L<https://huggingface.co/docs/transformers/chat_templating> - HuggingFace Chat Templates

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
