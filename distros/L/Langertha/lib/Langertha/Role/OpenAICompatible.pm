package Langertha::Role::OpenAICompatible;
# ABSTRACT: Role for OpenAI-compatible API format
our $VERSION = '0.304';
use Moose::Role;
use File::ShareDir::ProjectDistDir qw( :all );
use Carp qw( croak );
use JSON::MaybeXS;


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


sub _build_openapi_operations {
  require Langertha::Spec::OpenAI;
  return Langertha::Spec::OpenAI::data();
}


sub default_embedding_model { 'text-embedding-3-large' }
sub default_transcription_model { 'whisper-1' }
sub default_image_model { 'gpt-image-1' }

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

sub embedding_request {
  my ( $self, $input, %extra ) = @_;
  return $self->generate_request( $self->embedding_operation_id, sub { $self->embedding_response(shift) },
    defined $self->embedding_model ? ( model => $self->embedding_model ) : (),
    input => $input,
    %extra,
  );
}


sub embedding_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  # tracing
  my @objects = @{$data->{data}};
  return $objects[0]->{embedding};
}


# Chat

sub chat_operation_id { 'createChatCompletion' }

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
  return $self->generate_request( $self->chat_operation_id, sub { $self->chat_response(shift) },
    defined $self->chat_model ? ( model => $self->chat_model ) : (),
    messages => $messages,
    $self->get_response_size ? ( max_tokens => $self->get_response_size ) : (),
    ($self->can('has_response_format') && $self->has_response_format) ? ( response_format => $self->response_format ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    stream => JSON->false,
    %extra,
  );
}


sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  my $choice = $data->{choices}[0];
  my $msg = $choice->{message} || {};
  require Langertha::Response;
  return Langertha::Response->new(
    content       => $msg->{content} // '',
    raw           => $data,
    $data->{id} ? ( id => $data->{id} ) : (),
    $data->{model} ? ( model => $data->{model} ) : (),
    defined $choice->{finish_reason} ? ( finish_reason => $choice->{finish_reason} ) : (),
    $data->{usage} ? ( usage => $data->{usage} ) : (),
    $data->{created} ? ( created => $data->{created} ) : (),
    defined $msg->{reasoning_content} ? ( thinking => $msg->{reasoning_content} ) : (),
  );
}


# Transcription

sub transcription_operation_id { 'createTranscription' }

sub transcription_request {
  my ( $self, $file, %extra ) = @_;
  return $self->generate_request( $self->transcription_operation_id, sub { $self->transcription_response(shift) },
    file => [ $file ],
    $self->transcription_model ? ( model => $self->transcription_model ) : (),
    %extra,
  );
}


sub transcription_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  return $data->{text};
}


# Streaming

sub stream_format { 'sse' }


sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;
  return $self->generate_request( $self->chat_operation_id, sub {},
    defined $self->chat_model ? ( model => $self->chat_model ) : (),
    messages => $messages,
    $self->get_response_size ? ( max_tokens => $self->get_response_size ) : (),
    ($self->can('has_response_format') && $self->has_response_format) ? ( response_format => $self->response_format ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    stream => JSON->true,
    %extra,
  );
}


sub parse_stream_chunk {
  my ( $self, $data, $event ) = @_;

  return undef unless $data && $data->{choices};

  my $choice = $data->{choices}[0];
  return undef unless $choice;

  my $content = $choice->{delta}{content} // '';
  my $finish_reason = $choice->{finish_reason};

  require Langertha::Stream::Chunk;
  return Langertha::Stream::Chunk->new(
    content => $content,
    raw => $data,
    is_final => defined $finish_reason,
    defined $finish_reason ? (finish_reason => $finish_reason) : (),
    $data->{model} ? (model => $data->{model}) : (),
    $data->{usage} ? (usage => $data->{usage}) : (),
  );
}


# Tool calling support (MCP)

