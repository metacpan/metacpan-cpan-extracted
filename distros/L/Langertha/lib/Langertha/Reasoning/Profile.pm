package Langertha::Reasoning::Profile;
# ABSTRACT: Typed per-model reasoning wire-truth (accepted vocabulary + numeric bounds)
our $VERSION = '0.503';
use Moose;
use Moose::Util::TypeConstraints;
use Carp qw( croak );


# The normalized ascending reasoning vocabulary, defined ONCE and reused. A
# namespaced type name so it cannot collide with any other 'ReasoningLevel'
# registered in the process (Moose croaks on enum-name redefinition).
enum 'Langertha::Reasoning::Level'
  => [qw( none minimal low medium high xhigh max )];
enum 'Langertha::Reasoning::Control'
  => [qw( effort budget boolean none )];
enum 'Langertha::Reasoning::DisableForm'
  => [qw( absent explicit_none think_false budget_zero thinking_disabled )];
enum 'Langertha::Reasoning::ThinkingOn'
  => [qw( adaptive enabled )];
enum 'Langertha::Reasoning::Wire'
  => [qw( openai responses anthropic gemini ollama )];

# The full Anthropic Messages-API output_config.effort vocabulary (the
# normalized none/minimal have no Anthropic equivalent and drop). The default
# the generic-claude, Fable/Mythos and provider-default profiles reuse — but NOT
# uniform across every Claude model: Claude 4.6 (opus/sonnet) drops xhigh, so
# anthropic_effort_ok checks the resolved profile's own `levels` rather than this
# module-level set (karr k177).
my @ANTHROPIC_EFFORT_LEVELS = qw( low medium high xhigh max );

# Normalized effort -> Gemini 3 thinkingLevel base vocabulary
# (minimal|low|medium|high); then clamped down to the family's accepted subset.
my %GEMINI_BASE = (
  none    => 'minimal',
  minimal => 'minimal',
  low     => 'low',
  medium  => 'medium',
  high    => 'high',
  xhigh   => 'high',
  max     => 'high',
);
my %GEMINI_ORDER = ( minimal => 0, low => 1, medium => 2, high => 3 );

# Normalized effort -> GPT-OSS Ollama options.think level (low|medium|high|max).
# GPT-OSS always reasons — there is no "off" — so 'none' (and 'minimal') map to
# the floor 'low' (live-probed 2026-09-17 via ollama.com gpt-oss:20b, k175).
my %OLLAMA_LEVEL = (
  none    => 'low',
  minimal => 'low',
  low     => 'low',
  medium  => 'medium',
  high    => 'high',
  xhigh   => 'max',
  max     => 'max',
);

has model_match => (
  is  => 'ro',
  isa => 'Str | RegexpRef',
);


has control => (
  is       => 'ro',
  isa      => 'Langertha::Reasoning::Control',
  required => 1,
);


has levels => (
  is      => 'ro',
  isa     => 'ArrayRef[Langertha::Reasoning::Level]',
  default => sub { [] },
);


has levels_by_wire => (
  is      => 'ro',
  isa     => 'HashRef[ArrayRef[Langertha::Reasoning::Level]]',
  default => sub { {} },
);


has ollama_levels => (
  is        => 'ro',
  isa       => 'ArrayRef[Langertha::Reasoning::Level]',
  predicate => 'has_ollama_levels',
);


has can_disable => (
  is      => 'ro',
  isa     => 'Bool',
  default => 1,
);


has default_reasoning_off => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has is_reasoning_model => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has disable_form => (
  is      => 'ro',
  isa     => 'Langertha::Reasoning::DisableForm',
  default => 'absent',
);


has thinking_on => (
  is        => 'ro',
  isa       => 'Langertha::Reasoning::ThinkingOn',
  predicate => 'has_thinking_on',
);


has wire_format => (
  is       => 'ro',
  isa      => 'Langertha::Reasoning::Wire',
  required => 1,
);


has is_gemini3 => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


for my $bound (qw( budget_min budget_max off_value dynamic_value )) {
  has $bound => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_' . $bound,
  );
}




has source => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);



sub fable_class { return $_[0]->can_disable ? 0 : 1 }


sub thinking_toggle_for {
  my ( $self, $effort ) = @_;
  return unless $self->has_thinking_on;
  if ( $effort eq 'none' ) {
    return unless $self->disable_form eq 'thinking_disabled';
    return { type => 'disabled' };
  }
  return { type => $self->thinking_on };
}


sub effort_accepted_on {
  my ( $self, $wire, $effort ) = @_;
  my $set = $self->levels_by_wire->{$wire};
  return 1 unless defined $set;
  return ( grep { $_ eq $effort } @$set ) ? 1 : 0;
}


sub anthropic_effort_ok {
  my ( $self, $effort ) = @_;
  return ( grep { $_ eq $effort } @{ $self->levels } ) ? 1 : 0;
}


sub gemini_level_for {
  my ( $self, $effort ) = @_;
  unless ( $self->is_gemini3 ) {
    return ( $effort eq 'high' || $effort eq 'xhigh' || $effort eq 'max' )
      ? 'high' : 'low';
  }
  my $level = $GEMINI_BASE{$effort} // 'low';
  return $self->_clamp_gemini_level($level);
}

