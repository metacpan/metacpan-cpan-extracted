package Langertha::Engine::Ollama;
# ABSTRACT: Ollama API
our $VERSION = '0.503';
use Moose;
use File::ShareDir::ProjectDistDir qw( :all );
use Carp qw( croak );
use JSON::MaybeXS;
use Module::Runtime qw( use_module );
use Langertha::Response;
use Langertha::ToolCall;
use Langertha::Reasoning;

use Langertha::Engine::OllamaOpenAI;

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  OpenAPI
  Models
  Seed
  Temperature
  ContextSize
  ResponseSize
  SystemPrompt
  KeepAlive
  Chat
  Embedding
  ResponseFormat
  Streaming
  Tools
  ImageInput
);


sub openai {
  my ( $self, %args ) = @_;
  return Langertha::Engine::OllamaOpenAI->new(
    url => $self->url.'/v1',
    model => $self->model,
    defined $self->api_key ? ( api_key => $self->api_key ) : (),
    # The pin carries over while the url stays on its host (karr k375).
    $self->_connect_address_for( exists $args{url} ? $args{url} : $self->url.'/v1' ),
    $self->embedding_model ? ( embedding_model => $self->embedding_model ) : (),
    $self->chat_model ? ( chat_model => $self->chat_model ) : (),
    $self->has_system_prompt ? ( system_prompt => $self->system_prompt ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    %args,
  );
}


sub new_openai {
  my ( $class, %args ) = @_;
  my $tools = delete $args{tools} || [];
  my $self = $class->new(%args);
  # openai() copies only a few settings from the native engine; every other
  # argument meant for the returned engine is handed on directly (karr k335).
  my %accepts = map { $_->init_arg => 1 }
    grep { defined $_->init_arg } Langertha::Engine::OllamaOpenAI->meta->get_all_attributes;
  my %pass = map { $_ => $args{$_} } grep { $accepts{$_} && $_ ne 'url' } keys %args;
  $pass{mcp_servers} = [ @{ $pass{mcp_servers} // [] }, @$tools ] if @$tools;
  return $self->openai(%pass);
}


sub default_model { 'llama3.3' }
sub default_embedding_model { 'mxbai-embed-large' }

# api_key_env derives LANGERTHA_OLLAMA_API_KEY, the variable _build_api_key
# reads: it unlocks Ollama Cloud, a local server needs no credentials.
sub api_key_required { 0 }

has api_key => (
  is => 'ro',
  lazy_build => 1,
);

sub _build_api_key {
  return $ENV{LANGERTHA_OLLAMA_API_KEY};
}


sub update_request {
  my ( $self, $request ) = @_;
  my $key = $self->api_key;
  $request->header('Authorization', 'Bearer '.$key) if defined $key;
}


sub openapi_file { yaml => dist_file('Langertha','ollama.yaml') };

sub _build_openapi_operations {
  return use_module('Langertha::Spec::Ollama')->data;
}


has json_format => (
  isa => 'Bool',
  is => 'ro',
  default => sub {0},
);


sub embedding_request {
  my ( $self, $prompt, %extra ) = @_;
  return $self->generate_request( embed => sub { $self->embedding_response(shift, $prompt) },
    model => $self->embedding_model,
    input => $prompt,
    # /api/embed truncates and renormalizes to `dimensions` for any model (k319).
    defined $self->embedding_dimensions ? ( dimensions => $self->embedding_dimensions ) : (),
    %extra,
  );
}

sub embedding_response {
  my ( $self, $response, $input ) = @_;
  my $data = $self->parse_response($response);
  # /api/embed returns one vector per input, by position. An ArrayRef input is
  # a batch and gets them all; a string input keeps getting one vector (k289).
  my $embeddings = ref $data eq 'HASH' ? $data->{embeddings} : undef;
  # No vector is not a result: older Ollama answers some load errors with a
  # 200 {"error":...}, and undef would be stored as a vector (k290).
  unless ( ref $embeddings eq 'ARRAY' && @{$embeddings}
    && !grep { ref $_ ne 'ARRAY' || !@{$_} } @{$embeddings} ) {
    my $err = ref $data eq 'HASH' ? $data->{error} : undef;
    $err = $err->{message} if ref $err eq 'HASH';
    croak "".(ref $self)." embedding response contained no vector"
      .( defined $err ? " (error: $err)" : '' );
  }
  if ( ref $input eq 'ARRAY' ) {
    my $count = scalar @{$embeddings};
    croak "".(ref $self)." embedding response returned $count vectors for "
      .scalar(@{$input})." inputs"
      unless $count == @{$input};
    return [ @{$embeddings} ];
  }
  return $embeddings->[0];
}

sub chat_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};
  # No parallel knob on this wire (parallel_tool_use is cleared): a value the
  # caller set is only dropped, with the shared carp (karr k241).
  $self->_parallel_tool_calls_kwarg( \%extra, $controls );

  # /api/chat has no tool_choice field: the tool_choice_* flags are cleared
  # below, so the shared rule drops it (none withholds the tools, a forced
  # choice carps; karr k239).
  $self->_gate_tool_choice(\%extra);

  # Translate response_format -> Ollama's format parameter. Ollama
  # accepts either the literal string 'json' or a JSON-Schema HashRef.
  # A per-request response_format (chat_f) beats the engine attribute,
  # and is removed from the extras either way: Ollama has no
  # response_format field and would silently ignore it. Fall back to the
  # legacy json_format attribute when neither is set.
  my $rf = exists $controls->{response_format}
    ? delete $controls->{response_format}
    : exists $extra{response_format}
      ? delete $extra{response_format}
      : $self->has_response_format ? $self->response_format : undef;
  my $format;
  if ( defined $rf ) {
    my $type = ref($rf) eq 'HASH' ? ( $rf->{type} // '' ) : '';
    if ( $type eq 'json_object' ) {
      $format = 'json';
    }
    elsif ( $type eq 'json_schema'
        && ref( $rf->{json_schema} ) eq 'HASH'
        && ref( $rf->{json_schema}{schema} ) eq 'HASH' ) {
      $format = $rf->{json_schema}{schema};
    }
  }
  $format = 'json' if !defined $format && $self->json_format;

  # reasoning_effort -> the TOP-LEVEL `think` field, a sibling of
  # model/messages/stream — NOT under options. Live-probed 2026-09-17 via
  # ollama.com gpt-oss:20b: `think` inside options is silently ignored (low and
  # max both yield the default ~180-220 thinking chars), while top-level `think`
  # grades cleanly (low ~25-47, max ~207-402). Ollama does not compose
  # ReasoningEffort, so serialize directly via the value object rather than
  # advertising the capability; to_ollama emits (think => <boolean|level>).
  my @reasoning = exists $controls->{reasoning_effort}
    ? Langertha::Reasoning->new(
        effort => $controls->{reasoning_effort},
        ( $self->can('chat_model') ? ( model => $self->chat_model ) : () ),
      )->to('ollama')
    : ();

  return $self->generate_request( chat => sub { $self->chat_response(shift) },
    model => $self->chat_model,
    messages => $messages,
    stream => JSON->false,
    @reasoning,
    defined $format ? ( format => $format ) : (),
    defined $self->get_keep_alive ? ( keep_alive => $self->get_keep_alive ) : (),
    options => {
      exists $controls->{temperature}
        ? ( temperature => $controls->{temperature} )
        : ( $self->has_temperature ? ( temperature => $self->temperature ) : () ),
      $self->has_context_size ? ( num_ctx => $self->get_context_size ) : (),
      exists $controls->{max_tokens}
        ? ( num_predict => $controls->{max_tokens} )
        : ( $self->get_response_size ? ( num_predict => $self->get_response_size ) : () ),
      exists $controls->{seed}
        ? ( seed => $controls->{seed} )
        : ( $self->has_seed ? ( seed => $self->seed )
          : $self->randomize_seed ? ( seed => $self->random_seed ) : () ),
      $extra{options} ? (%{delete $extra{options}}) : (),
    },
    %extra,
  );
}

sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  my $msg = $data->{message};

  my $usage = {};
  $usage->{prompt_tokens}     = $data->{prompt_eval_count} if $data->{prompt_eval_count};
  $usage->{completion_tokens} = $data->{eval_count}        if $data->{eval_count};
  $usage = undef unless %$usage;

  my $timing = {};
  for my $k (qw( total_duration load_duration prompt_eval_duration eval_duration )) {
    $timing->{$k} = $data->{$k} if $data->{$k};
  }
  # Ollama reports the four native durations in nanoseconds. Mirror them
  # as *_seconds (Float, seconds) so Langertha::Response.ttft_seconds /
  # total_seconds and downstream observability (Langfuse, Prometheus
  # scrapers) have a consistent unit. The original *_duration keys are
  # preserved verbatim for backward compatibility.
  my $ns_to_s = sub { $_[0] * 1e-9 };
  $timing->{total_seconds}        = $ns_to_s->( $data->{total_duration}        ) if $data->{total_duration};
  $timing->{load_seconds}         = $ns_to_s->( $data->{load_duration}         ) if $data->{load_duration};
  $timing->{prompt_eval_seconds}  = $ns_to_s->( $data->{prompt_eval_duration}  ) if $data->{prompt_eval_duration};
  $timing->{eval_seconds}         = $ns_to_s->( $data->{eval_duration}         ) if $data->{eval_duration};
  $timing = undef unless %$timing;

  # Ollama stamps every response with an RFC3339 string carrying nanoseconds
  # ("2026-02-22T04:00:45.027209927Z"). It is handed over verbatim: normalizing
  # it is Langertha::Moment->from_wire's job, reached through
  # Langertha::Response's BUILDARGS, which also parses the epoch seconds some
  # Ollama-compatible shims send instead and drops a stamp it cannot read (the
  # "0001-01-01T00:00:00Z" zero-value sentinel included) rather than failing
  # the whole response. The native string stays untouched under raw.created_at
  # -- the same normalized-plus-native split the *_seconds timing keys use
  # (ADR 0011). See karr #92 / #117 and GitHub issue #3.
  my @tcs = Langertha::ToolCall->extract( $self->tool_wire_format, $data );
  return Langertha::Response->new(
    content       => $msg->{content} // '',
    raw           => $data,
    $data->{model} ? ( model => $data->{model} ) : (),
    defined $data->{done_reason} ? ( finish_reason => $data->{done_reason} ) : (),
    $usage ? ( usage => $usage ) : (),
    $timing ? ( timing => $timing ) : (),
    defined $data->{created_at} ? ( created => $data->{created_at} ) : (),
    # Ollama's native /api/chat returns the model's chain-of-thought under
    # message.thinking (think=true). Surface it onto Response.thinking so the
    # non-streamed native route matches the OpenAI-compatible path. -- karr k129
    defined $msg->{thinking} ? ( thinking => $msg->{thinking} ) : (),
    @tcs ? ( tool_calls => [ @tcs ] ) : (),
  );
}

sub tags { $_[0]->tags_request }
sub tags_request {
  my ( $self ) = @_;
  return $self->generate_request( list => sub { $self->tags_response(shift) } );
}


sub tags_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  my @model_list = map { $_->{model} } @{$data->{models}};
  $self->models(\@model_list);
  return $data->{models};
}

