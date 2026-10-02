package Langertha::Engine::Gemini;
# ABSTRACT: Google Gemini API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use Langertha::ToolChoice;
use Langertha::Response;
use Langertha::ToolCall;
use Langertha::CachedContent;

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  Models
  Chat
  Temperature
  ReasoningEffort
  ResponseSize
  SystemPrompt
  ResponseFormat
  Streaming
  Tools
  CachedContent
  ImageInput
  Embedding
);

sub _build_reasoning_wire_format { 'gemini' }

# Gemini splits its reasoning knob by model generation: Gemini 2.5-* takes
# an integer thinking_budget (no level vocabulary), Gemini 3 takes a
# thinkingLevel (minimal|low|medium|high, clamped to the model family's
# subset by Langertha::Reasoning). Exactly one native control is honored per
# model. Reflect that in the capability flags so callers can ask
# supports('thinking_budget') vs supports('reasoning_effort') and get the
# truth for the configured model.
#
# The same around also gates cached_content: explicit cachedContent
# resources are an "on" feature for Gemini 2.5+ and Gemini 3. Older
# generations (1.x, 2.0) don't accept the cachedContents REST endpoints,
# so we drop the flag there.
#
# parallel_tool_use is cleared on every model (karr k241): the v1beta
# ToolConfig is retrievalConfig | functionCallingConfig (mode +
# allowedFunctionNames) | includeServerSideToolInvocations, with no parallel
# knob (discovery doc revision 20260924). The model emits several
# functionCall parts on its own; there is nothing to switch off.
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete $caps->{parallel_tool_use};
  my $model = $self->can('chat_model') ? ( $self->chat_model // '' ) : '';
  if ( $model =~ /\Agemini-2\.5/ ) {
    $caps->{thinking_budget} = 1;
    delete $caps->{reasoning_effort};
    $caps->{cached_content} = 1;
  }
  elsif ( $model =~ /\Agemini-3/ ) {
    # Gemini 3 (and any future unknown Gemini generation) keeps the
    # default reasoning_effort cap; thinking_budget is not advertised.
    delete $caps->{thinking_budget};
    $caps->{cached_content} = 1;
  }
  else {
    delete $caps->{thinking_budget};
    delete $caps->{cached_content};
  }
  return $caps;
};

# image_input (k266, ADR 0019 k266 Update): every Gemini chat model takes
# inline_data image parts (llm-advisor, docs only, 2026-09-25), so the family
# keeps the role-derived flag. Cleared: TTS / Live / native-audio /
# transcription and embedding ids, the lyria/imagen/veo generators (advisor
# table), plus the text-only Gemini 1.0 Pro and aqa. Gemma: Gemma 3 and 4 are
# multimodal and keep the flag; Gemma 1/2 and the text-only gemma-3-1b clear
# it (decision k266: restrict the exclusion to the text-only sizes rather than
# the whole family).
sub model_capability_corrections {
  return (
    qr/(?:-tts|-live|native-audio|transcribe|embedding)/ => { image_input => 0 },
    qr/\A(?:lyria|imagen|veo|aqa)/                        => { image_input => 0 },
    qr/\Agemini-(?:1\.0-)?pro(?:-\d+)?\z/                => { image_input => 0 },
    qr/\Agemma-(?:[12](?!\d)|3-1b)/                      => { image_input => 0 },
  );
}

# Tool-result images (karr k344): functionResponse.parts[].inlineData is
# documented for the Gemini 3 series only (function-calling guide, v1beta;
# docs-derived, not live-verified, 2026-09-29). Other models keep the k336
# placeholder string; a later generation joins when its docs say so. The
# (?!\d) guard keeps a hypothetical gemini-30 out (ADR 0023 k196).
sub _tool_result_images_on_wire {
  my ($self) = @_;
  return ( $self->chat_model // '' ) =~ /\Agemini-3(?!\d)/ ? 1 : 0;
}

# Tool-result PDFs (karr k361): the same guide section lists "Documents:
# application/pdf, text/plain" beside the image types for Gemini 3
# multimodal function responses (ai.google.dev/gemini-api/docs/
# generate-content/function-calling, fetched 2026-09-30; docs-derived, not
# live-verified), so a PDF follows the image predicate. (A text/plain blob is
# already decoded into the result string.)
sub _tool_result_pdf_on_wire { shift->_tool_result_images_on_wire }


sub default_response_size { 2048 }

sub content_format { 'gemini' }

has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_GEMINI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_GEMINI_API_KEY or api_key set";
}


has '+url' => (
  lazy => 1,
  default => sub { 'https://generativelanguage.googleapis.com' },
);

has cached_content => (
  is        => 'rw',
  isa       => 'Maybe[Langertha::CachedContent]',
  predicate => 'has_cached_content',
  clearer   => 'clear_cached_content',
);