# Clamp a base Gemini level down to the profile's accepted set: keep it if
# accepted, else drop to the highest accepted level below it, or rise to the
# lowest accepted level when it sits below the family's floor. The accepted sets
# are contiguous ranges, so this reproduces the family clamps exactly.
sub _clamp_gemini_level {
  my ( $self, $level ) = @_;
  my %ok = map { $_ => 1 } @{ $self->levels };
  return $level if $ok{$level};
  my @sorted = sort { $GEMINI_ORDER{$a} <=> $GEMINI_ORDER{$b} }
    grep { defined $GEMINI_ORDER{$_} } @{ $self->levels };
  my $target = $GEMINI_ORDER{$level};
  my $result;
  for my $lvl (@sorted) {
    $result = $lvl if $GEMINI_ORDER{$lvl} < $target;
  }
  return defined $result ? $result : $sorted[0];
}


sub ollama_level_for {
  my ( $self, $effort ) = @_;
  return $OLLAMA_LEVEL{$effort} // 'low';
}

# ---------------------------------------------------------------------------
# The registry — one ordered, most-specific-first table. Built lazily so the
# class is fully defined (and immutable) before any profile is constructed.
# ---------------------------------------------------------------------------
my @REGISTRY;
my $DEFAULT;

# developers.openai.com/api/docs/guides/reasoning + per-model pages,
# advisor-verified 2026-09-01 (karr k140); gpt-6-astra 2026-09-14 (karr k151).
my $OPENAI_SRC = 'developers.openai.com/api/docs/guides/reasoning; k140 2026-09-01, gpt-6 k151 2026-09-14';
# ai.google.dev/gemini-api/docs/thinking level table, verified 2026-09-01
# (karr k140); gemini-3.8-flash 2026-09-14 (karr k153).
my $GEMINI3_SRC = 'ai.google.dev/gemini-api/docs/thinking; k140 2026-09-01, 3.8-flash k153 2026-09-14';
# ai.google.dev/gemini-api/docs/thinking budget table (2.5), advisor-verified
# 2026-09-16 (karr k173).
my $GEMINI25_SRC = 'ai.google.dev/gemini-api/docs/thinking budget table; k173 2026-09-16';
# Self-hosted Qwen3.x reasoning family: the loaded model's chat template — NOT
# the vLLM/SGLang/llama.cpp server — fixes the accepted reasoning_effort
# vocabulary. Live-probed 2026-09-17 on a cortex vLLM server (karr k79/k180):
# Qwen/Qwen3.8-27B-FP8 400s on reasoning_effort=high ("Unexpected reasoning
# effort high. Supported types are xhigh (default), medium, and low."), accepting
# only none/low/medium/xhigh.
my $QWEN_SELFHOSTED_SRC = 'live-probed 2026-09-17 cortex vLLM Qwen/Qwen3.8-27B-FP8: reasoning_effort high->400, accepts none/low/medium/xhigh (k79/k180)';

# karr k176: 'max' is Responses-only for the gpt-6 and gpt-5.6 generations. The
# gpt-5.6 split is live-confirmed (2026-09-16 on gpt-5.6-terra): Chat Completions
# reasoning_effort=max -> HTTP 400 ("Supported values are: 'none', 'low',
# 'medium', 'high', and 'xhigh'."), Responses reasoning.effort=max -> HTTP 200.
# The gpt-6 split is doc-sourced (advisor Azure mirror, same Responses-only-max
# pattern) — not live-probed.
my $OPENAI_K176_LIVE = "$OPENAI_SRC; k176 2026-09-16 live gpt-5.6-terra: chat reasoning_effort=max->400, responses reasoning.effort=max->200";
my $OPENAI_K176_DOC  = "$OPENAI_SRC; k176 gpt-6 max Responses-only (advisor Azure mirror, doc-sourced, not live-probed)";
# karr k174: gpt-5.1 is gated (Azure Foundry reasoning table, advisor-verified
# 2026-09-16 — doc-sourced, NOT live-probed). Base gpt-5.1 drops minimal/xhigh/max
# (none|low|medium|high); gpt-5.1-codex-max re-adds xhigh (still no max). Both
# wires identical (xhigh is not Responses-only), so no openai_levels split.
my $OPENAI_K174_DOC  = "$OPENAI_SRC; k174 gpt-5.1 gate (Azure Foundry reasoning table, advisor-verified 2026-09-16, doc-sourced not live)";
# karr k177: Claude 4.6 (opus/sonnet) accepts low|medium|high|max but NOT xhigh
# — Anthropic's effort doc lists 4.6 under `max` yet not under `xhigh`; 4.7+/5
# take the full set. Advisor-verified 2026-09-16 (doc-sourced, NOT live-probed).
my $ANTHROPIC_K177_DOC = 'platform.claude.com output_config.effort doc; k177 2026-09-16 claude-4.6 no xhigh (advisor-verified, doc-sourced not live)';
# karr k208: xAI reasoning page (updated 2026-09-21), advisor-verified
# 2026-09-25 — doc-sourced, NOT live-probed (the reply to an off-enum value,
# 400 or ignored, is unverified).
my $XAI_K208_DOC = 'docs.x.ai/developers/model-capabilities/text/reasoning; k208 2026-09-25 (advisor-verified, doc-sourced not live)';

