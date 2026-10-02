package Langertha::Manifest::Builder;
# ABSTRACT: Build a provider manifest from configured engines (offline, never copies a secret)
our $VERSION = '0.503';
use Moose;
use Carp qw( carp croak );
use Scalar::Util qw( blessed );
use Module::Runtime qw( use_module );
use URI;
use Langertha::Manifest;


has provider_id => (
  is        => 'ro',
  isa       => 'Str',
  writer    => '_set_provider_id',
  predicate => 'has_provider_id',
);

has issuer => (
  is        => 'ro',
  isa       => 'Str',
  writer    => '_set_issuer',
  predicate => 'has_issuer',
);

has extensions => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

has _endpoints => ( is => 'ro', default => sub { [] } );
has _auth      => ( is => 'ro', default => sub { [] } );
has _models    => ( is => 'ro', default => sub { [] } );


# The capabilities a model entry may claim: exactly those that describe a
# CHAT CALL to that model at that endpoint -- what the request may carry and
# what the reply can be. Everything else engine_capabilities reports is left
# out on purpose:
#   - other operations of the engine (embedding, transcription,
#     image_generation) are not facts about a chat model;
#   - client-side or server-management features (runtime_metrics is
#     Langertha's own Prometheus scrape, prefix_caching the self-hosted
#     cache knobs, keep_alive Ollama's model residency, cached_content
#     Gemini's cache-resource lifecycle, context_size Ollama's server-side
#     num_ctx allocation) are not provider claims about a model either, and
#     would be wrong behind a proxy's public URL.
# A capability added to %ROLE_TO_CAPS later is NOT published until it is
# added here (t/96_manifest_builder.t forces that decision).
my @MODEL_CAPABILITIES = qw(
  chat
  streaming
  tools_native tools_hermes
  tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
  parallel_tool_use
  response_format_json_object response_format_json_schema
  reasoning_effort thinking_budget
  temperature seed
  system_prompt response_size
  prompt_cache prompt_cache_key
  server_tools
  image_input
);
my %MODEL_CAPABILITY = map { $_ => 1 } @MODEL_CAPABILITIES;

sub model_capabilities { return @MODEL_CAPABILITIES }


# Most specific first: OpenAIResponses isa OpenAI isa OpenAIBase. A code
# value decides within a family.
my @DIALECT_BY_CLASS = (
  [ 'Langertha::Engine::Perplexity'      => 'perplexity-agent' ],
  [ 'Langertha::Engine::OpenAIResponses' => 'responses' ],
  [ 'Langertha::Engine::OpenAIBase'      => 'openai-chat' ],
  # Same Messages envelope, two wire variants: first-party Anthropic sends
  # structured output as native output_config.format, the /anthropic shims
  # emulate it with a synthetic tool + forced tool_choice. The engine's own
  # predicate (Role::AnthropicCompatible) tells them apart.
  [ 'Langertha::Engine::AnthropicBase' => sub {
      $_[0]->_native_structured_output ? 'anthropic' : 'anthropic-compat' } ],
  [ 'Langertha::Engine::Gemini'   => 'gemini' ],
  [ 'Langertha::Engine::Ollama'   => 'ollama' ],
  [ 'Langertha::Engine::AKI'      => 'aki' ],
  [ 'Langertha::Engine::LMStudio' => 'lmstudio' ],
);

sub dialect_for_engine {
  my ( $class, $engine ) = @_;
  for my $row (@DIALECT_BY_CLASS) {
    my ( $isa, $dialect ) = @$row;
    next unless $engine->isa($isa);
    return ref $dialect eq 'CODE' ? $dialect->($engine) : $dialect;
  }
  return undef;
}


# The inverse of @DIALECT_BY_CLASS: per dialect the one generic class that
# takes the endpoint's base_url as its `url` (not a vendor subclass).
my %ENGINE_CLASS_BY_DIALECT = (
  'openai-chat'      => 'Langertha::Engine::OpenAI',
  'responses'        => 'Langertha::Engine::OpenAIResponses',
  'perplexity-agent' => 'Langertha::Engine::Perplexity',
  'anthropic'        => 'Langertha::Engine::Anthropic',
  'anthropic-compat' => 'Langertha::Engine::AnthropicBase',
  'gemini'           => 'Langertha::Engine::Gemini',
  'ollama'           => 'Langertha::Engine::Ollama',
  'aki'              => 'Langertha::Engine::AKI',
  'lmstudio'         => 'Langertha::Engine::LMStudio',
);

