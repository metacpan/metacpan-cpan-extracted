package Langertha::Engine::Ollama;
# ABSTRACT: Ollama API
our $VERSION = '0.404';
use Moose;
use File::ShareDir::ProjectDistDir qw( :all );
use Carp qw( croak );
use JSON::MaybeXS;
use Module::Runtime qw( use_module );

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
  Streaming
  Tools
);


sub openai {
  my ( $self, %args ) = @_;
  return Langertha::Engine::OllamaOpenAI->new(
    url => $self->url.'/v1',
    model => $self->model,
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
  return $self->openai( tools => $tools );
}


sub default_model { 'llama3.3' }
sub default_embedding_model { 'mxbai-embed-large' }

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
  return $self->generate_request( embed => sub { $self->embedding_response(shift) },
    model => $self->embedding_model,
    input => $prompt,
    %extra,
  );
}

sub embedding_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  # New API returns embeddings as array of arrays
  return $data->{embeddings}[0];
}

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
  return $self->generate_request( chat => sub { $self->chat_response(shift) },
    model => $self->chat_model,
    messages => $messages,
    stream => JSON->false,
    $self->json_format ? ( format => 'json' ) : (),
    defined $self->get_keep_alive ? ( keep_alive => $self->get_keep_alive ) : (),
    options => {
      $self->has_temperature ? ( temperature => $self->temperature ) : (),
      $self->has_context_size ? ( num_ctx => $self->get_context_size ) : (),
      $self->get_response_size ? ( num_predict => $self->get_response_size ) : (),
      $self->has_seed ? ( seed => $self->seed )
        : $self->randomize_seed ? ( seed => $self->random_seed ) : (),
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
  $timing = undef unless %$timing;

  require Langertha::Response;
  return Langertha::Response->new(
    content       => $msg->{content} // '',
    raw           => $data,
    $data->{model} ? ( model => $data->{model} ) : (),
    defined $data->{done_reason} ? ( finish_reason => $data->{done_reason} ) : (),
    $usage ? ( usage => $usage ) : (),
    $timing ? ( timing => $timing ) : (),
    $data->{created_at} ? ( created => $data->{created_at} ) : (),
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
  return $self->generate_request( chat => sub {},
    model => $self->chat_model,
    messages => $messages,
    stream => JSON->true,
    $self->json_format ? ( format => 'json' ) : (),
    defined $self->get_keep_alive ? ( keep_alive => $self->get_keep_alive ) : (),
    options => {
      $self->has_temperature ? ( temperature => $self->temperature ) : (),
      $self->has_context_size ? ( num_ctx => $self->get_context_size ) : (),
      $self->get_response_size ? ( num_predict => $self->get_response_size ) : (),
      $self->has_seed ? ( seed => $self->seed )
        : $self->randomize_seed ? ( seed => $self->random_seed ) : (),
      $extra{options} ? (%{delete $extra{options}}) : (),
    },
    %extra,
  );
}

sub parse_stream_chunk {
  my ( $self, $data ) = @_;

  my $content = $data->{message}{content} // '';
  my $is_done = $data->{done} ? 1 : 0;

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
  );
}

# Tool calling support (MCP)
# Ollama uses the same tool format as OpenAI

sub format_tools {
  my ( $self, $mcp_tools ) = @_;
  return [map {
    {
      type     => 'function',
      function => {
        name        => $_->{name},
        description => $_->{description},
        parameters  => $_->{input_schema} // $_->{inputSchema} // $_->{parameters},
      },
    }
  } @$mcp_tools];
}

sub response_tool_calls {
  my ( $self, $data ) = @_;
  my $msg = $data->{message} or return [];
  return $msg->{tool_calls} // [];
}

sub extract_tool_call {
  my ( $self, $tc ) = @_;
  return ( $tc->{function}{name}, $tc->{function}{arguments} );
}

sub response_text_content {
  my ( $self, $data ) = @_;
  my $msg = $data->{message} or return '';
  return $msg->{content} // '';
}

sub format_tool_results {
  my ( $self, $data, $results ) = @_;
  return (
    { role => 'assistant', content => $data->{message}{content},
      tool_calls => $data->{message}{tool_calls} },
    map {
      my $r = $_;
      {
        role    => 'tool',
        content => $self->json->encode($r->{result}{content}),
      }
    } @$results
  );
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::Ollama - Ollama API

=head1 VERSION

version 0.404

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

    my $embedding = $ollama->embedding($content);

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

For Hermes-format tool calling in models without API-level tool support,
compose L<Langertha::Role::HermesTools>. See L<Langertha::Role::HermesTools>
for details.

B<THIS API IS WORK IN PROGRESS>

=head2 openai

    my $oai = $ollama->openai;
    my $oai = $ollama->openai(model => 'different_model');

Returns a L<Langertha::Engine::OllamaOpenAI> instance configured for Ollama's
C</v1> OpenAI-compatible endpoint, inheriting the current model, embedding
model, system prompt, and temperature settings. Supports streaming, embeddings,
and MCP tool calling.

=head2 new_openai

    my $oai = Langertha::Engine::Ollama->new_openai(
        url   => 'http://localhost:11434',
        model => 'llama3.3',
        tools => \@mcp_tools,
    );

Class method. Constructs a native Ollama engine and immediately returns an
L<Langertha::Engine::OllamaOpenAI> instance from its C<openai()> method.
The optional C<tools> list is passed to C<openai()>.

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