# karr k209: MiniMax chat/completions + /anthropic request schemas, advisor
# 2026-09-25 — doc-sourced, NOT live-probed.
my $MINIMAX_K209_DOC = 'platform.minimax.io openapi-chat-openai.json + openapi-chat-anthropic.json; k209 2026-09-25 (advisor-verified, doc-sourced not live)';
# karr k215: Kimi Messages API + Claude Code guide, advisor 2026-09-25 —
# doc-sourced, NOT live-probed (budget_tokens on `enabled` unverified).
my $KIMI_K215_DOC = 'platform.kimi.ai docs/api/messages.md + docs/guide/claude-code-kimi.md; k215 2026-09-25 (advisor-verified, doc-sourced not live; budget_tokens unverified)';
# $levels is the superset a family accepts on the `responses` (Responses API)
# wire; $extra{openai_levels} is the narrower Chat Completions set, defaulting to
# $levels when the two wires agree. The k176 per-wire max split is exactly this
# openai_levels-vs-levels divergence for the gpt-6 / gpt-5.6 generations.
sub _openai_profile {
  my ( $match, $levels, %extra ) = @_;
  my $openai_levels = delete $extra{openai_levels} // $levels;
  return __PACKAGE__->new(
    model_match    => $match,
    control        => 'effort',
    wire_format    => 'openai',
    levels         => $levels,
    levels_by_wire => { openai => $openai_levels, responses => $levels },
    source         => $OPENAI_SRC,
    %extra,
  );
}

# An OpenAI line whose effort ladder is uncurated: the unlisted-id passthrough
# serialization (full normalized enum, no per-wire restriction) with an explicit
# reasoning classification (karr k186).
sub _openai_passthrough {
  my ( $match, $is_reasoning, $source ) = @_;
  return __PACKAGE__->new(
    model_match        => $match,
    control            => 'effort',
    wire_format        => 'openai',
    levels             => [@ANTHROPIC_EFFORT_LEVELS],
    is_reasoning_model => $is_reasoning,
    source             => $source,
  );
}

# A non-reasoning chat carve-out that serializes exactly like the reasoning
# family it sits in ($like is that family's resolved profile): only the
# classification differs, so the carve-out changes nothing on the reasoning wire
# (karr k186).
sub _non_reasoning_like {
  my ( $match, $like ) = @_;
  return $like->meta->clone_object( $like,
    model_match        => $match,
    is_reasoning_model => 0,
    source             => $like->source . "; k186 non-reasoning chat carve-out",
  );
}

sub _gemini3_profile {
  my ( $match, $levels ) = @_;
  return __PACKAGE__->new(
    model_match => $match,
    control     => 'effort',
    wire_format => 'gemini',
    is_gemini3  => 1,
    levels      => $levels,
    source      => $GEMINI3_SRC,
  );
}

sub _ensure_registry {
  return if @REGISTRY;

  # Provider default: an unrecognized id keeps the full normalized enum on the
  # openai wire (no per-wire restriction), takes the fixed set on anthropic, and
  # the binary collapse on gemini. Shared by every OpenAI-compatible provider
  # (and no model at all). Never a reasoning model (is_reasoning_model 0). Built
  # first: a chat carve-out whose family id matches no row copies the default,
  # so the registry must not depend on a passthrough row existing (karr k196).
  $DEFAULT = __PACKAGE__->new(
    model_match        => '',
    control            => 'effort',
    wire_format        => 'openai',
    levels             => [@ANTHROPIC_EFFORT_LEVELS],
    is_reasoning_model => 0,
    source             => 'normalized OpenAI superset passthrough (unlisted id)',
  );

  my @families = _family_profiles();

  # Non-reasoning chat carve-outs (karr k186): gpt-5-chat and every dotted
  # gpt-5.N-chat id (gpt-5.1-chat-latest, gpt-5.2-chat-latest, ...) are
  # non-reasoning chat models inside reasoning families. Listed first so they
  # win over the family patterns. Generated per digit (karr k196): each copies
  # the profile of its own family id (gpt-5.N-chat -> gpt-5.N), so a newly
  # curated gpt-5.N family is picked up without a hand-kept mapping. The
  # literal "-chat" after the digit already rejects a second digit.
  my @carve_outs = map {
    my ( $match, $like_id ) = @$_;
    _non_reasoning_like( $match, _match( $like_id, @families ) );
  } (
    [ qr/\Agpt-5-chat/, 'gpt-5' ],
    map { my $digit = $_; [ qr/\Agpt-5\.${digit}-chat/, "gpt-5.$digit" ] } 0 .. 9,
  );

  @REGISTRY = ( @carve_outs, @families );
  return;
}

