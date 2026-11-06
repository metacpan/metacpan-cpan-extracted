package Langertha::Role::ReasoningEffort;
# ABSTRACT: Role for an engine with a request-side reasoning-effort control
our $VERSION = '0.505';
use Moose::Role;
use Carp qw( carp );
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


has thinking_enabled => (
  is        => 'ro',
  isa       => 'Bool',
  predicate => 'has_thinking_enabled',
);

# The engine attributes are one layer: a contradicting pair croaks at
# construction already, not first at the request build (karr k382), with the
# value object's message. $orig has already turned a list or a HashRef into one
# HashRef. AnthropicBase's `effort` alias of reasoning_effort is mapped by its
# own BUILDARGS wrapper, which may run after this one, so read the alias too.
around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  Langertha::Reasoning->assert_switch_agrees(
    $args->{thinking_enabled},
    defined $args->{reasoning_effort} ? $args->{reasoning_effort} : $args->{effort},
  );
  return $args;
};


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

  my %merged = $self->_reasoning_controls_for(%args);
  return () unless %merged;
  my $fmt = $self->reasoning_wire_format;
  my $reasoning = Langertha::Reasoning->new(
    %merged,
    ( $self->can('chat_model') ? ( model => $self->chat_model ) : () ),
    # The thinking on/off toggle (MiniMax, both Kimi faces) is an
    # endpoint's spelling, not a model's: an engine opts in with
    # _reasoning_thinking_toggle, every other engine serializes a toggle
    # model's id like any unlisted id (ADR 0023 k209 Update, review I1).
    ( $self->can('_reasoning_thinking_toggle') && $self->_reasoning_thinking_toggle
      ? ( thinking_toggle => 1 ) : () ),
  );
  $self->_warn_thinking_enabled_dropped( $fmt, $reasoning->thinking_enabled )
    if $reasoning->drops_thinking_enabled_on($fmt);
  return $reasoning->to($fmt);
}

# Per-request controls (chat_f, karr #46) beat the engine attributes. %args may
# carry effort / thinking_enabled / thinking_budget / thinking_display (or the
# canonical control name reasoning_effort, so the whole controls hash can be
# passed wholesale). thinking_budget and thinking_display layer per key: a key
# %args does not carry falls back to its attribute. effort and thinking_enabled are
# ONE concern (karr k382): a per-request value for either replaces both engine
# attributes, so engine reasoning_effort=high + per-request thinking_enabled=0
# is thinking off, not a contradiction. Only a contradiction within one layer
# croaks (Langertha::Reasoning BUILD). An undef per-request value counts as not
# set, so it neither replaces the engine values nor is sent. thinking_enabled=0
# without an effort is resolved to effort 'none' here as well as in
# Langertha::Reasoning (Langertha::Reasoning::normalize_off_switch, not on a
# budget generation), so readers of the resolved effort (Engine::OpenAI's ADR
# 0025 temperature gate, DeepSeek) see the off switch.
sub _reasoning_controls_for {
  my ( $self, %args ) = @_;
  my $request_sets_switch =
    grep { defined $args{$_} } qw( effort reasoning_effort thinking_enabled );
  my $attr = sub {
    my ( $name, $key ) = @_;
    my $predicate = 'has_' . $name;
    return $self->$predicate ? ( $key => $self->$name ) : ();
  };
  my %merged = (
    ( $request_sets_switch ? (
      ( map { defined $args{$_} ? ( $_ => $args{$_} ) : () } qw( effort thinking_enabled ) ),
      ( defined $args{reasoning_effort} ? ( effort => $args{reasoning_effort} ) : () ),
    ) : (
      $attr->( reasoning_effort => 'effort' ),
      $attr->( thinking_enabled => 'thinking_enabled' ),
    ) ),
    $attr->( thinking_budget  => 'thinking_budget' ),
    $attr->( thinking_display => 'thinking_display' ),
    ( map { exists $args{$_} ? ( $_ => $args{$_} ) : () } qw( thinking_budget thinking_display ) ),
  );
  my $model = $self->can('chat_model') ? $self->chat_model : undef;
  my $normalized = Langertha::Reasoning->normalize_off_switch(
    { %merged, ( defined $model ? ( model => $model ) : () ) } );
  $merged{effort} = $normalized->{effort} if defined $normalized->{effort};
  return %merged;
}