sub engine_class_for_dialect {
  my ( $class, $dialect ) = @_;
  return undef unless defined $dialect;
  my $engine_class = $ENGINE_CLASS_BY_DIALECT{$dialect} or return undef;
  return use_module($engine_class);
}


# Validation errors from the value objects are "...\n" strings without a
# location; re-raise them from the caller's perspective.
sub _reraise {
  my ($error) = @_;
  my $message = blessed($error) && $error->can('message') ? $error->message : "$error";
  $message =~ s/\s+\z//;
  croak $message;
}

sub from_engine {
  my ( $class, $engine, %opt ) = @_;
  my $self = $class->new(
    map { exists $opt{$_} ? ( $_ => delete $opt{$_} ) : () } qw( provider_id issuer extensions )
  );
  $self->add_engine( $engine, %opt );
  return $self->manifest;
}


sub add_engine {
  my ( $self, $engine, %opt ) = @_;
  croak 'Langertha::Manifest::Builder: add_engine needs a chat engine (an object'
    . ' composing Langertha::Role::Chat); ' . ( ref($engine) || 'a non-object' ) . ' is not one'
    unless blessed($engine) && $engine->can('does') && $engine->does('Langertha::Role::Chat');

  my $dialect = $opt{dialect} // $self->dialect_for_engine($engine);
  croak 'Langertha::Manifest::Builder: ' . ref($engine) . ' has no manifest dialect;'
    . ' pass dialect => ... to name one'
    unless defined $dialect;

  my $base_url = $opt{base_url} // ( $engine->can('url') ? $engine->url : undef );
  croak 'Langertha::Manifest::Builder: ' . ref($engine) . ' has no url; pass base_url => ...'
    unless defined $base_url;

  # Everything lazy is read from a clone, so the caller's engine keeps its
  # unbuilt slots (and a model-less engine with `models` given never runs its
  # croaking default_model).
  my $probe = _capability_clone($engine);

  my @model_ids;
  if ( $opt{models} ) {
    @model_ids = @{ $opt{models} };
  }
  else {
    my $model_id = eval { $probe->chat_model };
    croak 'Langertha::Manifest::Builder: cannot determine a model for ' . ref($engine)
      . '; pass models => [...]'
      if $@;
    # "default" is the self-hosted engines' placeholder for "whatever the
    # server loaded" -- not a model id worth publishing.
    @model_ids = grep { defined && length && $_ ne 'default' } $model_id;
    carp 'Langertha::Manifest::Builder: ' . ref($engine) . ' has only the placeholder model '
      . q{'} . ( $model_id // '' ) . q{'} . "; endpoint '" . ( $opt{endpoint_id} // 'chat' )
      . q{' is published without models (pass models => [...] to list them)}
      unless @model_ids;
  }

  my $auth_type = $opt{auth} // _auth_type_for($probe);
  my ( $auth_ref, $new_auth );
  if ( $auth_type ne 'none' ) {
    $auth_ref = $opt{auth_id} // 'api';
    my ($existing) = grep { $_->id eq $auth_ref } @{ $self->_auth };
    if ($existing) {
      croak "Langertha::Manifest::Builder: auth id '$auth_ref' already has type '"
        . $existing->type . q{'}
        unless $existing->type eq $auth_type;
    }
    else {
      $new_auth = eval { Langertha::Manifest::Auth->new( id => $auth_ref, type => $auth_type ) }
        or _reraise($@);
    }
  }

  my $endpoint_id = $opt{endpoint_id} // 'chat';
  my $endpoint = eval {
    Langertha::Manifest::Endpoint->new(
      id       => $endpoint_id,
      dialect  => $dialect,
      base_url => $base_url,
      ( defined $auth_ref ? ( auth_ref => $auth_ref ) : () ),
    );
  } or _reraise($@);
  $self->_check_new_endpoint($endpoint);

  my @models;
  for my $model_id (@model_ids) {
    my $model = eval {
      Langertha::Manifest::Model->new(
        id           => $model_id,
        endpoint_ref => $endpoint_id,
        capabilities => _capabilities_for( $engine, $model_id ),
      );
    } or _reraise($@);
    $self->_check_new_model( $model, @models );
    push @models, $model;
  }

  # All checks passed: commit. A croak above leaves the builder unchanged.
  push @{ $self->_auth }, $new_auth if $new_auth;
  push @{ $self->_endpoints }, $endpoint;
  push @{ $self->_models }, @models;
  $self->_set_provider_id( _provider_id_for( ref $engine ) ) unless $self->has_provider_id;
  $self->_set_issuer( _origin_of($base_url) ) unless $self->has_issuer;
  return $self;
}


sub _check_new_endpoint {
  my ( $self, $endpoint ) = @_;
  croak "Langertha::Manifest::Builder: duplicate endpoint id '" . $endpoint->id . q{'}
    if grep { $_->id eq $endpoint->id } @{ $self->_endpoints };
  return;
}

sub _check_new_model {
  my ( $self, $model, @pending ) = @_;
  croak "Langertha::Manifest::Builder: duplicate model '" . $model->id . "' on endpoint '"
    . $model->endpoint_ref . q{'}
    if grep { $_->id eq $model->id && $_->endpoint_ref eq $model->endpoint_ref }
      @{ $self->_models }, @pending;
  return;
}

sub add_endpoint {
  my ( $self, %args ) = @_;
  my $endpoint = eval { Langertha::Manifest::Endpoint->new(%args) } or _reraise($@);
  $self->_check_new_endpoint($endpoint);
  push @{ $self->_endpoints }, $endpoint;
  return $self;
}


sub add_auth {
  my ( $self, %args ) = @_;
  my $auth = eval { Langertha::Manifest::Auth->new(%args) } or _reraise($@);
  croak "Langertha::Manifest::Builder: duplicate auth id '" . $auth->id . q{'}
    if grep { $_->id eq $auth->id } @{ $self->_auth };
  push @{ $self->_auth }, $auth;
  return $self;
}


sub add_model {
  my ( $self, %args ) = @_;
  my $model = eval { Langertha::Manifest::Model->new(%args) } or _reraise($@);
  $self->_check_new_model($model);
  push @{ $self->_models }, $model;
  return $self;
}


sub manifest {
  my ($self) = @_;
  croak 'Langertha::Manifest::Builder: no provider_id (add an engine or pass provider_id)'
    unless $self->has_provider_id;
  croak 'Langertha::Manifest::Builder: no issuer (add an engine or pass issuer)'
    unless $self->has_issuer;
  my $manifest = eval {
    Langertha::Manifest->new(
      provider_id => $self->provider_id,
      issuer      => $self->issuer,
      endpoints   => [ @{ $self->_endpoints } ],
      auth        => [ @{ $self->_auth } ],
      models      => [ @{ $self->_models } ],
      extensions  => $self->extensions,
    );
  } or _reraise($@);
  return $manifest;
}


sub _provider_id_for {
  my ($class_name) = @_;
  ( my $name = $class_name ) =~ s/\A.*::Engine:://;
  $name =~ s/\A.*:://;
  return lc $name;
}

sub _origin_of {
  my ($url) = @_;
  my $uri = URI->new($url);
  return $url unless $uri->can('host') && $uri->can('port');
  my $origin = $uri->scheme . '://' . $uri->host;
  $origin .= ':' . $uri->port if $uri->port != $uri->default_port;
  return $origin;
}

# $probe is a clone: reading the lazy api_key builds it there, not on the
# caller's engine.
sub _auth_type_for {
  my ($probe) = @_;
  return 'api_key' if $probe->can('api_key_required') && $probe->api_key_required;
  # Optional key: announce the mechanism only when one is configured. Only
  # definedness is inspected; the value is dropped on the spot.
  return 'none'
    unless $probe->can('api_key_env') && defined $probe->api_key_env && $probe->can('api_key');
  my $configured = defined( scalar eval { $probe->api_key } );
  return $configured ? 'api_key' : 'none';
}

sub _capabilities_for {
  my ( $engine, $model_id ) = @_;
  # engine_capabilities is model-scoped (ADR 0019 layer 3 and model-aware
  # `around engine_capabilities`, e.g. Gemini): evaluate it on an in-memory
  # clone whose chat_model is this model. The caller's engine is not read
  # for its chat_model and not touched.
  my $probe = _capability_clone( $engine, chat_model => $model_id );
  my $caps  = $probe->engine_capabilities;
  return { map { $_ => 1 } grep { $caps->{$_} && $MODEL_CAPABILITY{$_} } keys %$caps };
}

# clone_object copies every slot already set, so a tool_wire_format the
# builder made for the source engine's chat_model would ride along into a
# probe for another model (karr k251). The probe drops a builder-made tag and
# resolves it again for its own chat_model; a constructor tag is kept.
sub _capability_clone {
  my ( $engine, %params ) = @_;
  my $probe = $engine->meta->clone_object( $engine, %params );
  $probe->_reset_derived_tool_wire_format if $probe->can('_reset_derived_tool_wire_format');
  return $probe;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Manifest::Builder - Build a provider manifest from configured engines (offline, never copies a secret)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Manifest::Builder;

    # One engine, one endpoint
    my $manifest = Langertha::Manifest::Builder->from_engine(
      Langertha::Engine::vLLM->new( url => 'http://gpu01:8000/v1', model => 'qwen3' ),
    );
    print $manifest->to_json;

    # A proxy exposing several protocol endpoints under its public URL
    my $builder = Langertha::Manifest::Builder->new(
      provider_id => 'my-knarr',
      issuer      => 'https://knarr.example',
    );
    $builder->add_engine( $openrouter_engine,        # no model of its own needed
      endpoint_id => 'openai', base_url => 'https://knarr.example/v1',
      models      => [ 'gpt-5.6', 'local-qwen' ] );
    $builder->add_endpoint( id => 'ollama', dialect => 'ollama',
      base_url => 'https://knarr.example' );
    $builder->add_model( id => 'local-qwen', endpoint_ref => 'ollama',
      capabilities => { chat => 1, streaming => 1 } );
    my $manifest = $builder->manifest;

=head1 DESCRIPTION

Maps configured Langertha chat engines into a L<Langertha::Manifest>.
Everything is read from the engine object: no network I/O happens (in
particular C<list_models> is never called), and the caller's engine is not
touched — lazy attributes (C<model>, C<chat_model>, C<api_key>) are
evaluated on in-memory clones, never on the engine itself.

=over

=item * B<dialect> — from the engine family, most specific class first:
L<Langertha::Engine::Perplexity> → C<perplexity-agent>,
L<Langertha::Engine::OpenAIResponses> → C<responses>,
L<Langertha::Engine::OpenAIBase> → C<openai-chat>,
L<Langertha::Engine::AnthropicBase> → C<anthropic> when the engine emits
first-party native structured output (C<output_config.format>), otherwise
C<anthropic-compat> (the C</anthropic> shims: AKIAnthropic,
MiniMaxAnthropic, MoonshotAnthropic, LMStudioAnthropic),
L<Langertha::Engine::Gemini> → C<gemini>, L<Langertha::Engine::Ollama> →
C<ollama>, L<Langertha::Engine::AKI> → C<aki>, L<Langertha::Engine::LMStudio>
→ C<lmstudio>. An engine that is not a chat engine (e.g. the
transcription-only L<Langertha::Engine::Whisper>) croaks.

=item * B<base_url> — the engine's C<url> (override with C<base_url> to
publish a public URL instead of an internal one).

=item * B<auth> — from the engine class's C<api_key_required> /
C<api_key_env>: a required key yields an C<api_key> auth entry; an optional
key only when one is configured; no key, no entry. Only the I<definedness>
of the key is looked at — its value never enters the manifest.

=item * B<models> — C<models =E<gt> [...]> when given. Otherwise the
engine's configured model; a placeholder id (C<default>, which the
self-hosted engines use for "whatever the server loaded", or an empty id)
is skipped rather than published (with a warning, since the endpoint then
lists no models), and an engine with no model at all
croaks asking for C<models>.

=item * B<capabilities> — C<engine_capabilities> evaluated B<per model>
(on a clone with C<chat_model> set to that model id, so model-scoped
corrections apply), then filtered to L</model_capabilities>: only flags that
describe a chat call to that model at that endpoint. Names are exactly the
registry's (L<Langertha::Role::Capabilities>); the Builder adds none.

=back

Known v1 limitations: engine-class facts that the capability flags cannot
express are not in the manifest — the Groq/Cerebras refusal of C<tools> plus
C<response_format> in one request (ADR 0024) and OpenAI's temperature gate
under active reasoning (ADR 0025).

=head2 provider_id

The manifest's C<provider_id>. When not given, the first L</add_engine>
derives it from the engine class (C<Langertha::Engine::vLLM> → C<vllm>).

=head2 issuer

The manifest's C<issuer>. When not given, the first L</add_engine> derives
it from the origin of the engine's URL.

=head2 extensions

HashRef passed into the manifest's C<extensions> (deep-copied there).

=head2 model_capabilities

    my @names = Langertha::Manifest::Builder->model_capabilities;

The allowlist of capability names a Builder-made model entry may claim —
the flags that describe a chat call to that model: C<chat>, C<streaming>,
the tool flags (C<tools_native>, C<tools_hermes>, C<tool_choice_auto>,
C<tool_choice_any>, C<tool_choice_none>, C<tool_choice_named>,
C<parallel_tool_use>), structured output (C<response_format_json_object>,
C<response_format_json_schema>), reasoning (C<reasoning_effort>,
C<thinking_budget>), sampling and request controls (C<temperature>,
C<seed>, C<system_prompt>, C<response_size>) and the
request-side prompt-cache controls (C<prompt_cache>, C<prompt_cache_key>),
C<server_tools> (the wire accepts provider-native server-side tools; I<which>
types is not published), and C<image_input> (the model sees an image part;
model-scoped, see L<Langertha::Role::ImageInput>).

Engine-level and client-side flags are never published on a model:
C<embedding>, C<transcription>, C<image_generation>, C<runtime_metrics>,
C<prefix_caching>, C<keep_alive>, C<cached_content>, C<context_size> (Ollama's
server-side C<num_ctx> allocation, like C<keep_alive>).

This filters only what the Builder B<emits>. A parsed manifest accepts any
capability name (L<Langertha::Manifest::Model/supports>).

=head2 dialect_for_engine

    my $dialect = Langertha::Manifest::Builder->dialect_for_engine($engine);

The manifest dialect of an engine (see L</DESCRIPTION>), or C<undef> when
its family has none.

=head2 engine_class_for_dialect

    my $engine_class = Langertha::Manifest::Builder->engine_class_for_dialect('openai-chat');
    my $engine = $engine_class->new( url => $endpoint->base_url, api_key => $key );

The inverse of L</dialect_for_engine>: the generic engine class that speaks
a manifest dialect, loaded and ready for C<new>, or C<undef> for an unknown
(or undefined) dialect. It never croaks on an unknown dialect.

Each dialect maps to the one class that takes the endpoint's C<base_url> as
its C<url>, not to a vendor subclass: C<openai-chat> is
L<Langertha::Engine::OpenAI> (the ~25 OpenAI-compatible engines share that
wire), C<responses> L<Langertha::Engine::OpenAIResponses>, C<perplexity-agent>
L<Langertha::Engine::Perplexity>, C<anthropic> L<Langertha::Engine::Anthropic>,
C<anthropic-compat> L<Langertha::Engine::AnthropicBase> (the C</anthropic>
shims), C<gemini> L<Langertha::Engine::Gemini>, C<ollama>
L<Langertha::Engine::Ollama>, C<aki> L<Langertha::Engine::AKI> and
C<lmstudio> L<Langertha::Engine::LMStudio>. Every dialect of
L<Langertha::Manifest::Endpoint/known_dialects> has a class, and a test holds
the round trip: C<dialect_for_engine> of that class gives the dialect back.

=head2 from_engine

    my $manifest = Langertha::Manifest::Builder->from_engine( $engine, %options );

Shortcut: a builder with C<provider_id> / C<issuer> / C<extensions> from
C<%options>, one L</add_engine> with the rest, then L</manifest>.

=head2 add_engine

    $builder->add_engine( $engine,
      endpoint_id => 'chat',            # default 'chat'
      base_url    => $public_url,       # default $engine->url
      models      => [ ... ],           # default: the engine's model (placeholders skipped)
      auth        => 'api_key',         # or 'none'; default from the engine class
      auth_id     => 'api',             # default 'api' (shared across engines)
      dialect     => 'openai-chat',     # default from the engine family
    );

Adds one endpoint for the chat engine, its auth entry (if any) and one
model entry per model id. Croaks for a non-chat engine, for a chat engine
without a manifest dialect unless C<dialect> is given, for a model-less
engine unless C<models> is given, and on a duplicate endpoint id or
C<(model, endpoint)> pair. Atomic: on a croak the builder is unchanged.
Returns the builder.

=head2 add_endpoint

    $builder->add_endpoint( id => ..., dialect => ..., base_url => ..., auth_ref => ... );

Adds an endpoint that is not an engine (a proxy's own protocol route).
Croaks on a duplicate id.

=head2 add_auth

    $builder->add_auth( id => 'api', type => 'api_key' );

Adds an auth entry. Croaks on a duplicate id.

=head2 add_model

    $builder->add_model( id => ..., endpoint_ref => ..., capabilities => { ... } );

Adds a model entry as given (no capability filtering: the caller states the
claim). Croaks on a duplicate C<(id, endpoint_ref)> pair.

=head2 manifest

Returns the validated L<Langertha::Manifest>.

=head1 SEE ALSO

=over

=item * L<Langertha::Manifest> - The manifest value object and validator

=item * L<Langertha::Role::Capabilities> - Where the capability names come from

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