# The family rows, most-specific-first (everything except the chat carve-outs
# and the provider default).
sub _family_profiles {
  return (
    # Anthropic always-on Fable/Mythos: matched before the generic claude
    # family. Case-insensitive substring, mirroring the legacy _is_fable_class.
    __PACKAGE__->new(
      model_match  => qr/fable|mythos/i,
      control      => 'effort',
      wire_format  => 'anthropic',
      levels       => [@ANTHROPIC_EFFORT_LEVELS],
      can_disable  => 0,
      disable_form => 'absent',
      source       => 'Anthropic Messages API; Fable/Mythos always-on thinking, k173 2026-09-16',
    ),

    # OpenAI generation ladders. gpt-6 (astra): no none/minimal. gpt-5.6 /
    # gpt-5.5: none but no minimal. gpt-5.1: gated (karr k174), with a codex-max
    # carve-out matched first. Legacy gpt-5: minimal but no none/xhigh/max — the
    # gpt-5(?![.\d]) negative-lookahead keeps it off gpt-5.5/5.6/5.1.
    # gpt-6 and gpt-5.6 carry a per-wire split (karr k176): 'max' is
    # Responses-only, so their openai (Chat Completions) set drops max while the
    # responses set (== levels) keeps it. gpt-5.6 live-confirmed, gpt-6 doc-sourced.
    # The gpt-6 row also covers its single-digit point releases (gpt-6.1, karr
    # k201): they keep this doc-sourced ladder rather than an uncurated
    # passthrough (which would send none/minimal and chat 'max'), so no separate
    # gpt-6.N row exists. (?!\.\d\d) is the multi-digit guard after the dot:
    # gpt-6.10 is an unknown id, not gpt-6.
    _openai_profile( qr/\Agpt-6(?!\d)(?!\.\d\d)/,
      [qw( low medium high xhigh max )],
      openai_levels => [qw( low medium high xhigh )],
      source        => $OPENAI_K176_DOC,
      disable_form => 'absent', can_disable => 1, is_reasoning_model => 1 ),
    _openai_profile( qr/\Agpt-5\.6(?!\d)/,
      [qw( none low medium high xhigh max )],
      openai_levels => [qw( none low medium high xhigh )],
      source        => $OPENAI_K176_LIVE,
      disable_form => 'explicit_none', is_reasoning_model => 1 ),
    _openai_profile( qr/\Agpt-5\.5(?!\d)/,
      [qw( none low medium high xhigh )], disable_form => 'explicit_none',
      is_reasoning_model => 1 ),
    # gpt-5.1 (karr k174), most-specific-first: codex-max re-adds xhigh, base
    # drops minimal/xhigh/max. Both wires identical (xhigh is not Responses-only).
    # default_reasoning_off: the 5.1 line's no-effort server-side default is
    # reasoning-OFF (k185 2026-09-19 live) — a bare request does not reason.
    _openai_profile( qr/\Agpt-5\.1-codex-max/,
      [qw( none low medium high xhigh )],
      source => $OPENAI_K174_DOC, disable_form => 'explicit_none',
      default_reasoning_off => 1, is_reasoning_model => 1 ),
    _openai_profile( qr/\Agpt-5\.1(?!\d)/,
      [qw( none low medium high )],
      source => $OPENAI_K174_DOC, disable_form => 'explicit_none',
      default_reasoning_off => 1, is_reasoning_model => 1 ),
    # gpt-5.2 / gpt-5.4: same no-effort-default-off generation as gpt-5.1
    # (reasoning_tokens=0 with no effort, a non-default temperature honored --
    # k185 2026-09-19 live). Their accepted effort ladder is not yet live-curated,
    # so they keep the unlisted-id passthrough (full enum, no per-wire restriction)
    # rather than an invented gate — only the default-reasoning-off signal is
    # sourced. gpt-5.3, if it appears, falls through to the reasoning-on default.
    __PACKAGE__->new(
      model_match           => qr/\Agpt-5\.[24](?!\d)/,
      control               => 'effort',
      wire_format           => 'openai',
      levels                => [@ANTHROPIC_EFFORT_LEVELS],
      default_reasoning_off => 1,
      is_reasoning_model    => 1,
      source                => 'k185 2026-09-19 live: gpt-5.2/5.4 no-effort default reasoning off; effort ladder uncurated (passthrough)',
    ),
    _openai_profile( qr/\Agpt-5(?![.\d])/,
      [qw( minimal low medium high )], disable_form => 'absent',
      is_reasoning_model => 1 ),
    # Uncurated OpenAI reasoning lines (karr k186): any other gpt-5.N (5.3, 5.7,
    # ...) and the o-series are reasoning models, but their effort ladder is not
    # curated, so they keep the unlisted-id passthrough serialization — only the
    # reasoning classification is added. Matched after the curated gpt-5.N
    # families above. Every dotted family pattern ends in (?!\d) (karr k196):
    # gpt-5.10 is not gpt-5.1, and a multi-digit id matches no gpt-5.N row at
    # all, so it is an unknown id (non-reasoning, temperature kept). The undotted
    # gpt-6 and o-series rows carry the same guard (gpt-60, o10 are unknown).
    _openai_passthrough( qr/\Agpt-5\.\d(?!\d)/, 1,
      'k186: uncurated gpt-5.N reasoning line; effort ladder passthrough' ),
    _openai_passthrough( qr/\Ao\d(?!\d)/, 1,
      'k186: OpenAI o-series reasoning models; effort ladder passthrough' ),
    # Non-reasoning OpenAI chat models (karr k186), marked explicitly so the
    # classification never falls out of the default: gpt-4o / gpt-4.1 (and the
    # rest of gpt-4*). Same passthrough serialization as the unlisted default.
    _openai_passthrough( qr/\Agpt-4/, 0,
      'k186: non-reasoning gpt-4 line (gpt-4o, gpt-4.1); effort ladder passthrough' ),

    # xAI grok (karr k208): grok-4.6 / grok-4.7 (and later single-digit 4.N)
    # accept low|medium|high|xhigh, grok-4.5 low|medium|high; reasoning cannot
    # be disabled (default high), so none/minimal/max drop and the server
    # default applies. Same set on chat and responses. The (?!\d) guard keeps
    # grok-4.20-multi-agent (effort = agent count) an unknown id.
    _openai_profile( qr/\Agrok-4\.[6-9](?!\d)/,
      [qw( low medium high xhigh )],
      source => $XAI_K208_DOC, can_disable => 0, disable_form => 'absent' ),
    _openai_profile( qr/\Agrok-4\.5(?!\d)/,
      [qw( low medium high )],
      source => $XAI_K208_DOC, can_disable => 0, disable_form => 'absent' ),

    # Moonshot kimi-k3 (karr k207): top-level reasoning_effort on
    # chat/completions and output_config.effort on the Messages API, both
    # low|high|max (server default max); always reasons, and the Messages API
    # has no thinking request field, so can_disable 0 keeps to_anthropic from
    # sending one. \A-anchored on Moonshot's own ids: OpenRouter's
    # moonshotai/kimi-k3 is deliberately not matched (what an aggregator
    # forwards was not checked). K2.x takes no effort (cleared per model on
    # Engine::Moonshot only). (?!\d): kimi-k30 is an unknown id (k196 guard).
    _openai_profile( qr/\Akimi-k3(?!\d)/,
      [qw( low high max )],
      source => 'platform.kimi.ai use-reasoning-effort + api/chat + api/messages; k207 2026-09-25 (advisor-verified, doc-sourced not live)',
      can_disable => 0, disable_form => 'absent' ),

    # Thinking-toggle families (karr k209, k215): the wire takes a `thinking`
    # object with an on/off type and no effort level, so Langertha::Reasoning
    # maps none -> off and every other level -> on (the ladder collapses).
    # \A-anchored on the providers' own ids; aggregator ids are not matched.
    #
    # MiniMax (platform.minimax.io openapi-chat-openai.json /
    # openapi-chat-anthropic.json, advisor 2026-09-25, doc-sourced not live):
    # thinking {type: disabled|adaptive}, no effort, no budget. M3 honors
    # disabled; M2.x accepts it but keeps thinking on, so it cannot disable.
    # MiniMax's own /v1/responses maps effort the same way (none -> off, any
    # level -> adaptive).
    __PACKAGE__->new(
      model_match  => qr/\AMiniMax-M3(?!\d)/,
      control      => 'boolean',
      wire_format  => 'openai',
      can_disable  => 1,
      disable_form => 'thinking_disabled',
      thinking_on  => 'adaptive',
      source       => $MINIMAX_K209_DOC,
    ),
    __PACKAGE__->new(
      model_match  => qr/\AMiniMax-M2(?!\d)/,
      control      => 'boolean',
      wire_format  => 'openai',
      can_disable  => 0,
      disable_form => 'absent',
      thinking_on  => 'adaptive',
      source       => $MINIMAX_K209_DOC,
    ),
    # Kimi K2.x (karr k215; platform.kimi.ai api/messages + guide/claude-code-kimi,
    # advisor 2026-09-25, doc-sourced not live): thinking {type: enabled|disabled},
    # no effort (output_config.effort is K3-only). kimi-k2.7-code(-highspeed) is
    # forced on ("only type=enabled is allowed"), kimi-k2.6 can disable. Whether
    # `enabled` needs budget_tokens on the Messages face is UNVERIFIED; none is
    # sent. \z-anchored to Kimi's documented ids: AKI.IO's hosted
    # kimi-k2.7-code-1100b is a different API and is not matched. Reached on
    # MoonshotAnthropic (both rows) and on Engine::Moonshot's chat/completions
    # (kimi-k2.6 only, karr k219: the same toggle as a top-level `thinking`;
    # wire_format is descriptive, to_openai serializes it). Engine::Moonshot
    # keeps reasoning_effort cleared on kimi-k2.7-code, where the chat face
    # must not be sent thinking at all.
    __PACKAGE__->new(
      model_match  => qr/\Akimi-k2\.7-code(?:-highspeed)?\z/,
      control      => 'boolean',
      wire_format  => 'anthropic',
      can_disable  => 0,
      disable_form => 'absent',
      thinking_on  => 'enabled',
      source       => $KIMI_K215_DOC,
    ),
    __PACKAGE__->new(
      model_match  => qr/\Akimi-k2\.6\z/,
      control      => 'boolean',
      wire_format  => 'anthropic',
      can_disable  => 1,
      disable_form => 'thinking_disabled',
      thinking_on  => 'enabled',
      source       => $KIMI_K215_DOC,
    ),
    # Self-hosted Qwen3.x reasoning family (vLLM / SGLang / llama.cpp), matched
    # with or without its HuggingFace org prefix (served ids look like
    # "Qwen/Qwen3.8-27B-FP8"). The loaded chat template — not the server —
    # dictates the vocabulary: this family accepts none|low|medium|xhigh and
    # REJECTS high|minimal (live-probed, k79/k180). Only the openai (Chat
    # Completions) wire is restricted — the sole wire these engines speak — so the
    # two rejected efforts drop before they can 400 the server. Unknown
    # self-hosted models are deliberately NOT listed: they fall through to the
    # passthrough default and keep going raw (correct for an unknown chat
    # template, k180).
    __PACKAGE__->new(
      model_match    => qr{(?:\A|/)qwen3\.\d(?!\d)}i,
      control        => 'effort',
      wire_format    => 'openai',
      levels         => [qw( none low medium xhigh )],
      levels_by_wire => { openai => [qw( none low medium xhigh )] },
      disable_form   => 'explicit_none',
      source         => $QWEN_SELFHOSTED_SRC,
    ),

    # Gemini 2.5: integer thinkingBudget (no level vocabulary). Category (b)
    # bounds carried but not enforced in Phase 1 (the value passes through).
    __PACKAGE__->new(
      model_match => qr/\Agemini-2\.5-flash-lite/,
      control => 'budget', wire_format => 'gemini', levels => [],
      budget_min => 512, budget_max => 24576, off_value => 0, dynamic_value => -1,
      disable_form => 'budget_zero', source => $GEMINI25_SRC,
    ),
    __PACKAGE__->new(
      model_match => qr/\Agemini-2\.5-flash/,
      control => 'budget', wire_format => 'gemini', levels => [],
      budget_min => 0, budget_max => 24576, off_value => 0, dynamic_value => -1,
      disable_form => 'budget_zero', source => $GEMINI25_SRC,
    ),
    __PACKAGE__->new(
      model_match => qr/\Agemini-2\.5-pro/,
      control => 'budget', wire_format => 'gemini', levels => [],
      budget_min => 128, budget_max => 32768, dynamic_value => -1, can_disable => 0,
      disable_form => 'absent', source => $GEMINI25_SRC,
    ),
    __PACKAGE__->new(
      model_match => qr/\Agemini-2\.5(?!\d)/,
      control => 'budget', wire_format => 'gemini', levels => [],
      budget_min => 0, budget_max => 24576, off_value => 0, dynamic_value => -1,
      disable_form => 'budget_zero', source => $GEMINI25_SRC,
    ),

    # Gemini 3 thinkingLevel families, most-specific-first: 3.7/3.8-flash and
    # 3.1-pro drop minimal (low|medium|high); 3-pro is binary (low|high); every
    # other gemini-3 keeps the full minimal..high set.
    _gemini3_profile( qr/\Agemini-3\.[78]-flash/, [qw( low medium high )] ),
    _gemini3_profile( qr/\Agemini-3\.1-pro/,      [qw( low medium high )] ),
    _gemini3_profile( qr/\Agemini-3-pro/,         [qw( low high )] ),
    _gemini3_profile( qr/\Agemini-3/,             [qw( minimal low medium high )] ),

    # Claude 4.6 (opus/sonnet): accepts low|medium|high|max but NOT xhigh —
    # Anthropic's effort doc lists 4.6 under `max`, not under `xhigh`. Matched
    # before the generic claude family. karr k177, doc-sourced (not live).
    __PACKAGE__->new(
      model_match => qr/\Aclaude-(opus|sonnet)-4-6/,
      control     => 'effort',
      wire_format => 'anthropic',
      levels      => [qw( low medium high max )],
      source      => $ANTHROPIC_K177_DOC,
    ),

    # Generic Claude family (adaptive thinking, can disable).
    __PACKAGE__->new(
      model_match => qr/\Aclaude/,
      control     => 'effort',
      wire_format => 'anthropic',
      levels      => [@ANTHROPIC_EFFORT_LEVELS],
      source      => 'Anthropic Messages API output_config.effort; k173 2026-09-16',
    ),

    # GPT-OSS on Ollama: the one family that takes graded level STRINGS on the
    # options.think knob (low<medium<high<max) instead of the model-agnostic
    # boolean, and ALWAYS reasons — there is no "off" (think:false is ignored,
    # so 'none' -> floor 'low'). Its other wires stay unrestricted so nothing
    # regresses off the ollama path: no levels_by_wire (openai passes the full
    # enum through), and levels keeps the generic anthropic set. Live-probed
    # 2026-09-17 via ollama.com gpt-oss:20b (k175).
    __PACKAGE__->new(
      model_match   => qr/\Agpt-oss/,
      control       => 'effort',
      wire_format   => 'ollama',
      levels        => [@ANTHROPIC_EFFORT_LEVELS],
      ollama_levels => [qw( low medium high max )],
      source        => 'live-probed 2026-09-17 via ollama.com gpt-oss:20b (k175)',
    ),
  );
}


