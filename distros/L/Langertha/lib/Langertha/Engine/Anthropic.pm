package Langertha::Engine::Anthropic;
# ABSTRACT: Anthropic API
our $VERSION = '0.304';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;

extends 'Langertha::Engine::Remote';

with 'Langertha::Role::'.$_ for (qw(
  Models
  Chat
  Temperature
  ResponseSize
  SystemPrompt
  Streaming
));


sub default_response_size { 1024 }

has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_ANTHROPIC_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_ANTHROPIC_API_KEY or api_key set";
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

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.anthropic.com' },
);

sub default_model { 'claude-sonnet-4-6' }

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
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
  return $self->generate_http_request( POST => $self->url.'/v1/messages', sub { $self->chat_response(shift) },
    model => $self->chat_model,
    messages => \@msgs,
    max_tokens => $self->get_response_size, # must be always set
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    $self->has_effort ? ( effort => $self->effort ) : (),
    $self->has_inference_geo ? ( inference_geo => $self->inference_geo ) : (),
    $system ? ( system => $system ) : (),
    %extra,
  );
}

sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  my @blocks = @{$data->{content}};
  my $text = join('', map { $_->{text} // '' } grep { $_->{type} eq 'text' } @blocks);
  my @thinking = map { $_->{thinking} // '' } grep { $_->{type} eq 'thinking' } @blocks;
  my $thinking = @thinking ? join("\n", @thinking) : undef;
  require Langertha::Response;
  return Langertha::Response->new(
    content       => $text,
    raw           => $data,
    $data->{id} ? ( id => $data->{id} ) : (),
    $data->{model} ? ( model => $data->{model} ) : (),
    defined $data->{stop_reason} ? ( finish_reason => $data->{stop_reason} ) : (),
    $data->{usage} ? ( usage => $data->{usage} ) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
  );
}

sub stream_format { 'sse' }

sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;
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
  return $self->generate_http_request( POST => $self->url.'/v1/messages', sub {},
    model => $self->chat_model,
    messages => \@msgs,
    max_tokens => $self->get_response_size,
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    $self->has_effort ? ( effort => $self->effort ) : (),
    $self->has_inference_geo ? ( inference_geo => $self->inference_geo ) : (),
    $system ? ( system => $system ) : (),
    stream => JSON->true,
    %extra,
  );
}

sub parse_stream_chunk {
  my ( $self, $data, $event ) = @_;

  require Langertha::Stream::Chunk;

  # Anthropic uses event types: content_block_delta, message_delta, message_stop
  my $type = $data->{type} // '';

  if ($type eq 'content_block_delta') {
    my $delta = $data->{delta} || {};
    return Langertha::Stream::Chunk->new(
      content => $delta->{text} // '',
      raw => $data,
      is_final => 0,
    );
  }

  if ($type eq 'message_delta') {
    my $delta = $data->{delta} || {};
    return Langertha::Stream::Chunk->new(
      content => '',
      raw => $data,
      is_final => 0,
      $delta->{stop_reason} ? (finish_reason => $delta->{stop_reason}) : (),
      $data->{usage} ? (usage => $data->{usage}) : (),
    );
  }

  if ($type eq 'message_stop') {
    return Langertha::Stream::Chunk->new(
      content => '',
      raw => $data,
      is_final => 1,
    );
  }

  # Other event types (message_start, content_block_start, etc.) - skip
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


# Tool calling support (MCP)

sub format_tools {
  my ( $self, $mcp_tools ) = @_;
  return [map {
    {
      name         => $_->{name},
      description  => $_->{description},
      input_schema => $_->{inputSchema},
    }
  } @$mcp_tools];
}

sub response_tool_calls {
  my ( $self, $data ) = @_;
  return [grep { $_->{type} eq 'tool_use' } @{$data->{content} // []}];
}

sub extract_tool_call {
  my ( $self, $tc ) = @_;
  return ( $tc->{name}, $tc->{input} );
}

sub response_text_content {
  my ( $self, $data ) = @_;
  return join('', map { $_->{text} }
    grep { $_->{type} eq 'text' } @{$data->{content} // []})
}

sub format_tool_results {
  my ( $self, $data, $results ) = @_;
  return (
    { role => 'assistant', content => $data->{content} },
    { role => 'user', content => [
      map {
        my $r = $_;
        {
          type        => 'tool_result',
          tool_use_id => $r->{tool_call}{id},
          content     => $r->{result}{content},
          $r->{result}{isError} ? ( is_error => JSON->true ) : (),
        }
      } @$results
    ]},
  );
}

with 'Langertha::Role::Tools';

sub _parse_rate_limit_headers {
  my ( $self, $http_response ) = @_;
  my %raw;
  for my $name (qw(
    anthropic-ratelimit-requests-limit
    anthropic-ratelimit-requests-remaining
    anthropic-ratelimit-requests-reset
    anthropic-ratelimit-tokens-limit
    anthropic-ratelimit-tokens-remaining
    anthropic-ratelimit-tokens-reset
    anthropic-ratelimit-input-tokens-limit
    anthropic-ratelimit-input-tokens-remaining
    anthropic-ratelimit-input-tokens-reset
    anthropic-ratelimit-output-tokens-limit
    anthropic-ratelimit-output-tokens-remaining
    anthropic-ratelimit-output-tokens-reset
  )) {
    my $val = $http_response->header($name);
    $raw{$name} = $val if defined $val;
  }
  return undef unless %raw;
  require Langertha::RateLimit;
  return Langertha::RateLimit->new(
    ( defined $raw{'anthropic-ratelimit-requests-limit'}     ? ( requests_limit     => $raw{'anthropic-ratelimit-requests-limit'} + 0 )     : () ),
    ( defined $raw{'anthropic-ratelimit-requests-remaining'} ? ( requests_remaining => $raw{'anthropic-ratelimit-requests-remaining'} + 0 ) : () ),
    ( defined $raw{'anthropic-ratelimit-requests-reset'}     ? ( requests_reset     => $raw{'anthropic-ratelimit-requests-reset'} )         : () ),
    ( defined $raw{'anthropic-ratelimit-tokens-limit'}       ? ( tokens_limit       => $raw{'anthropic-ratelimit-tokens-limit'} + 0 )       : () ),
    ( defined $raw{'anthropic-ratelimit-tokens-remaining'}   ? ( tokens_remaining   => $raw{'anthropic-ratelimit-tokens-remaining'} + 0 )   : () ),
    ( defined $raw{'anthropic-ratelimit-tokens-reset'}       ? ( tokens_reset       => $raw{'anthropic-ratelimit-tokens-reset'} )           : () ),
    raw => \%raw,
  );
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Anthropic - Anthropic API

=head1 VERSION

version 0.304

=head1 SYNOPSIS

    use Langertha::Engine::Anthropic;

    my $claude = Langertha::Engine::Anthropic->new(
        api_key      => $ENV{ANTHROPIC_API_KEY},
        model        => 'claude-sonnet-4-6',
        response_size => 4096,
        temperature  => 0.7,
    );

    # Simple chat
    my $response = $claude->simple_chat('Generate Perl Moose classes to represent GeoJSON data types');
    print $response;

    # Streaming
    $claude->simple_chat_stream(sub {
        my ($chunk) = @_;
        print $chunk->content;
    }, 'Tell me about Perl');

    # Async with Future::AsyncAwait
    use Future::AsyncAwait;

    async sub ask_claude {
        my $response = await $claude->simple_chat_f('What is the meaning of life?');
        say $response;
    }

=head1 DESCRIPTION

Provides access to Anthropic's Claude models via their API. Claude is a
family of large language models known for helpfulness, harmlessness, and
honesty.

Available models include C<claude-opus-4-6> (most capable), C<claude-sonnet-4-6>
(balanced, default), and C<claude-haiku-4-5-20251001> (fastest). The default
API endpoint is C<https://api.anthropic.com>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

The Anthropic API key. If not provided, reads from C<LANGERTHA_ANTHROPIC_API_KEY>
environment variable. Get your key at L<https://console.anthropic.com/>. Required.

=head2 api_version

The Anthropic API version header sent with every request. Defaults to
C<2023-06-01>.

=head2 effort

Controls the depth of thinking for reasoning models. Values: C<low>, C<medium>,
C<high>. When set, passed as the C<effort> parameter in the API request.

    my $claude = Langertha::Engine::Anthropic->new(
        api_key => $ENV{ANTHROPIC_API_KEY},
        model   => 'claude-opus-4-6',
        effort  => 'high',
    );

=head2 inference_geo

Controls data residency for inference. Values: C<us>, C<eu>. When set, passed
as the C<inference_geo> parameter to keep processing in the specified region.

    my $claude = Langertha::Engine::Anthropic->new(
        api_key       => $ENV{ANTHROPIC_API_KEY},
        inference_geo => 'eu',
    );

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
L<Langertha::RateLimit> object. The C<raw> hash captures extras like
C<input-tokens-limit> and C<output-tokens-limit>.

=head1 SEE ALSO

=over

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