sub format_tools {
  my ( $self, $mcp_tools ) = @_;
  return [map {
    {
      type     => 'function',
      function => {
        name        => $_->{name},
        description => $_->{description},
        parameters  => $_->{inputSchema},
      },
    }
  } @$mcp_tools];
}


sub response_tool_calls {
  my ( $self, $data ) = @_;
  my $choice = $data->{choices}[0] or return [];
  my $msg = $choice->{message} or return [];
  return $msg->{tool_calls} // [];
}


sub extract_tool_call {
  my ( $self, $tc ) = @_;
  my $args = $tc->{function}{arguments};
  $args = $self->json->decode($args) if $args && !ref $args;
  return ( $tc->{function}{name}, $args );
}


sub response_text_content {
  my ( $self, $data ) = @_;
  my $choice = $data->{choices}[0] or return '';
  return $choice->{message}{content} // '';
}


sub format_tool_results {
  my ( $self, $data, $results ) = @_;
  my $choice = $data->{choices}[0];
  return (
    { role => 'assistant', content => $choice->{message}{content},
      tool_calls => $choice->{message}{tool_calls} },
    map {
      my $r = $_;
      {
        role         => 'tool',
        tool_call_id => $r->{tool_call}{id},
        content      => $self->json->encode($r->{result}{content}),
      }
    } @$results
  );
}


# Image generation

sub image_operation_id { 'createImage' }

sub image_request {
  my ( $self, $prompt, %extra ) = @_;
  return $self->generate_request( $self->image_operation_id, sub { $self->image_response(shift) },
    model  => $self->image_model,
    prompt => $prompt,
    %extra,
  );
}


