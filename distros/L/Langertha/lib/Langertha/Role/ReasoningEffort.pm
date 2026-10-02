package Langertha::Role::ReasoningEffort;
# ABSTRACT: Role for an engine with a request-side reasoning-effort control
our $VERSION = '0.503';
use Moose::Role;
use Langertha::Reasoning;

has reasoning_effort => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_reasoning_effort',
);


has thinking_budget => (
  is        => 'ro',
  isa       => 'Int',
  predicate => 'has_thinking_budget',
);


has thinking_display => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_thinking_display',
);


has reasoning_wire_format => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_reasoning_wire_format',
);

# Defaults to the OpenAI /chat/completions dialect; AnthropicBase, Gemini and
# OpenAIResponses override the builder. Deliberately NOT keyed off
# tool_wire_format — engines sharing tool_wire_format=openai (DeepSeek, MiniMax,
# Groq) disagree on the reasoning field.
sub _build_reasoning_wire_format { 'openai' }


sub reasoning_kwargs_for {
  my ( $self, %args ) = @_;

  # The wire agrees with the capability registry (karr #204, ADR 0009): an
  # engine that advertises neither reasoning control takes none, so nothing
  # is sent. Both flags, not reasoning_effort alone -- Gemini 2.5 clears
  # reasoning_effort per model yet takes thinkingBudget, and its effort croak
  # (ADR 0023) must stay loud.
  return ()
    unless $self->supports('reasoning_effort') || $self->supports('thinking_budget');

  # Per-request controls (chat_f, karr #46) beat the engine attributes on a
  # per-key basis: %args may carry effort / thinking_budget (or the canonical
  # control names reasoning_effort / thinking_budget, so the whole controls
  # hash can be passed wholesale), and any key it does not carry falls back
  # to the configured attribute.
  my %merged = (
    ( $self->has_reasoning_effort ? ( effort => $self->reasoning_effort ) : () ),
    ( $self->has_thinking_budget  ? ( thinking_budget => $self->thinking_budget ) : () ),
    ( $self->has_thinking_display ? ( thinking_display => $self->thinking_display ) : () ),
    ( exists $args{effort} ? ( effort => $args{effort} ) : () ),
    ( exists $args{reasoning_effort} ? ( effort => $args{reasoning_effort} ) : () ),
    ( exists $args{thinking_budget} ? ( thinking_budget => $args{thinking_budget} ) : () ),
    ( exists $args{thinking_display} ? ( thinking_display => $args{thinking_display} ) : () ),
  );
  return () unless %merged;
  return Langertha::Reasoning->new(
    ( exists $merged{effort} ? ( effort => $merged{effort} ) : () ),
    ( exists $merged{thinking_budget} ? ( thinking_budget => $merged{thinking_budget} ) : () ),
    ( exists $merged{thinking_display} ? ( thinking_display => $merged{thinking_display} ) : () ),
    ( $self->can('chat_model') ? ( model => $self->chat_model ) : () ),
    # The thinking on/off toggle (MiniMax, both Kimi faces) is an
    # endpoint's spelling, not a model's: an engine opts in with
    # _reasoning_thinking_toggle, every other engine serializes a toggle
    # model's id like any unlisted id (ADR 0023 k209 Update, review I1).
    ( $self->can('_reasoning_thinking_toggle') && $self->_reasoning_thinking_toggle
      ? ( thinking_toggle => 1 ) : () ),
  )->to( $self->reasoning_wire_format );
}


