package Langertha::Role::AnthropicCompatible;
# ABSTRACT: Role for Anthropic-compatible API format
our $VERSION = '0.503';
use Moose::Role;
use Carp qw( croak carp );
use JSON::MaybeXS;
use Langertha::ToolChoice;
use Langertha::Tool;
use Langertha::Response;
use Langertha::ToolCall;


sub _build_reasoning_wire_format { 'anthropic' }
sub _build_cache_wire_format { 'anthropic' }

sub default_response_size { 1024 }

sub content_format { 'anthropic' }

has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key {
  my ( $self ) = @_;
  return croak "".(ref $self)." requires api_key to be set";
}


has api_version => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_version { '2023-06-01' }


has effort => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_effort',
);


has inference_geo => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_inference_geo',
);


sub update_request {
  my ( $self, $request ) = @_;
  $request->header('x-api-key', $self->api_key);
  $request->header('content-type', 'application/json');
  $request->header('anthropic-version', $self->api_version);
}


sub chat_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};

  # Structured output. Engines whose wire has native structured output
  # (Engine::Anthropic, via _native_structured_output) emit it as
  # output_config.format and leave the content JSON on the wire (chat_response
  # returns it verbatim). Engines without it (the legacy /anthropic shims)
  # keep the ADR 0005 synthesized-tool + forced tool_choice rewrite, whose
  # tool_use input chat_response lifts back into content.
  my $rf_routed = 0;
  my $output_config_format;
  if ( $self->_native_structured_output_for_model ) {
    my $rf = $self->_take_response_format(\%extra, $controls);
    # A schema-bearing response_format goes native (output_config.format); the
    # first-party validator rejects an open schema, so it is normalized to a
    # closed one first (k182/k149). A bare json_object has no schema and the
    # Messages API has no native free-form JSON form, so it routes through the
    # synthesized-tool path (open, non-strict input_schema) exactly like the
    # legacy /anthropic shims -- forced where the model allows it, degraded to
    # tool_choice `auto` where forced tool use 400s (fable-5-1 / mythos-5-1).
    if ( $self->_rf_is_native_schema($rf) ) {
      $output_config_format = $self->_response_format_to_output_config($rf);
    }
    else {
      # // 0 keeps $rf_routed defined (a non-honorable rf yields undef) so
      # chat_response does not fall back to the has_response_format heuristic.
      $rf_routed = $self->_response_format_via_tool($rf, \%extra) // 0;
    }
  }
  else {
    $rf_routed = $self->_translate_response_format(\%extra, $controls);
  }

  $self->_normalize_tool_params(\%extra, $controls);
  my @msgs;
  my $system = "";
  for my $message (@{$messages}) {
    if ($message->{role} eq 'system') {
      $system .= "\n\n" if length $system;
      $system .= $message->{content};
    } else {
      push @msgs, $message;
    }
  }
  if ($system and scalar @msgs == 0) {
    push @msgs, {
      role => 'user',
      content => $system,
    };
    $system = undef;
  }

  my %generation = $self->generation_kwargs_for(%$controls);
  $self->_merge_output_config_format( \%generation, $output_config_format );

  return $self->generate_http_request( POST => $self->url.'/v1/messages', sub { $self->chat_response(shift, $rf_routed) },
    model => $self->chat_model,
    messages => \@msgs,
    exists $controls->{max_tokens}
      ? ( max_tokens => $controls->{max_tokens} )
      : ( max_tokens => $self->get_response_size ), # must be always set
    $self->_temperature_kwargs($controls),
    %generation,
    $self->has_inference_geo ? ( inference_geo => $self->inference_geo ) : (),
    $system ? ( system => $system ) : (),
    %extra,
  );
}


# Whether this engine's wire has native structured output (output_config.format,
# GA on the first-party Claude API — see ADR 0005 amendment). Default no: the
# legacy /anthropic shim engines (MiniMax, Moonshot, AKI, LM Studio) keep the
# synthesized-tool rewrite. Engine::Anthropic overrides this to a true value.
sub _native_structured_output { 0 }


# Whether THIS request's chat_model takes native output_config.format. Defaults
# to the endpoint predicate above; a shim whose endpoint documents the native
# form for some models only overrides this one (MoonshotAnthropic: kimi-k3,
# karr k218), so the endpoint -- and its manifest dialect -- stays a shim.
sub _native_structured_output_for_model {
  my ( $self ) = @_;
  return $self->_native_structured_output;
}


# Pull a response_format hash out of the per-request controls / %extra / engine
# attribute (per-request beats engine attribute, chat_f/karr #46) and remove it
# from both — the Messages API has no top-level response_format field and 400s
# when one reaches the wire, on every structured-output path.
sub _take_response_format {
  my ( $self, $extra, $controls ) = @_;
  return exists $controls->{response_format}
    ? delete $controls->{response_format}
    : exists $extra->{response_format}
      ? delete $extra->{response_format}
      : $self->has_response_format ? $self->response_format : undef;
}