sub image_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
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
  my %raw;
  for my $name (qw(
    x-ratelimit-limit-requests
    x-ratelimit-remaining-requests
    x-ratelimit-reset-requests
    x-ratelimit-limit-tokens
    x-ratelimit-remaining-tokens
    x-ratelimit-reset-tokens
  )) {
    my $val = $http_response->header($name);
    $raw{$name} = $val if defined $val;
  }
  return undef unless %raw;
  require Langertha::RateLimit;
  return Langertha::RateLimit->new(
    ( defined $raw{'x-ratelimit-limit-requests'}     ? ( requests_limit     => $raw{'x-ratelimit-limit-requests'} + 0 )     : () ),
    ( defined $raw{'x-ratelimit-remaining-requests'} ? ( requests_remaining => $raw{'x-ratelimit-remaining-requests'} + 0 ) : () ),
    ( defined $raw{'x-ratelimit-reset-requests'}     ? ( requests_reset     => $raw{'x-ratelimit-reset-requests'} )         : () ),
    ( defined $raw{'x-ratelimit-limit-tokens'}       ? ( tokens_limit       => $raw{'x-ratelimit-limit-tokens'} + 0 )       : () ),
    ( defined $raw{'x-ratelimit-remaining-tokens'}   ? ( tokens_remaining   => $raw{'x-ratelimit-remaining-tokens'} + 0 )   : () ),
    ( defined $raw{'x-ratelimit-reset-tokens'}       ? ( tokens_reset       => $raw{'x-ratelimit-reset-tokens'} )           : () ),
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

version 0.304

=head1 SYNOPSIS

    # This role is not used directly - it's composed by engines
    # that implement the OpenAI-compatible API format.

    package My::Engine;
    use Moose;

    with 'Langertha::Role::'.$_ for (qw(
        JSON HTTP OpenAICompatible OpenAPI Models Temperature
        ResponseSize SystemPrompt Streaming Chat
    ));
    with 'Langertha::Role::Tools';

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

B<Engines using this role:> L<Langertha::Engine::OpenAI>, L<Langertha::Engine::DeepSeek>,
L<Langertha::Engine::Groq>, L<Langertha::Engine::Mistral>, L<Langertha::Engine::vLLM>,
L<Langertha::Engine::NousResearch>, L<Langertha::Engine::Perplexity>,
L<Langertha::Engine::HuggingFace>, L<Langertha::Engine::OllamaOpenAI>,
L<Langertha::Engine::AKIOpenAI>.

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

Generates an OpenAI-format embedding request for the given C<$input>
string. Uses C<embedding_model> (default: C<text-embedding-3-large>).
Returns an HTTP request object.

=head2 embedding_response

    my $vector = $engine->embedding_response($http_response);

Parses an OpenAI-format embedding response. Returns an ArrayRef of
floats representing the embedding vector.

=head2 chat_request

    my $request = $engine->chat_request($messages, %extra);

Generates an OpenAI-format chat completion request. Includes model,
messages, max_tokens, temperature, response_format (if set), and
C<stream =E<gt> false>. Returns an HTTP request object.

=head2 chat_response

    my $response = $engine->chat_response($http_response);

Parses an OpenAI-format chat completion response. Returns a
L<Langertha::Response> object with C<content>, C<model>, C<finish_reason>,
C<usage>, C<created>, and C<raw>.

=head2 transcription_request

    my $request = $engine->transcription_request($file_path, %extra);

Generates an OpenAI-format transcription request for the given audio file.
Uses C<transcription_model> (default: C<whisper-1>). Returns an HTTP
request object.

=head2 transcription_response

    my $text = $engine->transcription_response($http_response);

Parses an OpenAI-format transcription response. Returns the transcribed
text as a string.

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

    my $chunk = $engine->parse_stream_chunk($data, $event);

Parses a single SSE data payload from an OpenAI-format stream. Returns
a L<Langertha::Stream::Chunk> with C<content>, C<is_final>, C<finish_reason>,
C<model>, and C<usage>, or C<undef> if the chunk has no content.

=head2 format_tools

    my $tools = $engine->format_tools($mcp_tools);

Converts an ArrayRef of MCP tool definitions to OpenAI function calling
format. Each tool becomes C<{ type =E<gt> 'function', function =E<gt> { name, description, parameters } }>.

=head2 response_tool_calls

    my $tool_calls = $engine->response_tool_calls($raw_data);

Extracts the tool call objects from a raw OpenAI-format response hashref.
Returns an ArrayRef of tool call objects (may be empty).

=head2 extract_tool_call

    my ($name, $args) = $engine->extract_tool_call($tool_call);

Extracts the function name and decoded argument hashref from a single
OpenAI tool call object. JSON-decodes the arguments string if needed.

=head2 response_text_content

    my $text = $engine->response_text_content($raw_data);

Extracts the assistant message text content from a raw OpenAI-format
response hashref. Returns an empty string if no content.

=head2 format_tool_results

    my @messages = $engine->format_tool_results($raw_data, $results);

Converts tool execution results into OpenAI-format messages to append
to the conversation. Returns a list: first the assistant message (with
tool calls), then one C<role =E<gt> 'tool'> message per result.

=head2 image_request

    my $request = $engine->image_request($prompt, %extra);

Generates an OpenAI-format image generation request for the given
C<$prompt>. Uses C<image_model> (default: C<gpt-image-1>). Accepts
optional C<size>, C<quality>, C<n>, C<response_format> via C<%extra>.
Returns an HTTP request object.

=head2 image_response

    my $images = $engine->image_response($http_response);

Parses an OpenAI-format image generation response. Returns an ArrayRef
of image objects, each with C<url> or C<b64_json> and optionally
C<revised_prompt>.

=head2 simple_image

    my $images = $engine->simple_image('A cat in space');

Sends an image generation request and returns the result. Blocks until
the request completes. Returns an ArrayRef of image objects.

=head2 _parse_rate_limit_headers

Parses C<x-ratelimit-*> headers from the HTTP response into a
L<Langertha::RateLimit> object. Covers OpenAI, Groq, Cerebras, OpenRouter,
Replicate, and all other OpenAI-compatible engines.

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