sub for_model {
  my ( $class, $id ) = @_;
  _ensure_registry();
  return _match( $id, @REGISTRY );
}

# First profile in @profiles (most-specific-first) whose model_match matches
# $id, else the provider default.
sub _match {
  my ( $id, @profiles ) = @_;
  $id = '' unless defined $id;
  for my $profile (@profiles) {
    my $match = $profile->model_match;
    if ( ref $match eq 'Regexp' ) {
      return $profile if $id =~ $match;
    }
    elsif ( defined $match && length $match ) {
      return $profile if $id eq $match;
    }
  }
  return $DEFAULT;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Reasoning::Profile - Typed per-model reasoning wire-truth (accepted vocabulary + numeric bounds)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $profile = Langertha::Reasoning::Profile->for_model('gpt-5.6-terra');
    $profile->control;                          # 'effort'
    $profile->effort_accepted_on('openai', 'max');  # 1

=head1 DESCRIPTION

Immutable value object holding what a reasoning model's wire literally accepts —
the linchpin datatype behind L<Langertha::Reasoning>. It carries the two
non-overridable categories from karr k173's three-category taxonomy: the
B<accepted vocabulary + native control type> (which levels the wire takes,
effort/budget/boolean) and the B<provider-enforced numeric bounds & magic
values> (Gemini 2.5's budget floor/ceiling, C<0>=off, C<-1>=dynamic). The
invented level-to-token interpolation (category c) is deliberately absent — it
lives in L<Langertha::Reasoning::BudgetPolicy>, clamped to this object's bounds.

L</for_model> resolves an id to its profile most-specific-first (exact id →
family regex → provider default), replacing the scattered per-model hashes and
regexes that used to live inline in L<Langertha::Reasoning>. Each profile
carries a C<source> receipt (doc URL + verification date) so curating a new
family is a single declarative add.

=head2 model_match

The id or family pattern this profile matches — an exact C<Str> id or a
C<RegexpRef> family pattern. Descriptive; L</for_model> tests the registry's
matchers in order.

=head2 control

The wire's native reasoning control type: C<effort> (a level string),
C<budget> (an integer token budget, Gemini 2.5), C<boolean> (Ollama's
C<options.think>, or a C<thinking> on/off toggle — see L</thinking_on>) or
C<none>.

=head2 levels

The on-spectrum vocabulary the wire literally accepts, ascending. Empty for
C<budget>/C<boolean> controls (quantization anchors are not wire-truth). For a
Gemini 3 family it is the accepted C<thinkingLevel> subset.

=head2 levels_by_wire

Per-wire refinement of L</levels> for a family whose accepted set differs
between the wires it speaks (the OpenAI C<openai> vs C<responses> axis, karr
k176). The gpt-6 and gpt-5.6 generations drop C<max> on the C<openai> (Chat
Completions) wire while keeping it on C<responses> — C<max> is Responses-only
(live-confirmed 2026-09-16, karr k176). A family whose wires agree populates
both keys with the same set; the unlisted-id default leaves it empty (no
per-wire restriction).

=head2 ollama_levels

The graded level strings this model accepts on Ollama's C<options.think> knob,
in place of the model-agnostic boolean. Set only on the GPT-OSS family, which
ignores C<think:true>/C<think:false> and instead takes C<low|medium|high|max>
(live-probed 2026-09-17 via ollama.com gpt-oss:20b, k175). L</has_ollama_levels>
gates L<Langertha::Reasoning/to_ollama> between the level-string and boolean
serializations; unset for every other model (they take the boolean).

=head2 can_disable

Whether reasoning can be turned off on this model. C<0> marks the always-on
"Fable-class" Anthropic models, where C<thinking:{type:disabled}> 400s and no
C<thinking> field may be sent.

=head2 default_reasoning_off

Whether the model's server-side default effort (the one that applies when no
C<reasoning_effort> is sent) leaves reasoning OFF. C<0> — the common case —
means the model reasons by default: a bare request already triggers reasoning.
C<1> marks the models whose no-effort default is non-reasoning (the gpt-5.1 /
gpt-5.2 / gpt-5.4 line: C<reasoning_tokens=0> with no effort, live-verified
2026-09-19), so a control-on-control gate can tell "reasoning is active on the
default path" apart from "an effort was set". Consumed read-only by
L<Langertha::Engine::OpenAI/_temperature_rejected_by_reasoning>; distinct from
L</can_disable> (whether an explicit C<none> effort turns reasoning off at all).

=head2 is_reasoning_model

Whether the model is a curated OpenAI reasoning model — one that can reject a
non-default C<temperature> while reasoning is active. C<1> is set explicitly on
the o-series, the gpt-5 line (non-chat), the single-digit gpt-5.N lines
(non-chat) and gpt-6 (with its single-digit gpt-6.N point releases). A
multi-digit id such as C<gpt-5.10> or C<gpt-6.10> matches no family and is an
unknown id (karr k196, k201).
The explicit non-reasoning entries (gpt-4o / gpt-4.1 and every C<gpt-5-chat> /
C<gpt-5.N-chat> id) carry C<0>, and so does the unlisted-id default: an unknown
model never classifies as reasoning, because wrongly dropping a caller's
temperature is the worse error (karr k186). Only the OpenAI families are
curated; a C<0> on another family (Claude, Gemini, Qwen, GPT-OSS) means "not
classified", not "known non-reasoning". Consumed read-only by
L<Langertha::Engine::OpenAI/_temperature_rejected_by_reasoning>.

=head2 disable_form

How "off" is expressed on the wire: C<absent> (omit the field),
C<explicit_none> (the literal C<none> level), C<think_false> (Ollama),
C<budget_zero> (Gemini flash C<thinkingBudget=0>) or C<thinking_disabled>
(C<< thinking =E<gt> { type =E<gt> 'disabled' } >>, the thinking-toggle rows;
read by L</thinking_toggle_for>).

=head2 thinking_on

Set only on a B<thinking-toggle> model: one whose wire takes a C<thinking>
object with an on/off C<type> and no effort level (MiniMax-M3 / M2.x, Kimi
K2.x; karr k209, k215). Its value is the "on" type the model takes:
C<adaptive> (MiniMax) or C<enabled> (Kimi). When set, L<Langertha::Reasoning>
serializes the effort onto that toggle on the C<openai> and C<anthropic> wires
instead of an effort field (see L</thinking_toggle_for>); the level ladder
collapses to on/off. Unset everywhere else.

=head2 wire_format

The reasoning dialect this model's family primarily speaks. Descriptive: the
serialization is still selected by the caller's C<reasoning_wire_format> (an
OpenAI-compatible engine may run a non-gpt model on the C<openai> wire), so it
is a curation hint, not the dispatch key.

