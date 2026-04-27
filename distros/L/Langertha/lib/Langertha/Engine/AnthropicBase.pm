package Langertha::Engine::AnthropicBase;
# ABSTRACT: Base class for Anthropic-compatible engines
our $VERSION = '0.500';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use Langertha::ToolChoice;
use Langertha::Tool;
use Langertha::Response;
use Langertha::ToolCall;

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  Models
  Chat
  Temperature
  ResponseSize
  SystemPrompt
  ResponseFormat
  Streaming
  Tools
);


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

sub default_model { croak "".(ref $_[0])." requires model to be set" }

sub chat_request {
  my ( $self, $messages, %extra ) = @_;

  # Anthropic has no native response_format. Translate json_object /
  # json_schema response_format hashes into a synthesized tool + forced
  # named tool_choice; the response parser will pull the structured
  # output out of the resulting tool_use block.
  $self->_translate_response_format(\%extra);

  $self->_normalize_tool_params(\%extra);
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

# Anthropic has no response_format; emulate via a synthetic tool plus
# a forced tool_choice. The response_call will detect the synthetic
# tool_use block and lift its input back into the response content.
my $SYNTH_RF_TOOL_NAME = '__langertha_response_format__';

sub _translate_response_format {
  my ( $self, $extra ) = @_;
  return unless $self->has_response_format;
  my $rf = $self->response_format;
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
  $extra->{tool_choice} = { type => 'tool', name => $name };
}

# Normalize tool_choice (any accepted format -> Anthropic native) and fold
# parallel_tool_use into the tool_choice block as Anthropic expects.
sub _normalize_tool_params {
  my ( $self, $extra ) = @_;

  if ( exists $extra->{tool_choice} && defined $extra->{tool_choice} ) {
    if ( my $tc = Langertha::ToolChoice->from_hash( $extra->{tool_choice} ) ) {
      $extra->{tool_choice} = $tc->to_anthropic;
    }
  }

  return unless exists $extra->{tools}
    && $self->can('has_parallel_tool_use') && $self->has_parallel_tool_use;

  my $tc = $extra->{tool_choice};
  $tc = { type => 'auto' } unless ref($tc) eq 'HASH';
  unless ( exists $tc->{disable_parallel_tool_use} ) {
    $tc->{disable_parallel_tool_use} = $self->parallel_tool_use ? JSON->false : JSON->true;
  }
  $extra->{tool_choice} = $tc;
}

sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  my @blocks = @{$data->{content}};
  my $text = join('', map { $_->{text} // '' } grep { $_->{type} eq 'text' } @blocks);
  my @thinking = map { $_->{thinking} // '' } grep { $_->{type} eq 'thinking' } @blocks;
  my $thinking = @thinking ? join("\n", @thinking) : undef;
  my @tcs = Langertha::ToolCall->extract($data);

  # If the caller asked for a response_format and we routed it through a
  # synthesized tool, lift the tool_use input back into the content as
  # JSON so callers can treat it like any other structured-output result.
  if ( $self->has_response_format && @tcs ) {
    $text = $self->json->encode( $tcs[0]->arguments );
  }
  return Langertha::Response->new(
    content       => $text,
    raw           => $data,
    $data->{id} ? ( id => $data->{id} ) : (),
    $data->{model} ? ( model => $data->{model} ) : (),
    defined $data->{stop_reason} ? ( finish_reason => $data->{stop_reason} ) : (),
    $data->{usage} ? ( usage => $data->{usage} ) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
    @tcs ? ( tool_calls => [ @tcs ] ) : (),
  );
}

sub stream_format { 'sse' }

sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;
  $self->_normalize_tool_params(\%extra);
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
      input_schema => $_->{input_schema} // $_->{inputSchema} // $_->{parameters},
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

Langertha::Engine::AnthropicBase - Base class for Anthropic-compatible engines

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    package My::AnthropicCompatible;
    use Moose;

    extends 'Langertha::Engine::AnthropicBase';

    has '+url' => ( default => sub { 'https://api.example.com' } );

    sub _build_api_key { $ENV{MY_API_KEY} || die "MY_API_KEY required" }
    sub default_model { 'my-model-v1' }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Intermediate base class for engines speaking the Anthropic-compatible
C</v1/messages> format. Extends L<Langertha::Engine::Remote> and composes
models/chat/streaming plus Anthropic-style tool calling and response parsing.

Concrete engines extending this class include
L<Langertha::Engine::Anthropic>, L<Langertha::Engine::MiniMax>, and
L<Langertha::Engine::LMStudioAnthropic>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

Anthropic-compatible API key sent as C<x-api-key>. Subclasses typically
override C<_build_api_key> to read a provider-specific environment variable.

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
