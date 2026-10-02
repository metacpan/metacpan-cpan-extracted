package Langertha::Role::OpenAICompatible;
# ABSTRACT: Role for OpenAI-compatible API format
our $VERSION = '0.503';
use Moose::Role;
use File::ShareDir::ProjectDistDir qw( :all );
use Carp qw( croak carp );
use JSON::MaybeXS;
use MIME::Base64 qw( decode_base64 );
use Langertha::ToolChoice;
use Langertha::Response;
use Langertha::ToolCall;


has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key { undef }


sub update_request {
  my ( $self, $request ) = @_;
  my $key = $self->api_key;
  $request->header('Authorization', 'Bearer '.$key) if defined $key;
}


sub openapi_file { yaml => dist_file('Langertha','openai.yaml') };


sub default_embedding_model { 'text-embedding-3-large' }
# gpt-image-1 is removed by OpenAI on 2026-10-23 (gpt-image-1-mini, -1.5 and
# chatgpt-image-latest on 2026-12-01); gpt-image-2 is the default (k308, k313).
# whisper-1 is the transcription alias OpenAI-compatible servers accept;
# Engine::OpenAI overrides it with the OpenAI-only gpt-transcribe (k313).
sub default_transcription_model { 'whisper-1' }
sub default_image_model { 'gpt-image-2' }

# Dynamic model listing

sub list_models_path { '/models' }


sub list_models_request {
  my ($self, %params) = @_;
  my $url = $self->url.$self->list_models_path;
  if ($params{after}) {
    $url .= '?after='.$params{after};
  }
  return $self->generate_http_request(
    GET => $url,
    sub { $self->list_models_response(shift) },
  );
}


sub list_models_response {
  my ($self, $response) = @_;
  my $data = $self->parse_response($response);
  return $data;
}