=head2 is_gemini3

Selects the Gemini serialization branch: true for the Gemini 3 family (map onto
C<thinkingLevel> then clamp to L</levels>), false for everything else (the
universally-accepted binary C<low>|C<high> collapse a non-Gemini-3 model takes).

=head2 budget_min

=head2 budget_max

Provider-enforced integer C<thinkingBudget> bounds for a C<budget>-control
family (Gemini 2.5). Category (b) wire-truth: a later BudgetPolicy may only emit
values inside them. Carried but not enforced in Phase 1 (the value passes
through verbatim, as today).

=head2 off_value

The magic C<thinkingBudget> that disables thinking (Gemini flash / flash-lite:
C<0>); C<undef> where the family cannot disable (Gemini 2.5 pro).

=head2 dynamic_value

The magic C<thinkingBudget> that hands budget selection to the model (Gemini:
C<-1>).

=head2 source

The curation receipt — provider doc URL plus verification date — for the
accepted vocabulary and numeric bounds this profile encodes.

=head2 fable_class

True for the always-on Anthropic "Fable-class" models (the inverse of
L</can_disable>): they carry an effort but never a C<thinking> block.

=head2 thinking_toggle_for

    $profile->thinking_toggle_for('none')   # { type => 'disabled' } on MiniMax-M3
    $profile->thinking_toggle_for('high')   # { type => 'adaptive' }