sub reasoning_kwargs {
  my ( $self ) = @_;
  return $self->reasoning_kwargs_for;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::ReasoningEffort - Role for an engine with a request-side reasoning-effort control

=head1 VERSION

version 0.503

=head2 reasoning_effort

Normalized request-side reasoning effort. Vocabulary (the OpenAI superset):
C<none>, C<minimal>, C<low>, C<medium>, C<high>, C<xhigh>, C<max>. When set, it
is translated to the provider-specific wire field via L<Langertha::Reasoning>
keyed by L</reasoning_wire_format>; values the target wire cannot accept are
dropped. When not set, no reasoning field is emitted and the model's own
default applies.

Note this is a request-side control, distinct from L<Langertha::Role::ThinkTag>
(which filters C<E<lt>thinkE<gt>> tags out of responses).

=head2 thinking_budget

Optional integer thinking budget, currently consumed only by Gemini 2.5 models
(L<Langertha::Engine::Gemini>): on C<gemini-2.5-*> the value is emitted as
C<generationConfig.thinkingConfig.thinkingBudget>. On Gemini 3 models
C<thinking_budget> is rejected — Gemini 3 takes C<thinkingLevel>, not the
integer budget; setting both L</reasoning_effort> and C<thinking_budget> on a
Gemini 3 model croaks at construction (L<Langertha::Reasoning/BUILD>). When
unset, no budget field is emitted. (Anthropic legacy C<budget_tokens> is
deliberately not modeled: it 400s on current Claude families.)

=head2 thinking_display

Optional Anthropic thinking-visibility control (C<summarized> | C<omitted> |
C<updates>), serialized by L<Langertha::Reasoning/to_anthropic> to
C<thinking.display>. On every current Claude model the wire default is
C<omitted>, which returns an empty C<< $response->thinking >>; set
C<thinking_display =E<gt> 'summarized'> to get a readable reasoning summary back
(it costs summary tokens, so it is opt-in rather than the Langertha default).
Ignored on non-Anthropic wires and on Fable-class models (which never carry a
C<thinking> block). Like L</reasoning_effort>, a per-request control (chat_f)
beats this attribute.

=head2 reasoning_wire_format

    reasoning_wire_format => 'anthropic'

The per-engine enum naming which reasoning dialect this engine speaks —
C<openai> | C<anthropic> | C<gemini> | C<responses>. Drives the value-object
dispatch in L</reasoning_kwargs>. The default follows the engine base-class
hierarchy: C<OpenAIBase> leaves it at C<openai>, C<AnthropicBase> overrides to
C<anthropic>, C<Gemini> to C<gemini>, C<OpenAIResponses> to C<responses>.

=head2 reasoning_kwargs_for

    my %kwargs = $engine->reasoning_kwargs_for( effort => 'high' );
    my %kwargs = $engine->reasoning_kwargs_for( %$controls );

Returns the body kwargs to merge into a chat request for the reasoning
control, serialized for L</reasoning_wire_format> via L<Langertha::Reasoning>.
C<%args> may carry C<effort> and/or C<thinking_budget> (or the canonical
control names C<reasoning_effort> / C<thinking_budget>, so the whole controls
hash from chat_f can be passed wholesale); keys it does not carry fall back to
the engine attributes, so a per-request control (chat_f, karr #46) beats the
configured attribute on a per-key basis. Empty list when neither a per-request
value nor an attribute is set, when the value is unsupported on the engine's
wire, or when the engine advertises neither C<reasoning_effort> nor
C<thinking_budget> (L<Langertha::Role::Capabilities/supports>) -- clearing
those flags is how an engine says it takes no reasoning control, and nothing
is sent then. Engines override this only to model wire divergence within a
shared format (e.g. DeepSeek's model-gated split). An engine whose endpoint
speaks the C<thinking> on/off toggle (MiniMax, MiniMaxAnthropic, Moonshot,
MoonshotAnthropic) opts in by defining C<_reasoning_thinking_toggle> as true;
see L<Langertha::Reasoning/thinking_toggle>.

=head2 reasoning_kwargs

    my %kwargs = $engine->reasoning_kwargs;

Returns the body kwargs to merge into a chat request for the configured
C<reasoning_effort> and/or L</thinking_budget>, serialized for
L</reasoning_wire_format> via L<Langertha::Reasoning>. Empty list when neither
is set, or when the value is unsupported on the engine's wire. Delegates to
L</reasoning_kwargs_for> with no per-request overrides.

=head1 SEE ALSO

=over

=item * L<Langertha::Reasoning> - The value object this role dispatches to

=item * L<Langertha::Role::Capabilities> - Where C<reasoning_effort> is registered

=item * L<Langertha::Role::Temperature> - Sibling request-side sampling control

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