# True when a response_format hash is a json_schema carrying an actual schema
# object -- the only form with a native output_config.format home. A bare
# json_object (no schema) is not: it has no closed native form and routes
# through the synthesized-tool path instead (k182).
sub _rf_is_native_schema {
  my ( $self, $rf ) = @_;
  return 0 unless ref($rf) eq 'HASH';
  return 0 unless ( $rf->{type} // '' ) eq 'json_schema';
  return 0 unless ref( $rf->{json_schema} ) eq 'HASH';
  return ref( $rf->{json_schema}{schema} ) eq 'HASH' ? 1 : 0;
}

# Turn a json_schema response_format into the native output_config.format value.
# The first-party validator requires a CLOSED schema (additionalProperties:false
# on every object) and 400s on anything else, so the caller's schema is
# normalized to closed rather than passed through unchanged (k182/k149). Returns
# undef when the hash is not a native json_schema (json_object has no schema and
# goes via the synthesized-tool path).
sub _response_format_to_output_config {
  my ( $self, $rf ) = @_;
  return undef unless $self->_rf_is_native_schema($rf);
  return {
    type   => 'json_schema',
    schema => $self->_close_schema( $rf->{json_schema}{schema} ),
  };
}

# Normalize a JSON Schema for the first-party output_config.format validator,
# which requires additionalProperties:false on every object and rejects an open
# schema (k182/k149). Recurses the standard schema carriers and sets
# additionalProperties:false on each object that does not already close itself,
# without mutating the caller's schema. An additionalProperties that is itself a
# schema — a dictionary/map value type, e.g. { type => 'string' } — is kept and
# recursed as a subschema, not clobbered to false (k183): only an absent or
# truthy-boolean additionalProperties means "open object" and gets closed. This
# is the house "normalize the wire quirk, don't gatekeep" stance; a caller who
# wants genuinely free-form JSON uses response_format json_object, which routes
# through the non-strict tool path.
sub _close_schema {
  my ( $self, $node ) = @_;
  return $node unless ref($node) eq 'HASH';
  my %out = %$node;
  if ( ( ( $out{type} // '' ) eq 'object' ) || exists $out{properties} ) {
    my $ap = $out{additionalProperties};
    if ( ref $ap eq 'HASH' ) {
      # A map/dictionary value schema: recurse into it, keep it as a schema.
      $out{additionalProperties} = $self->_close_schema($ap);
    }
    elsif ( !exists $out{additionalProperties} || $ap ) {
      # Absent, or a truthy boolean (JSON true) -> close the object.
      $out{additionalProperties} = JSON->false;
    }
    # else: already explicitly false -> leave it closed.
  }
  if ( ref $out{properties} eq 'HASH' ) {
    $out{properties} = {
      map { $_ => $self->_close_schema( $out{properties}{$_} ) }
        keys %{ $out{properties} }
    };
  }
  $out{items} = $self->_close_schema( $out{items} ) if ref $out{items} eq 'HASH';
  for my $key (qw( anyOf allOf oneOf )) {
    $out{$key} = [ map { $self->_close_schema($_) } @{ $out{$key} } ]
      if ref $out{$key} eq 'ARRAY';
  }
  for my $key (qw( $defs definitions )) {
    $out{$key} = {
      map { $_ => $self->_close_schema( $out{$key}{$_} ) } keys %{ $out{$key} }
    } if ref $out{$key} eq 'HASH';
  }
  return \%out;
}

# Fold a native structured-output format into output_config, MERGING rather than
# replacing: Langertha::Reasoning::to_anthropic already puts effort under the
# same output_config key, so a naive second output_config would silently drop
# one of the two (k133 point 3). Mutates the generation-kwargs hash in place.
sub _merge_output_config_format {
  my ( $self, $generation, $format ) = @_;
  return unless $format;
  my $oc = $generation->{output_config};
  $generation->{output_config} = {
    ( ref($oc) eq 'HASH' ? %$oc : () ),
    format => $format,
  };
  return;
}

# temperature / top_p / top_k are deprecated on the Messages API and 400 with a
# non-default value on a growing set of models (Opus 4.7+ and the 5-series);
# Engine::Anthropic clears the `temperature` capability for those via
# model_capability_corrections (k138), and this gate keeps the field off the
# wire whenever the selected model rejects it — whether it came from the engine
# attribute or a per-request control (k135 point 1). The same capability clear
# covers Kimi's /anthropic face, where every current id fixes temperature
# server-side (karr k214). A caller-set non-default value that the gate drops
# carps (ADR 0025 k214 Update) -- that drop used to be silent; 1 is dropped
# quietly.
sub _temperature_kwargs {
  my ( $self, $controls ) = @_;
  my $temp = exists $controls->{temperature} ? $controls->{temperature}
           : $self->has_temperature          ? $self->temperature
           :                                    undef;
  return () unless defined $temp;
  # An engine attribute is the same on every request: warn once per engine
  # instance (karr k247); a per-request control warns every time.
  my $once = exists $controls->{temperature} ? undef
    : 'temperature=' . $temp . ' model=' . ( $self->can('chat_model') ? $self->chat_model // '' : '' );
  unless ( $self->supports('temperature') ) {
    $self->_langertha_carp( "".( ref $self ).": dropping temperature=$temp -- model '"
      . ( $self->chat_model // '' )
      . "' does not take a temperature (rejected or fixed server-side); "
      . "unset temperature to silence this",
      defined $once ? "$once unsupported" : undef )
      if $temp != 1;
    return ();
  }
  return ( temperature => $temp );
}

# Anthropic has no response_format; emulate via a synthetic tool plus
# a forced tool_choice. The response_call will detect the synthetic
# tool_use block and lift its input back into the response content.
my $SYNTH_RF_TOOL_NAME = '__langertha_response_format__';

sub _translate_response_format {
  my ( $self, $extra, $controls ) = @_;

  # A per-request response_format (chat_f, karr #46) beats the engine
  # attribute, and is removed from the extras either way: the Messages API
  # has no response_format field and answers 400 when one reaches the wire.
  my $rf = $self->_take_response_format($extra, $controls);
  return $self->_response_format_via_tool( $rf, $extra );
}

# Build the synthesized tool + tool_choice for a response_format hash, push them
# onto %extra, and return the synthetic tool name (undef when the hash is not
# honorable). The tool's input_schema is not strict, so an open schema -- a
# caller's, or the open-object stand-in for a bare json_object -- passes here
# where the native output_config.format validator would 400. The tool is forced
# where the model allows forced tool use and degraded to `auto` where it does not
# (claude-fable-5-1 / claude-mythos-5-1 clear tool_choice_named, k133 point 2);
# under `auto` chat_response lifts the tool_use only if the model emits it, so
# free-form json_object has no guaranteed path on those models (k182).
sub _response_format_via_tool {
  my ( $self, $rf, $extra ) = @_;
  return unless ref($rf) eq 'HASH';
  my $type = $rf->{type} // '';

  my ( $name, $schema, $description );
  if ( $type eq 'json_schema' && ref( $rf->{json_schema} ) eq 'HASH' ) {
    my $js = $rf->{json_schema};
    $name        = $js->{name} // $SYNTH_RF_TOOL_NAME;
    $schema      = $js->{schema};
    $description = $js->{description};
  }
  elsif ( $type eq 'json_object' ) {
    $name   = $SYNTH_RF_TOOL_NAME;
    $schema = { type => 'object', additionalProperties => JSON->true };
  }
  else {
    return;
  }
  return unless ref($schema) eq 'HASH';

  my $tool = Langertha::Tool->new(
    name         => $name,
    input_schema => $schema,
    ( defined $description ? ( description => $description ) : () ),
  )->to_anthropic;

  $extra->{tools} ||= [];
  push @{ $extra->{tools} }, $tool;
  $extra->{tool_choice} = $self->supports('tool_choice_named')
    ? { type => 'tool', name => $name }
    : { type => 'auto' };
  return $name;
}


# Normalize tool_choice (any accepted format -> Anthropic native) and fold
# parallel_tool_use into the tool_choice block as Anthropic expects. A
# per-request parallel_tool_use control (chat_f, karr #46) beats the engine
# attribute.
sub _normalize_tool_params {
  my ( $self, $extra, $controls ) = @_;

  if ( exists $extra->{tool_choice} && defined $extra->{tool_choice} ) {
    if ( my $tc = Langertha::ToolChoice->from_hash( $extra->{tool_choice} ) ) {
      $extra->{tool_choice} = $tc->to( $self->tool_wire_format );
    }
  }

  return unless exists $extra->{tools};

  my $ptu;
  if ( exists $controls->{parallel_tool_use} ) {
    $ptu = $controls->{parallel_tool_use};
  }
  elsif ( $self->can('has_parallel_tool_use') && $self->has_parallel_tool_use ) {
    $ptu = $self->parallel_tool_use;
  }
  return unless defined $ptu;

  my $tc = $extra->{tool_choice};
  $tc = { type => 'auto' } unless ref($tc) eq 'HASH';
  unless ( exists $tc->{disable_parallel_tool_use} ) {
    $tc->{disable_parallel_tool_use} = $ptu ? JSON->false : JSON->true;
  }
  $extra->{tool_choice} = $tc;
}


sub chat_response {
  my ( $self, $response, $rf_routed ) = @_;
  my $data = $self->parse_response($response);
  # An error envelope ({"type":"error","error":{...}}) or an `error` object
  # without content, delivered with a 200, is no answer: it parsed to content
  # '' like a model that said nothing. Croak like the k301 OpenAI-compatible
  # parser -- karr k338.
  if ( ref $data eq 'HASH'
       && ( ( $data->{type} // '' ) eq 'error'
         || ( defined $data->{error}
           && !( ref $data->{content} eq 'ARRAY' && @{ $data->{content} } ) ) ) ) {
    croak "".( ref $self )." response carried an error: "
      .( $self->_body_error_text( $data->{error} ) // 'no error message' );
  }
  # A malformed/error payload that still parses as a 200 JSON body (a shim
  # error shape) can lack the `content` array; default it to empty so callers
  # get graceful empty content rather than a raw deref crash on @{undef}. The
  # OpenAI path is defensive at the equivalent spot. -- karr k171
  my @blocks = @{ $data->{content} // [] };
  my $text = join('', map { $_->{text} // '' } grep { $_->{type} eq 'text' } @blocks);
  my @thinking = map { $_->{thinking} // '' } grep { $_->{type} eq 'thinking' } @blocks;
  my $thinking = @thinking ? join("\n", @thinking) : undef;
  my @tcs = Langertha::ToolCall->extract( $self->tool_wire_format, $data );

  # If the caller asked for a response_format and we routed it through a
  # synthesized tool, lift the tool_use input back into the content as
  # JSON so callers can treat it like any other structured-output result.
  # chat_request passes the synthesized tool name for both the per-request
  # and the engine-attribute path; the attribute check stays as the
  # fallback for callers invoking chat_response directly.
  $rf_routed = $self->has_response_format unless defined $rf_routed;
  if ( $rf_routed && @tcs ) {
    $text = $self->encode_json_text( $tcs[0]->arguments );
  }
  return Langertha::Response->new(
    content       => $text,
    raw           => $data,
    $data->{id} ? ( id => $data->{id} ) : (),
    $data->{model} ? ( model => $data->{model} ) : (),
    defined $data->{stop_reason} ? ( finish_reason => $data->{stop_reason} ) : (),
    $data->{usage} ? ( usage => $self->_wire_usage( $data->{usage} ) ) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
    @tcs ? ( tool_calls => [ @tcs ] ) : (),
  );
}


# Whether this endpoint counts the cache reads/writes inside usage.input_tokens.
# Langertha::Usage infers it from the spelling, and the flat Anthropic keys mean
# "beside" -- first-party Anthropic's truth, also documented by MiniMax and
# Moonshot. A shim that reuses the spelling but counts the cache inside
# input_tokens overrides this to 1 (ADR 0018 tier 3, ADR 0031, k265). undef
# keeps the inference.
sub _usage_input_includes_cache { return }

# The usage block as it goes onto the Response / the final stream chunk: a copy
# carrying the canonical input_includes_cache key when the engine sets one, so
# Usage->from_hash reads the same flag on the non-streaming and streaming path.
# The wire hash itself is never modified.
sub _wire_usage {
  my ( $self, $usage ) = @_;
  return $usage unless ref $usage eq 'HASH';
  my $includes = $self->_usage_input_includes_cache;
  return $usage unless defined $includes;
  return { %$usage, input_includes_cache => $includes ? 1 : 0 };
}


sub stream_format { 'sse' }


sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};

  # Structured output on the streaming path. Engines with native structured
  # output (output_config.format) stream it as ordinary text deltas — the JSON
  # is the content — so it needs no Response lift and streams fine. The legacy
  # /anthropic shims have no native form; their synthesized-tool rewrite has no
  # streaming counterpart to the chat_response tool_use lift (ADR 0005), so
  # rather than silently streaming unstructured text (karr #52 Folge 1) or
  # leaking response_format onto the wire (Folge 2) they consume the key and
  # refuse loudly.
  my $rf = $self->_take_response_format(\%extra, $controls);
  my $output_config_format;
  if ( $self->_native_structured_output_for_model ) {
    # A json_schema streams as native output_config.format (normalized closed).
    # A bare json_object has no native free-form form and the synthesized-tool
    # fallback has no streaming lift, so -- like the shims below -- consume the
    # key and refuse loudly rather than 400 on the wire or stream unstructured
    # text (k182, ADR 0005 paragraph 2).
    if ( $self->_rf_is_native_schema($rf) ) {
      $output_config_format = $self->_response_format_to_output_config($rf);
    }
    elsif ( ref($rf) eq 'HASH' && ( $rf->{type} // '' ) eq 'json_object' ) {
      croak "".(ref $self)." cannot stream a json_object response_format: the "
        . "Messages endpoint has no native free-form JSON output (only json_schema "
        . "via output_config.format), and the synthesized-tool fallback has no streaming lift. Use "
        . "chat_f/chat_request, or pass a json_schema response_format to stream "
        . "native structured output.";
    }
  }
  elsif ( ref($rf) eq 'HASH' ) {
    my $type = $rf->{type} // '';
    my $honored = $type eq 'json_object'
      || ( $type eq 'json_schema'
        && ref( $rf->{json_schema} ) eq 'HASH'
        && ref( $rf->{json_schema}{schema} ) eq 'HASH' );
    if ($honored) {
      croak "".(ref $self)." cannot stream response_format: this Anthropic-shim engine "
        . "routes structured output through a synthesized tool whose tool_use input "
        . "is lifted into Response.content by chat_response, and the streaming path "
        . "has no Response to lift from. Use chat_f/chat_request for structured output.";
    }
  }

  $self->_normalize_tool_params(\%extra, $controls);
  my @msgs;
  my $system = "";
  for my $message (@{$messages}) {
    if ($message->{role} eq 'system') {
      $system .= "\n\n" if length $system;
      $system .= $message->{content};
    } else {
      push @msgs, $message;
    }
  }
  if ($system and scalar @msgs == 0) {
    push @msgs, {
      role => 'user',
      content => $system,
    };
    $system = undef;
  }

  my %generation = $self->generation_kwargs_for(%$controls);
  $self->_merge_output_config_format( \%generation, $output_config_format );

  return $self->generate_http_request( POST => $self->url.'/v1/messages', sub {},
    model => $self->chat_model,
    messages => \@msgs,
    exists $controls->{max_tokens}
      ? ( max_tokens => $controls->{max_tokens} )
      : ( max_tokens => $self->get_response_size ), # must be always set
    $self->_temperature_kwargs($controls),
    %generation,
    $self->has_inference_geo ? ( inference_geo => $self->inference_geo ) : (),
    $system ? ( system => $system ) : (),
    stream => JSON->true,
    %extra,
  );
}


sub parse_stream_chunk {
  my ( $self, $data, $event, $state ) = @_;

  require Langertha::Stream::Chunk;

  # Anthropic uses event types: content_block_delta, message_delta, message_stop
  my $type = $data->{type} // '';

  # A streamed tool call is a tool_use content block: content_block_start
  # names it (id, name, an empty input), input_json_delta events carry its
  # input as partial_json fragments, content_block_stop closes it. Assemble the
  # block per content-block index in this stream's state and deliver it on its
  # content_block_stop, read by the same ToolCall->extract chat_response uses,
  # so a streamed and a non-streamed reply of one response yield the same call.
  # The block leaves the state as it is delivered, so it never arrives twice.
  # -- karr k221
  $state //= $self->_stream_parse_state;
  my $blocks = $state->{anthropic_tool_blocks} //= {};

  # Anthropic splits the terminal stream metadata across two SSE events:
  # message_delta carries finish_reason (stop_reason) + usage but is not the
  # final event, and message_stop is the final event but carries neither. The
  # cross-dialect Stream::Chunk contract puts finish_reason + usage on the same
  # chunk that is is_final -- which the documented
  # `if ($chunk->is_final) { ...$chunk->finish_reason... }` consumer relies on --
  # so the message_delta metadata is held in the stream state under
  # anthropic_final_meta and replayed onto the message_stop chunk (karr k167).
  # It lives in the per-stream state, not on the engine, so two concurrent
  # streams on one engine cannot wipe or swap each other's (karr k221 review).

  # A new message begins the terminal-metadata carry fresh (karr k167): guards
  # against a prior stream on the same state that aborted before message_stop.
  # message_start also carries the input side of the usage (input_tokens,
  # cache_read_input_tokens, cache_creation_input_tokens) and the model;
  # message_delta's usage documents only output_tokens. Keep both in the
  # stream state so the final chunk's usage is complete and names the model.
  # -- karr k298
  if ($type eq 'message_start') {
    delete $state->{anthropic_final_meta};
    %$blocks = ();
    my $message = ref $data->{message} eq 'HASH' ? $data->{message} : {};
    $state->{anthropic_start_usage} =
      ref $message->{usage} eq 'HASH' ? { %{ $message->{usage} } } : undef;
    $state->{anthropic_model} = length( $message->{model} // '' ) ? $message->{model} : undef;
    return undef;
  }

  if ($type eq 'content_block_start') {
    my $block = $data->{content_block};
    if ( ref $block eq 'HASH' && ( $block->{type} // '' ) eq 'tool_use' ) {
      $blocks->{ $data->{index} // 0 } = { block => { %$block }, json => '' };
    }
    return undef;
  }

  if ($type eq 'content_block_stop') {
    my $open = delete $blocks->{ $data->{index} // 0 } or return undef;
    my $block = $open->{block};
    $block->{input} = $open->{json} if length $open->{json};
    my @tool_calls = Langertha::ToolCall->extract( $self->tool_wire_format,
      { content => [ $block ] } );
    return undef unless @tool_calls;
    return Langertha::Stream::Chunk->new(
      content    => '',
      raw        => $data,
      is_final   => 0,
      tool_calls => \@tool_calls,
    );
  }

  if ($type eq 'content_block_delta') {
    my $delta = $data->{delta} || {};
    if ( ( $delta->{type} // '' ) eq 'input_json_delta'
      && ( my $open = $blocks->{ $data->{index} // 0 } ) ) {
      $open->{json} .= $delta->{partial_json} // '';
    }
    # A content_block_delta is discriminated by delta.type: text_delta carries
    # `text`, thinking_delta carries `thinking` (extended-thinking models), then
    # exactly one signature_delta precedes content_block_stop. Surface the
    # streamed thinking onto the chunk; content stays the text delta. -- karr k129
    my $dtype = $delta->{type} // '';
    return Langertha::Stream::Chunk->new(
      content => $delta->{text} // '',
      raw => $data,
      is_final => 0,
      ( $dtype eq 'thinking_delta' && defined $delta->{thinking}
        ? ( thinking => $delta->{thinking} ) : () ),
    );
  }

  if ($type eq 'message_delta') {
    my $delta = $data->{delta} || {};
    # Remember the terminal metadata (finish_reason + usage) so it can be
    # replayed onto the is_final message_stop chunk, matching the cross-dialect
    # contract (see anthropic_final_meta above). It still rides this chunk too.
    # -- k167
    # The usage is message_start's merged with this event's, key by key with
    # this event winning: it carries the final output_tokens, and newer API
    # versions repeat cumulative input counts here too. -- karr k298
    my $start = $state->{anthropic_start_usage};
    my $usage = ref $data->{usage} eq 'HASH'
      ? { ( ref $start eq 'HASH' ? %$start : () ), %{ $data->{usage} } }
      : $start;
    my %final = (
      $delta->{stop_reason} ? (finish_reason => $delta->{stop_reason}) : (),
      $usage ? (usage => $self->_wire_usage($usage)) : (),
      defined $state->{anthropic_model} ? (model => $state->{anthropic_model}) : (),
    );
    $state->{anthropic_final_meta} = %final ? { %final } : undef;
    return Langertha::Stream::Chunk->new(
      content => '',
      raw => $data,
      is_final => 0,
      %final,
    );
  }

  if ($type eq 'message_stop') {
    # Replay the finish_reason + usage that message_delta carried onto the
    # is_final chunk, so is_final and the terminal metadata land together as
    # every other dialect delivers them (karr k167).
    my $final = delete $state->{anthropic_final_meta};
    return Langertha::Stream::Chunk->new(
      content => '',
      raw => $data,
      is_final => 1,
      ( ref $final eq 'HASH' ? %$final : () ),
    );
  }

  # Other event types (ping, ...) - skip
  return undef;
}


# Dynamic model listing with cursor pagination
sub list_models_request {
  my ($self, %params) = @_;
  my $url = $self->url.'/v1/models';

  # Add pagination params if provided
  if (%params) {
    require URI;
    my $uri = URI->new($url);
    $uri->query_form(%params);
    $url = $uri->as_string;
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


sub _fetch_all_models {
  my ($self) = @_;
  my @all_models;
  my $after_id;

  do {
    my $request = $self->list_models_request(
      $after_id ? (after_id => $after_id, limit => 100) : ()
    );
    my $response = $self->user_agent->request($request);
    my $data = $request->response_call->($response);

    push @all_models, @{$data->{data}};
    $after_id = $data->{has_more} ? $data->{last_id} : undef;
  } while ($after_id);

  return \@all_models;
}

sub list_models {
  my ($self, %opts) = @_;

  # Check cache unless force_refresh requested
  unless ($opts{force_refresh}) {
    my $cache = $self->_models_cache;
    if ($cache->{timestamp} && time - $cache->{timestamp} < $self->models_cache_ttl) {
      return $opts{full} ? $cache->{models} : $cache->{model_ids};
    }
  }

  # Fetch all pages from API
  my $models = $self->_fetch_all_models;

  # Extract IDs and update cache
  my @model_ids = map { $_->{id} } @$models;
  $self->_models_cache({
    timestamp => time,
    models => $models,
    model_ids => \@model_ids,
  });

  return $opts{full} ? $models : \@model_ids;
}


# Tool calling support (MCP) is the tag-driven default in Langertha::Role::Tools.
sub _build_tool_wire_format { 'anthropic' }

sub _parse_rate_limit_headers {
  my ( $self, $http_response ) = @_;
  require Langertha::RateLimit;
  require Langertha::Moment;
  my %raw = Langertha::RateLimit::_collect_headers($http_response);
  return undef unless %raw;
  my $req_reset = $raw{'anthropic-ratelimit-requests-reset'};
  my $tok_reset = $raw{'anthropic-ratelimit-tokens-reset'};
  # Anthropic reset headers are RFC 3339 instants — a "when", so they populate
  # *_reset_at via the lenient inbound door (ADR 0017); the matching
  # *_reset_after is derived lazily against `received`. from_wire returns undef
  # for anything it cannot read, and then neither half is set (raw keeps it).
  my $req_at = defined $req_reset ? Langertha::Moment->from_wire($req_reset) : undef;
  my $tok_at = defined $tok_reset ? Langertha::Moment->from_wire($tok_reset) : undef;
  return Langertha::RateLimit->new(
    received => Langertha::Moment->now_utc,
    ( defined $raw{'anthropic-ratelimit-requests-limit'}     ? ( requests_limit     => $raw{'anthropic-ratelimit-requests-limit'} + 0 )     : () ),
    ( defined $raw{'anthropic-ratelimit-requests-remaining'} ? ( requests_remaining => $raw{'anthropic-ratelimit-requests-remaining'} + 0 ) : () ),
    ( defined $req_reset                                     ? ( requests_reset     => $req_reset )                                        : () ),
    ( defined $req_at                                        ? ( requests_reset_at  => $req_at )                                           : () ),
    ( defined $raw{'anthropic-ratelimit-tokens-limit'}       ? ( tokens_limit       => $raw{'anthropic-ratelimit-tokens-limit'} + 0 )       : () ),
    ( defined $raw{'anthropic-ratelimit-tokens-remaining'}   ? ( tokens_remaining   => $raw{'anthropic-ratelimit-tokens-remaining'} + 0 )   : () ),
    ( defined $tok_reset                                     ? ( tokens_reset       => $tok_reset )                                        : () ),
    ( defined $tok_at                                        ? ( tokens_reset_at    => $tok_at )                                           : () ),
    raw => \%raw,
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::AnthropicCompatible - Role for Anthropic-compatible API format

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # This role is not used directly - it's composed by engines
    # that implement the Anthropic-compatible /v1/messages API format.

    package My::Engine;
    use Moose;

    extends 'Langertha::Engine::AnthropicBase';

    sub _build_api_key { $ENV{MY_API_KEY} || die "needs api_key" }
    sub default_model { 'my-model' }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This role provides the Anthropic C</v1/messages> wire-envelope methods for
chat, streaming, tool calling, structured-output emulation, model listing,
and rate-limit parsing. Engines that speak the Anthropic-compatible API format
(Anthropic itself, MiniMax's legacy shim, Moonshot Kimi, LM Studio's
Anthropic-compatible endpoint) compose this role via
L<Langertha::Engine::AnthropicBase>, which supplies the C<url> / HTTP / JSON
infrastructure from L<Langertha::Engine::Remote>.

As with L<Langertha::Role::OpenAICompatible>, this role is only
self-contained in isolation: it assumes the composer brings the
L<Langertha::Engine::Remote> infrastructure (C<url>, C<generate_http_request>,
C<parse_response>, C<json>, C<user_agent>, C<chat_model>,
C<get_response_size>, C<has_temperature>, C<reasoning_kwargs_for>,
C<prompt_cache_kwargs_for>, C<tool_wire_format>, C<has_parallel_tool_use> /
C<parallel_tool_use>, C<has_response_format> / C<response_format>) — normally
provided by extending L<Langertha::Engine::Remote> plus the universal roles
composed in L<Langertha::Engine::AnthropicBase>.

The wire envelope mirrors L<Langertha::Role::OpenAICompatible>: this role owns
the Anthropic request/response/stream/auth/rate-limit envelope, and the base
class stays a thin composition shell.

=head2 api_key

Anthropic-compatible API key sent as C<x-api-key>. Subclasses typically
override C<_build_api_key> to read a provider-specific environment variable.

=head2 api_version

The Anthropic API version header sent with every request. Defaults to
C<2023-06-01>.

=head2 effort

Back-compat alias of L<Langertha::Role::ReasoningEffort/reasoning_effort>.
Controls the depth of thinking for reasoning models. When set (and
C<reasoning_effort> is not), it seeds C<reasoning_effort>, which is serialized
via L<Langertha::Reasoning> to C<output_config.effort> plus
C<thinking: { type =E<gt> 'adaptive' }> (the current Messages-API shape) rather
than the legacy top-level C<effort> key.

    my $claude = Langertha::Engine::Anthropic->new(
        api_key => $ENV{ANTHROPIC_API_KEY},
        model   => 'claude-opus-4-8',
        effort  => 'high',   # same as reasoning_effort => 'high'
    );

=head2 inference_geo

Controls data residency for inference on the first-party Claude API. The API
accepts exactly two values: C<global> (the default) and C<us>. There is B<no>
EU inference-geo on the first-party API; a value such as C<eu> is not part of
the enum and is rejected. It is only honoured on Claude 4.6+ models; older
models return a 400 regardless of the value.

    my $claude = Langertha::Engine::Anthropic->new(
        api_key       => $ENV{ANTHROPIC_API_KEY},
        inference_geo => 'us',
    );

The response reports where the request actually ran via
C<usage.inference_geo>, and C<us> residency is billed at 1.1x the base rate.

EU data residency is not available this way. For EU-hosted inference use one of
the EU engines Langertha already ships — L<Langertha::Engine::AKI>,
L<Langertha::Engine::Mistral>, L<Langertha::Engine::Scaleway>,
L<Langertha::Engine::TSystems> or L<Langertha::Engine::Hetzner> — or reach
Claude through the regional endpoints of Amazon Bedrock or Google Vertex AI,
where C<inference_geo> does not apply.

=head2 update_request

    $self->update_request($http_request);

Adds the C<x-api-key>, C<content-type: application/json>, and
C<anthropic-version> headers to outgoing requests.

=head2 chat_request

    my $request = $engine->chat_request($messages, %extra);

Generates an Anthropic-format message request (C<POST /v1/messages>).
Includes model, messages, max_tokens, temperature, reasoning-effort and
prompt-cache controls, and optional C<system>. Returns an HTTP request
object.

=head2 _native_structured_output

Internal predicate. True when the engine's wire supports native structured
output via C<output_config.format> (the first-party Claude Messages API); false
(the default) for the legacy C</anthropic> shim engines, which fall back to the
ADR 0005 synthesized-tool rewrite. L<Langertha::Engine::Anthropic> overrides it
to a true value. It describes the B<endpoint> and so decides the manifest
dialect (C<anthropic> vs C<anthropic-compat>, L<Langertha::Manifest::Builder>);
the request builders ask L</_native_structured_output_for_model> instead.

=head2 _native_structured_output_for_model

Internal predicate the request builders use to pick the structured-output path
for the current C<chat_model>: native C<output_config.format> when true, the
ADR 0005 synthesized-tool rewrite when false. Defaults to
L</_native_structured_output>; L<Langertha::Engine::MoonshotAnthropic>
overrides it to be true on C<kimi-k3> only.

=head2 _translate_response_format

Internal: turns a C<response_format> hash into a synthesized tool plus a
C<tool_choice>, returning the synthetic tool name. Returns C<undef> when no
usable structure is present. Used by the legacy C</anthropic> shim engines and,
for a bare C<json_object>, by first-party L<Langertha::Engine::Anthropic> (which
routes a C<json_schema> natively via C<output_config.format> instead). The
synthesized tool is forced via a named C<tool_choice> where the model supports
forced tool use, and degraded to C<tool_choice> C<auto> where it does not
(C<claude-fable-5-1> / C<claude-mythos-5-1>).

=head2 _normalize_tool_params

Internal: normalizes C<tool_choice> to Anthropic's native format and folds
C<parallel_tool_use> into the C<tool_choice> block as C<disable_parallel_tool_use>.

=head2 chat_response

    my $response = $role->chat_response($http_response, $rf_routed);

Parses an Anthropic-format message response into a L<Langertha::Response>
object. When C<$rf_routed> (a synthetic tool name, or truthy for the
attribute path) and tool calls are present, lifts the first tool_use
arguments back into C<content> as JSON.

A 200 body that is an error envelope (C<{"type":"error","error":{...}}>), or
carries an C<error> object and no content, croaks with
C<< <engine class> response carried an error: MESSAGE >>, as the
OpenAI-compatible parser does.

=head2 _usage_input_includes_cache

Internal hook. Returns whether this endpoint counts the prompt-cache reads and
writes it reports (C<cache_read_input_tokens> / C<cache_creation_input_tokens>)
inside C<usage.input_tokens>. The default returns C<undef>, which keeps the
inference of L<Langertha::Usage/from_hash>: the flat Anthropic keys are counted
beside C<input_tokens>, as first-party Anthropic reports them. An
Anthropic-compatible shim that counts them inside overrides it with
C<sub _usage_input_includes_cache { 1 }>, as L<Langertha::Engine::AKIAnthropic>
does. The answer reaches L<Langertha::Usage/input_includes_cache> on both the
L</chat_response> path and the streamed final chunk, as an
C<input_includes_cache> key in a copy of the usage block.

=head2 stream_format

    my $format = $engine->stream_format;

Returns C<'sse'> (Server-Sent Events), the streaming format used by
Anthropic-compatible APIs.

=head2 chat_stream_request

    my $request = $engine->chat_stream_request($messages, %extra);

Generates an Anthropic-format streaming request (SSE, C<stream =E<gt> true>).
Returns an HTTP request object for use with streaming execution.

=head2 parse_stream_chunk

    my $chunk = $engine->parse_stream_chunk($data, $event, \%state);

Parses a single SSE data payload from an Anthropic-format stream by event
type. A C<content_block_delta> of type C<thinking_delta> surfaces its
C<thinking> text onto the chunk's C<thinking> attribute. Anthropic splits the
terminal metadata across two events — C<message_delta> carries C<finish_reason>
(C<stop_reason>) and C<usage> while C<message_stop> is the C<is_final> event — so
the C<message_delta> metadata is held in C<\%state> and replayed onto the
C<is_final> C<message_stop> chunk, matching the cross-dialect contract where C<finish_reason> and C<usage>
land on the same chunk that is C<is_final>. That C<usage> is complete: the
input side C<message_start> reports (C<input_tokens>,
C<cache_read_input_tokens>, C<cache_creation_input_tokens>) merged with the
C<message_delta> usage, whose keys win; both chunks also carry the C<model>
from C<message_start>. Returns a
L<Langertha::Stream::Chunk>, or C<undef> for event types that carry no content.

A C<tool_use> content block is assembled from its C<content_block_start> and
C<input_json_delta> fragments in C<\%state> (one HashRef per stream, reset on
C<message_start>; the stream paths pass it, a direct caller may omit it and
share the engine's fallback; C<$event> is set only on the
L<Langertha::Role::Streaming/process_stream_data> path) and
lands as a L<Langertha::ToolCall> on the chunk for its C<content_block_stop>,
read by the same L<Langertha::ToolCall/extract> as L</chat_response>. Collect
the calls with L<Langertha::Role::Chat/aggregate_tool_calls>. The
C<content_block_stop> of any other block still returns C<undef>.

=head2 list_models_request

    my $request = $engine->list_models_request;
    my $request = $engine->list_models_request(after_id => $last_id);

Generates an HTTP GET request for the Anthropic C</v1/models> endpoint,
optionally with pagination params. Returns an HTTP request object.

=head2 list_models_response

    my $data = $engine->list_models_response($http_response);

Parses the Anthropic C</v1/models> response. Returns the full response
hashref.

=head2 list_models

    my $model_ids = $engine->list_models;
    my $models    = $engine->list_models(full => 1);
    my $models    = $engine->list_models(force_refresh => 1);

Fetches available models from the Anthropic API using cursor pagination.
Returns an ArrayRef of model ID strings by default, or full model objects
when C<full => 1> is passed. Results are cached for C<models_cache_ttl>
seconds (default: 3600). Pass C<force_refresh => 1> to bypass the cache.

=head2 _parse_rate_limit_headers

Parses C<anthropic-ratelimit-*> headers from the HTTP response into a
L<Langertha::RateLimit> object. Collects the full C<raw> superset via
L<Langertha::RateLimit/_collect_headers> — capturing extras like
C<input-tokens-limit>, C<output-tokens-limit> and the C<anthropic-priority-*>
/ C<anthropic-fast-*> families — then normalizes the RFC 3339 reset instants
into L<Langertha::RateLimit/requests_reset_at> / L<Langertha::RateLimit/tokens_reset_at>;
the C<*_reset_after> durations are derived lazily against
L<Langertha::RateLimit/received>.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::AnthropicBase> - Composes this role as a thin shell

=item * L<Langertha::Role::OpenAICompatible> - The parallel OpenAI wire-envelope role

=item * L<https://status.anthropic.com/> - Anthropic service status

=item * L<https://docs.anthropic.com/> - Official Anthropic documentation

=item * L<Langertha::Role::Chat> - Chat interface methods

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Role::Streaming> - Streaming support (SSE format)

=item * L<Langertha::Engine::Gemini> - Another non-OpenAI-compatible engine

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
