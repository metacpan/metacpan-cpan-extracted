package Langertha::Role::ThinkTag;
# ABSTRACT: Configurable think tag filtering for reasoning models
our $VERSION = '0.503';
use Moose::Role;


has think_tag => (
  is => 'ro',
  isa => 'Str',
  default => 'think',
);


has think_tag_filter => (
  is => 'ro',
  isa => 'Bool',
  default => 1,
);


sub filter_think_content {
  my ( $self, $text ) = @_;
  return ($text, undef) unless $self->think_tag_filter && defined $text;
  my ( $open, $close ) = ( '<' . $self->think_tag . '>', '</' . $self->think_tag . '>' );
  my $first_open  = index( $text, $open );
  my $first_close = index( $text, $close );
  # No tag at all: the text is the model's, byte for byte (karr k302).
  return ($text, undef) if $first_open < 0 && $first_close < 0;
  my ( @thinking, @kept );
  my $rest = $text;
  # Orphan closing tag: the chat template (DeepSeek-R1, Qwen3 thinking) put
  # the opening tag into the prompt, so the reply starts inside the thought.
  if ( $first_close >= 0 && ( $first_open < 0 || $first_close < $first_open ) ) {
    my $thought = substr( $rest, 0, $first_close, '' );
    substr( $rest, 0, length $close, '' );
    push @thinking, $thought if length $thought;
    push @kept, '';
  }
  while ( ( my $at = index( $rest, $open ) ) >= 0 ) {
    push @kept, substr( $rest, 0, $at, '' );
    substr( $rest, 0, length $open, '' );
    my $end = index( $rest, $close );
    if ( $end < 0 ) {
      # Unclosed tag: <think>... (rest of text) — model stopped mid-thought
      push @thinking, $rest if length $rest;
      $rest = '';
      last;
    }
    # Matched pair: <think>...</think>
    push @thinking, substr( $rest, 0, $end, '' );
    substr( $rest, 0, length $close, '' );
  }
  push @kept, $rest;
  # Only the whitespace a removed block leaves at either end goes; the line
  # after a leading block keeps its indentation.
  my $filtered = join '', @kept;
  if ( $kept[0] =~ /\A\s*\z/ ) {
    $filtered =~ s/\A\s*\n// or $filtered =~ s/\A\s+//;
  }
  $filtered =~ s/\s+\z// if $kept[-1] =~ /\A\s*\z/;
  my $thinking = @thinking ? join("\n", @thinking) : undef;
  return ($filtered, $thinking);
}