The C<thinking> object a thinking-toggle model (L</has_thinking_on>) takes for
a normalized effort: C<none> gives C<< { type =E<gt> 'disabled' } >> when
L</disable_form> is C<thinking_disabled>, and nothing (C<undef>) on a model
that cannot turn thinking off — the field is omitted and the server default
applies, as on every always-on model; any other level gives
C<< { type =E<gt> L</thinking_on> } >>. C<undef> on a model without a toggle.

=head2 effort_accepted_on

    $profile->effort_accepted_on('openai', 'max')

Whether the given effort is accepted on the named OpenAI wire (C<openai> or
C<responses>). A family without a per-wire restriction (every non-gpt family and
the unlisted-id default) returns true for every effort — the full normalized
enum passes through, which is the current OpenAI enum. A restricted gpt family
checks membership in its L</levels_by_wire> set for that wire.

=head2 anthropic_effort_ok

Whether the effort maps onto this model's C<output_config.effort> vocabulary.
Per-model, checking membership in the resolved profile's own L</levels> rather
than a uniform Anthropic set: Claude 4.6 (opus/sonnet) accepts
C<low|medium|high|max> but B<not> C<xhigh>, while Claude 4.7+/5 accept the full
C<low|medium|high|xhigh|max> (karr k177). The normalized C<none>/C<minimal> have
no Anthropic equivalent and are absent from every Claude profile's C<levels>.

