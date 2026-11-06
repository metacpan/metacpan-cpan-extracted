package Langertha::Reasoning;
# ABSTRACT: Immutable normalized reasoning-effort control with cross-provider conversion
our $VERSION = '0.505';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use Langertha::Reasoning::Profile;


# Optional attributes with normal Moose predicates. No `default` / `Maybe[...]`
# so that `has_effort` / `has_thinking_budget` reflect whether the caller
# supplied the field — the standard Moose predicate (true when set, false when
# not set) is what BUILD and the serializers dispatch on.
has effort => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_effort',
);


has model => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_model',
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



has thinking_enabled => (
  is        => 'ro',
  isa       => 'Bool',
  predicate => 'has_thinking_enabled',
);


has thinking_toggle => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


# The resolved reasoning profile (Langertha::Reasoning::Profile) for the
# configured model — the single source for what the model's wire accepts. All
# per-model gating (openai ladder, gemini clamp, fable-class, budget-vs-effort
# control) reads from here instead of the inline hashes/regexes that used to
# live in this file (karr k173). Resolved once, lazily, off the immutable model.
has _profile => (
  is       => 'ro',
  isa      => 'Langertha::Reasoning::Profile',
  lazy     => 1,
  init_arg => undef,
  builder  => '_build_profile',
);

# A thinking-toggle row is the wire truth of the endpoint that opted in
# (thinking_toggle), not of the model id: on every other endpoint it is
# invisible and the id resolves like any unlisted id (review I1).
# The fallback is the provider default, for_model(''), not the next matching
# non-toggle row. That is the same thing only while no non-toggle row matches
# an id a toggle row matches (true today: MiniMax-M2/M3 and the kimi-k2.6 /
# kimi-k2.7-code rows overlap no other row). A broader row covering those ids
# would have to be re-resolved here, skipping has_thinking_on rows (karr k223).
sub _build_profile {
  my ( $self ) = @_;
  my $profile = Langertha::Reasoning::Profile->for_model(
    $self->has_model ? $self->model : '' );
  return Langertha::Reasoning::Profile->for_model('')
    if $profile->has_thinking_on && !$self->thinking_toggle;
  return $profile;
}

# thinking_enabled => 0 without an effort is the off switch every wire already
# knows as effort 'none' (karr k382): normalize it here, before BUILD checks
# the per-generation gates, so the serializers and the ADR 0025 temperature
# gate see one value. A contradicting effort is left alone for BUILD to croak.
around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  return $class->normalize_off_switch( $class->$orig(@args) );
};

