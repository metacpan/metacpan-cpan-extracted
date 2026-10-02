package Langertha::Role::PromptCache;
# ABSTRACT: Role for an engine with a request-side prompt-caching control
our $VERSION = '0.503';
use Moose::Role;
use Langertha::PromptCache;

has prompt_cache => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has prompt_cache_ttl => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_prompt_cache_ttl',
);


has prompt_cache_key => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_prompt_cache_key',
);


has cache_wire_format => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_cache_wire_format',
);

# Defaults to the OpenAI dialect; AnthropicBase overrides the builder. This role
# is composed only on OpenAIBase and AnthropicBase (the two providers with a
# real request-side knob), so those are the only two formats.
sub _build_cache_wire_format { 'openai' }


sub prompt_cache_kwargs_for {
  my ( $self, %args ) = @_;

  # Per-request controls (chat_f, karr #46) beat the engine attributes on a
  # per-key basis: %args may carry prompt_cache / prompt_cache_ttl /
  # prompt_cache_key, and any key it does not carry falls back to the
  # configured attribute.
  my %merged = (
    ( prompt_cache => $self->prompt_cache ),
    ( $self->has_prompt_cache_ttl ? ( prompt_cache_ttl => $self->prompt_cache_ttl ) : () ),
    ( $self->has_prompt_cache_key ? ( prompt_cache_key => $self->prompt_cache_key ) : () ),
    %args,
  );
  # The wire agrees with the capability registry for the routing key (karr
  # #200, ADR 0009): an engine that clears prompt_cache_key does not send it.
  # prompt_cache is deliberately not gated -- the family-wide flag would drop
  # cache_control under an explicit cache_wire_format => 'anthropic' override.
  delete $merged{prompt_cache_key} unless $self->supports('prompt_cache_key');
  return () unless $merged{prompt_cache} || defined $merged{prompt_cache_key};
  return Langertha::PromptCache->new(
    enable => $merged{prompt_cache},
    ( defined $merged{prompt_cache_ttl} ? ( ttl => $merged{prompt_cache_ttl} ) : () ),
    ( defined $merged{prompt_cache_key} ? ( key => $merged{prompt_cache_key} ) : () ),
  )->to( $self->cache_wire_format );
}


sub prompt_cache_kwargs {
  my ( $self ) = @_;
  return $self->prompt_cache_kwargs_for;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::PromptCache - Role for an engine with a request-side prompt-caching control

=head1 VERSION

version 0.503

=head2 prompt_cache

Enable an Anthropic C<cache_control> breakpoint on the request (the top-level
auto-place form). Defaults off. No effect on the OpenAI wire, where caching is
automatic — see L</prompt_cache_key> for the only OpenAI-side lever.

The top-level C<cache_control> Langertha emits is Anthropic's documented
"automatic caching" form: the system applies the cache breakpoint to the last
cacheable block and it consumes one of the four available breakpoints. This is
the intended shape — do not "fix" it into per-block breakpoints.

B<Turning C<prompt_cache> on does not prove a cache write happened.> The minimum
cacheable prefix is model-dependent (roughly 512–4096 tokens depending on the
model), and Anthropic silently processes a shorter prompt B<without> caching —
no error is returned. A 200 response therefore says nothing; only
C<< $response->usage->{cache_creation_input_tokens} >> /
C<cache_read_input_tokens> confirm the cache was actually used.

=head2 prompt_cache_ttl

Optional Anthropic cache time-to-live: C<5m> (the current default when unset)
or C<1h>. Only meaningful together with L</prompt_cache>; the C<1h> window
requires this set explicitly.

=head2 prompt_cache_key

Optional OpenAI C<prompt_cache_key> routing hint. OpenAI prompt caching is
automatic; this only steers which cache shard is used. No effect on the
Anthropic wire. Sent only where C<< $engine->supports('prompt_cache_key') >>;
the self-hosted OpenAI-compatible engines (vLLM, SGLang, llama.cpp, Ollama,
LM Studio) do not advertise it and use L<Langertha::Role::RuntimeKnobs> for
their own prefix-cache controls.

=head2 cache_wire_format

    cache_wire_format => 'anthropic'

The per-engine enum naming which caching dialect this engine speaks —
C<openai> | C<anthropic>. Drives the value-object dispatch in
L</prompt_cache_kwargs>. The default follows the engine base-class hierarchy:
C<OpenAIBase> leaves it at C<openai>, C<AnthropicBase> overrides to
C<anthropic>.

=head2 prompt_cache_kwargs_for

    my %kwargs = $engine->prompt_cache_kwargs_for( prompt_cache => 1 );

Returns the body kwargs to merge into a chat request for the caching control,
serialized for L</cache_wire_format> via L<Langertha::PromptCache>. C<%args> may
carry C<prompt_cache>, C<prompt_cache_ttl> and/or C<prompt_cache_key>; keys it
does not carry fall back to the engine attributes, so a per-request control
(chat_f, karr #46) beats the configured attribute on a per-key basis. Empty
list when nothing applies to the engine's wire (caching off / no key).

A C<prompt_cache_key> the engine does not advertise
(C<< $engine->supports('prompt_cache_key') >> false, e.g. on the self-hosted
OpenAI-compatible servers) is dropped silently, so the request body never
carries a routing key the capability registry says the wire does not honor.
C<prompt_cache> is not gated, so an explicit C<cache_wire_format> override
keeps emitting C<cache_control>.

=head2 prompt_cache_kwargs

    my %kwargs = $engine->prompt_cache_kwargs;

Returns the body kwargs to merge into a chat request for the configured caching
options, serialized for L</cache_wire_format> via L<Langertha::PromptCache>.
Empty list when nothing applies to the engine's wire (caching off / no key).
Delegates to L</prompt_cache_kwargs_for> with no per-request overrides.

=head1 SEE ALSO

=over

=item * L<Langertha::PromptCache> - The value object this role dispatches to

=item * L<Langertha::Role::Capabilities> - Where C<prompt_cache> / C<prompt_cache_key> are registered

=item * L<Langertha::Role::ReasoningEffort> - Sibling request-side reasoning control

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