sub simple_tags {
  my ( $self ) = @_;
  my $request = $self->tags;
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}


sub ps { $_[0]->ps_request }
sub ps_request {
  my ( $self ) = @_;
  return $self->generate_request( ps => sub { $self->ps_response(shift) } );
}


sub ps_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  return $data->{models};
}

sub simple_ps {
  my ( $self ) = @_;
  my $request = $self->ps;
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}


# Dynamic model listing (wrapper around simple_tags with caching)
sub list_models {
  my ($self, %opts) = @_;

  # Check cache unless force_refresh requested
  unless ($opts{force_refresh}) {
    my $cache = $self->_models_cache;
    if ($cache->{timestamp} && time - $cache->{timestamp} < $self->models_cache_ttl) {
      return $opts{full} ? $cache->{models} : $cache->{model_ids};
    }
  }

  # Fetch from API via simple_tags
  my $models = $self->simple_tags;

  # Extract IDs and update cache
  my @model_ids = map { $_->{model} } @$models;
  $self->_models_cache({
    timestamp => time,
    models => $models,
    model_ids => \@model_ids,
  });

  return $opts{full} ? $models : \@model_ids;
}


sub stream_format { 'ndjson' }

sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};
  # No parallel knob on this wire (parallel_tool_use is cleared): a value the
  # caller set is only dropped, with the shared carp (karr k241).
  $self->_parallel_tool_calls_kwarg( \%extra, $controls );

  # No tool_choice field, same rule as chat_request (karr k239).
  $self->_gate_tool_choice(\%extra);

  # Translate response_format -> Ollama's format parameter, same wire as
  # chat_request. Ollama accepts either the literal string 'json' or a
  # JSON-Schema HashRef. A per-request response_format
  # (chat_stream_realtime_f) beats the engine attribute, and is removed
  # from the extras either way: Ollama has no response_format field and
  # would silently ignore it. Fall back to the legacy json_format
  # attribute when neither is set.
  my $rf = exists $controls->{response_format}
    ? delete $controls->{response_format}
    : exists $extra{response_format}
      ? delete $extra{response_format}
      : $self->has_response_format ? $self->response_format : undef;
  my $format;
  if ( defined $rf ) {
    my $type = ref($rf) eq 'HASH' ? ( $rf->{type} // '' ) : '';
    if ( $type eq 'json_object' ) {
      $format = 'json';
    }
    elsif ( $type eq 'json_schema'
        && ref( $rf->{json_schema} ) eq 'HASH'
        && ref( $rf->{json_schema}{schema} ) eq 'HASH' ) {
      $format = $rf->{json_schema}{schema};
    }
  }
  $format = 'json' if !defined $format && $self->json_format;

  # reasoning_effort -> top-level `think`, same wire and placement as
  # chat_request: a sibling of model/messages/stream, never under options
  # (Ollama silently ignores options.think). Live-probed 2026-09-17 via
  # ollama.com gpt-oss:20b (k175).
  my @reasoning = exists $controls->{reasoning_effort}
    ? Langertha::Reasoning->new(
        effort => $controls->{reasoning_effort},
        ( $self->can('chat_model') ? ( model => $self->chat_model ) : () ),
      )->to('ollama')
    : ();

  return $self->generate_request( chat => sub {},
    model => $self->chat_model,
    messages => $messages,
    stream => JSON->true,
    @reasoning,
    defined $format ? ( format => $format ) : (),
    defined $self->get_keep_alive ? ( keep_alive => $self->get_keep_alive ) : (),
    options => {
      exists $controls->{temperature}
        ? ( temperature => $controls->{temperature} )
        : ( $self->has_temperature ? ( temperature => $self->temperature ) : () ),
      $self->has_context_size ? ( num_ctx => $self->get_context_size ) : (),
      exists $controls->{max_tokens}
        ? ( num_predict => $controls->{max_tokens} )
        : ( $self->get_response_size ? ( num_predict => $self->get_response_size ) : () ),
      exists $controls->{seed}
        ? ( seed => $controls->{seed} )
        : ( $self->has_seed ? ( seed => $self->seed )
          : $self->randomize_seed ? ( seed => $self->random_seed ) : () ),
      $extra{options} ? (%{delete $extra{options}}) : (),
    },
    %extra,
  );
}

