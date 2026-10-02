package Langertha::Role::Capabilities;
# ABSTRACT: Engine-capability registry derived from composed roles
our $VERSION = '0.503';
use Moose::Role;
use Carp qw( croak );
use Scalar::Util qw( blessed );
use Future::AsyncAwait;
use Langertha::ModelProbe;


# Role-name => list of capability flag names that role contributes.
# Plus implicit:
#   chat            -> simple_chat works (Role::Chat is composed)
#   streaming       -> chat_stream_request is wired up (Role::Streaming)
#   tools_native    -> Role::Tools (the named flags below come too)
#   tools_hermes    -> Role::HermesTools
#   ... see %ROLE_TO_CAPS below.
# Every Langertha::Role::* is on one of two axes (ADR 0016 decision 2):
# a capability (an entry here) or envelope/infrastructure (the allowlist
# in t/78_capability_registry.t). That guard fails on a role in neither,
# so a new role cannot quietly skip the decision.
my %ROLE_TO_CAPS = (
  'Langertha::Role::Chat'             => [qw( chat )],
  'Langertha::Role::Streaming'        => [qw( streaming )],
  'Langertha::Role::Tools'            => [qw(
    tools_native tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
  )],
  'Langertha::Role::HermesTools'      => [qw( tools_hermes )],
  'Langertha::Role::ResponseFormat'   => [qw(
    response_format_json_object response_format_json_schema
  )],
  'Langertha::Role::Embedding'        => [qw( embedding )],
  'Langertha::Role::Transcription'    => [qw( transcription )],
  'Langertha::Role::ImageGeneration'  => [qw( image_generation )],
  'Langertha::Role::Temperature'      => [qw( temperature )],
  'Langertha::Role::ReasoningEffort'  => [qw( reasoning_effort )],
  'Langertha::Role::PromptCache'      => [qw( prompt_cache prompt_cache_key )],
  'Langertha::Role::CachedContent'    => [qw( cached_content )],
  'Langertha::Role::Seed'             => [qw( seed )],
  'Langertha::Role::ContextSize'      => [qw( context_size )],
  'Langertha::Role::ResponseSize'     => [qw( response_size )],
  'Langertha::Role::SystemPrompt'     => [qw( system_prompt )],
  'Langertha::Role::KeepAlive'        => [qw( keep_alive )],
  'Langertha::Role::ParallelToolUse'  => [qw( parallel_tool_use )],
  'Langertha::Role::Runtime::MetricsPoll' => [qw( runtime_metrics )],
  'Langertha::Role::RuntimeKnobs'    => [qw( prefix_caching )],
  'Langertha::Role::ServerTools'      => [qw( server_tools )],
  'Langertha::Role::ImageInput'       => [qw( image_input )],
);

sub engine_capabilities {
  my ($self) = @_;
  my %caps;
  for my $role ( keys %ROLE_TO_CAPS ) {
    next unless $self->does($role);
    $caps{$_} = 1 for @{ $ROLE_TO_CAPS{$role} };
  }
  # Layer 3 (ADR 0002 amendment, ADR 0019): per-model refinement.
  # The tool / structured-output wire reality is often per-MODEL, not
  # per-engine (kimi-k3 forbids a forced named tool while its K2.x siblings
  # allow it; deepseek-reasoner clamps differ from deepseek-chat). Engines
  # declare a model-id/pattern -> {cap => 0|1} table in
  # model_capability_corrections; it refines the role-derived base for the
  # currently selected chat_model. Engine-WIDE corrections stay in
  # `around engine_capabilities` (the outer endpoint-reality gate, layer 2).
  # The wire set (layer 1) before any model-scoped refinement: a learned fact
  # can re-assert only a flag the composed roles grant (ADR 0032).
  my %wire = %caps;
  $self->_apply_model_capability_corrections(\%caps);
  # Learned layer (ADR 0032): facts the engine read from the provider's own
  # model metadata (probe_model_capabilities_f), for this chat_model. They
  # run after the static per-model table, so for a model the probe reported,
  # the provider's statement beats the static default in both directions.
  # Empty until the caller probes: supports() never does network I/O.
  $self->_apply_learned_model_capabilities( \%caps, \%wire );
  return \%caps;
}