=head2 gemini_level_for

    $profile->gemini_level_for('max')   # -> 'high'

Maps the normalized effort onto the Gemini C<thinkingLevel> this model accepts.
A non-Gemini-3 family (L</is_gemini3> false) collapses to the universally
accepted binary C<low>|C<high> at C<high>. A Gemini 3 family maps onto the
C<minimal>|C<low>|C<medium>|C<high> base vocabulary then clamps down to its
L</levels> subset (never up — an unsupported level 400s), a level below the
family's floor rising to that floor.

=head2 ollama_level_for

    $profile->ollama_level_for('xhigh')   # -> 'max'

Maps the normalized effort onto the GPT-OSS C<options.think> level vocabulary
(C<low|medium|high|max>): C<none>/C<minimal>/C<low> become C<low>,
C<xhigh>/C<max> become C<max>, C<medium> and C<high> pass through. GPT-OSS
always reasons, so C<none> collapses onto the floor C<low> rather than an off
state (there is no off — C<think:false> is ignored). Mirrors
L</gemini_level_for>; only meaningful when L</has_ollama_levels> is true.

=head2 for_model

    my $profile = Langertha::Reasoning::Profile->for_model('gemini-3-pro-preview');

Resolve a model id to its profile, matched most-specific-first: an exact id, a
family regex, then the provider default (which every unlisted id and the
no-model case falls through to). Never dies.

=head1 SEE ALSO

=over

=item * L<Langertha::Reasoning> - The value object that resolves and consumes profiles

=item * L<Langertha::Reasoning::BudgetPolicy> - The category-(c) convention clamped to this object's (b) bounds

=item * L<Langertha::Role::ReasoningEffort> - The composed role dispatching to L<Langertha::Reasoning>

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