sub parse_stream_chunk {
  my ( $self, $data ) = @_;

  my $content = $data->{message}{content} // '';
  my $is_done = $data->{done} ? 1 : 0;

  # Native /api/chat with think=true streams the chain-of-thought incrementally
  # under message.thinking, parallel to message.content -- surface it onto the
  # chunk so aggregate_thinking reconstructs the same text chat_response lifts on
  # the non-streaming path. -- karr k129
  my $thinking = $data->{message}{thinking};

  # Native /api/chat streams message.tool_calls whole, on the chunk where the
  # call completes (not fragmented). Read it with the same ToolCall->extract
  # chat_response uses. -- karr k221
  my @tool_calls = Langertha::ToolCall->extract( $self->tool_wire_format, $data );

  require Langertha::Stream::Chunk;
  return Langertha::Stream::Chunk->new(
    content => $content,
    raw => $data,
    is_final => $is_done,
    $data->{model} ? (model => $data->{model}) : (),
    $is_done && $data->{done_reason} ? (finish_reason => $data->{done_reason}) : (),
    $is_done ? (usage => {
      $data->{eval_count} ? (completion_tokens => $data->{eval_count}) : (),
      $data->{prompt_eval_count} ? (prompt_tokens => $data->{prompt_eval_count}) : (),
    }) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
    @tool_calls ? ( tool_calls => \@tool_calls ) : (),
  );
}