sub normalize_off_switch {
  my ( $self, $args ) = @_;
  return $args unless defined $args->{thinking_enabled} && !$args->{thinking_enabled}
    && !defined $args->{effort};
  # A budget-control generation (Gemini 2.5) takes no effort at all, so the
  # off switch cannot become effort 'none' there (it would croak, and collide
  # with a thinking_budget); it stays a bare thinking_enabled => 0, which no
  # serializer of that generation sends and drops_thinking_enabled_on reports.
  # Mapping it to thinkingBudget 0 is not done: which 2.5 models take 0 is
  # unverified.
  my $profile = Langertha::Reasoning::Profile->for_model( $args->{model} // '' );
  return $args if $profile->control eq 'budget';
  return { %$args, effort => 'none' };
}


sub assert_switch_agrees {
  my ( $self, $thinking_enabled, $effort ) = @_;
  return unless defined $thinking_enabled && defined $effort;
  my $effort_on = $effort ne 'none';
  return if $thinking_enabled ? $effort_on : !$effort_on;
  croak "Langertha::Reasoning: thinking_enabled => "
    . ( $thinking_enabled ? 1 : 0 ) . " contradicts effort '"
    . $effort . "' -- thinking off is effort 'none', thinking on is "
    . "any other effort level; set one of them, or make them agree";
}


# Build-time wire-truth gate: exactly one native control per generation, never
# both. Errors here surface before the request is built (Langertha::Engine::Gemini
# calls to() inside chat_request), so a misconfigured engine never produces an
# ambiguous wire form. The budget-vs-effort split derives from the resolved
# profile's control (Gemini 2.5 is the only control=budget family today), so the
# family boundary lives in Langertha::Reasoning::Profile, not in an inline regex.
sub BUILD {
  my ( $self ) = @_;

  $self->assert_switch_agrees(
    ( $self->has_thinking_enabled ? $self->thinking_enabled : undef ),
    ( $self->has_effort ? $self->effort : undef ),
  );

  my $has_effort = $self->has_effort;
  my $has_budget = $self->has_thinking_budget;
  my $model      = $self->has_model ? $self->model : '';

  if ( $has_effort && $has_budget ) {
    croak "Langertha::Reasoning: 'effort' and 'thinking_budget' are mutually "
      . "exclusive — pick one (effort -> thinkingLevel, thinking_budget -> "
      . "thinkingBudget); model='" . $model . "'";
  }

  my $is_budget_control = $self->_profile->control eq 'budget';

  if ( $has_budget && !$is_budget_control ) {
    croak "Langertha::Reasoning: 'thinking_budget' is only valid on Gemini 2.5 "
      . "models (model id starting with 'gemini-2.5'); got model='" . $model . "'";
  }

  if ( $has_effort && $is_budget_control ) {
    croak "Langertha::Reasoning: 'effort' is not valid on Gemini 2.5 models — "
      . "use 'thinking_budget' (integer tokens) instead; got model='"
      . $model . "'";
  }
}

sub to_gemini_level {
  my ( $self ) = @_;
  return $self->_profile->gemini_level_for( $self->effort );
}


# A thinking-toggle model (Profile thinking_on, karr k209/k215) on an endpoint
# that opted in (thinking_toggle: MiniMax, MiniMaxAnthropic, Moonshot,
# MoonshotAnthropic)
# takes a `thinking` object with an on/off type and no effort level, on both the
# openai and the anthropic wire: none -> off where the model can disable (else
# the field is omitted), any other level -> the model's on-type. On any other
# endpoint the same id serializes like the passthrough default (review I1).
# thinking_display rides along on the anthropic wire only, never on an off
# toggle; a display-only request turns the toggle on, as the adaptive path does.
# Whether MiniMax / Kimi accept `display` there is unverified (it is a
# first-party Anthropic field; kept because MiniMaxAnthropic sent it before k209).
sub _thinking_toggle {
  my ( $self, $with_display ) = @_;
  my $profile = $self->_profile;
  my $display = $with_display && $self->has_thinking_display;
  # thinking_enabled without an effort is always 1 here (0 is normalized to
  # effort 'none' in BUILDARGS), so it turns the toggle on (karr k382).
  my $thinking = $self->has_effort ? $profile->thinking_toggle_for( $self->effort )
               : $display || $self->has_thinking_enabled
                                   ? { type => $profile->thinking_on }
               :                     undef;
  return () unless $thinking;
  $thinking = { %$thinking, display => $self->thinking_display }
    if $display && $thinking->{type} ne 'disabled';
  return ( thinking => $thinking );
}

sub to_openai {
  my ( $self ) = @_;
  return $self->_thinking_toggle(0) if $self->_profile->has_thinking_on;
  return () unless $self->has_effort;
  return () unless $self->_profile->effort_accepted_on( 'openai', $self->effort );
  return ( reasoning_effort => $self->effort );
}

sub to_responses {
  my ( $self ) = @_;
  return () unless $self->has_effort;
  return () unless $self->_profile->effort_accepted_on( 'responses', $self->effort );
  return ( reasoning => { effort => $self->effort } );
}


sub to_anthropic {
  my ( $self ) = @_;
  return $self->_thinking_toggle(1) if $self->_profile->has_thinking_on;
  my $e = $self->has_effort ? $self->effort : undef;
  my $effort_ok = defined $e && $self->_profile->anthropic_effort_ok($e);

  # Adaptive-thinking models need thinking:{type:adaptive} or thinking stays
  # off; always-on "Fable-class" models 400 on thinking:{type:disabled} and
  # need no thinking field at all (thinking is always on). thinking.display
  # controls visibility: the wire default is "omitted" on every current model,
  # so $response->thinking comes back empty unless the caller asks for
  # "summarized". We emit the thinking block whenever an effort or a display is
  # in play so a display-only request still turns summaries on.
  my @thinking;
  if ( !$self->_profile->fable_class && ( $effort_ok || $self->has_thinking_display ) ) {
    @thinking = ( thinking => {
      type => 'adaptive',
      ( $self->has_thinking_display ? ( display => $self->thinking_display ) : () ),
    } );
  }

  return (
    ( $effort_ok ? ( output_config => { effort => $e } ) : () ),
    @thinking,
  );
}


sub to_gemini {
  my ( $self ) = @_;
  if ( $self->has_thinking_budget ) {
    # BUILD has already verified the model is Gemini 2.5.
    return ( thinkingConfig => { thinkingBudget => $self->thinking_budget } );
  }
  return () unless $self->has_effort;
  return ( thinkingConfig => { thinkingLevel => $self->to_gemini_level } );
}

sub to_ollama {
  my ( $self ) = @_;
  # A bare thinking_enabled => 1 is the boolean on-switch; GPT-OSS has no
  # level-free form, so nothing there (drops_thinking_enabled_on).
  unless ( $self->has_effort ) {
    return () unless $self->has_thinking_enabled && $self->thinking_enabled
      && !$self->_profile->has_ollama_levels;
    return ( think => JSON->true );
  }
  # GPT-OSS takes graded level STRINGS on the options.think knob
  # (low<medium<high<max) and ALWAYS reasons — there is no "off": think:false is
  # ignored, so a boolean has zero effect and 'none' maps to the floor 'low'.
  # Live-probed 2026-09-17 via ollama.com gpt-oss:20b (k175). Every other model
  # takes only the boolean: any effort level -> on, 'none' -> off.
  return ( think => $self->_profile->ollama_level_for( $self->effort ) )
    if $self->_profile->has_ollama_levels;
  return ( think => $self->effort eq 'none' ? JSON->false : JSON->true );
}


# Self-hosted OpenAI-compatible servers (llama.cpp, SGLang; opt-in for any
# other) switch thinking through the chat template: top-level
# chat_template_kwargs.enable_thinking (karr k382, advisor-validated against the
# llama.cpp / SGLang source). The OpenAI per-model effort ladder is NOT
# consulted -- a self-hosted model id is whatever the operator named it, so the
# effort goes out unclamped. enable_thinking must be a real JSON boolean:
# llama.cpp reacts only to true/false after dumping the kwargs (a 0/1 desyncs
# template and reasoning parser), and a string 400s. 'none' sends no
# reasoning_effort, because older SGLang, gpt-oss and MiniMax-M3 templates 400
# on it.
sub to_chat_template_kwargs {
  my ( $self ) = @_;
  if ( $self->has_effort ) {
    return ( chat_template_kwargs => { enable_thinking => JSON->false } )
      if $self->effort eq 'none';
    return (
      chat_template_kwargs => { enable_thinking => JSON->true },
      reasoning_effort     => $self->effort,
    );
  }
  return () unless $self->has_thinking_enabled;
  return ( chat_template_kwargs => {
    enable_thinking => $self->thinking_enabled ? JSON->true : JSON->false,
  } );
}


sub drops_thinking_enabled_on {
  my ( $self, $fmt ) = @_;
  return 0 unless $self->has_thinking_enabled && !$self->has_effort;
  $fmt //= '';
  return 0 if $fmt eq 'chat_template_kwargs';
  # An off switch left without an effort is one normalize_off_switch kept (a
  # budget generation): no other wire sends it.
  return 1 unless $self->thinking_enabled;
  # The toggle path of to_openai / to_anthropic has an on-type of its own.
  return 0 if $self->_profile->has_thinking_on && ( $fmt eq 'openai' || $fmt eq 'anthropic' );
  # Ollama's boolean think; GPT-OSS takes only levels, so nothing there.
  return 0 if $fmt eq 'ollama' && !$self->_profile->has_ollama_levels;
  return 1;
}


# Maps a reasoning_wire_format tag to the per-format serializer method.
my %TO_METHOD = (
  openai               => 'to_openai',
  responses            => 'to_responses',
  anthropic            => 'to_anthropic',
  gemini               => 'to_gemini',
  ollama               => 'to_ollama',
  chat_template_kwargs => 'to_chat_template_kwargs',
);

sub to {
  my ( $self, $fmt ) = @_;
  my $method = $TO_METHOD{ $fmt // '' }
    or croak "Langertha::Reasoning: unknown reasoning wire format '" . ( $fmt // '' ) . "'";
  return $self->$method;
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Reasoning - Immutable normalized reasoning-effort control with cross-provider conversion

=head1 VERSION

version 0.505

=head1 SYNOPSIS

    my $r = Langertha::Reasoning->new(
        effort => 'high',
        model  => 'claude-opus-4-8',
    );
    my %kwargs = $r->to('anthropic');
    # ( output_config => { effort => 'high' }, thinking => { type => 'adaptive' } )

    # Gemini 2.5 takes an integer thinking_budget instead of a level
    my $rb = Langertha::Reasoning->new(
        thinking_budget => 2048,
        model           => 'gemini-2.5-pro',
    );
    my %kw = $rb->to('gemini');
    # ( thinkingConfig => { thinkingBudget => 2048 } )

=head1 DESCRIPTION

Canonical value object for the request-side reasoning-effort knob, dispatched
by an engine's C<reasoning_wire_format>. Mirrors L<Langertha::Tool> /
L<Langertha::ToolChoice>: the value-set clamping and per-provider placement of
the field live in this one reviewable place rather than scattered across
engines (ADR 0001).

The normalized vocabulary is the OpenAI superset
C<none|minimal|low|medium|high|xhigh|max>. Each C<to_*> serializer clamps that
vocabulary to what the target wire actually accepts and returns the body kwargs
to merge into the request.

The OpenAI clamp is B<model-gated>, not wire-gated: Chat Completions
(C<to_openai>) and the Responses API (C<to_responses>) C<$ref> the identical
C<ReasoningEffort> schema, so both share one per-model gate and can never
diverge for the same model. The accepted set differs per model generation —
gpt-6 (astra) accepts neither C<none> nor C<minimal> (C<low>..C<max>); the
gpt-5.6/gpt-5.5 generation accepts C<none>/C<xhigh>/(C<max>) but not
C<minimal>; the legacy gpt-5 generation accepts C<minimal> but not
C<none>/C<xhigh>/C<max> — so no single wire-level clamp is correct. Unlisted
model ids keep the full vocabulary. See L</to_openai>.

Gemini splits its reasoning knob by model generation: Gemini 3 and Gemini 4
accept a C<thinkingLevel> emitted from C<effort> (vocabulary
C<minimal>|C<low>|C<medium>|C<high>, clamped to the subset the configured
model family accepts — see L</to_gemini_level>); Gemini 2.5 takes a
C<thinkingBudget> integer instead. Exactly one of the two fields is
emitted per request — never both. C<BUILD> rejects every
C<effort>/C<thinking_budget> combination that would produce an ambiguous wire
form (either field on the wrong generation, or both fields together on any
generation). The rule is "exactly one native control per generation",
enforced loudly before any request is built.

Self-hosted OpenAI-compatible servers (llama.cpp, SGLang) switch thinking
through the chat template instead: the C<chat_template_kwargs> tag
(L</to_chat_template_kwargs>) sends C<chat_template_kwargs.enable_thinking>
plus the effort unclamped. L</thinking_enabled> is an explicit on/off switch
without an effort level; it and L</effort> are one concern and must agree.

=head2 effort

The normalized reasoning effort, one of C<none|minimal|low|medium|high|xhigh|max>.
Optional (must not coexist with C<thinking_budget> on any Gemini generation;
see L</BUILD>). On Gemini 3 and Gemini 4, C<effort> is the only knob and emits
C<thinkingConfig.thinkingLevel>, model-gated clamped to the level subset the
configured model family accepts (L</to_gemini_level>). Setting C<effort> on a
Gemini 2.5 model is rejected — Gemini 2.5 takes the integer budget, not the
level vocabulary.

=head2 model

Optional model name. Used by L</to_anthropic> to detect always-on
"Fable-class" models (where C<thinking:{type:disabled}> 400s and the
C<thinking> field must be omitted) and by L</to_gemini> to dispatch between
Gemini 2.5 (C<thinkingBudget>) and Gemini 3 (C<thinkingLevel>) and to clamp
the Gemini 3 level vocabulary to the model family's supported subset.

=head2 thinking_display

Optional Anthropic thinking-visibility control, serialized by L</to_anthropic>
as C<thinking.display>. Values: C<summarized> (return a readable summary of the
reasoning), C<omitted> (no summary; the C<thinking> field comes back empty), or
C<updates> (beta; between-tool-call progress notes). On every current Claude
model the API default is C<omitted>, so a caller that wants to read
C<< $response->thinking >> must set C<thinking_display =E<gt> 'summarized'>
explicitly. Consumed only on the C<anthropic> wire; ignored on every other
format. Only takes effect together with a thinking block, i.e. on the adaptive
(non-Fable-class) path — see L</to_anthropic>.

=head2 thinking_budget

Optional integer thinking budget for Gemini 2.5 models. When set on a Gemini
2.5 model (model id starting with C<gemini-2.5>), L</to_gemini> emits
C<thinkingConfig.thinkingBudget> as the integer. Setting C<thinking_budget>
on a Gemini 3 or Gemini 4 model, or setting it together with C<effort> on any model, is
rejected at construction time (L</BUILD>) — the two fields speak different
units (binary level vs integer tokens) and a combined or wrong-generation wire
form would be ambiguous.

=head2 thinking_enabled

Optional explicit thinking on/off switch, without an effort level (karr
k382). Tri-state: unset (C<has_thinking_enabled> false, the default), C<0> or
C<1>. It is the same concern as L</effort>, so the two must agree:
C<thinking_enabled =E<gt> 0> together with any effort other than C<none>, or
C<thinking_enabled =E<gt> 1> together with effort C<none>, croaks at
construction (L</BUILD>). C<thinking_enabled =E<gt> 0> without an effort is
normalized to effort C<none> at construction (L</normalize_off_switch>), so
every wire sees the same off switch. Off therefore cannot disable thinking
where effort C<none> cannot: Gemini 3/4 raise it to their floor level
(C<minimal> or C<low>), models whose OpenAI or Responses ladder has no C<none>
(gpt-6, legacy gpt-5) drop it, GPT-OSS on Ollama raises it to C<low>, and on a
Gemini 2.5 (budget-control) model it is not normalized at all and is dropped
with a carp. C<thinking_enabled =E<gt> 1> without an effort has a wire form only
on C<chat_template_kwargs> (L</to_chat_template_kwargs>), on the opted-in
thinking-toggle path (L</thinking_toggle>, the model's on-type) and on Ollama's
boolean C<think> (not GPT-OSS); every other wire sends nothing for it
(L</drops_thinking_enabled_on>).

=head2 thinking_toggle

Whether the target endpoint speaks the C<thinking> on/off toggle (MiniMax's
cloud API, Kimi's Messages and chat/completions faces; karr k209/k215/k219). Set by
L<Langertha::Role::ReasoningEffort/reasoning_kwargs_for> from the engine's
opt-in. Only when it is true does a thinking-toggle profile
(L<Langertha::Reasoning::Profile/thinking_on>) serialize as the toggle; when
false (the default) the same model id serializes exactly like the unlisted-id
passthrough, because a self-hosted server or proxy serving a bare
C<MiniMax-M3> / C<kimi-k2.6> id does not parse the toggle.

=head2 normalize_off_switch

    my $args = Langertha::Reasoning->normalize_off_switch(\%args);

Returns the constructor arguments with C<thinking_enabled =E<gt> 0> (and no
C<effort>) turned into C<effort =E<gt> 'none'>, the off switch every wire knows.
Not on a budget-control generation (Gemini 2.5, see L</thinking_budget>), which
takes no effort: there the switch stays as given and is dropped
(L</drops_thinking_enabled_on>). The constructor calls it;
L<Langertha::Role::ReasoningEffort> calls it to resolve the effort for readers
other than the serializers.

=head2 assert_switch_agrees

    Langertha::Reasoning->assert_switch_agrees( $thinking_enabled, $effort );

Croaks when the two disagree within one layer: C<thinking_enabled =E<gt> 0>
with an effort other than C<none>, or C<thinking_enabled =E<gt> 1> with
C<none>. Either one undefined passes. Called from L</BUILD> and from the
engine constructor (L<Langertha::Role::ReasoningEffort/thinking_enabled>).

=head2 to_gemini_level

Maps the normalized effort onto Gemini 3's C<thinkingLevel> vocabulary
(C<minimal>|C<low>|C<medium>|C<high>): C<none>/C<minimal> become C<minimal>,
C<high>/C<xhigh>/C<max> become C<high>, C<low> and C<medium> pass through.
The result is then clamped down to the subset the configured L</model> family
accepts: C<gemini-3.7-flash>, C<gemini-3.8-flash> and C<gemini-3.1-pro-*> drop
C<minimal> to C<low> (no C<minimal> support), C<gemini-3-pro-*> accepts only
C<low>|C<high> and drops C<minimal> and C<medium> to C<low>. Gemini 4
(C<gemini-4-argon> and the rest of C<gemini-4*>, not C<gemini-40>) accepts
C<low>|C<medium>|C<high> and raises C<minimal> to C<low>, as 3.7/3.8-flash do.
Models outside the Gemini 3 and 4 lines (or no
model) keep the universally-accepted binary C<low>|C<high> collapse, splitting
at C<high>.

=head2 to_openai

=head2 to_responses

Serialize L</effort> to the two OpenAI wires — Chat Completions
(C<reasoning_effort =E<gt> $effort>) and the Responses API
(C<reasoning =E<gt> { effort =E<gt> $effort }>). Both surfaces C<$ref> the
identical C<ReasoningEffort> schema, so both clamp through the same model-gated
gate: the accepted value set is per model generation
(gpt-6 astra: C<low|medium|high|xhigh|max>, no C<none|minimal>;
gpt-5.6-* / gpt-5.5-*: C<none|low|medium|high|xhigh(|max)>, no C<minimal>;
gpt-5 legacy: C<minimal|low|medium|high>, no C<none|xhigh|max>), and an
unrecognized model id keeps the full normalized vocabulary. An effort the
configured L</model> does not accept yields an empty list on B<both> wires —
they can never diverge. Empty list when no L</effort> is set.

A B<thinking-toggle> model (its profile has
L<Langertha::Reasoning::Profile/thinking_on>: MiniMax-M3 / M2.x, Kimi K2.x),
serialized for an endpoint that opted in with L</thinking_toggle>, takes no
effort field on C<to_openai>: it gets
C<< thinking =E<gt> { type =E<gt> ... } >> instead — C<disabled> for C<none>
where the model can turn thinking off, the model's on-type (C<adaptive> or
C<enabled>) for any other level. Every level gives the same depth there.
Without L</thinking_toggle> the same model id is serialized like any unlisted
id.

=head2 to_anthropic

Serializes to the Messages-API reasoning shape: C<output_config.effort> (when
L</effort> maps onto Anthropic's C<low|medium|high|xhigh|max> set) plus a
C<thinking> block. On adaptive (non-Fable-class) models the block is
C<< { type =E<gt> 'adaptive' } >>, carrying C<display =E<gt> ...> when
L</thinking_display> is set. Fable-class models (Fable / Mythos) get no
C<thinking> key — thinking is always on and C<type:disabled> 400s there — and
therefore cannot carry a C<display> either. Empty list when neither an
Anthropic-supported effort nor a C<thinking_display> is present.

A B<thinking-toggle> model on an opted-in endpoint (L</thinking_toggle>) gets
only the C<thinking> toggle described under L</to_openai> (no
C<output_config.effort>), with C<display> added to an on toggle when
L</thinking_display> is set (whether MiniMax and Kimi accept C<display> there is
not verified).

=head2 to_ollama

Serializes to Ollama's C<options.think> knob. For the GPT-OSS family (whose
resolved L<Langertha::Reasoning::Profile> carries C<ollama_levels>) it emits a
graded level B<string> — C<low>/C<medium>/C<high>/C<max> — because GPT-OSS
ignores the boolean and always reasons (C<none> maps to the floor C<low>;
live-probed 2026-09-17 via ollama.com gpt-oss:20b, k175). For every other model
it emits the C<options.think> B<boolean>: any effort level other than C<none>
turns thinking on, C<none> turns it off, and so do L</thinking_enabled> C<1> and
C<0>. A bare C<thinking_enabled =E<gt> 1> sends nothing on GPT-OSS. Empty list
when neither is set.
(Ollama does not compose L<Langertha::Role::ReasoningEffort> — the engine calls
this serializer directly from its C<chat_request> when a per-request
C<reasoning_effort> or C<thinking_enabled> control arrives.)

=head2 to_chat_template_kwargs

Serializes to the chat-template switch of self-hosted OpenAI-compatible
servers (llama.cpp, SGLang, and any OpenAI-compatible endpoint that opts in
with C<reasoning_wire_format =E<gt> 'chat_template_kwargs'>):

    effort none                 ->  chat_template_kwargs => { enable_thinking => false }
    effort low .. max           ->  chat_template_kwargs => { enable_thinking => true },
                                    reasoning_effort     => $effort
    thinking_enabled 1 (alone)  ->  chat_template_kwargs => { enable_thinking => true }
    nothing set                 ->  ()

C<enable_thinking> is always a real JSON boolean. The effort is sent as given:
the OpenAI per-model effort ladder (L</to_openai>) is not consulted, since a
self-hosted model id says nothing about which levels its template takes. Effort
C<none> sends no C<reasoning_effort>, because some servers and templates reject
it. A C<chat_template_kwargs> the caller passes to the request is merged with
this one, the caller's keys winning
(L<Langertha::Role::OpenAICompatible/chat_request>).

=head2 drops_thinking_enabled_on

    my $dropped = $r->drops_thinking_enabled_on($reasoning_wire_format);

True when L</thinking_enabled> is set without an L</effort> and the given wire
has no form for it, so the serializers send nothing;
L<Langertha::Role::ReasoningEffort/reasoning_kwargs_for> uses this to carp once
per engine. A bare C<thinking_enabled =E<gt> 1> has a form on
C<chat_template_kwargs>, on the opted-in thinking-toggle path and on C<ollama>
(except GPT-OSS, which takes only levels). A bare C<thinking_enabled =E<gt> 0>
is left only on a budget-control generation (L</normalize_off_switch>) and has
a form only on C<chat_template_kwargs>.

=head2 to

    my %kwargs = $r->to($reasoning_wire_format);

Dispatch to the per-format serializer. Returns the body kwargs to merge into
the request (an empty list when the value is unsupported on that wire).

=head1 SEE ALSO

=over

=item * L<Langertha::Reasoning::Profile> - The per-model wire-truth this value object resolves and consumes

=item * L<Langertha::Role::ReasoningEffort> - The composed role exposing C<reasoning_effort>
and C<thinking_budget>

=item * L<Langertha::ToolChoice> - Sibling value object for tool-selection policy

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