# A switch without an effort level that has no wire form here (karr k382):
# thinking_enabled => 1 on a wire without a level-free on-switch, or => 0 on a
# budget generation (Gemini 2.5), which takes no effort. Never croak: one
# request matrix runs over every engine (Holmgang), so the switch is dropped
# with a carp, once per engine instance, value and wire.
sub _warn_thinking_enabled_dropped {
  my ( $self, $fmt, $on ) = @_;
  $on = 1 unless defined $on;
  my $model = $self->can('chat_model') ? ( $self->chat_model // '' ) : '';
  my $message = ( ref $self ) . ': dropping thinking_enabled => ' . ( $on ? 1 : 0 )
    . ( $on
      ? " -- reasoning wire '" . $fmt . "' has no thinking on-switch without an "
        . "effort level; set reasoning_effort (e.g. 'medium') to turn thinking on"
      : " -- model '" . $model . "' takes a thinking budget, not an effort level, "
        . "so reasoning wire '" . $fmt . "' has no off switch for it; configure "
        . 'thinking_budget instead' );
  my $once = 'thinking_enabled=' . ( $on ? 1 : 0 ) . ' wire=' . $fmt . ' model=' . $model;
  return $self->_langertha_carp( $message, $once ) if $self->can('_langertha_carp');
  carp $message;
  return;
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

version 0.505

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
C<generationConfig.thinkingConfig.thinkingBudget>. On Gemini 3 and Gemini 4
models C<thinking_budget> is rejected — they take C<thinkingLevel>, not the
integer budget (Gemini 4 on Vertex answers a budget with HTTP 400); a
C<thinking_budget> on such a model croaks before the request is built
(L<Langertha::Reasoning/BUILD>), and is never sent. When
unset, no budget field is emitted. (Anthropic legacy C<budget_tokens> is
deliberately not modeled: it 400s on current Claude families.)

=head2 thinking_enabled

Optional explicit thinking on/off switch without an effort level (karr k382),
for servers whose chat template takes a boolean (C<enable_thinking> on
llama.cpp, SGLang and other C<chat_template_kwargs> endpoints). Tri-state: unset
(the default, nothing sent), C<0> or C<1>.

C<0> means the same as C<< reasoning_effort =E<gt> 'none' >> on every wire, and
so it cannot disable thinking where effort C<none> cannot: Gemini 3/4 raise it
to their floor level, OpenAI and Responses models without C<none> (gpt-6,
legacy gpt-5) drop it, GPT-OSS on Ollama raises it to C<low>. On a Gemini 2.5
model (thinking budget, no effort) it is dropped with a carp, once per engine;
a L</thinking_budget> there still goes out.

C<1> without a L</reasoning_effort> is sent only on the C<chat_template_kwargs>
wire (C<enable_thinking =E<gt> true>), on the thinking-toggle endpoints
(MiniMax, Kimi: the model's on-type), on DeepSeek V3.x (C<thinking> enabled)
and on native Ollama (C<think =E<gt> true>, not GPT-OSS); on every other wire
nothing is sent and the engine carps once.

It is the same concern as L</reasoning_effort>. Within one layer the two must
agree -- C<< thinking_enabled =E<gt> 0 >> with an effort other than C<none>, or
C<< thinking_enabled =E<gt> 1 >> with C<none>, croaks: for the engine
attributes at construction, for the per-request controls when the request is
built (L<Langertha::Reasoning/assert_switch_agrees>). Across layers a per-request control (chat_f)
carrying either C<reasoning_effort> or C<thinking_enabled> replaces B<both>
engine attributes, so C<< reasoning_effort =E<gt> 'high' >> on the engine plus a
per-request C<< thinking_enabled =E<gt> 0 >> turns thinking off without a croak.

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
C<openai> | C<anthropic> | C<gemini> | C<responses> | C<chat_template_kwargs>
(C<ollama> exists on L<Langertha::Reasoning/to> but the native Ollama engine
calls it directly). Drives the value-object dispatch in L</reasoning_kwargs>.
The default follows the engine base-class hierarchy: C<OpenAIBase> leaves it at
C<openai>, C<AnthropicBase> overrides to C<anthropic>, C<Gemini> to C<gemini>,
C<OpenAIResponses> to C<responses>, C<LlamaCpp> and C<SGLang> to
C<chat_template_kwargs> (L<Langertha::Reasoning/to_chat_template_kwargs>).

Any other OpenAI-compatible engine opts in at construction, e.g. for a
self-hosted server behind a generic base URL whose chat template reads
C<enable_thinking>:

    my $engine = Langertha::Engine::OpenAI->new(
        url                   => 'http://gpu-box:8000/v1',
        api_key               => 'unused',
        model                 => 'Qwen/Qwen3-32B',
        reasoning_wire_format => 'chat_template_kwargs',
        reasoning_effort      => 'none',
    );

The opt-in stays explicit: C<api.openai.com> rejects request fields it does
not know, so C<chat_template_kwargs> is never sent by default.

=head2 reasoning_kwargs_for

    my %kwargs = $engine->reasoning_kwargs_for( effort => 'high' );
    my %kwargs = $engine->reasoning_kwargs_for( %$controls );

Returns the body kwargs to merge into a chat request for the reasoning
control, serialized for L</reasoning_wire_format> via L<Langertha::Reasoning>.
C<%args> may carry C<effort>, C<thinking_enabled>, C<thinking_budget> and/or
C<thinking_display> (or the canonical control name C<reasoning_effort>, so the
whole controls hash from chat_f can be passed wholesale); keys it does not
carry fall back to the engine attributes, so a per-request control (chat_f,
karr #46) beats the configured attribute. C<thinking_budget> and
C<thinking_display> layer per key; C<effort> and C<thinking_enabled> layer as
one concern -- a per-request value for either replaces both attributes (see
L</thinking_enabled>). A C<thinking_enabled =E<gt> 1> without an effort on a
wire that cannot carry it is dropped with a carp, once per engine. Empty list
when neither a per-request value nor an attribute is set, when the value is unsupported on the engine's
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

Please report bugs and feature requests at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