# Tool calling support (MCP) is the tag-driven default in Langertha::Role::Tools.
sub _build_tool_wire_format { 'ollama' }

# Native /api/chat messages carry a string content plus a sibling images array
# of raw base64 (docs.ollama.com/api/chat): Role::Chat lifts Content::Image
# blocks there (karr k267).
sub content_format { 'ollama' }

# Native /api/chat's ChatRequest (api/types.go, main 2026-09-24, v0.34.4) is
# model, messages, stream, format, keep_alive, tools, options, think, truncate,
# shift, logprobs, top_logprobs: no tool_choice and no parallel knob. The Go
# server binds without DisallowUnknownFields, so either field is accepted,
# IGNORED and answered 200 -- the caller would believe a tool was forced.
# Clear every tool_choice flag and parallel_tool_use (karr k239, k241; ADR
# 0002 layer 2); tools_native stays. With tool_choice_named gone, chat_f
# reroutes a forced named tool through format=<schema> (ADR 0005), which the
# grammar enforces. Mirrors OllamaOpenAI, the same server's /v1 face.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete @{$caps}{ qw(
    tool_choice_auto tool_choice_any tool_choice_none tool_choice_named
    parallel_tool_use
  ) };
  return $caps;
};

# image_input (k266, ADR 0019): self-hosted: the served model is launch state
# the client cannot see, so no static claim. A layer-3 catch-all rather than a
# layer-2 delete, so a fact probed from /api/show can answer per model (ADR 0032).
sub model_capability_corrections {
  return ( qr/\A/ => { image_input => 0 } );
}