sub default_model { 'gemini-3-flash-preview' }

# --- endpoint + auth seam -------------------------------------------------
#
# Every request URL in this engine is assembled here, and the credential is
# placed by gemini_auth_query alone. A second consumer of the Gemini dialect
# (Vertex AI express or standard, a Gemini-native gateway) differs from the
# Developer API exclusively in base URL, API version, model-path prefix and
# auth scheme — never in the request envelope — so such a shim is a subclass
# that overrides here rather than a copy of chat_request (ADR 0016, karr #88).

sub gemini_api_version { 'v1beta' }

sub gemini_auth_query {
  my ( $self ) = @_;
  my $key = $self->api_key;
  return defined $key && length $key ? ( key => $key ) : ();
}

sub gemini_endpoint {
  my ( $self, $path ) = @_;
  return $self->url . '/' . $self->gemini_api_version . '/' . $path;
}

sub gemini_url {
  my ( $self, $path, @query ) = @_;
  my $url = $self->gemini_endpoint($path);
  my @params = ( $self->gemini_auth_query, @query );
  return $url unless @params;
  # Values are interpolated verbatim, exactly as the call sites did before:
  # the API key and the fixed switches (alt=sse) are URL-safe, and encoding
  # them here would change bytes on the wire for no gain.
  my @pairs;
  while ( my ( $name, $value ) = splice @params, 0, 2 ) {
    push @pairs, $name . '=' . $value;
  }
  return $url . '?' . join( '&', @pairs );
}

sub gemini_model_url {
  my ( $self, $model, $method, @query ) = @_;
  return $self->gemini_url( 'models/' . $model . ':' . $method, @query );
}


# The REST contract names the field `cachedContent` and takes the resource
# name as a plain string (https://ai.google.dev/api/generate-content). A
# request naming a cache may not also set systemInstruction, tools or
# toolConfig: the server answers 400 "CachedContent can not be used with
# GenerateContent request setting system_instruction, tools or tool_config.
# Proposed fix: move those values to CachedContent from GenerateContent
# request." They come from the cache, so they are left out here, with one
# carp per engine (k327). Both JSON spellings of each field are dropped.
sub _cached_content_reference {
  my ( $self, $body, $extra ) = @_;
  return unless $self->can('cached_content') && defined $self->cached_content;
  my $cc = $self->cached_content;
  croak "Langertha::Engine::Gemini: cached_content must be a Langertha::CachedContent with a 'name'"
    unless ref($cc) && eval { $cc->isa('Langertha::CachedContent') && $cc->has_name };
  $body->{cachedContent} = $cc->name;
  my @dropped;
  for my $field (
    [ systemInstruction => 'system_instruction' ],
    [ tools             => 'tools' ],
    [ toolConfig        => 'tool_config' ],
  ) {
    my $sent = 0;
    for my $key ( @$field ) {
      $sent = 1 if defined delete $body->{$key};
      $sent = 1 if defined delete $extra->{$key};
    }
    push @dropped, $field->[0] if $sent;
  }
  $self->_langertha_carp( "".( ref $self ).": not sending " . join( ', ', @dropped )
    . " -- cached_content " . $cc->name . " is bound, and a request naming a cache takes"
    . " systemInstruction, tools and toolConfig from the cache", 'cached_content_overrides' )
    if @dropped;
  return;
}