sub list_models {
  my ($self, %opts) = @_;

  # Guard: if supported_operations excludes listModels, fall back to current model
  unless ($self->can_operation('listModels')) {
    return [$self->model];
  }

  # Check cache unless force_refresh requested
  unless ($opts{force_refresh}) {
    my $cache = $self->_models_cache;
    if ($cache->{timestamp} && time - $cache->{timestamp} < $self->models_cache_ttl) {
      return $opts{full} ? $cache->{models} : $cache->{model_ids};
    }
  }

  # Fetch all pages
  my @all_models;
  my $after;
  for my $page (1..100) {
    my $request = $self->list_models_request($after ? (after => $after) : ());
    my $response = $self->user_agent->request($request);
    my $data = $request->response_call->($response);
    my $models = ref $data eq 'HASH' ? ($data->{data} // []) : $data;
    push @all_models, @$models;
    last unless ref $data eq 'HASH' && $data->{has_more} && $data->{last_id};
    $after = $data->{last_id};
  }

  # Extract IDs and update cache
  my @model_ids = map { $_->{id} } @all_models;
  $self->_models_cache({
    timestamp => time,
    models => \@all_models,
    model_ids => \@model_ids,
  });

  return $opts{full} ? \@all_models : \@model_ids;
}


# Embedding

sub embedding_operation_id { 'createEmbedding' }

# The body field embedding_dimensions goes out as, or undef when the engine
# documents none for its embedding_model: then the attribute is not sent and
# carps once per instance (k319). Engines override it.
sub _embedding_dimensions_field { 'dimensions' }

sub embedding_request {
  my ( $self, $input, %extra ) = @_;
  my @dimensions;
  my $size = $self->embedding_dimensions;
  if ( defined $size && !exists $extra{dimensions} ) {
    my $field = $self->_embedding_dimensions_field;
    if ( !defined $field ) {
      $self->_langertha_carp( "".( ref $self ).": not sending embedding_dimensions=$size -- no "
        . "documented dimensions field for embedding model '"
        . ( $self->embedding_model // 'served by the server' ) . "'", 'embedding_dimensions' );
    }
    elsif ( !exists $extra{$field} ) {
      @dimensions = ( $field => $size );
    }
  }
  return $self->generate_request( $self->embedding_operation_id, sub { $self->embedding_response(shift, $input) },
    defined $self->embedding_model ? ( model => $self->embedding_model ) : (),
    input => $input,
    @dimensions,
    %extra,
  );
}


sub embedding_response {
  my ( $self, $response, $input ) = @_;
  my $data = $self->parse_response($response);
  # tracing
  # A malformed/error payload that still parses as a 200 JSON body can lack the
  # `data` array; croak with a readable message instead of a raw deref crash on
  # @{undef} ("Can't use an undefined value as an ARRAY reference"). Embeddings
  # must return a vector, so there is no graceful-empty fallback here. -- karr k171
  unless ( ref $data eq 'HASH' && ref $data->{data} eq 'ARRAY' ) {
    croak "".(ref $self)." embedding response missing 'data' array"
      . $self->_payload_error_suffix($data);
  }
  my @objects = @{$data->{data}};
  # data[].index is the input position and the wire does not promise the array
  # comes in input order, so sort by it whenever every entry carries one (k289).
  unless ( grep { ref $_ ne 'HASH' || !defined $_->{index} } @objects ) {
    @objects = sort { $a->{index} <=> $b->{index} } @objects;
  }
  my @vectors = map { $self->_embedding_vector($_) } @objects;
  # An empty data array or an entry without a vector is not a result: undef
  # would be stored as if it were one (Raider's session search did) (k290).
  if ( !@vectors || grep { ref $_ ne 'ARRAY' || !@{$_} } @vectors ) {
    croak "".(ref $self)." embedding response contained no vector"
      . $self->_payload_error_suffix($data);
  }
  if ( ref $input eq 'ARRAY' ) {
    croak "".(ref $self)." embedding response returned ".scalar(@vectors)
      ." vectors for ".scalar(@{$input})." inputs"
      unless @vectors == @{$input};
    return \@vectors;
  }
  return $vectors[0];
}

# One data[] entry's vector. encoding_format => 'base64' answers with a string
# of little-endian float32 instead of a float array; decode it, so the caller
# gets the same ArrayRef of floats either way (k289).
sub _embedding_vector {
  my ( $self, $object ) = @_;
  my $embedding = ref $object eq 'HASH' ? $object->{embedding} : undef;
  return [ unpack 'f<*', decode_base64($embedding) ]
    if defined $embedding && !ref $embedding;
  return $embedding;
}

# " (error: <message>)" when a 200 body carries a provider error, else ''.
sub _payload_error_suffix {
  my ( $self, $data ) = @_;
  my $err = ref $data eq 'HASH' && $data->{error}
    ? ( ref $data->{error} eq 'HASH' ? $data->{error}{message} : $data->{error} )
    : undef;
  return defined $err ? " (error: $err)" : '';
}


# Chat

sub chat_operation_id { 'createChatCompletion' }

# The completion-length body key is engine-overridable. OpenAI's gpt-5.x line
# only accepts max_completion_tokens (max_tokens is an HTTP 400 on those
# models), so Langertha::Engine::OpenAI overrides this for the gpt-5* family;
# every other OpenAI-compatible engine keeps max_tokens.
sub _max_tokens_key { 'max_tokens' }

# OpenAI reasoning models (gpt-5.x / gpt-6 / o-series) 400 on a non-default
# temperature whenever reasoning is active -- only the wire default (1) is
# accepted (karr k155, live-verified 2026-09-17 against /v1/chat/completions).
# This gate mirrors AnthropicCompatible::_temperature_kwargs (the
# supports('temperature') check + control-beats-attribute resolution) and adds
# the OpenAI EFFORT-AWARE drop. The per-model, resolved-effort predicate lives on
# the engine (Engine::OpenAI::_temperature_rejected_by_reasoning, inherited by
# OpenAIResponses); every other OpenAI-compatible engine never defines it, so the
# can() guard leaves their temperature untouched. The drop fires only for a
# non-default value under active reasoning: temperature=1 passes through silently
# (dropping the wire default would be a pure-noise warning), and a caller who
# disables reasoning (reasoning_effort => 'none', where the model accepts it)
# keeps its temperature.
#
# A model that does not take temperature at all (supports('temperature') false:
# every current Kimi id fixes it server-side, karr k214) never gets the field,
# not even 1. A caller-set non-default value is dropped with a carp rather than
# silently (ADR 0025 k214 Update); 1 is dropped quietly.
sub _temperature_kwargs {
  my ( $self, $controls ) = @_;
  my $temp = exists $controls->{temperature} ? $controls->{temperature}
           : $self->can('has_temperature') && $self->has_temperature ? $self->temperature
           :                                    undef;
  return () unless defined $temp;
  # An engine attribute is the same on every request: warn once per engine
  # instance (karr k247); a per-request control warns every time.
  my $once = exists $controls->{temperature} ? undef
    : 'temperature=' . $temp . ' model=' . ( $self->can('chat_model') ? $self->chat_model // '' : '' );
  unless ( $self->supports('temperature') ) {
    $self->_langertha_carp( "".( ref $self ).": dropping temperature=$temp -- model '"
      . ( $self->can('chat_model') ? $self->chat_model // '' : '' )
      . "' does not take a temperature (rejected or fixed server-side); "
      . "unset temperature to silence this",
      defined $once ? "$once unsupported" : undef )
      if $temp != 1;
    return ();
  }
  if ( $temp != 1
    && $self->can('_temperature_rejected_by_reasoning')
    && $self->_temperature_rejected_by_reasoning($controls) ) {
    $self->_langertha_carp( "".( ref $self ).": dropping temperature=$temp -- this reasoning model "
      . "rejects a non-default temperature while reasoning is active (only the "
      . "wire default 1 is accepted); pass reasoning_effort => 'none' to keep it",
      defined $once ? "$once reasoning" : undef );
    return ();
  }
  return ( temperature => $temp );
}

# Normalize tool_choice to OpenAI native format (accepts Anthropic-style,
# OpenAI-style, string shorthands and a Langertha::ToolChoice object), in place,
# for both request builders (the streaming one too, karr k235). The wire is
# always OpenAI-shaped here (see chat_response), so pin to 'openai' rather than
# $self->tool_wire_format (hermes engines / Perplexity). A kind the engine does
# not support('tool_choice_*') is not sent (Role::Chat::_gate_tool_choice,
# karr k239): Ollama's /v1 has no tool_choice field and ignores one.
sub _openai_tool_choice_kwarg {
  my ( $self, $extra ) = @_;
  my $tc = $self->_gate_tool_choice($extra) or return;
  $extra->{tool_choice} = $tc->to('openai');
  return;
}

# parallel_tool_use -> OpenAI's parallel_tool_calls, gated on
# supports('parallel_tool_use') (karr k241); see
# Role::Chat::_parallel_tool_calls_kwarg.
sub _openai_parallel_tool_calls_kwarg {
  my ( $self, $extra, $controls ) = @_;
  return $self->_parallel_tool_calls_kwarg( $extra, $controls );
}

sub chat_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};

  $self->_openai_tool_choice_kwarg(\%extra);
  $self->_openai_parallel_tool_calls_kwarg(\%extra, $controls);

  return $self->generate_request( $self->chat_operation_id, sub { $self->chat_response(shift) },
    defined $self->chat_model ? ( model => $self->chat_model ) : (),
    messages => $messages,
    exists $controls->{max_tokens}
      ? ( $self->_max_tokens_key => $controls->{max_tokens} )
      : ( $self->get_response_size ? ( $self->_max_tokens_key => $self->get_response_size ) : () ),
    exists $controls->{response_format}
      ? ( response_format => $controls->{response_format} )
      : ( ($self->can('has_response_format') && $self->has_response_format) ? ( response_format => $self->response_format ) : () ),
    $self->_temperature_kwargs($controls),
    exists $controls->{seed} ? ( seed => $controls->{seed} ) : (),
    $self->generation_kwargs_for(%$controls),
    ( $self->can('knobs_kwargs_for') ? $self->knobs_kwargs_for(%$controls) : () ),
    stream => JSON->false,
    %extra,
  );
}


# A reply that carries tool calls finishes with 'tool_calls' in the
# Chat-Completions convention, but gpt-oss served by vLLM-style stacks (seen
# live on AKI.IO, gpt-oss-120b and llama3-chat-8b) answers a non-streaming tool
# call with 'stop'. Response.tool_calls is the one tool-call shape (ADR 0003),
# so the finish reported alongside it says 'tool_calls' too -- the rule
# ResponsesCompatible applies (k171). Only 'stop' is rewritten: 'length' and
# the other values carry information ('length' = cut off) and pass through; a
# missing finish stays missing. The wire value remains on ->raw.
# Shared by chat_response and parse_stream_chunk. -- karr k248, ADR 0018
sub _openai_finish_reason {
  my ( $self, $finish_reason, $has_tool_calls ) = @_;
  return 'tool_calls'
    if $has_tool_calls && defined $finish_reason && $finish_reason eq 'stop';
  return $finish_reason;
}

# message.content / delta.content is a string on most OpenAI-compatible
# servers, but Mistral's reasoning models (Magistral, or any model called with
# reasoning_effort) send a list of content chunks instead:
#   [ { type => 'thinking', thinking => [ { type => 'text', text => ... } ] },
#     { type => 'text', text => ... } ]
# and a stream switches from the list to plain strings mid-answer.
# Response.content and Stream::Chunk.content are Str, so the list is read here,
# in the dialect role (ADR 0018 tier 2): text chunks and bare strings join into
# content, the text of thinking chunks (a list of text chunks, or a string)
# joins into thinking, and any other chunk type (image_url, reference, ...)
# carries no answer text and is skipped. Returns ($content, $thinking);
# $thinking is undef when no thinking chunk carried text. -- karr k296
sub _openai_content_parts {
  my ( $self, $content ) = @_;
  return ( $content // '', undef ) unless ref $content;
  return ( '', undef ) unless ref $content eq 'ARRAY';
  my ( $text, $thinking ) = ( '', undef );
  for my $part (@$content) {
    if ( !ref $part ) { $text .= $part if defined $part; next }
    next unless ref $part eq 'HASH';
    my $type = $part->{type} // '';
    if ( $type eq 'text' ) {
      $text .= $part->{text} if defined $part->{text} && !ref $part->{text};
    }
    elsif ( $type eq 'thinking' ) {
      my $inner = $part->{thinking};
      my @texts = ref $inner eq 'ARRAY'
        ? map { !ref $_ ? $_ : ref $_ eq 'HASH' && !ref $_->{text} ? $_->{text} : undef } @$inner
        : ( !ref $inner ? $inner : undef );
      $thinking = ( $thinking // '' ) . $_ for grep { defined } @texts;
    }
  }
  return ( $text, $thinking );
}

sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  # A 200 without a choice is no answer: gateways (OpenRouter and other
  # proxies) put an `error` object into a 200 body, and an empty choices list
  # parsed to content '' with no finish_reason -- the same as a model that
  # legitimately said nothing. Croak, naming the engine and the error, like
  # the k290 embedding/image croaks. -- karr k301
  my $choice = ref $data eq 'HASH' && ref $data->{choices} eq 'ARRAY' ? $data->{choices}[0] : undef;
  unless ( ref $choice eq 'HASH' ) {
    my $error = $self->_body_error_text( ref $data eq 'HASH' ? $data->{error} : undef );
    croak "".(ref $self)." response carried an error: $error" if defined $error;
    croak "".(ref $self)." response contained no choices";
  }
  # OpenRouter reports a provider failure inside the choice (its `error`,
  # finish_reason 'error'); that parsed to an empty success. -- karr k311
  if ( defined( my $error = $self->_openai_choice_error( $data, $choice ) ) ) {
    croak "".(ref $self)." response carried an error: $error";
  }
  # finish_reason 'error' with no error object anywhere is still a failed
  # generation, not an answer. -- karr k317
  croak "".(ref $self)." response ended with finish_reason error"
    if ( $choice->{finish_reason} // '' ) eq 'error';
  my $msg = $choice->{message} || {};
  # The OpenAI-compatible response envelope is always OpenAI-shaped, even for
  # engines whose tool_wire_format is 'hermes' (their calls ride in the message
  # text, parsed elsewhere).
  # Pin the structured extractor to 'openai' rather than $self->tool_wire_format.
  my @tcs = Langertha::ToolCall->extract( 'openai', $data );
  # Chain-of-thought reaches the OpenAI-compatible message under two spellings:
  # the DeepSeek/SGLang/Moonshot/xAI `reasoning_content`, and the bare
  # `reasoning` that vLLM (renamed from reasoning_content), Groq, Cerebras,
  # OpenRouter and AKI.IO send. Read the canonical spelling first, then fall
  # back to `reasoning` -- guarded !ref so OpenRouter's structured
  # `reasoning_details` ARRAY (or any non-string shape) never lands in the Str
  # thinking attribute. The precedence tests `length`, not `defined`: a server
  # that keeps `reasoning_content` as an empty back-compat stub beside a filled
  # `reasoning` must not mask it -- the exact failure mode the vLLM migration
  # note warns about. -- karr k127, k129, k79
  # A content-chunk list (Mistral reasoning models) carries its own thinking
  # chunks; they fill thinking only when neither reasoning field did. -- k296
  my ( $content, $part_thinking ) = $self->_openai_content_parts( $msg->{content} );
  my $thinking =
      length( $msg->{reasoning_content} // '' ) ? $msg->{reasoning_content}
    : ( defined $msg->{reasoning} && !ref $msg->{reasoning} ) ? $msg->{reasoning}
    : $part_thinking;
  return Langertha::Response->new(
    content       => $content,
    raw           => $data,
    $data->{id} ? ( id => $data->{id} ) : (),
    $data->{model} ? ( model => $data->{model} ) : (),
    defined $choice->{finish_reason}
      ? ( finish_reason => $self->_openai_finish_reason( $choice->{finish_reason}, scalar @tcs ) ) : (),
    $data->{usage} ? ( usage => $self->_wire_usage( $data->{usage} ) ) : (),
    ( $data->{usage} && $data->{usage}{prompt_tokens_details}
      && defined $data->{usage}{prompt_tokens_details}{cached_tokens}
      ? ( cached_tokens => $data->{usage}{prompt_tokens_details}{cached_tokens} ) : () ),
    $data->{created} ? ( created => $data->{created} ) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
    # A declined structured-output request answers content null plus
    # message.refusal; it was reachable only through raw (ADR 0004). -- k301
    ( defined $msg->{refusal} && !ref $msg->{refusal} ? ( refusal => $msg->{refusal} ) : () ),
    @tcs ? ( tool_calls => [ @tcs ] ) : (),
  );
}

# The usage block as it goes onto the Response / a stream chunk. The default is
# the wire block itself; an engine that knows something the wire does not say
# overrides it and returns a copy with a canonical key added (OpenRouter states
# that its bare usage.cost is USD as cost_usd; ADR 0018 tier 3, ADR 0031, k363),
# as Role::AnthropicCompatible's _wire_usage does for input_includes_cache.
# The wire hash itself is never modified.
sub _wire_usage {
  my ( $self, $usage ) = @_;
  return $usage;
}


# The error a choice reports, as "message (code)", or undef: the choice's own
# `error` (OpenRouter's NonStreamingChoice / StreamingChoice `error`), or a
# top-level `error` beside a choice whose finish_reason is 'error' --
# OpenRouter's documented mid-stream failure frame. Shapes:
# https://openrouter.ai/docs/api-reference/overview and .../errors -- k311
sub _openai_choice_error {
  my ( $self, $data, $choice ) = @_;
  return $self->_body_error_text( $choice->{error} ) if defined $choice->{error};
  return $self->_body_error_text( $data->{error} )
    if defined $data->{error} && ( $choice->{finish_reason} // '' ) eq 'error';
  return undef;
}


# Transcription

sub transcription_operation_id { 'createTranscription' }

sub transcription_request {
  my ( $self, $file, %extra ) = @_;
  my $filename = delete $extra{filename};
  # A list goes out as repeated languages[] parts (k286 convention), never as
  # a file spec. gpt-transcribe takes only that plural field, so a singular
  # language is folded into it for that model (k313).
  my @languages = map { ref $_ eq 'ARRAY' ? @$_ : defined $_ ? ($_) : () }
    delete @extra{qw( languages languages[] )};
  my $model = exists $extra{model} ? $extra{model} : $self->transcription_model;
  if ( defined $model && $model =~ /\Agpt-transcribe/ && defined $extra{language} ) {
    my $language = delete $extra{language};
    push @languages, $language unless grep { $_ eq $language } @languages;
  }
  $extra{'languages[]'} = \@languages if @languages;
  return $self->generate_request( $self->transcription_operation_id, sub { $self->transcription_response(shift) },
    file => $self->transcription_file_part( $file, $filename ),
    $self->transcription_model ? ( model => $self->transcription_model ) : (),
    %extra,
  );
}


sub transcription_result {
  my ( $self, $response ) = @_;
  # response_format json / verbose_json answer JSON; text, srt and vtt answer
  # the transcript as a plain body. Decide by Content-Type, and by the body
  # only when the type says neither (a transcript can start with "{" but is
  # then served as text/*). -- karr k288
  my $type = lc( $response->content_type // '' );
  my $is_json = $type =~ /json/
    || ( $type !~ m{\Atext/} && $response->content =~ /\A\s*\{/ );
  return $self->parse_response($response) if $is_json || !$response->is_success;
  $self->_update_rate_limit($response) if $self->can('_update_rate_limit');
  # Bounded Content-Encoding decode (karr k346): a gzip transcript body inflates
  # under response_max_bytes or is refused with the too-big croak.
  return { text => $self->_bounded_decoded_content( $response, default_charset => 'UTF-8' ) };
}


sub transcription_response {
  my ( $self, $response ) = @_;
  return $self->transcription_result($response)->{text};
}


# Streaming

sub stream_format { 'sse' }


sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;

  # Same canonical-control consumption as chat_request (karr #46).
  my $controls = delete $extra{controls} // {};

  # Same tool_choice normalization and parallel_tool_calls placement as
  # chat_request (karr k235, k240).
  $self->_openai_tool_choice_kwarg(\%extra);
  $self->_openai_parallel_tool_calls_kwarg(\%extra, $controls);

  return $self->generate_request( $self->chat_operation_id, sub {},
    defined $self->chat_model ? ( model => $self->chat_model ) : (),
    messages => $messages,
    exists $controls->{max_tokens}
      ? ( $self->_max_tokens_key => $controls->{max_tokens} )
      : ( $self->get_response_size ? ( $self->_max_tokens_key => $self->get_response_size ) : () ),
    exists $controls->{response_format}
      ? ( response_format => $controls->{response_format} )
      : ( ($self->can('has_response_format') && $self->has_response_format) ? ( response_format => $self->response_format ) : () ),
    $self->_temperature_kwargs($controls),
    exists $controls->{seed} ? ( seed => $controls->{seed} ) : (),
    $self->generation_kwargs_for(%$controls),
    ( $self->can('knobs_kwargs_for') ? $self->knobs_kwargs_for(%$controls) : () ),
    stream => JSON->true,
    %extra,
  );
}


sub parse_stream_chunk {
  my ( $self, $data, $event, $state ) = @_;

  return undef unless ref $data eq 'HASH';

  # A gateway that fails mid-stream (OpenRouter) sends a frame with a
  # top-level `error` object and no choice. Returning undef ended the stream
  # as a short, silent success; the croak fails the stream future, as the
  # Responses parser does for its error events. -- karr k301
  if ( defined $data->{error} && !( ref $data->{choices} eq 'ARRAY' && @{ $data->{choices} } ) ) {
    croak "".(ref $self)." stream carried an error: ".$self->_body_error_text( $data->{error} );
  }
  # OpenRouter's mid-stream failure frame keeps a choice (delta content '',
  # finish_reason 'error') beside the error, or puts the error on the choice;
  # both ended the stream as a silent success. -- karr k311
  if ( ref $data->{choices} eq 'ARRAY' && ref $data->{choices}[0] eq 'HASH'
    && defined( my $error = $self->_openai_choice_error( $data, $data->{choices}[0] ) ) ) {
    croak "".(ref $self)." stream carried an error: $error";
  }
  # The same frame without any error object still ends a failed stream. -- k317
  if ( ref $data->{choices} eq 'ARRAY' && ref $data->{choices}[0] eq 'HASH'
    && ( $data->{choices}[0]{finish_reason} // '' ) eq 'error' ) {
    croak "".(ref $self)." stream ended with finish_reason error";
  }

  # With stream_options.include_usage (OpenAI; vLLM and SGLang emit it too) the
  # usage arrives in a frame of its own after the finish chunk, with an empty
  # choices list. It becomes a content-less, non-final chunk carrying the usage
  # (and cached_tokens), so aggregate_usage and a caller scanning the chunks
  # see it; dropping it lost the stream's token counts. -- karr k298
  my $choice = ref $data->{choices} eq 'ARRAY' ? $data->{choices}[0] : undef;
  unless ($choice) {
    return undef unless ref $data->{usage} eq 'HASH';
    require Langertha::Stream::Chunk;
    return Langertha::Stream::Chunk->new(
      content  => '',
      raw      => $data,
      is_final => 0,
      $data->{model} ? ( model => $data->{model} ) : (),
      $self->_openai_stream_usage_kwargs( $data->{usage} ),
    );
  }

  # delta.content may be a content-chunk list too (k296, see
  # _openai_content_parts); its thinking chunks feed the thinking below.
  my ( $content, $part_thinking ) = $self->_openai_content_parts(
    ref $choice->{delta} eq 'HASH' ? $choice->{delta}{content} : undef );
  my $finish_reason = $choice->{finish_reason};

  # A streamed tool call arrives as delta.tool_calls fragments keyed by
  # `index`: the first carries id, type and function.name, the rest append to
  # function.arguments, and fragments of parallel calls interleave. Assemble
  # them per index in this stream's state and deliver the finished calls on the
  # chunk that carries finish_reason -- read by the same
  # ToolCall->extract('openai', ...) chat_response uses, so a streamed and a
  # non-streamed reply of one response yield the same calls. The calls leave the
  # state as they are delivered, so none arrives twice. A fragment without
  # `index` (servers that stream whole calls) is keyed by its id, and only by
  # its position when it has neither; an empty-string finish_reason is no
  # finish and flushes nothing. A stream that ends without a finish_reason is
  # reported by _finish_stream_state. -- karr k221
  $state //= $self->_stream_parse_state;
  my $pending = $state->{openai_tool_calls} //= {};
  my $order   = $state->{openai_tool_order} //= [];
  my $delta_calls = ref $choice->{delta} eq 'HASH' ? $choice->{delta}{tool_calls} : undef;
  if ( ref $delta_calls eq 'ARRAY' ) {
    for my $pos ( 0 .. $#$delta_calls ) {
      my $fragment = $delta_calls->[$pos];
      next unless ref $fragment eq 'HASH';
      my $key = defined $fragment->{index}     ? "index:$fragment->{index}"
              : length( $fragment->{id} // '' ) ? "id:$fragment->{id}"
              :                                   "pos:$pos";
      my $call = $pending->{$key} //= do {
        push @$order, $key;
        { type => 'function', function => { arguments => '' } };
      };
      $call->{id} = $fragment->{id} if !length( $call->{id} // '' ) && length( $fragment->{id} // '' );
      my $fn = ref $fragment->{function} eq 'HASH' ? $fragment->{function} : {};
      $call->{function}{name} = $fn->{name}
        if !length( $call->{function}{name} // '' ) && length( $fn->{name} // '' );
      if ( ref $fn->{arguments} ) { $call->{function}{arguments} = $fn->{arguments} }
      elsif ( defined $fn->{arguments} ) { $call->{function}{arguments} .= $fn->{arguments} }
    }
  }
  my @tool_calls;
  if ( length( $finish_reason // '' ) && @$order ) {
    my @calls = map { $pending->{$_} } @$order;
    %$pending = ();
    @$order   = ();
    @tool_calls = Langertha::ToolCall->extract( 'openai',
      { choices => [ { message => { tool_calls => \@calls } } ] } );
  }

  # Streamed chain-of-thought reaches the delta under the same two spellings the
  # non-streaming chat_response reads: the DeepSeek/SGLang/Moonshot/xAI
  # `reasoning_content`, and the bare `reasoning` that vLLM (renamed from
  # reasoning_content), Cerebras and AKI.IO send. Read the canonical spelling
  # first, then fall back to `reasoning` -- guarded !ref so a non-string shape
  # (e.g. OpenRouter's `reasoning_details` ARRAY, which the docs put on the
  # delta) never lands in the Str thinking attribute. As in chat_response the
  # precedence tests `length`, not `defined`, so an empty back-compat
  # `reasoning_content` stub cannot mask a filled `reasoning`. -- karr k129, k79
  my $delta = $choice->{delta} || {};
  my $thinking =
      length( $delta->{reasoning_content} // '' ) ? $delta->{reasoning_content}
    : ( defined $delta->{reasoning} && !ref $delta->{reasoning} ) ? $delta->{reasoning}
    : $part_thinking;

  # An empty-string finish_reason is no finish here either (as for the tool
  # call flush above): the chunk is not final and carries no finish_reason,
  # as Gemini's parser reads an empty finishReason. -- karr k253 review
  my $finished = length( $finish_reason // '' );

  require Langertha::Stream::Chunk;
  return Langertha::Stream::Chunk->new(
    content => $content,
    raw => $data,
    is_final => $finished ? 1 : 0,
    $finished
      ? (finish_reason => $self->_openai_finish_reason( $finish_reason, scalar @tool_calls )) : (),
    $data->{model} ? (model => $data->{model}) : (),
    $self->_openai_stream_usage_kwargs( $data->{usage} ),
    defined $thinking ? ( thinking => $thinking ) : (),
    ( defined $delta->{refusal} && !ref $delta->{refusal} && length $delta->{refusal}
      ? ( refusal => $delta->{refusal} ) : () ),
    @tool_calls ? ( tool_calls => \@tool_calls ) : (),
  );
}

# The usage and cached_tokens constructor arguments of a stream chunk for one
# wire usage block (empty when there is none). Shared by the choice and the
# usage-only chunk, and by engines that find usage elsewhere (Groq's
# x_groq.usage). -- karr k298
sub _openai_stream_usage_kwargs {
  my ( $self, $usage ) = @_;
  return () unless ref $usage eq 'HASH';
  my $details = $usage->{prompt_tokens_details};
  return (
    usage => $self->_wire_usage($usage),
    ( ref $details eq 'HASH' && defined $details->{cached_tokens}
      ? ( cached_tokens => $details->{cached_tokens} ) : () ),
  );
}


sub _finish_stream_state {
  my ( $self, $state ) = @_;
  $state //= $self->_stream_parse_state;
  my $order = $state->{openai_tool_order} or return;
  return unless @$order;
  my $pending = $state->{openai_tool_calls} // {};
  my @names = map { $pending->{$_}{function}{name} // '?' } @$order;
  %$pending = ();
  @$order   = ();
  carp "".( ref $self )." stream ended without a finish_reason; dropping "
    . scalar(@names) . " unfinished tool call(s): " . join( ', ', @names );
  return;
}


# Tool calling support (MCP) is provided by the tag-driven defaults in
# Langertha::Role::Tools (tool_wire_format => 'openai'). No per-engine copies.

# Image generation

sub image_operation_id { 'createImage' }

sub image_request {
  my ( $self, $prompt, %extra ) = @_;
  # GPT image models always answer b64_json and reject response_format with a
  # 400 "Unknown parameter" (k308).
  my $model = exists $extra{model} ? $extra{model} : $self->image_model;
  if ( defined $model && $model =~ /\Agpt-image/ && exists $extra{response_format} ) {
    delete $extra{response_format};
    carp "".(ref $self)." image_request: $model does not take response_format"
      . " (it always answers b64_json); dropped";
  }
  return $self->generate_request( $self->image_operation_id, sub { $self->image_response(shift) },
    model  => $self->image_model,
    prompt => $prompt,
    %extra,
  );
}


sub image_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  # An image call that yields no image is an error, not an empty result (k290).
  unless ( ref $data eq 'HASH' && ref $data->{data} eq 'ARRAY' && @{$data->{data}} ) {
    croak "".(ref $self)." image response contained no image"
      . $self->_payload_error_suffix($data);
  }
  return $data->{data};
}


sub simple_image {
  my ( $self, $prompt, %extra ) = @_;
  my $request = $self->image_request($prompt, %extra);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}


sub _parse_rate_limit_headers {
  my ( $self, $http_response ) = @_;
  require Langertha::RateLimit;
  require Langertha::Moment;
  my %raw = Langertha::RateLimit::_collect_headers($http_response);
  return undef unless %raw;
  my $req_reset = $raw{'x-ratelimit-reset-requests'};
  my $tok_reset = $raw{'x-ratelimit-reset-tokens'};
  # OpenAI-family reset headers are Go time.Duration strings ("6m0s",
  # "2m59.56s", "250ms") — a duration, so they populate *_reset_after; the
  # matching *_reset_at is derived lazily against `received`. A value that is
  # not a Go duration parses to undef and neither half is set (raw keeps it).
  my $req_after = defined $req_reset ? Langertha::RateLimit::_parse_go_duration($req_reset) : undef;
  my $tok_after = defined $tok_reset ? Langertha::RateLimit::_parse_go_duration($tok_reset) : undef;
  return Langertha::RateLimit->new(
    received => Langertha::Moment->now_utc,
    ( defined $raw{'x-ratelimit-limit-requests'}     ? ( requests_limit       => $raw{'x-ratelimit-limit-requests'} + 0 )     : () ),
    ( defined $raw{'x-ratelimit-remaining-requests'} ? ( requests_remaining   => $raw{'x-ratelimit-remaining-requests'} + 0 ) : () ),
    ( defined $req_reset                             ? ( requests_reset       => $req_reset )                                 : () ),
    ( defined $req_after                             ? ( requests_reset_after => $req_after )                                 : () ),
    ( defined $raw{'x-ratelimit-limit-tokens'}       ? ( tokens_limit         => $raw{'x-ratelimit-limit-tokens'} + 0 )       : () ),
    ( defined $raw{'x-ratelimit-remaining-tokens'}   ? ( tokens_remaining     => $raw{'x-ratelimit-remaining-tokens'} + 0 )   : () ),
    ( defined $tok_reset                             ? ( tokens_reset         => $tok_reset )                                 : () ),
    ( defined $tok_after                             ? ( tokens_reset_after   => $tok_after )                                 : () ),
    raw => \%raw,
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::OpenAICompatible - Role for OpenAI-compatible API format

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # This role is not used directly - it's composed by engines
    # that implement the OpenAI-compatible API format.

    package My::Engine;
    use Moose;

    with map { 'Langertha::Role::'.$_ } qw(
        JSON HTTP OpenAICompatible OpenAPI Models Temperature
        ResponseSize SystemPrompt Streaming Chat Tools
    );

    sub _build_api_key { $ENV{MY_API_KEY} || die "needs api_key" }
    sub default_model { 'my-model' }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This role provides the OpenAI API format methods for chat completions,
embeddings, transcription, streaming, and tool calling. Engines that
use the OpenAI-compatible API format (whether OpenAI itself, Ollama's
C</v1> endpoint, or other compatible providers) can compose this role
instead of inheriting from L<Langertha::Engine::OpenAI>.

The role provides default implementations for all OpenAI-format operations.
Engines can override individual methods to customize behavior (e.g.,
different operation IDs for Mistral, or disabling unsupported features).

B<Engines should also compose these roles:>

=over 4

=item * L<Langertha::Role::JSON> - JSON encoding/decoding

=item * L<Langertha::Role::HTTP> - HTTP request handling

=item * L<Langertha::Role::OpenAPI> - OpenAPI spec-driven request generation

=item * L<Langertha::Role::Models> - Model management

=back

B<Engines using this role:>

=over 4

=item * Cloud providers — L<Langertha::Engine::OpenAI>,
L<Langertha::Engine::DeepSeek>, L<Langertha::Engine::Groq>,
L<Langertha::Engine::Hetzner>, L<Langertha::Engine::MiniMax>,
L<Langertha::Engine::Mistral>, L<Langertha::Engine::Moonshot>,
L<Langertha::Engine::XAI>, L<Langertha::Engine::Cerebras>,
L<Langertha::Engine::NousResearch>, L<Langertha::Engine::OpenRouter>,
L<Langertha::Engine::Replicate>, L<Langertha::Engine::HuggingFace>,
L<Langertha::Engine::Perplexity>, L<Langertha::Engine::AKIOpenAI>,
L<Langertha::Engine::TSystems>, L<Langertha::Engine::Scaleway>

=item * Self-hosted — L<Langertha::Engine::OllamaOpenAI>,
L<Langertha::Engine::vLLM>, L<Langertha::Engine::SGLang>,
L<Langertha::Engine::LlamaCpp>, L<Langertha::Engine::LMStudioOpenAI>

=back

The base classes L<Langertha::Engine::OpenAIBase> and
L<Langertha::Engine::OpenAI> also compose this role (and so every engine
that extends them inherits it without listing it explicitly).

=head2 api_key

Optional API key for Bearer token authentication. Override
C<_build_api_key> in engines that require authentication (typically
from an environment variable). When C<undef>, no Authorization header
is sent.

=head2 update_request

    $role->update_request($http_request);

Adds C<Authorization: Bearer {api_key}> header to outgoing requests
when an API key is configured. Skipped when C<api_key> is C<undef>
(e.g. for local servers like vLLM or llama.cpp).

=head2 openapi_file

    my ($type, $path) = $role->openapi_file;

Returns the OpenAI OpenAPI spec file path used for request generation.
Override in an engine to use a provider-specific spec (e.g., Mistral).

=head2 list_models_path

    my $path = $engine->list_models_path;

Returns the path appended to C<url> for the models endpoint.
Default: C</models>. Override in engines whose API spec uses a
different path (e.g. Mistral uses C</v1/models> because its base URL
does not include C</v1>).

=head2 list_models_request

    my $request = $engine->list_models_request;
    my $request = $engine->list_models_request(after => $last_id);

Generates an HTTP GET request for the models endpoint using
C<list_models_path>. Pass C<after> for cursor-based pagination.
Returns an HTTP request object.

=head2 list_models_response

    my $data = $engine->list_models_response($http_response);

Parses the C</v1/models> response. Returns the full response hashref
including C<data>, C<has_more>, and C<last_id> for pagination.

=head2 list_models

    my $model_ids = $engine->list_models;
    # Returns: ['gpt-4o', 'gpt-4o-mini', ...]

    my $models = $engine->list_models(full => 1);
    # Returns: [{id => 'gpt-4o', created => ..., ...}, ...]

    my $fresh = $engine->list_models(force_refresh => 1);

Fetches available models from the C</v1/models> endpoint with caching.
Automatically paginates through all pages using cursor-based pagination
(C<has_more> / C<after>). By default returns an ArrayRef of model ID
strings. Pass C<full =E<gt> 1> for full model objects. Results are cached
for C<models_cache_ttl> seconds (default: 3600). Pass C<force_refresh =E<gt> 1>
to bypass the cache.

=head2 embedding_request

    my $request = $engine->embedding_request($input, %extra);

Generates an OpenAI-format embedding request for C<$input>: a string, or
an ArrayRef of strings for a batch (sent as one C<input> array). Uses
C<embedding_model> (default: C<text-embedding-3-large>). C<%extra> goes
into the body unchanged (C<dimensions>, C<encoding_format>, ...);
L<Langertha::Role::Embedding/embedding_dimensions>, when set, is sent under
the field the private hook C<_embedding_dimensions_field> names
(C<dimensions> by default; L<Langertha::Engine::Mistral> overrides it with
C<output_dimension>), unless C<%extra> carries C<dimensions> or that field.
An engine whose hook returns C<undef> documents no such field for its
C<embedding_model>: the attribute is then not sent and carps once per engine
instance, while an explicit C<dimensions> extra still goes out untouched. The
request's response parser knows the input shape, so a batch comes back as
one vector per input (see L</embedding_response>). Returns an HTTP request
object.

=head2 embedding_response

    my $vector  = $engine->embedding_response($http_response);
    my $vectors = $engine->embedding_response($http_response, \@inputs);

Parses an OpenAI-format embedding response. The second argument is the
request's input; the parser built by L</embedding_request> passes it itself.
For a string input (or none) it returns the vector of the first input
(C<data[].index> 0) as an ArrayRef of floats. For an ArrayRef input it
returns an ArrayRef with one vector per input, in input order (sorted by
C<data[].index>), and croaks when the number of vectors does not match the
number of inputs. A response without a vector (no C<data> array, an empty
one, or an entry without an C<embedding>) croaks too, naming the engine and
any C<error> in the body; it never returns C<undef>.

A response requested with C<< encoding_format => 'base64' >> is decoded
(little-endian float32), so the result is floats either way; there is no
option to get the base64 string back. Parse the L<HTTP::Response> yourself
when you need the raw form.

=head2 chat_request

    my $request = $engine->chat_request($messages, %extra);

Generates an OpenAI-format chat completion request. Includes model,
messages, max_tokens, temperature, response_format (if set), and
C<stream =E<gt> false>. Returns an HTTP request object.

=head2 _wire_usage

Internal hook. Returns the usage block that goes onto the
L<Langertha::Response> of L</chat_response> and onto a stream chunk. The
default returns the wire block unchanged. An engine that knows what the wire
does not say overrides it and returns a copy with a canonical key added, which
L<Langertha::Usage/from_hash> reads on both paths:
L<Langertha::Engine::OpenRouter> adds C<cost_usd> from its bare C<usage.cost>.

=head2 chat_response

    my $response = $engine->chat_response($http_response);

Parses an OpenAI-format chat completion response. Returns a
L<Langertha::Response> object with C<content>, C<model>, C<finish_reason>,
C<usage>, C<created>, and C<raw>.

C<finish_reason> is the wire value, with one normalization: a reply that
carries tool calls but says C<stop> (gpt-oss on vLLM-style servers, e.g.
AKI.IO) reports C<tool_calls>, so it agrees with C<tool_calls>. Every other
value, C<length> included, passes through; the wire value stays readable in
C<raw>.

C<message.content> may be a list of content chunks instead of a string, as
Mistral's reasoning models send it: the text of C<text> chunks becomes
C<content>, the text inside C<thinking> chunks becomes C<thinking> (unless
C<reasoning_content> / C<reasoning> already filled it), and other chunk types
are skipped.

C<message.refusal> (a declined structured-output request, C<content> then
null) becomes L<Langertha::Response/refusal>.

A body without a choice is not an answer and croaks, naming the engine: with
an C<error> object (gateways such as OpenRouter return one in a 200 body)
C<"E<lt>engineE<gt> response carried an error: E<lt>messageE<gt> (E<lt>codeE<gt>)">,
otherwise C<"E<lt>engineE<gt> response contained no choices">. A choice
carrying an C<error> object, or a top-level C<error> beside a choice whose
C<finish_reason> is C<error> (OpenRouter reports a provider failure this
way), croaks the same C<response carried an error>; a C<finish_reason> of
C<error> with no error object anywhere croaks
C<"E<lt>engineE<gt> response ended with finish_reason error">. Only
C<choices[0]> is read.

=head2 transcription_request

    my $request = $engine->transcription_request($audio, %extra);

Generates an OpenAI-format transcription request for the given audio (a path,
C<\$bytes> or a filehandle; C<filename> in C<%extra> names the upload, see
L<Langertha::Role::Transcription/transcription_file_part>).
Uses C<transcription_model> (default: C<whisper-1>; C<gpt-transcribe> on
L<Langertha::Engine::OpenAI>). Returns an HTTP request object.

C<< languages => [ 'de', 'en' ] >> is sent as repeated C<languages[]> fields.
C<gpt-transcribe> takes only that plural field, so for a C<gpt-transcribe*>
model a C<language> you pass is sent as C<languages[]> too (merged into
C<languages> if both are given); other models get C<language> as given.

C<gpt-transcribe> (and the older C<gpt-4o-transcribe> /
C<gpt-4o-mini-transcribe>) answer only C<< response_format => 'json' >>, which
is what the API sends when no C<response_format> is given; Langertha never
defaults one. C<verbose_json>, C<srt>, C<vtt> and
C<timestamp_granularities[]> need a model that supports them, such as
C<whisper-1> on OpenAI or a Whisper server; a C<response_format> you pass is
sent as given.

=head2 transcription_result

    my $result = $engine->transcription_result($http_response);
    say $result->{text};
    for my $segment ( @{ $result->{segments} // [] } ) { ... }

Parses a transcription response into a HashRef. A JSON answer
(C<response_format> C<json> or C<verbose_json>) is returned as decoded, so
C<segments>, C<words>, C<language>, C<duration> and C<usage> stay reachable. A
plain-text answer (C<text>, C<srt>, C<vtt>) becomes C<< { text => $body } >>,
decoded as UTF-8 unless the response names another charset. Croaks like
L<Langertha::Role::HTTP/parse_response> on an HTTP error.

=head2 transcription_response

    my $text = $engine->transcription_response($http_response);

Parses an OpenAI-format transcription response and returns the transcript as
a string, for every C<response_format>: the C<text> field of a C<json> or
C<verbose_json> answer, the body of a C<text>, C<srt> or C<vtt> answer (the
subtitle markup included). Use L</transcription_result> to keep segments and
word timestamps.

=head2 stream_format

    my $format = $engine->stream_format;

Returns C<'sse'> (Server-Sent Events), indicating the streaming format
used by OpenAI-compatible APIs. Used by L<Langertha::Role::Chat> to
select the correct stream parser.

=head2 chat_stream_request

    my $request = $engine->chat_stream_request($messages, %extra);

Generates an OpenAI-format streaming chat request (C<stream =E<gt> true>).
Returns an HTTP request object for use with streaming execution.

=head2 parse_stream_chunk

    my $chunk = $engine->parse_stream_chunk($data, $event, \%state);

Parses a single SSE data payload from an OpenAI-format stream. Returns
a L<Langertha::Stream::Chunk> with C<content>, C<is_final>, C<finish_reason>,
C<model>, C<usage>, C<cached_tokens> (lifted from
C<usage.prompt_tokens_details.cached_tokens> when present), and C<thinking>
(the streamed C<delta.reasoning_content> / bare C<delta.reasoning>, guarded
C<!ref>). A C<delta.content> that is a list of content chunks is read as in
L</chat_response>: C<text> chunks into C<content>, C<thinking> chunks into
C<thinking>. The usage-only frame that C<stream_options =E<gt> { include_usage
=E<gt> 1 }> adds after the finish chunk (an empty C<choices> list) becomes a
content-less chunk that is not C<is_final> and carries C<usage> and
C<cached_tokens>; collect the stream's usage with
L<Langertha::Role::Chat/aggregate_usage>. Returns C<undef> only when the
payload carries neither a choice nor a usage block. A frame with a top-level
C<error> object and no choice (a gateway failing mid-stream) croaks
C<"E<lt>engineE<gt> stream carried an error: E<lt>messageE<gt> (E<lt>codeE<gt>)">,
which fails the stream; so does a choice carrying an C<error> object, or a
top-level C<error> beside a choice with C<finish_reason> C<error>
(OpenRouter's mid-stream failure frame). A choice with C<finish_reason>
C<error> and no error object anywhere croaks
C<"E<lt>engineE<gt> stream ended with finish_reason error">. A C<delta.refusal> fragment lands on the chunk's
C<refusal>.

C<delta.tool_calls> fragments are assembled per C<index> (a fragment without
C<index> by its C<id>, and by its position only when it has neither) in
C<\%state>, and the finished calls land as L<Langertha::ToolCall> objects, in
stream order, on the chunk that carries a non-empty C<finish_reason>, read by the
same L<Langertha::ToolCall/extract> as L</chat_response>. Collect them with
L<Langertha::Role::Chat/aggregate_tool_calls>. C<finish_reason> is read as on
the non-streaming path: the wire value, except that C<stop> on the chunk that
delivers tool calls reports C<tool_calls> (the wire value stays in C<raw>). A stream that
ends without one drops its pending calls with a C<carp> (see
L</_finish_stream_state>).

C<\%state> is one HashRef per stream. The stream paths pass it;
C<$event> is only set by L<Langertha::Role::Streaming/process_stream_data>, the
C<chat_stream_realtime_f> path passes C<undef>. A direct caller may omit
C<\%state> and share the engine's fallback, which is closed when a
C<_process_stream_buffer> flush with C<$final> set ends the stream; a caller
feeding events to C<parse_stream_chunk> one by one should pass its own state.

=head2 _finish_stream_state

    $engine->_finish_stream_state(\%state);

Internal: called once when a stream ends (by
L<Langertha::Role::Streaming/process_stream_data> and
L<Langertha::Role::Chat/chat_stream_realtime_f>, and by a final
C<_process_stream_buffer> flush that was given no state). Tool calls still
pending because no chunk carried a C<finish_reason> -- a truncated stream -- are
dropped with one C<carp> naming them, not flushed: their C<arguments> may be
cut off, and a partial JSON string would decode to C<{}>. Clearing them also
keeps them out of the next stream that shares the same state.

=head2 image_request

    my $request = $engine->image_request($prompt, %extra);

Generates an OpenAI-format image generation request for the given
C<$prompt>. Uses C<image_model> (default: C<gpt-image-2>). Accepts
optional C<model>, C<size>, C<quality> and C<n> via C<%extra>, passed
through as given. Returns an HTTP request object.

GPT image models (C<gpt-image-*>) always return the image as C<b64_json> and
reject C<response_format>, so a C<response_format> in C<%extra> is dropped
with a warning for them.

=head2 image_response

    my $images = $engine->image_response($http_response);

Parses an OpenAI-format image generation response. Returns an ArrayRef
of image objects, each with C<url> or C<b64_json> (GPT image models answer
C<b64_json> only) and optionally C<revised_prompt>. Croaks, naming the engine and any C<error> in the
body, when the response carries no image.

=head2 simple_image

    my $images = $engine->simple_image('A cat in space');

Sends an image generation request and returns the result. Blocks until
the request completes. Returns an ArrayRef of image objects.

=head2 _parse_rate_limit_headers

Parses C<x-ratelimit-*> headers from the HTTP response into a
L<Langertha::RateLimit> object. Covers OpenAI, Groq, Cerebras, OpenRouter,
Replicate, and all other OpenAI-compatible engines. Collects the full C<raw>
superset via L<Langertha::RateLimit/_collect_headers>, then normalizes the
Go C<time.Duration> reset strings into L<Langertha::RateLimit/requests_reset_after>
/ L<Langertha::RateLimit/tokens_reset_after> (seconds); the C<*_reset_at>
instants are derived lazily against L<Langertha::RateLimit/received>.

=head1 SEE ALSO

=over

=item * L<Langertha::RateLimit> - Normalized rate limit data

=item * L<Langertha::Engine::OpenAI> - OpenAI engine

=item * L<Langertha::Engine::DeepSeek> - DeepSeek engine

=item * L<Langertha::Engine::Groq> - Groq engine

=item * L<Langertha::Engine::Mistral> - Mistral engine

=item * L<Langertha::Engine::vLLM> - vLLM inference server

=item * L<Langertha::Engine::NousResearch> - Nous Research Hermes engine

=item * L<Langertha::Engine::Perplexity> - Perplexity Sonar engine

=item * L<Langertha::Engine::OllamaOpenAI> - Ollama OpenAI-compatible engine

=item * L<Langertha::Engine::AKIOpenAI> - AKI.IO OpenAI-compatible engine

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