sub model_metadata_format { 'ollama' }
sub model_metadata_url {
  my $url = $_[0]->url;
  $url =~ s{/\z}{};
  return $url . '/api/show';
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Ollama - Ollama API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Ollama;

    my $ollama = Langertha::Engine::Ollama->new(
        url          => $ENV{OLLAMA_URL},
        model        => 'llama3.3',
        system_prompt => 'You are a helpful assistant',
        context_size => 2048,
        temperature  => 0.5,
    );

    print $ollama->simple_chat('Say something nice');

    my $vector = $ollama->simple_embedding($content);
    # async: await $ollama->simple_embedding_f($content)

    # Get OpenAI-compatible API access to Ollama
    my $ollama_openai = $ollama->openai;

    # List available models
    my $models = $ollama->simple_tags;

    # Show running models
    my $running = $ollama->simple_ps;

=head1 DESCRIPTION

Provides access to Ollama, which runs large language models locally. Ollama
supports many popular open-source models including C<llama3.3> (default),
C<qwen2.5>, C<deepseek-coder-v2>, C<mixtral>, and C<mxbai-embed-large>
(default embedding model).

Supports chat, embeddings, streaming, MCP tool calling (OpenAI-compatible
format), and an OpenAI-compatible API via L</openai>. Not all models support
tool calling; known working models include C<qwen3:8b> and C<llama3.2:3b>.

Authentication is optional. A local server needs none; Ollama Cloud
(C<https://ollama.com>) serves the same native dialect but requires a
bearer token — set L</api_key> or C<LANGERTHA_OLLAMA_API_KEY>:

    my $cloud = Langertha::Engine::Ollama->new(
        url     => 'https://ollama.com',
        api_key => $ENV{LANGERTHA_OLLAMA_API_KEY},
        model   => 'gpt-oss:120b',
    );

For Hermes-format tool calling in models without API-level tool support,
compose L<Langertha::Role::HermesTools>. See L<Langertha::Role::HermesTools>
for details.

B<THIS API IS WORK IN PROGRESS>

=head2 openai

    my $oai = $ollama->openai;
    my $oai = $ollama->openai(model => 'different_model');

Returns a L<Langertha::Engine::OllamaOpenAI> instance configured for Ollama's
C</v1> OpenAI-compatible endpoint, inheriting the current model, embedding
model, API key, system prompt, and temperature settings (and
L<Langertha::Role::HTTP/connect_address> while the url stays on its host). Supports streaming,
embeddings, and MCP tool calling.

=head2 new_openai

    my $oai = Langertha::Engine::Ollama->new_openai(
        url   => 'http://localhost:11434',
        model => 'llama3.3',
        tools => [ $mcp ],
    );

Class method. Constructs a native Ollama engine and immediately returns an
L<Langertha::Engine::OllamaOpenAI> instance from its C<openai()> method.
Every argument the OllamaOpenAI engine accepts (C<mcp_servers>,
C<tool_max_iterations>, C<response_format>, C<reasoning_effort>, ...) is
passed on to it; C<url> gets the C</v1> suffix. The optional C<tools> list
names MCP clients and is added to C<mcp_servers>. Native-only arguments
(C<keep_alive>, C<seed>, C<context_size>) have no C</v1> counterpart and
are not passed on.

=head2 api_key

Optional bearer token. A local Ollama server needs none; Ollama Cloud
(C<https://ollama.com>) rejects unauthenticated requests with HTTP 401.
If not provided, reads from C<LANGERTHA_OLLAMA_API_KEY>. When undefined,
no C<Authorization> header is sent.

=head2 update_request

    $ollama->update_request($http_request);

Adds C<Authorization: Bearer {api_key}> to outgoing requests when an API
key is configured. Skipped entirely when C<api_key> is C<undef>, keeping
unauthenticated local servers working.

=head2 json_format

When set to a true value, passes C<format => 'json'> to the Ollama API,
requesting JSON-formatted output from the model. Defaults to C<0>.

=head2 tags

    my $request = $ollama->tags;

Returns an HTTP request object for the Ollama C<GET /api/tags> endpoint.
Execute it with C<simple_tags> or pass it to an async HTTP client.

=head2 simple_tags

    my $models = $ollama->simple_tags;
    # Returns: [{name => 'llama3.3', model => 'llama3.3', ...}, ...]

Synchronously fetches and returns the list of locally available models from
the Ollama C</api/tags> endpoint. Also updates the engine's C<models> list.

=head2 ps

    my $request = $ollama->ps;

Returns an HTTP request object for the Ollama C<GET /api/ps> endpoint which
lists currently loaded (running) models.

=head2 simple_ps

    my $running = $ollama->simple_ps;
    # Returns: [{name => 'llama3.3', ...}, ...]

Synchronously fetches and returns the list of models currently loaded in
Ollama's memory from the C</api/ps> endpoint.

=head2 list_models

    my $model_ids = $ollama->list_models;
    my $models    = $ollama->list_models(full => 1);
    my $models    = $ollama->list_models(force_refresh => 1);

Fetches locally available models from Ollama via L</simple_tags> with caching.
Returns an ArrayRef of model name strings by default, or full model objects
when C<full => 1> is passed. Results are cached for C<models_cache_ttl>
seconds (default: 3600).

=head1 SEE ALSO

=over

=item * L<https://ollama.com/library> - Ollama model library

=item * L<https://github.com/ollama/ollama> - Ollama project

=item * L<Langertha::Engine::OllamaOpenAI> - OpenAI-compatible Ollama access via L</openai>

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Role::Seed> - Seed for reproducible outputs (composed by this engine)

=item * L<Langertha::Role::ContextSize> - Context window size (composed by this engine)

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