# Default: no per-model corrections. Engines override with a declarative,
# ordered list of ( $matcher => \%overrides ) pairs — see the =method below.
sub model_capability_corrections { return () }

sub _apply_model_capability_corrections {
  my ( $self, $caps ) = @_;
  my @corrections = $self->model_capability_corrections;
  return unless @corrections;
  # chat_model is the model that actually carries tools / tool_choice /
  # response_format on the wire (Role::Chat); guard for the rare consumer
  # of engine_capabilities that has no model surface at all.
  # An empty or undef chat_model is matched as '' rather than skipped, so a
  # default-deny catch-all row (qr/\A/, Engine::MiniMax, ADR 0019 k209 Update)
  # holds even for model => ''; every family row needs a real id to match.
  return unless $self->can('chat_model');
  my $model = $self->_capability_model // '';
  while ( @corrections >= 2 ) {
    my ( $matcher, $overrides ) = splice @corrections, 0, 2;
    my $hit = ref $matcher eq 'Regexp' ? ( $model =~ $matcher )
            :                            ( $model eq $matcher );
    next unless $hit;
    # Later matching entries win on a shared flag. A true value asserts the
    # capability, a false value clears it.
    for my $cap ( keys %$overrides ) {
      if ( $overrides->{$cap} ) { $caps->{$cap} = 1 }
      else                      { delete $caps->{$cap} }
    }
  }
  return;
}

# The model the capability picture is evaluated for. An engine without a
# default model (OpenRouter, OllamaOpenAI, Groq) croaks when chat_model is
# built with no model configured. For the capability picture that means "no
# model", which the table walk matches as '' (ADR 0019 k209 rule), not an
# error of supports() (ADR 0032).
sub _capability_model {
  my ( $self ) = @_;
  return undef unless $self->can('chat_model');
  my $model;
  # supports() must not leave the chat_model croak behind in the caller's $@.
  local $@;
  my $ok = eval { $model = $self->chat_model; 1 };
  return $ok ? $model : undef;
}

has _learned_model_capabilities => (
  is       => 'ro',
  isa      => 'HashRef',
  default  => sub { {} },
  writer   => '_set_learned_model_capabilities',
  init_arg => undef,
);

sub _apply_learned_model_capabilities {
  my ( $self, $caps, $wire ) = @_;
  my $learned = $self->_learned_model_capabilities;
  return unless %$learned;
  my $model = $self->_capability_model;
  return unless defined $model && !ref $model && length $model;
  # Exact id first, then the format's equivalent spellings (Ollama's implicit
  # :latest tag, OpenRouter's :variant suffixes), see ModelProbe->lookup_ids.
  my $format = $self->model_metadata_format;
  my @ids = defined $format && Langertha::ModelProbe->is_known_format($format)
    ? Langertha::ModelProbe->lookup_ids( $format, $model ) : ( $model );
  my ($facts) = grep { ref $_ eq 'HASH' } map { $learned->{$_} } @ids;
  return unless $facts;
  for my $cap ( keys %$facts ) {
    if ( $facts->{$cap} ) { $caps->{$cap} = 1 if $wire->{$cap} }
    else                  { delete $caps->{$cap} }
  }
  return;
}

sub learned_model_capabilities {
  my ( $self ) = @_;
  my $learned = $self->_learned_model_capabilities;
  return { map { $_ => { %{ $learned->{$_} } } } keys %$learned };
}

sub clear_learned_model_capabilities {
  my ( $self ) = @_;
  $self->_set_learned_model_capabilities( {} );
  return;
}

# Engine hooks (ADR 0032). An engine that can read its provider's model
# metadata names the document format (a Langertha::ModelProbe tag) and its
# URL. The default is no probe: probe_model_capabilities_f resolves to {}
# without a request.
sub model_metadata_format { return undef }
sub model_metadata_url    { return undef }