around 'chat_response' => sub {
  my ( $orig, $self, @args ) = @_;
  my $response = $self->$orig(@args);
  return $response unless $self->think_tag_filter;
  my $content = $response->content;
  my ($filtered, $thinking) = $self->filter_think_content($content);
  return $response
    if !defined $thinking && ( $filtered // '' ) eq ( $content // '' );
  return $response->clone_with(
    content => $filtered,
    defined $thinking ? (thinking => $thinking) : (),
  );
};

# Both streaming entry points carry an aggregated thinking string alongside
# content (Role::Chat::aggregate_thinking, filled from the native reasoning
# deltas). Two thinking sources can appear and must not both win: a tag-based
# model inlines its chain-of-thought in <think> tags in the content, while a
# native-reasoning model surfaces it out-of-band as the aggregated string. The
# non-stream `around chat_response` resolves this the same way — tag-extracted
# thinking overrides the native one only when tags were actually present.
around 'simple_chat_stream' => sub {
  my ( $orig, $self, @args ) = @_;
  my ( $content, $thinking ) = $self->$orig(@args);
  if ( $self->think_tag_filter ) {
    my ( $filtered, $tag_thinking ) = $self->filter_think_content($content);
    $content  = $filtered;
    $thinking = $tag_thinking if defined $tag_thinking;
  }
  return wantarray ? ( $content, $thinking ) : $content;
};

around 'chat_stream_realtime_f' => sub {
  my ( $orig, $self, @args ) = @_;
  return $self->$orig(@args)->then(sub {
    my ( $content, $chunks, $timing, $thinking ) = @_;
    return Future->done($content, $chunks, $timing, $thinking)
      unless $self->think_tag_filter;
    my ($filtered, $tag_thinking) = $self->filter_think_content($content);
    $thinking = $tag_thinking if defined $tag_thinking;
    return Future->done($filtered, $chunks, $timing, $thinking);
  });
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ThinkTag - Configurable think tag filtering for reasoning models

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Think tag filter is enabled by default on all engines.
    # <think> tags are automatically stripped and thinking preserved:
    my $response = $engine->simple_chat('Explain quantum computing');
    say $response;                  # clean answer text
    say $response->thinking;        # chain-of-thought (if any)

    # For APIs with native reasoning (DeepSeek, Anthropic, Gemini),
    # thinking is extracted from the API response automatically —
    # no tag filtering needed.

    # Custom tag name (e.g. for models using <reasoning> tags):
    my $engine = Langertha::Engine::vLLM->new(
        url       => $vllm_url,
        model     => 'my-reasoning-model',
        think_tag => 'reasoning',
    );

    # Disable filtering if you want raw output:
    my $engine = Langertha::Engine::OpenAI->new(
        api_key          => $key,
        think_tag_filter => 0,
    );

=head1 DESCRIPTION

This role provides automatic filtering of C<E<lt>thinkE<gt>> tags from LLM
responses. Many reasoning models (DeepSeek R1, QwQ, Hermes with reasoning
enabled) emit chain-of-thought reasoning wrapped in C<E<lt>thinkE<gt>> tags
inline with their response text. This role strips those tags and preserves
the thinking content on the L<Langertha::Response/thinking> attribute.

Composed into L<Langertha::Role::Chat>, so every engine gets it automatically.
The filter handles closed pairs (C<E<lt>thinkE<gt>...E<lt>/thinkE<gt>>),
a closing tag whose opening tag the chat template put into the prompt, and
unclosed tags where the model stopped mid-thought (see
L</filter_think_content>). A response without think tags is left untouched.

For APIs that provide reasoning content natively (DeepSeek C<reasoning_content>,
Anthropic C<thinking> blocks, Gemini C<thought> parts), the thinking is
extracted directly from the API response — no tag filtering needed.

=head2 think_tag

The XML tag name used for thinking content. Defaults to C<think>.
Some models may use different tag names (e.g. C<reasoning>).

=head2 think_tag_filter

When true, C<E<lt>thinkE<gt>...E<lt>/thinkE<gt>> blocks are stripped from
response text. The thinking content is preserved on the
L<Langertha::Response/thinking> attribute for inspection. Defaults to C<1>
(enabled). Set to C<0> to pass think tags through unmodified.

=head2 filter_think_content

    my ($filtered_text, $thinking) = $engine->filter_think_content($text);

Strips C<E<lt>thinkE<gt>...E<lt>/thinkE<gt>> blocks from C<$text>. Handles
three shapes:

=over

=item * closed pairs, anywhere in the text, each one a thinking block;

=item * an orphan closing tag: a C<E<lt>/thinkE<gt>> with no opening tag
before it. Chat templates of DeepSeek-R1 and Qwen3 thinking models put the
opening tag into the prompt, so a server without a reasoning parser returns
C<reasoning...E<lt>/thinkE<gt>answer>; everything before that first closing
tag is thinking;

=item * an unclosed opening tag, where the model stopped mid-thought:
everything from it to the end is thinking.

=back

Nested tags are not balanced (the first closing tag ends a block) and the tag
match is case-sensitive.

Text without any think tag is returned exactly as given, whitespace included.
When blocks were removed, only the whitespace they leave at the start or end
of the text is trimmed; after a leading block, the first content line keeps
its indentation. Returns the filtered text and the extracted thinking content
(or C<undef> if none). Returns the original text unchanged when
L</think_tag_filter> is false.

Streaming callbacks (C<chunk_callback>) see the raw text, tags included; only
the aggregated content and thinking a streaming call returns are filtered.

=head1 SEE ALSO

=over

=item * L<Langertha::Response> - Response object with C<thinking> attribute

=item * L<Langertha::Role::Chat> - Chat role that composes this role

=item * L<Langertha::Engine::NousResearch> - Engine with C<reasoning> attribute for Hermes models

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
