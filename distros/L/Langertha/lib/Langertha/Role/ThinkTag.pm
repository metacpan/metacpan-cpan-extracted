package Langertha::Role::ThinkTag;
# ABSTRACT: Configurable think tag filtering for reasoning models
our $VERSION = '0.400';
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
  my $tag = $self->think_tag;
  my @thinking;
  # Matched pairs: <think>...</think>
  $text =~ s{<\Q$tag\E>(.*?)</\Q$tag\E>}{push @thinking, $1; ''}esg;
  # Unclosed tag: <think>... (rest of text) — model stopped mid-thought
  if ($text =~ s{<\Q$tag\E>(.*)$}{}s) {
    push @thinking, $1 if length $1;
  }
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;
  my $thinking = @thinking ? join("\n", @thinking) : undef;
  return ($text, $thinking);
}


around 'chat_response' => sub {
  my ( $orig, $self, @args ) = @_;
  my $response = $self->$orig(@args);
  return $response unless $self->think_tag_filter;
  my ($filtered, $thinking) = $self->filter_think_content($response->content);
  return $response->clone_with(
    content => $filtered,
    defined $thinking ? (thinking => $thinking) : (),
  );
};

around 'simple_chat_stream' => sub {
  my ( $orig, $self, @args ) = @_;
  my $content = $self->$orig(@args);
  return $content unless $self->think_tag_filter;
  my ($filtered, $thinking) = $self->filter_think_content($content);
  return $filtered;
};

around 'simple_chat_stream_realtime_f' => sub {
  my ( $orig, $self, @args ) = @_;
  return $self->$orig(@args)->then(sub {
    my ($content, $chunks) = @_;
    return Future->done($content, $chunks) unless $self->think_tag_filter;
    my ($filtered, $thinking) = $self->filter_think_content($content);
    return Future->done($filtered, $chunks);
  });
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ThinkTag - Configurable think tag filtering for reasoning models

=head1 VERSION

version 0.400

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
The filter handles both closed pairs (C<E<lt>thinkE<gt>...E<lt>/thinkE<gt>>)
and unclosed tags where the model stopped mid-thought.

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
both closed pairs and unclosed tags (where the model stopped mid-thought).
Returns the filtered text and the extracted thinking content (or C<undef> if
none). Returns the original text unchanged when L</think_tag_filter> is false.

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