async sub probe_model_capabilities_f {
  my ( $self, %args ) = @_;
  my $format = $self->model_metadata_format;
  return {} unless defined $format;
  my $url = $self->model_metadata_url;
  croak ref($self) . ": model_metadata_format '$format' without a model_metadata_url"
    unless defined $url && length $url;

  my @models;
  if ( exists $args{models} && !ref $args{models} && ( $args{models} // '' ) eq 'all' ) {
    # The whole catalogue (k282): only a document that names its models can
    # answer "every model"; the others need ids to key their fact by.
    croak ref($self) . ": probe_model_capabilities_f models => 'all' needs a catalogue"
      . " document; model_metadata_format '$format' does not name its models"
      unless Langertha::ModelProbe->is_catalogue($format);
  }
  elsif ( exists $args{models} ) {
    croak ref($self) . q{: probe_model_capabilities_f models must be an ArrayRef or 'all'}
      unless ref $args{models} eq 'ARRAY';
    @models = grep { defined && !ref && length } @{ $args{models} };
  }
  else {
    my $model = $self->_capability_model;
    @models = ( $model ) if defined $model && !ref $model && length $model;
  }

  my $probe     = 'Langertha::ModelProbe';
  my $method    = $probe->http_method($format);
  my $per_model = $probe->per_model($format);
  # A per-model document (Ollama /api/show) takes one request per model and
  # needs a model; a server-wide document is one request whatever was asked.
  my @batches = $per_model ? ( map { [ $_ ] } @models ) : ( [ @models ] );
  my %allowed = map { $_ => 1 } $probe->probed_capabilities;

  my %learned;
  for my $batch (@batches) {
    my $request = $self->generate_http_request( $method, $url, sub { $_[0] },
      $per_model ? ( model => $batch->[0] ) : () );
    my $response = await $self->_async_do_request_f( request => $request );
    # A per-model document that does not know the model (Ollama /api/show
    # answers 404 "model not found") gives no fact for that model; the other
    # models of the call are still learned. Every other failure fails loud.
    next if $per_model && $response->code == 404;
    unless ( $response->is_success ) {
      my $body = $self->can('_error_response_body') ? $self->_error_response_body($response) : '';
      croak ref($self) . ' model metadata probe failed: ' . $response->status_line
        . ( length $body ? " - $body" : '' );
    }
    my $data;
    {
      local $@;
      croak ref($self) . ' model metadata probe: response from ' . $request->uri->path
        . ' is not JSON'
        unless eval { $data = $self->json->decode( $response->content ); 1 };
    }
    my $facts = $probe->extract( $format, $data, $batch );
    for my $model ( grep { length } keys %$facts ) {
      for my $cap ( grep { $allowed{$_} } keys %{ $facts->{$model} } ) {
        $learned{$model}{$cap} = $facts->{$model}{$cap} ? 1 : 0;
      }
    }
  }

  $self->_merge_learned_model_capabilities( \%learned );
  return \%learned;
}

# Merge facts into the store; a later fact for the same model and capability
# wins. A new HashRef, never a mutation in place: clone_object
# (Manifest::Builder) shares the slot, and a clone that probes or imports must
# not write into its source.
sub _merge_learned_model_capabilities {
  my ( $self, $learned ) = @_;
  my $current = $self->learned_model_capabilities;
  for my $model ( keys %$learned ) {
    $current->{$model} = { %{ $current->{$model} // {} }, %{ $learned->{$model} } };
  }
  $self->_set_learned_model_capabilities($current);
  return;
}

sub _is_fact_value {
  my ( $value ) = @_;
  return 0 unless defined $value;
  return 1 unless ref $value;
  return blessed($value) ? 1 : 0;
}

sub import_learned_capabilities {
  my ( $self, $map ) = @_;
  croak ref($self) . ': import_learned_capabilities needs a HashRef of { $model_id => { $capability => 0|1 } }'
    unless ref $map eq 'HASH';
  my %allowed = map { $_ => 1 } Langertha::ModelProbe->probed_capabilities;
  my %import;
  for my $model ( keys %$map ) {
    # Hash keys are always strings; an empty key is never a model id.
    next unless length $model && ref $map->{$model} eq 'HASH';
    my $facts = $map->{$model};
    # A fact is a defined plain scalar or a JSON boolean (a map that went
    # through a JSON store); undef or an unblessed reference is no fact.
    for my $cap ( grep { $allowed{$_} && _is_fact_value( $facts->{$_} ) } keys %$facts ) {
      $import{$model}{$cap} = $facts->{$cap} ? 1 : 0;
    }
  }
  $self->_merge_learned_model_capabilities( \%import );
  return \%import;
}

sub probe_model_capabilities {
  my ( $self, %args ) = @_;
  # ->get drives the loop the pending future belongs to, or returns at once
  # on the synchronous fallback (ADR 0027), as poll_metrics does.
  return $self->probe_model_capabilities_f(%args)->get;
}




sub supports {
  my ( $self, $cap ) = @_;
  return !!$self->engine_capabilities->{$cap};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Capabilities - Engine-capability registry derived from composed roles

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    if ( $engine->supports('tool_choice_named') ) { ... }

    my $caps = $engine->engine_capabilities;
    for my $cap ( sort keys %$caps ) {
        say "$cap" if $caps->{$cap};
    }

    # Engine-level override for a wire reality the role inventory
    # cannot express (e.g. provider only accepts string tool_choice):
    around engine_capabilities => sub {
      my ( $orig, $self, @rest ) = @_;
      my $caps = $self->$orig(@rest);
      delete $caps->{tool_choice_named};
      return $caps;
    };

=head1 DESCRIPTION

Composed by L<Langertha::Role::Chat> (and therefore present on every
engine), this role provides the C<engine_capabilities> method plus the
C<supports> helper. The default implementation derives the flag set
from which capability-bearing roles the engine composes — no per-role
plumbing required, the registry below is the single source of truth.

Engines override (via C<around>) when the wire reality differs from
the role inventory — for example to clear C<tool_choice_named> on a
provider that only accepts string forms of C<tool_choice>.

The mapping from role to flag is intentionally kept inside this one
module so adding a new capability is a single-file change. The role
itself does not need to know about C<engine_capabilities>.

=head2 probe_model_capabilities_f

    my $learned = await $engine->probe_model_capabilities_f;
    my $learned = await $engine->probe_model_capabilities_f( models => [ 'llava', 'llama3.3' ] );
    # { 'llava' => { image_input => 1 }, 'llama3.3' => { image_input => 0 } }

    $engine->supports('image_input');   # now answers from the learned fact

Asks the provider's own model metadata endpoint which capabilities a model has
and stores the answer on this engine instance (ADR 0032). It is the only way
facts enter the learned layer: C<supports> and L</engine_capabilities> never
send a request.

Without C<models>, the probe asks about C<chat_model> (nothing when no model is
configured). Endpoints that describe every model in one document (OpenRouter,
Mistral, LM Studio, TSystems) are fetched once and every model they describe is learned;
Ollama's C</api/show> is asked once per model; llama.cpp's C</props> describes
the one loaded model, so its fact is stored for every id that was asked about.

C<< models => 'all' >> asks for the whole catalogue and does not fall back to
C<chat_model>: every model the document names is learned from one request.
It croaks on a format whose document does not name its models (Ollama,
llama.cpp; see L<Langertha::ModelProbe/is_catalogue>). Use it to probe an
endpoint once and hand the result to the other engine instances on the same
endpoint with L</import_learned_capabilities>.

Resolves to C<< { $model_id => { $capability => 0|1 } } >>, the facts learned by
this call, exactly as they were merged into the engine's store (a fresh
HashRef the caller owns, ready for L</import_learned_capabilities>). Only the capabilities in
L<Langertha::ModelProbe/probed_capabilities> are learned (C<image_input>). A
model the document does not describe, or describes without the field, gets no
fact and keeps its static answer.

Engines that implement a probe: L<Langertha::Engine::OpenRouter>,
L<Langertha::Engine::Mistral>, L<Langertha::Engine::Ollama>,
L<Langertha::Engine::OllamaOpenAI>, L<Langertha::Engine::LMStudio>,
L<Langertha::Engine::LMStudioOpenAI>, L<Langertha::Engine::LlamaCpp> and
L<Langertha::Engine::TSystems> (documentation-derived, not live-verified). On
every other engine the method exists and resolves to an empty HashRef without
a request.

Only non-empty plain strings count as model ids; anything else in C<models>
is ignored. When C<chat_model> is looked up in the store, the exact id wins,
then the format's equivalent spelling (L<Langertha::ModelProbe/lookup_ids>):
on Ollama a missing tag means C<:latest> (C<llava> finds C<llava:latest> and
back), on OpenRouter a routing variant such as C<:online> or C<:free> falls
back to its base id when the variant itself is not listed.

On Ollama a model the server does not have (C</api/show> answers 404) gives
no fact, and the other models of the call are still learned. Any other
non-success answer fails the future with C<< <engine> model metadata probe
failed: <status> - <body> >>, a success answer that is not JSON with C<<
<engine> model metadata probe: response from <path> is not JSON >>; in both
cases nothing from the call is stored.

=head2 probe_model_capabilities

    my $learned = $engine->probe_model_capabilities;

Synchronous wrapper around L</probe_model_capabilities_f> (blocks with
C<< ->get >>).

=head2 learned_model_capabilities

    my $learned = $engine->learned_model_capabilities;
    # { 'openai/gpt-4o' => { image_input => 1 }, ... }

A copy of every fact probed or imported so far on this instance, per model id.
It has the shape L</import_learned_capabilities> takes.

=head2 import_learned_capabilities

    # One metadata fetch for a whole endpoint, shared by every instance on it:
    my $learned = await $probe_engine->probe_model_capabilities_f( models => 'all' );
    $_->import_learned_capabilities($learned) for @other_engines;

Merges C<< { $model_id => { $capability => 0|1 } } >> into this instance's
learned store, as if this instance had probed it: the facts take the same
place in L</engine_capabilities> (after the static per-model table, under the
layer-1 and layer-2 wire gates), and a later fact for the same model and
capability replaces the earlier one. The map is the result of
L</probe_model_capabilities_f> or L</learned_model_capabilities> of another
instance; nothing is fetched (ADR 0032).

Only the capabilities in L<Langertha::ModelProbe/probed_capabilities> are
taken; other names are ignored. An empty model id, a model whose facts are not
a HashRef, and a fact value that is C<undef> or an unblessed reference are
skipped; any other value is stored as C<1> or C<0> by truth (a JSON boolean
works). Croaks unless the argument is a HashRef. Returns the facts it merged,
in the same shape.

Facts are keyed by model id, not by endpoint: import only into instances that
talk to the endpoint the facts were read from.

=head2 clear_learned_model_capabilities

Forgets every probed or imported fact; L</engine_capabilities> answers from the static
layers again.

=head2 model_metadata_format

The L<Langertha::ModelProbe> format tag of this engine's model metadata, or
C<undef> (the default) when the engine has no probe.

=head2 model_metadata_url

The URL L</probe_model_capabilities_f> requests, or C<undef> (the default).

=head2 engine_capabilities

    my $caps = $engine->engine_capabilities;

Returns a HashRef of capability flags. The default derives the flag set in
three layers: (1) it scans the composed role inventory and sets flags from
the static role-to-flags map (ADR 0002); (2) an engine may correct the
whole-endpoint wire reality via C<around> (remove flags the wire cannot
deliver at all, or add an ad-hoc flag — the outer gate); (3) it applies the
engine's C<model_capability_corrections> for the currently selected
C<chat_model>, refining the base where the wire reality is per-model rather
than per-engine (ADR 0002 amendment, ADR 0019).

After layer 3 comes the B<learned layer> (ADR 0032): facts that
L</probe_model_capabilities_f> read from the provider's own model metadata for
the current C<chat_model>. For a model the probe reported, the provider's
statement wins over the static table in both directions; a learned C<1> can
only re-assert a flag the composed roles grant (layer 1). The learned layer
runs inside the base method, so the engine's C<around> (layer 2) still has the
last word: a wire that cannot carry a field stays closed. The learned layer is
empty until the caller probes, so this method never sends a request.

A capability flag means B<the wire accepts the field>, not that any given
model will honor it. For example C<reasoning_effort> being true says the
engine's API will accept a reasoning-effort field on the request; whether a
particular model supports reasoning is a separate runtime concern (every
reasoning field 400s on a non-reasoning model). Engines whose wire never
accepts the field clear the flag via C<around engine_capabilities>
(e.g. Perplexity), or per model via L</model_capability_corrections> (e.g.
MiniMax's OpenAI endpoint, where only C<MiniMax-M3> keeps it).

Prompt caching is request-side-asymmetric, so it gets B<two> flags rather
than one: C<prompt_cache> means the wire accepts an explicit cache-enable
breakpoint (Anthropic's C<cache_control>), while C<prompt_cache_key> means the
wire accepts an OpenAI-style routing hint (caching itself is automatic there).
The single C<Langertha::Role::PromptCache> role contributes both; the
C<OpenAIBase> / C<AnthropicBase> base classes each clear the one that does not
apply to their wire, so the OpenAI family advertises only the key and the
Anthropic family only the enable breakpoint.

C<prefix_caching> (from C<Langertha::Role::RuntimeKnobs>, composed on the
self-hosted vLLM / SGLang / llama.cpp engines) means B<the wire accepts
prefix-cache isolation/reuse controls> (C<cache_salt>, C<cache_prompt>,
C<n_cache_reuse>, C<id_slot>, C<priority>, C<return_cached_tokens_details>,
C<extra_key>) — B<not> that prefix caching is on. Whether the server actually
caches is launch state the client cannot observe (vLLM C<--enable-prefix-caching>,
SGLang C<--enable-mixed-prefill> / C<--enable-prefix-caching>, llama.cpp
C<--cache_prompt>); the flag only says the request body may carry the knobs.

C<server_tools> (from C<Langertha::Role::ServerTools>) means B<the wire accepts
provider-native server-side tool entries in C<tools>> (C<web_search>,
C<file_search>, remote C<mcp>, ...; see L<Langertha::ServerTool>). It is one
flag on purpose: which tool types a model honors is a fast-moving provider
vocabulary, not a capability.

C<image_input> (from C<Langertha::Role::ImageInput>) is the exception to the
wire-only contract: it means B<the selected model sees an image part>
(L<Langertha::Content::Image>), not merely that the wire accepts one. It is
resolved per model; engines whose model is unknown to the client (gateways,
self-hosted servers, shims) make no claim. The flag is advisory: nothing
blocks an image on an engine or model without it.

=head2 model_capability_corrections

    sub model_capability_corrections {
      return (
        'kimi-k3'       => { tool_choice_named => 0 },  # exact model id
        qr/\Akimi-k2\./ => { tool_choice_any   => 0 },  # a model family
      );
    }

The per-model correction layer (layer 3 of C<engine_capabilities>).
Returns an B<ordered> list of C<< ( $matcher => \%overrides ) >> pairs.
C<$matcher> is either an exact model-id string (matched with C<eq>) or a
C<qr//> regex (matched against the engine's C<chat_model>) — model ids come
in families (C<gpt-5.6-*>, C<kimi-k2.7-*>), so both forms are supported.
C<\%overrides> maps a capability flag to C<1> (assert) or C<0> (clear);
later matching entries win on a shared flag.

This is the sanctioned home for a wire reality that differs B<per model>
rather than per engine — for example a model that forbids a forced named
tool while its siblings allow it. Engine-B<wide> corrections (the whole
endpoint never accepts a field) belong in C<around engine_capabilities>
instead. The default returns an empty list, so engines that need no
per-model refinement pay nothing.

=head2 supports

    if ( $engine->supports('tool_choice_named') ) { ... }

Convenience wrapper that returns a true value when the named capability
is present and truthy in C<engine_capabilities>.

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