sub chat_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};
  # No parallel knob on this wire (parallel_tool_use is cleared): a value the
  # caller set is only dropped, with the shared carp (karr k241).
  $self->_parallel_tool_calls_kwarg( \%extra, $controls );

  # Translate tool_choice (canonical / OpenAI / Anthropic shapes) into
  # Gemini's toolConfig.functionCallingConfig form.
  if ( exists $extra{tool_choice} && defined $extra{tool_choice} ) {
    my $tc = Langertha::ToolChoice->from_hash( delete $extra{tool_choice} );
    if ($tc) {
      my $cfg = $tc->to( $self->tool_wire_format );
      $extra{toolConfig} = $cfg if $cfg;
    }
  }

  # Convert messages to Gemini format
  my @gemini_contents;
  my $system_instruction;

  for my $message (@{$messages}) {
    if ($message->{role} eq 'system') {
      # Gemini uses systemInstruction field for system messages
      $system_instruction .= "\n\n" if $system_instruction;
      # Array content arrives as parts (Role::Chat, karr k269); keep its text.
      $system_instruction .= $message->{parts}
        ? join( "\n", map { $_->{text} // () } @{ $message->{parts} } )
        : $message->{content};
    } elsif ($message->{parts}) {
      # Already in Gemini format (e.g. from format_tool_results)
      push @gemini_contents, $message;
    } else {
      # Convert role: 'assistant' -> 'model' for Gemini
      my $role = $message->{role} eq 'assistant' ? 'model' : $message->{role};
      push @gemini_contents, {
        role => $role,
        parts => [{ text => $message->{content} }],
      };
    }
  }

  # Build the URL with model and API key. A per-request model names the model
  # in the path, never in the body (karr k357).
  my $model_name = $self->_url_model( \%extra );
  my $url = $self->gemini_model_url( $model_name, 'generateContent' );

  my %request_body = (
    contents => \@gemini_contents,
  );

  # Add system instruction if present
  if ($system_instruction) {
    $request_body{systemInstruction} = {
      parts => [{ text => $system_instruction }],
    };
  }

  # Reference an explicit cachedContent resource by name when one was bound
  # via $engine->cached_content (karr #22, k327).
  $self->_cached_content_reference( \%request_body, \%extra );

  # Add generation config
  my %generation_config;
  if ( exists $controls->{max_tokens} ) {
    $generation_config{maxOutputTokens} = $controls->{max_tokens};
  }
  elsif ($self->get_response_size) {
    $generation_config{maxOutputTokens} = $self->get_response_size;
  }
  if ( exists $controls->{temperature} ) {
    $generation_config{temperature} = $controls->{temperature};
  }
  elsif ($self->has_temperature) {
    $generation_config{temperature} = $self->temperature;
  }

  # Translate response_format -> Gemini's generationConfig.responseJsonSchema /
  # responseMimeType. Accepts the OpenAI-shape response_format hash so that
  # callers can hand the same payload to any engine. A per-request
  # response_format (chat_f) beats the engine attribute, and is removed from
  # the extras either way: generateContent has no top-level response_format
  # field and would carry it as dead weight while the schema went missing.
  # chat_f hands us an OpenAI-shaped json_schema.schema (already JSON Schema),
  # so it goes into responseJsonSchema — the field that accepts JSON Schema
  # directly. The older responseSchema is deprecated and wanted Google's own
  # Schema proto dialect, not raw JSON Schema (ai.google.dev/api/generate-content,
  # verified 2026-09-01 — karr k140). responseMimeType stays required.
  my $rf = exists $controls->{response_format}
    ? delete $controls->{response_format}
    : exists $extra{response_format}
      ? delete $extra{response_format}
      : $self->has_response_format ? $self->response_format : undef;
  if ( defined $rf ) {
    my $type = ref($rf) eq 'HASH' ? ( $rf->{type} // '' ) : '';
    if ( $type eq 'json_object' ) {
      $generation_config{responseMimeType} = 'application/json';
    }
    elsif ( $type eq 'json_schema'
        && ref( $rf->{json_schema} ) eq 'HASH'
        && ref( $rf->{json_schema}{schema} ) eq 'HASH' ) {
      $generation_config{responseMimeType}     = 'application/json';
      $generation_config{responseJsonSchema}   = $rf->{json_schema}{schema};
    }
  }

  # Merge reasoning effort / thinking_budget ->
  # generationConfig.thinkingConfig.thinkingLevel (Gemini 3) or
  # thinkingConfig.thinkingBudget (Gemini 2.5). Langertha::Reasoning owns
  # the per-model placement; a per-request control (chat_f, karr #46) beats
  # the engine attribute on a per-key basis.
  my @reasoning = $self->reasoning_kwargs_for(%$controls);
  %generation_config = ( %generation_config, @reasoning ) if @reasoning;

  $request_body{generationConfig} = \%generation_config if %generation_config;

  return $self->generate_http_request(
    POST => $url,
    sub { $self->chat_response(shift) },
    %request_body,
    %extra,
  );
}

# --- embeddings (k309) -----------------------------------------------------
#
# A string goes to models/{m}:embedContent, an ArrayRef to
# models/{m}:batchEmbedContents with one EmbedContentRequest per input
# (ai.google.dev/api/embeddings, fetched 2026-09-25). taskType / title /
# outputDimensionality belong in embedContentConfig; the top-level spellings
# are deprecated, so the snake_case extras are placed there. Everything else
# in %extra goes into each EmbedContentRequest verbatim (ADR 0004).

sub default_embedding_model { 'gemini-embedding-001' }

my %EMBED_CONFIG_KEY = (
  task_type             => 'taskType',
  output_dimensionality => 'outputDimensionality',
  title                 => 'title',
);

sub embedding_request {
  my ( $self, $input, %extra ) = @_;
  my $model = $self->embedding_model;

  my %config = (
    defined $self->embedding_dimensions ? ( outputDimensionality => $self->embedding_dimensions ) : (),
    %{ delete $extra{embedContentConfig} // {} },
  );
  for my $key ( sort keys %EMBED_CONFIG_KEY ) {
    $config{ $EMBED_CONFIG_KEY{$key} } = delete $extra{$key} if exists $extra{$key};
  }
  my $embed_request = sub {
    my ( $text ) = @_;
    return {
      model   => 'models/' . $model,
      content => { parts => [ { text => $text } ] },
      %config ? ( embedContentConfig => {%config} ) : (),
      %extra,
    };
  };

  if ( ref $input eq 'ARRAY' ) {
    return $self->generate_http_request(
      POST => $self->gemini_model_url( $model, 'batchEmbedContents' ),
      sub { $self->embedding_response( shift, $input ) },
      requests => [ map { $embed_request->($_) } @{$input} ],
    );
  }
  return $self->generate_http_request(
    POST => $self->gemini_model_url( $model, 'embedContent' ),
    sub { $self->embedding_response( shift, $input ) },
    %{ $embed_request->($input) },
  );
}


sub embedding_response {
  my ( $self, $response, $input ) = @_;
  my $data = $self->parse_response($response);
  my $batch = ref $input eq 'ARRAY';
  my @embeddings = ref $data ne 'HASH' ? ()
    : $batch ? ( ref $data->{embeddings} eq 'ARRAY' ? @{ $data->{embeddings} } : () )
    : ( defined $data->{embedding} ? $data->{embedding} : () );
  my @vectors = map { ref $_ eq 'HASH' ? $_->{values} : undef } @embeddings;
  # No vector is no result: never hand back undef as if it were one (k290).
  if ( !@vectors || grep { ref $_ ne 'ARRAY' || !@{$_} } @vectors ) {
    my $err = ref $data eq 'HASH' && $data->{error}
      ? ( ref $data->{error} eq 'HASH' ? $data->{error}{message} : $data->{error} )
      : undef;
    croak "".(ref $self)." embedding response contained no vector"
      . ( defined $err ? " (error: $err)" : '' );
  }
  return $vectors[0] unless $batch;
  croak "".(ref $self)." embedding response returned ".scalar(@vectors)
    ." vectors for ".scalar(@{$input})." inputs"
    unless @vectors == @{$input};
  return \@vectors;
}


sub update_request {
  my ( $self, $request ) = @_;
  $request->header('content-type', 'application/json');
}

sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);

  # Gemini response format: candidates[0].content.parts[].text
  my $candidates = $data->{candidates} || [];
  my $text = '';
  my $finish_reason;
  my $thinking;
  if (@$candidates) {
    my $candidate = $candidates->[0];
    my $content = $candidate->{content} || {};
    my $parts = $content->{parts} || [];
    my @text_parts;
    my @thought_parts;
    for my $part (@$parts) {
      next unless exists $part->{text};
      if ($part->{thought}) {
        push @thought_parts, $part->{text};
      } else {
        push @text_parts, $part->{text};
      }
    }
    $text = join('', @text_parts);
    $thinking = join("\n", @thought_parts) if @thought_parts;
    $finish_reason = $candidate->{finishReason};
  }
  else {
    # No candidate: a blocked prompt says why in promptFeedback.blockReason.
    # A block is an answer, so it is reported as finish_reason, verbatim like
    # a candidate's finishReason (SAFETY, PROHIBITED_CONTENT, ...). Anything
    # else without a candidate is no answer and croaks. -- karr k301
    $finish_reason = $self->_gemini_block_reason($data);
    unless ( defined $finish_reason ) {
      my $error = $self->_body_error_text( $data->{error} );
      croak "".(ref $self)." response carried an error: $error" if defined $error;
      croak "".(ref $self)." response contained no candidates";
    }
  }

  # Normalize Gemini usage metadata. cachedContentTokenCount is surfaced
  # when present so callers can monitor cache-hit rate (karr #22, 22e).
  # See https://ai.google.dev/api/generate-content (usageMetadata).
  # Langertha::Usage->from_hash reads both spellings (ADR 0018 tier 1), but the
  # rename stays: Usage's %{} overload serves this hash verbatim, so
  # $response->usage->{prompt_tokens} / {cached_content_token_count} are
  # public back-compat keys (Langertha::CachedContent POD, karr k197).
  # The snake_case keys take OpenAI's meaning: thoughtsTokenCount (billed as
  # output, not part of candidatesTokenCount) is counted in completion_tokens
  # and shown under completion_tokens_details.reasoning_tokens; the tool-use
  # prompt (toolUsePromptTokenCount) in prompt_tokens (k299).
  my $usage;
  if (my $um = $data->{usageMetadata}) {
    my $thoughts = $um->{thoughtsTokenCount};
    my ( $prompt, $tool_prompt, $candidates ) =
      @{$um}{qw( promptTokenCount toolUsePromptTokenCount candidatesTokenCount )};
    $usage = {
      prompt_tokens     => defined $tool_prompt ? ( $prompt // 0 ) + $tool_prompt : $prompt,
      completion_tokens => defined $thoughts    ? ( $candidates // 0 ) + $thoughts : $candidates,
      total_tokens      => $um->{totalTokenCount},
    };
    $usage->{completion_tokens_details} = { reasoning_tokens => $thoughts } if defined $thoughts;
    if ( defined $um->{cachedContentTokenCount} ) {
      $usage->{cached_content_token_count} = $um->{cachedContentTokenCount};
    }
  }

  my @tcs = Langertha::ToolCall->extract( $self->tool_wire_format, $data );
  return Langertha::Response->new(
    content       => $text,
    raw           => $data,
    $data->{responseId} ? ( id => $data->{responseId} ) : (),
    $data->{modelVersion} ? ( model => $data->{modelVersion} ) : (),
    defined $finish_reason ? ( finish_reason => $finish_reason ) : (),
    $usage ? ( usage => $usage ) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
    @tcs ? ( tool_calls => [ @tcs ] ) : (),
  );
}

# promptFeedback.blockReason of a candidate-less answer (a blocked prompt),
# undef when there is none. -- karr k301, k311
sub _gemini_block_reason {
  my ( $self, $data ) = @_;
  my $feedback = ref $data->{promptFeedback} eq 'HASH' ? $data->{promptFeedback} : {};
  my $reason = $feedback->{blockReason};
  return defined $reason && !ref $reason && length $reason ? $reason : undef;
}

# The tool loops croak on a blocked prompt (Role::Tools, karr k339): the
# candidate-less answer chat_response reports as finish_reason.
sub _tool_loop_block_reason {
  my ( $self, $response ) = @_;
  my $data = $response->raw;
  return undef unless ref $data eq 'HASH';
  return undef if ref $data->{candidates} eq 'ARRAY' && @{ $data->{candidates} };
  return $self->_gemini_block_reason($data);
}


sub stream_format { 'sse' }

sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};
  # No parallel knob on this wire (parallel_tool_use is cleared): a value the
  # caller set is only dropped, with the shared carp (karr k241).
  $self->_parallel_tool_calls_kwarg( \%extra, $controls );

  # Same tool_choice translation as chat_request.
  if ( exists $extra{tool_choice} && defined $extra{tool_choice} ) {
    my $tc = Langertha::ToolChoice->from_hash( delete $extra{tool_choice} );
    if ($tc) {
      my $cfg = $tc->to( $self->tool_wire_format );
      $extra{toolConfig} = $cfg if $cfg;
    }
  }

  # Convert messages to Gemini format (same as non-streaming)
  my @gemini_contents;
  my $system_instruction;

  for my $message (@{$messages}) {
    if ($message->{role} eq 'system') {
      $system_instruction .= "\n\n" if $system_instruction;
      # Array content arrives as parts (Role::Chat, karr k269); keep its text.
      $system_instruction .= $message->{parts}
        ? join( "\n", map { $_->{text} // () } @{ $message->{parts} } )
        : $message->{content};
    } elsif ($message->{parts}) {
      # Already in Gemini format (e.g. from format_tool_results)
      push @gemini_contents, $message;
    } else {
      my $role = $message->{role} eq 'assistant' ? 'model' : $message->{role};
      push @gemini_contents, {
        role => $role,
        parts => [{ text => $message->{content} }],
      };
    }
  }

  # Build the URL for streaming endpoint (a per-request model as in chat_request)
  my $model_name = $self->_url_model( \%extra );
  my $url = $self->gemini_model_url( $model_name, 'streamGenerateContent', alt => 'sse' );

  my %request_body = (
    contents => \@gemini_contents,
  );

  if ($system_instruction) {
    $request_body{systemInstruction} = {
      parts => [{ text => $system_instruction }],
    };
  }

  # Reference an explicit cachedContent resource by name when one was bound
  # via $engine->cached_content (karr #22, k327). Same wire as chat_request.
  $self->_cached_content_reference( \%request_body, \%extra );

  my %generation_config;
  if ( exists $controls->{max_tokens} ) {
    $generation_config{maxOutputTokens} = $controls->{max_tokens};
  }
  elsif ($self->get_response_size) {
    $generation_config{maxOutputTokens} = $self->get_response_size;
  }
  if ( exists $controls->{temperature} ) {
    $generation_config{temperature} = $controls->{temperature};
  }
  elsif ($self->has_temperature) {
    $generation_config{temperature} = $self->temperature;
  }

  # Translate response_format -> Gemini's generationConfig.responseJsonSchema /
  # responseMimeType. Same wire as chat_request: a per-request
  # response_format (chat_stream_realtime_f) beats the engine attribute,
  # and is removed from the extras either way — generateContent has no
  # top-level response_format field and would carry it as dead weight
  # while the schema went missing. responseJsonSchema is the current field that
  # accepts raw JSON Schema; the deprecated responseSchema wanted Google's Schema
  # proto dialect instead (see chat_request — karr k140).
  my $rf = exists $controls->{response_format}
    ? delete $controls->{response_format}
    : exists $extra{response_format}
      ? delete $extra{response_format}
      : $self->has_response_format ? $self->response_format : undef;
  if ( defined $rf ) {
    my $type = ref($rf) eq 'HASH' ? ( $rf->{type} // '' ) : '';
    if ( $type eq 'json_object' ) {
      $generation_config{responseMimeType} = 'application/json';
    }
    elsif ( $type eq 'json_schema'
        && ref( $rf->{json_schema} ) eq 'HASH'
        && ref( $rf->{json_schema}{schema} ) eq 'HASH' ) {
      $generation_config{responseMimeType}     = 'application/json';
      $generation_config{responseJsonSchema}   = $rf->{json_schema}{schema};
    }
  }

  my @reasoning = $self->reasoning_kwargs_for(%$controls);
  %generation_config = ( %generation_config, @reasoning ) if @reasoning;

  $request_body{generationConfig} = \%generation_config if %generation_config;

  return $self->generate_http_request(
    POST => $url,
    sub {},
    %request_body,
    %extra,
  );
}

sub parse_stream_chunk {
  my ( $self, $data, $event ) = @_;

  require Langertha::Stream::Chunk;

  # An error inside an open stream arrives as a chunk with a top-level `error`
  # object. Skipping it ended the stream as a short, silent success; the croak
  # fails the stream, as the OpenAI-compatible parser does. -- karr k317
  if ( ref $data eq 'HASH' && defined $data->{error} ) {
    croak "".(ref $self)." stream carried an error: ".$self->_body_error_text( $data->{error} );
  }

  # Gemini streaming format is similar to non-streaming
  my $candidates = $data->{candidates} || [];
  unless (@$candidates) {
    # A blocked prompt streams a chunk with promptFeedback.blockReason and no
    # candidate. Skipping it ended the stream without a finish_reason; it is
    # the final chunk, reported like chat_response does (k301). -- karr k311
    my $block_reason = $self->_gemini_block_reason($data);
    return undef unless defined $block_reason;
    return Langertha::Stream::Chunk->new(
      content       => '',
      raw           => $data,
      is_final      => 1,
      finish_reason => $block_reason,
      $data->{usageMetadata} ? ( usage => $data->{usageMetadata} ) : (),
    );
  }

  my $candidate = $candidates->[0];
  my $content = $candidate->{content} || {};
  my $parts = $content->{parts} || [];

  # Same shape as chat_response: walk every part, not just parts[0]. A chunk can
  # carry a thought part ahead of (or interleaved with) the answer part; reading
  # only parts[0] leaked a thought summary into content and dropped the real
  # answer that followed it. A part is a thought summary when `thought` is true;
  # such parts feed the chunk's thinking, the rest feed content. -- karr k129
  my @text_parts;
  my @thought_parts;
  for my $part (@$parts) {
    next unless exists $part->{text};
    if ($part->{thought}) {
      push @thought_parts, $part->{text};
    } else {
      push @text_parts, $part->{text};
    }
  }
  my $text = join('', @text_parts);
  my $thinking = @thought_parts ? join('', @thought_parts) : undef;

  my $finish_reason = $candidate->{finishReason};
  my $is_final = defined $finish_reason && $finish_reason ne '';

  # A streamed functionCall part arrives whole in one chunk (it is not
  # fragmented), so the chunk that carries it is where the call completes. Read
  # it with the same ToolCall->extract chat_response uses. -- karr k221
  my @tool_calls = Langertha::ToolCall->extract( $self->tool_wire_format, $data );

  return Langertha::Stream::Chunk->new(
    content => $text,
    raw => $data,
    is_final => $is_final,
    $finish_reason ? (finish_reason => $finish_reason) : (),
    $data->{usageMetadata} ? (usage => $data->{usageMetadata}) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
    @tool_calls ? ( tool_calls => \@tool_calls ) : (),
  );
}

# Dynamic model listing with token pagination
sub list_models_request {
  my ($self, %params) = @_;
  my $url = $self->gemini_url('models');

  # Add pagination params if provided
  if (%params) {
    require URI;
    my $uri = URI->new($url);
    my %query = $uri->query_form;
    $uri->query_form(%query, %params);
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
  my $page_token;

  do {
    my $request = $self->list_models_request(
      $page_token ? (pageToken => $page_token) : ()
    );
    my $response = $self->user_agent->request($request);
    my $data = $request->response_call->($response);

    push @all_models, @{$data->{models} || []};
    $page_token = $data->{nextPageToken};
  } while ($page_token);

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
  # Gemini uses 'name' field like "models/gemini-2.0-flash"
  my @model_ids = map {
    my $name = $_->{name};
    $name =~ s{^models/}{};  # Strip "models/" prefix
    $name;
  } @$models;

  $self->_models_cache({
    timestamp => time,
    models => $models,
    model_ids => \@model_ids,
  });

  return $opts{full} ? $models : \@model_ids;
}


# Tool calling support (MCP) is the tag-driven default in Langertha::Role::Tools.
sub _build_tool_wire_format { 'gemini' }

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Gemini - Google Gemini API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::Gemini;

    my $gemini = Langertha::Engine::Gemini->new(
        api_key      => $ENV{GEMINI_API_KEY},
        model        => 'gemini-3-flash-preview',
        response_size => 4096,
        temperature  => 0.7,
    );

    # Simple chat
    my $response = $gemini->simple_chat('Explain quantum computing in simple terms');
    print $response;

    # Streaming
    $gemini->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Write a poem about Perl');

    # Async with Future::AsyncAwait
    use Future::AsyncAwait;

    async sub ask_gemini {
        my $response = await $gemini->simple_chat_f(
            'What are the benefits of functional programming?'
        );
        say $response;
    }

    # Embeddings (gemini-embedding-001 unless embedding_model is set)
    my $vector  = $gemini->simple_embedding('Some text to embed');
    my $vectors = $gemini->simple_embedding([ 'first', 'second' ]);

=head1 DESCRIPTION

Provides access to Google's Gemini models via the Generative Language API.
Gemini models support multimodal input (text, code, images) and long context
windows.

Available models include the current stable Flash line C<gemini-3.8-flash>
and C<gemini-3.7-flash> (C<thinkingLevel> low|medium|high, no C<minimal>),
the C<gemini-3-flash-preview> default (fast with thinking, and still accepts
C<thinkingLevel=minimal>), C<gemini-3.1-pro-preview> (most capable),
C<gemini-3.1-flash-lite> (cost-efficient workhorse), and the image-generation
models C<gemini-3.1-flash-image-preview> and C<gemini-3-pro-image-preview>.
The C<gemini-2.5-*> generation is still served but now classed as
previous-generation. The default API endpoint is
C<https://generativelanguage.googleapis.com>.

Embeddings (L<Langertha::Role::Embedding>) use C<gemini-embedding-001> by
default; C<gemini-embedding-2> embeds into a different, incompatible vector
space, so do not mix vectors of the two. See L</embedding_request> for
C<task_type> and C<output_dimensionality>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

The Google Generative Language API key. If not provided, reads from
C<LANGERTHA_GEMINI_API_KEY> environment variable. Get your key at
L<https://aistudio.google.com/app/apikey>. Required for the Developer API.

Pass C<< api_key =E<gt> undef >> explicitly to send no key at all (a keyless
proxy or gateway in front of Gemini): the environment variable is then not
read, no C<key> query parameter is added to any URL, and nothing warns. Leaving
C<api_key> out keeps the default: environment variable, croak when unset.

=head2 cached_content

Optional L<Langertha::CachedContent> resource bound to this engine. When
set, every chat request (C<chat>, C<chat_stream>, C<simple_chat_f>, …)
injects C<cachedContent =E<gt> '{name}'> into the generateContent body
so the model serves the request against the cached context.

A request that names a cache takes its system instruction, tools and tool
configuration from the cache: Gemini rejects a C<generateContent> request that
sets C<systemInstruction>, C<tools> or C<toolConfig> next to C<cachedContent>
(HTTP 400). While a cache is bound those three are therefore not sent, even
when the engine's C<system_prompt>, a system message, C<tools> or
C<tool_choice> would set them, and the engine carps once. Put them into the
cache when creating it (L<Langertha::CachedContent/system_instruction>,
L<Langertha::CachedContent/tools>).

Lifecycle (create / get / list / update / delete) is on the role —
L<Langertha::Role::CachedContent/create_cached_content_f> and friends.
Bind a freshly created resource with C<< $engine->cached_content($cc) >>.

Source URL: L<https://ai.google.dev/api/generate-content> (the
C<cachedContent> field on a generateContent body).

=head2 gemini_api_version

The API version segment of every endpoint, C<v1beta> for the Generative
Language API. Override in a subclass serving a different version. Tool
declarations are sent as C<parametersJsonSchema>, which C<v1> does not have.

=head2 gemini_auth_query

The auth seam: returns the credential as a C<< ( name =E<gt> value ) >> query
pair list, C<< ( key =E<gt> $self->api_key ) >> for the Developer API, or the
empty list when C<api_key> is C<undef> or empty. A
consumer that authenticates by header instead returns the empty list here and
sets the header in C<update_request>.

=head2 gemini_endpoint

Composes the credential-free endpoint C<< {url}/{gemini_api_version}/{path} >>.
This is the path half of the seam: a consumer whose resources live under an
extra prefix (Vertex AI's C<< projects/{p}/locations/{l}/ >>) overrides this
one method and every request URL follows. Callers that are about to issue a
request want L</gemini_url> instead — this one carries no credential.

=head2 gemini_url

Builds L</gemini_endpoint> and appends the query string:
first the pairs from L</gemini_auth_query>, then any C<< ( name =E<gt> value ) >>
pairs passed by the caller (e.g. C<< alt =E<gt> 'sse' >>).

=head2 gemini_model_url

Builds the endpoint of one model method, C<< models/{model}:{method} >>, via
L</gemini_url>. The C<models/> prefix lives here so a consumer with a
different resource path (Vertex AI's C<publishers/google/models/>) overrides
one method.

The chat routes pass C<chat_model> as C<{model}>, or a per-request C<model>
(from L<Langertha::Role::Chat/chat_f> or L<Langertha::Chat/model>) for that
request; the override is not sent in the body.

=head2 embedding_request

    my $request = $engine->embedding_request($text, %extra);
    my $request = $engine->embedding_request(\@texts,
        task_type => 'RETRIEVAL_DOCUMENT', output_dimensionality => 768);

Builds an embedding request with C<embedding_model> (default
C<gemini-embedding-001>). A string goes to C<models/{model}:embedContent>, an
ArrayRef of strings to C<models/{model}:batchEmbedContents> as one request per
input. The optional C<task_type>, C<title> and C<output_dimensionality> are
placed in C<embedContentConfig> (as C<taskType>, C<title>,
C<outputDimensionality>), merged with an C<embedContentConfig> you pass
yourself; any other key goes into each request unchanged. In a batch every
input gets the same settings. L<Langertha::Role::Embedding/embedding_dimensions>,
when set, is sent as C<outputDimensionality> unless the call passes one.

=head2 embedding_response

    my $vector  = $engine->embedding_response($http_response);
    my $vectors = $engine->embedding_response($http_response, \@texts);

Parses an embedding answer; the parser built by L</embedding_request> passes
the input itself. For a string it returns C<embedding.values>, for an ArrayRef
input C<embeddings[].values>, one vector per input in input order. A count
that does not match the number of inputs croaks, and so does a body without a
vector, naming the engine and any C<error> it carries; it never returns
C<undef>.

=head2 chat_response

    my $response = $engine->chat_response($http_response);

Parses a C<generateContent> answer into a L<Langertha::Response> from the
first candidate; C<finish_reason> is its C<finishReason> as Gemini spells it.
A blocked prompt (no candidate, C<promptFeedback.blockReason>) is an answer
with C<content> C<''> and the C<blockReason> as C<finish_reason> (e.g.
C<SAFETY>). A body with neither croaks, naming the engine and any C<error> it
carries. On a stream, the blocked prompt's chunk is the final chunk, with
C<content> C<''> and the C<blockReason> as C<finish_reason>. A stream chunk
with a top-level C<error> object croaks
C<"E<lt>engineE<gt> stream carried an error: E<lt>messageE<gt> (E<lt>codeE<gt>)">,
which fails the stream.

=head2 list_models

    my $model_ids = $engine->list_models;
    my $models    = $engine->list_models(full => 1);
    my $models    = $engine->list_models(force_refresh => 1);

Fetches available models from the Gemini API using token pagination. Returns
an ArrayRef of model ID strings (with the C<models/> prefix stripped) by
default, or full model objects when C<full => 1> is passed. Results are cached
for C<models_cache_ttl> seconds (default: 3600).

=head1 SEE ALSO

=over

=item * L<https://aistudio.google.com/status> - Google AI Studio service status

=item * L<https://ai.google.dev/gemini-api/docs> - Official Gemini API documentation

=item * L<https://aistudio.google.com/> - Google AI Studio for testing

=item * L<Langertha::Role::Chat> - Chat interface methods

=item * L<Langertha::Role::Tools> - MCP tool calling interface

=item * L<Langertha::Role::Streaming> - Streaming support (SSE format)

=item * L<Langertha::Role::Embedding> - Embedding interface (C<simple_embedding>, C<simple_embedding_f>)

=item * L<https://ai.google.dev/api/embeddings> - embedContent / batchEmbedContents reference

=item * L<Langertha::Engine::Anthropic> - Another non-OpenAI-compatible engine

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
