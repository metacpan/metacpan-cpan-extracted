package Langertha::Engine::Gemini;
# ABSTRACT: Google Gemini API
our $VERSION = '0.309';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  Models
  Chat
  Temperature
  ResponseSize
  SystemPrompt
  Streaming
  Tools
);


sub default_response_size { 2048 }

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

sub default_model { 'gemini-2.5-flash' }

sub chat_request {
  my ( $self, $messages, %extra ) = @_;

  # Convert messages to Gemini format
  my @gemini_contents;
  my $system_instruction;

  for my $message (@{$messages}) {
    if ($message->{role} eq 'system') {
      # Gemini uses systemInstruction field for system messages
      $system_instruction .= "\n\n" if $system_instruction;
      $system_instruction .= $message->{content};
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

  # Build the URL with model and API key
  my $model_name = $self->chat_model;
  my $url = $self->url . "/v1beta/models/${model_name}:generateContent?key=" . $self->api_key;

  my %request_body = (
    contents => \@gemini_contents,
  );

  # Add system instruction if present
  if ($system_instruction) {
    $request_body{systemInstruction} = {
      parts => [{ text => $system_instruction }],
    };
  }

  # Add generation config
  my %generation_config;
  if ($self->get_response_size) {
    $generation_config{maxOutputTokens} = $self->get_response_size;
  }
  if ($self->has_temperature) {
    $generation_config{temperature} = $self->temperature;
  }

  $request_body{generationConfig} = \%generation_config if %generation_config;

  return $self->generate_http_request(
    POST => $url,
    sub { $self->chat_response(shift) },
    %request_body,
    %extra,
  );
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

  # Normalize Gemini usage metadata
  my $usage;
  if (my $um = $data->{usageMetadata}) {
    $usage = {
      prompt_tokens     => $um->{promptTokenCount},
      completion_tokens => $um->{candidatesTokenCount},
      total_tokens      => $um->{totalTokenCount},
    };
  }

  require Langertha::Response;
  return Langertha::Response->new(
    content       => $text,
    raw           => $data,
    $data->{modelVersion} ? ( model => $data->{modelVersion} ) : (),
    defined $finish_reason ? ( finish_reason => $finish_reason ) : (),
    $usage ? ( usage => $usage ) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
  );
}

sub stream_format { 'sse' }

sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;

  # Convert messages to Gemini format (same as non-streaming)
  my @gemini_contents;
  my $system_instruction;

  for my $message (@{$messages}) {
    if ($message->{role} eq 'system') {
      $system_instruction .= "\n\n" if $system_instruction;
      $system_instruction .= $message->{content};
    } else {
      my $role = $message->{role} eq 'assistant' ? 'model' : $message->{role};
      push @gemini_contents, {
        role => $role,
        parts => [{ text => $message->{content} }],
      };
    }
  }

  # Build the URL for streaming endpoint
  my $model_name = $self->chat_model;
  my $url = $self->url . "/v1beta/models/${model_name}:streamGenerateContent?key=" . $self->api_key . "&alt=sse";

  my %request_body = (
    contents => \@gemini_contents,
  );

  if ($system_instruction) {
    $request_body{systemInstruction} = {
      parts => [{ text => $system_instruction }],
    };
  }

  my %generation_config;
  if ($self->get_response_size) {
    $generation_config{maxOutputTokens} = $self->get_response_size;
  }
  if ($self->has_temperature) {
    $generation_config{temperature} = $self->temperature;
  }

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

  # Gemini streaming format is similar to non-streaming
  my $candidates = $data->{candidates} || [];
  return undef unless @$candidates;

  my $candidate = $candidates->[0];
  my $content = $candidate->{content} || {};
  my $parts = $content->{parts} || [];

  my $text = '';
  $text = $parts->[0]->{text} if @$parts && $parts->[0]->{text};

  my $finish_reason = $candidate->{finishReason};
  my $is_final = defined $finish_reason && $finish_reason ne '';

  return Langertha::Stream::Chunk->new(
    content => $text,
    raw => $data,
    is_final => $is_final,
    $finish_reason ? (finish_reason => $finish_reason) : (),
    $data->{usageMetadata} ? (usage => $data->{usageMetadata}) : (),
  );
}

# Dynamic model listing with token pagination
sub list_models_request {
  my ($self, %params) = @_;
  my $url = $self->url . '/v1beta/models?key=' . $self->api_key;

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


# Tool calling support (MCP)

sub format_tools {
  my ( $self, $mcp_tools ) = @_;
  return [{
    functionDeclarations => [map {
      {
        name        => $_->{name},
        description => $_->{description},
        parameters  => $_->{inputSchema},
      }
    } @$mcp_tools],
  }];
}

sub response_tool_calls {
  my ( $self, $data ) = @_;
  my $candidates = $data->{candidates} || [];
  return [] unless @$candidates;
  my $parts = $candidates->[0]{content}{parts} || [];
  return [grep { exists $_->{functionCall} } @$parts];
}

sub extract_tool_call {
  my ( $self, $tc ) = @_;
  return ( $tc->{functionCall}{name}, $tc->{functionCall}{args} );
}

sub response_text_content {
  my ( $self, $data ) = @_;
  my $candidates = $data->{candidates} || [];
  return '' unless @$candidates;
  my $parts = $candidates->[0]{content}{parts} || [];
  return join('', map { $_->{text} } grep { exists $_->{text} } @$parts);
}

sub format_tool_results {
  my ( $self, $data, $results ) = @_;
  my $candidate = $data->{candidates}[0];
  return (
    { role => 'model', parts => $candidate->{content}{parts} },
    { role => 'user', parts => [
      map {
        my $content = $_->{result}{content};
        # Gemini expects response as a plain object, not an array
        my $text = join('', map { $_->{text} // '' } @$content);
        {
          functionResponse => {
            name     => $_->{tool_call}{functionCall}{name},
            response => { result => $text },
          },
        }
      } @$results
    ]},
  );
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Gemini - Google Gemini API

=head1 VERSION

version 0.309

=head1 SYNOPSIS

    use Langertha::Engine::Gemini;

    my $gemini = Langertha::Engine::Gemini->new(
        api_key      => $ENV{GEMINI_API_KEY},
        model        => 'gemini-2.5-flash',
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

=head1 DESCRIPTION

Provides access to Google's Gemini models via the Generative Language API.
Gemini models support multimodal input (text, code, images) and long context
windows.

Available models include C<gemini-2.5-flash> (fast with thinking, default),
C<gemini-2.5-pro> (most capable), and C<gemini-2.0-flash> (previous
generation). The default API endpoint is
C<https://generativelanguage.googleapis.com>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

The Google Generative Language API key. If not provided, reads from
C<LANGERTHA_GEMINI_API_KEY> environment variable. Get your key at
L<https://aistudio.google.com/app/apikey>. Required.

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

=item * L<Langertha::Engine::Anthropic> - Another non-OpenAI-compatible engine

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
