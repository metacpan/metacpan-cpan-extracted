package Langertha::Engine::LMStudio;
# ABSTRACT: LM Studio native REST API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use File::ShareDir::ProjectDistDir qw( :all );
use Module::Runtime qw( use_module );

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  OpenAPI
  Models
  Temperature
  ResponseSize
  ContextSize
  SystemPrompt
  Streaming
  Chat
  ImageInput
);

# image_input (k266, ADR 0019): self-hosted: the served model is launch state
# the client cannot see, so no static claim. A layer-3 catch-all rather than a
# layer-2 delete, so a fact probed from /api/v1/models (capabilities.vision)
# can answer per model (ADR 0032).
sub model_capability_corrections {
  return ( qr/\A/ => { image_input => 0 } );
}

sub model_metadata_format { 'lmstudio' }
sub model_metadata_url {
  my $url = $_[0]->url;
  $url =~ s{/\z}{};
  return $url . '/api/v1/models';
}


has '+url' => (
  lazy => 1,
  default => sub { 'http://localhost:1234' },
);

has api_key => (
  is => 'ro',
  lazy_build => 1,
);

sub _build_api_key {
  return $ENV{LANGERTHA_LMSTUDIO_API_KEY};
}


sub update_request {
  my ( $self, $request ) = @_;
  my $key = $self->api_key;
  $request->header('Authorization', 'Bearer '.$key) if defined $key;
}

sub default_model { 'default' }

# Native /api/v1/chat input takes { type => 'image', data_url } items carrying a
# base64 data URL only (lmstudio.ai/docs/developer/rest/chat), karr k267.
sub content_format { 'lmstudio' }
sub _content_inline_images_only { 1 }
sub default_response_size { 1024 }

# api_key_env derives LANGERTHA_LMSTUDIO_API_KEY, the variable _build_api_key
# reads: a secured LM Studio needs it, the default local server does not.
sub api_key_required { 0 }

sub openapi_file { yaml => dist_file('Langertha','lmstudio.yaml') };


sub _build_openapi_operations {
  return use_module('Langertha::Spec::LMStudio')->data;
}

sub _build_supported_operations {[qw(
  chat
  listModels
)]}

sub openai {
  my ( $self, %args ) = @_;

  require Langertha::Engine::LMStudioOpenAI;

  my $url = $self->url;
  $url =~ s{/\z}{};
  my $api_key = defined $self->api_key ? $self->api_key : 'lmstudio';

  return Langertha::Engine::LMStudioOpenAI->new(
    url => $url.'/v1',
    model => $self->model,
    api_key => $api_key,
    # The pin carries over while the url stays on its host (karr k375).
    $self->_connect_address_for( exists $args{url} ? $args{url} : $url.'/v1' ),
    $self->has_system_prompt ? ( system_prompt => $self->system_prompt ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    %args,
  );
}


sub anthropic {
  my ( $self, %args ) = @_;

  require Langertha::Engine::LMStudioAnthropic;

  my $api_key = defined $self->api_key ? $self->api_key : 'lmstudio';

  return Langertha::Engine::LMStudioAnthropic->new(
    url => $self->url,
    model => $self->model,
    api_key => $api_key,
    $self->_connect_address_for( exists $args{url} ? $args{url} : $self->url ),
    $self->has_system_prompt ? ( system_prompt => $self->system_prompt ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    %args,
  );
}


sub _normalize_usage {
  my ( $usage ) = @_;
  return undef unless $usage && ref $usage eq 'HASH';

  my %normalized;
  $normalized{prompt_tokens} = $usage->{prompt_tokens}
    if defined $usage->{prompt_tokens};
  $normalized{completion_tokens} = $usage->{completion_tokens}
    if defined $usage->{completion_tokens};
  $normalized{total_tokens} = $usage->{total_tokens}
    if defined $usage->{total_tokens};

  $normalized{prompt_tokens} = $usage->{input_tokens}
    if !defined($normalized{prompt_tokens}) && defined($usage->{input_tokens});
  $normalized{completion_tokens} = $usage->{output_tokens}
    if !defined($normalized{completion_tokens}) && defined($usage->{output_tokens});

  if (!defined($normalized{total_tokens})
    && defined($normalized{prompt_tokens})
    && defined($normalized{completion_tokens})) {
    $normalized{total_tokens} = $normalized{prompt_tokens} + $normalized{completion_tokens};
  }

  return %normalized ? \%normalized : undef;
}

sub _extract_text {
  my ( $content ) = @_;
  return '' unless defined $content;
  return $content unless ref $content;

  return '' unless ref $content eq 'ARRAY';

  my @parts;
  for my $part (@{$content}) {
    next unless ref $part eq 'HASH';
    if (defined $part->{text}) {
      push @parts, $part->{text};
      next;
    }
    if (defined $part->{content} && !ref $part->{content}) {
      push @parts, $part->{content};
      next;
    }
    if (defined $part->{delta} && !ref $part->{delta}) {
      push @parts, $part->{delta};
      next;
    }
  }

  return join('', @parts);
}

sub _extract_response_text {
  my ( $data ) = @_;
  return '' unless ref $data eq 'HASH';

  my @pieces;
  for my $item (@{$data->{output} // []}) {
    next unless ref $item eq 'HASH';
    push @pieces, $item->{content}
      if ($item->{type} // '') eq 'message' && defined $item->{content};
  }
  return join('', @pieces) if @pieces;

  return '';
}

sub _extract_reasoning_text {
  my ( $data ) = @_;
  return undef unless ref $data eq 'HASH';

  my @parts;
  for my $item (@{$data->{output} // []}) {
    next unless ref $item eq 'HASH';
    push @parts, $item->{content}
      if ($item->{type} // '') eq 'reasoning' && defined $item->{content};
  }
  return @parts ? join("\n", @parts) : undef;
}

# Native /api/v1/chat input is ONE user turn: a string, or an array of content
# parts { type => 'text', content } / { type => 'image', data_url }
# (lmstudio.ai/docs/developer/rest/chat, corrected in lmstudio-ai/docs 9b8bc20,
# karr k268). The items carry no role, so the caller has already cut the
# history down to the trailing user turn(s) (_trailing_turns).
sub _normalize_input {
  my ( $messages ) = @_;
  my @items;
  for my $msg (@{$messages}) {
    next unless ref $msg eq 'HASH';
    next if ($msg->{role} // '') eq 'system';
    next unless defined $msg->{content};
    if ( ref $msg->{content} eq 'ARRAY'
      && grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'image' } @{ $msg->{content} } ) {
      push @items, _input_items_with_images($msg->{content});
      next;
    }
    my $content = ref $msg->{content} ? _extract_text($msg->{content}) : $msg->{content};
    push @items, {
      type => 'text',
      content => $content,
    };
  }

  return '' unless @items;
  return $items[0]{content} if @items == 1 && $items[0]{type} eq 'text';
  return \@items;
}

# A content array holding image items (Content::Image->to_lmstudio, karr k267):
# the images become their own { type => 'image', data_url } input items, in
# order, between the text runs around them.
sub _input_items_with_images {
  my ( $parts ) = @_;
  my ( @items, @run );
  my $flush = sub {
    push @items, { type => 'text', content => _extract_text([ @run ]) } if @run;
    @run = ();
  };
  for my $part (@{$parts}) {
    if ( ref $part eq 'HASH' && ( $part->{type} // '' ) eq 'image' ) {
      $flush->();
      push @items, { type => 'image', data_url => $part->{data_url} };
    }
    else {
      push @run, $part;
    }
  }
  $flush->();
  return @items;
}

# The native chat endpoint takes no assistant messages ("Include assistant
# messages in the request: NO", lmstudio.ai/docs/developer/rest, karr k268):
# flattening earlier assistant replies into the input would present them as
# user text. Multi-turn on this wire is stateful (store + previous_response_id),
# so a history with assistant turns is cut to what follows the last one, with a
# carp per request. System messages stay: they go out as system_prompt.
sub _trailing_turns {
  my ( $self, $messages ) = @_;
  my $last_assistant;
  for my $i ( 0 .. $#{$messages} ) {
    my $msg = $messages->[$i];
    $last_assistant = $i if ref $msg eq 'HASH' && ( $msg->{role} // '' ) eq 'assistant';
  }
  return $messages unless defined $last_assistant;
  $self->_langertha_carp( "".( ref $self ).": LM Studio native has no multi-turn "
    . "history; sending only the trailing user turn(s); use ->openai/->anthropic "
    . "or previous_response_id" );
  return [ @{$messages}[ $last_assistant + 1 .. $#{$messages} ] ];
}

sub _normalize_system_prompt {
  my ( $messages ) = @_;
  my @system;
  for my $msg (@{$messages}) {
    next unless ref $msg eq 'HASH';
    next unless ($msg->{role} // '') eq 'system';
    next unless defined $msg->{content};
    push @system, $msg->{content};
  }
  return @system ? join("\n\n", @system) : undef;
}

# LM Studio's native /api/v1/chat takes neither tools nor tool_choice: its
# endpoint table lists "Custom tools: NO" for /api/v1/chat (yes on
# /v1/chat/completions, /v1/messages, /v1/responses; lmstudio.ai/docs/
# developer/rest), and the tool_call items it returns are server-run
# plugin/MCP calls. A tools list croaks, like a ServerTool off its wire, since
# no tool call could ever come back; an empty one or undef is simply not sent. A
# tool_choice goes through the shared rule (karr k239): this engine claims no
# tool_choice_*, so it is dropped, a forced one with a carp.
sub _lmstudio_tool_kwargs {
  my ( $self, $extra ) = @_;
  if ( exists $extra->{tools} ) {
    my $tools = delete $extra->{tools};
    croak "".( ref $self ).": LM Studio's native /api/v1/chat takes no tools; use "
      . "Langertha::Engine::LMStudioOpenAI or Langertha::Engine::LMStudioAnthropic "
      . "(the ->openai / ->anthropic methods) for tool calling"
        if defined $tools && ( ref $tools ne 'ARRAY' || @$tools );
  }
  $self->_gate_tool_choice($extra);
  return;
}

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
  $self->_lmstudio_tool_kwargs(\%extra);

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  # LM Studio's native wire only honors temperature and max_output_tokens;
  # the other canonical controls have no native placement here and are
  # consumed without being emitted.
  my $controls = delete $extra{controls} // {};

  my $system_prompt = _normalize_system_prompt($messages);
  my $input = _normalize_input( $self->_trailing_turns($messages) );

  return $self->generate_request(
    'chat',
    sub { $self->chat_response(shift) },
    model => $self->chat_model,
    input => $input,
    $system_prompt ? ( system_prompt => $system_prompt ) : (),
    exists $controls->{temperature}
      ? ( temperature => $controls->{temperature} )
      : ( $self->has_temperature ? ( temperature => $self->temperature ) : () ),
    exists $controls->{max_tokens}
      ? ( max_output_tokens => $controls->{max_tokens} )
      : ( $self->get_response_size ? ( max_output_tokens => $self->get_response_size ) : () ),
    $self->has_context_size ? ( context_length => $self->get_context_size ) : (),
    %extra,
  );
}

sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  my $text = _extract_response_text($data);
  my $thinking = _extract_reasoning_text($data);
  my $usage = _normalize_usage({
    input_tokens => $data->{stats}{input_tokens},
    output_tokens => $data->{stats}{total_output_tokens},
  });

  require Langertha::Response;
  return Langertha::Response->new(
    content       => $text,
    raw           => $data,
    $data->{response_id} ? ( id => $data->{response_id} ) : (),
    $data->{model_instance_id} ? ( model => $data->{model_instance_id} ) : (),
    $usage ? ( usage => $usage ) : (),
    defined $thinking ? ( thinking => $thinking ) : (),
  );
}

sub stream_format { 'sse' }

sub chat_stream_request {
  my ( $self, $messages, %extra ) = @_;
  $self->_lmstudio_tool_kwargs(\%extra);

  # Canonical per-request controls (chat_f, karr #46) beat the engine
  # attributes on a per-key basis; the rest of %extra passes straight through.
  my $controls = delete $extra{controls} // {};

  my $system_prompt = _normalize_system_prompt($messages);
  my $input = _normalize_input( $self->_trailing_turns($messages) );

  return $self->generate_request(
    'chat',
    sub {},
    model => $self->chat_model,
    input => $input,
    $system_prompt ? ( system_prompt => $system_prompt ) : (),
    stream => JSON->true,
    exists $controls->{temperature}
      ? ( temperature => $controls->{temperature} )
      : ( $self->has_temperature ? ( temperature => $self->temperature ) : () ),
    exists $controls->{max_tokens}
      ? ( max_output_tokens => $controls->{max_tokens} )
      : ( $self->get_response_size ? ( max_output_tokens => $self->get_response_size ) : () ),
    $self->has_context_size ? ( context_length => $self->get_context_size ) : (),
    %extra,
  );
}

sub parse_stream_chunk {
  my ( $self, $data, $event, $state ) = @_;
  $state //= {};

  require Langertha::Stream::Chunk;

  # LM Studio native SSE event stream (/api/v1/chat)
  my $type = $data->{type} // $event // '';
  if ($type eq 'error') {
    my $message = ref $data->{error} eq 'HASH' ? ($data->{error}{message} // 'Unknown LM Studio stream error') : 'Unknown LM Studio stream error';
    croak "LMStudio stream error: $message";
  }
  # reasoning.start / reasoning.delta / reasoning.end
  # (lmstudio.ai/docs/developer/rest/streaming-events): each delta goes onto
  # the chunk's thinking so aggregate_thinking rebuilds what chat_response
  # lifts from output[type=reasoning] -- including its "\n" between separate
  # reasoning blocks. -- karr k334
  if ($type eq 'reasoning.start') {
    $state->{lmstudio_reasoning_separator} = 1 if $state->{lmstudio_reasoning_seen};
    return undef;
  }
  if ($type eq 'reasoning.delta') {
    return undef unless defined $data->{content};
    my $thinking = $data->{content};
    $thinking = "\n" . $thinking if delete $state->{lmstudio_reasoning_separator};
    $state->{lmstudio_reasoning_seen} = 1;
    return Langertha::Stream::Chunk->new(
      content  => '',
      thinking => $thinking,
      raw      => $data,
      is_final => 0,
    );
  }
  if ($type eq 'message.delta') {
    return Langertha::Stream::Chunk->new(
      content => $data->{content} // '',
      raw => $data,
      is_final => 0,
    );
  }
  if ($type eq 'chat.end') {
    my $result = $data->{result} || {};
    my $usage = _normalize_usage({
      input_tokens => $result->{stats}{input_tokens},
      output_tokens => $result->{stats}{total_output_tokens},
    });

    return Langertha::Stream::Chunk->new(
      content => '',
      raw => $data,
      is_final => 1,
      defined $result->{response_id} ? ( finish_reason => 'end' ) : (),
      $result->{model_instance_id} ? ( model => $result->{model_instance_id} ) : (),
      $usage ? ( usage => $usage ) : (),
    );
  }

  return undef;
}

# Dynamic model listing
sub list_models_request {
  my ( $self ) = @_;
  return $self->generate_request(
    'listModels',
    sub { $self->list_models_response(shift) },
  );
}

sub list_models_response {
  my ( $self, $response ) = @_;
  return $self->parse_response($response);
}

sub list_models {
  my ( $self, %opts ) = @_;

  unless ($opts{force_refresh}) {
    my $cache = $self->_models_cache;
    if ($cache->{timestamp} && time - $cache->{timestamp} < $self->models_cache_ttl) {
      return $opts{full} ? $cache->{models} : $cache->{model_ids};
    }
  }

  my $request = $self->list_models_request;
  my $response = $self->user_agent->request($request);
  my $data = $request->response_call->($response);

  my $models = ref $data eq 'HASH'
    ? ($data->{data} // $data->{models} // [])
    : $data;
  $models = [] unless ref $models eq 'ARRAY';

  my @model_ids;
  for my $model (@{$models}) {
    next unless ref $model eq 'HASH';
    my $id = $model->{key} // $model->{id} // $model->{model} // $model->{name};
    push @model_ids, $id if defined $id;
  }

  $self->_models_cache({
    timestamp => time,
    models => $models,
    model_ids => \@model_ids,
  });

  return $opts{full} ? $models : \@model_ids;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::LMStudio - LM Studio native REST API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::LMStudio;

    my $lmstudio = Langertha::Engine::LMStudio->new(
        url   => 'http://localhost:1234',
        model => 'qwen2.5-7b-instruct',
    );

    print $lmstudio->simple_chat('Hello from LM Studio native API');

    $lmstudio->simple_chat_stream(sub {
        print shift->content;
    }, 'Explain Perl Moo vs Moose');

=head1 DESCRIPTION

Provides access to LM Studio's native local REST API (C</api/v1/...>),
without using the OpenAI-compatible C</v1> endpoints.

Implemented operations:

=over 4

=item * Chat: C<POST /api/v1/chat>

=item * Streaming chat (SSE): C<stream => true>; C<reasoning.delta> events land
on L<Langertha::Stream::Chunk/thinking>, so a streamed call keeps the same
thinking as L<Langertha::Response/thinking>

=item * Model listing: C<GET /api/v1/models>

=item * OpenAI-compatible wrapper via L</openai> (C</v1>)

=item * Anthropic-compatible wrapper via L</anthropic> (C</v1/messages>)

=back

The native chat endpoint takes no client tools: passing a non-empty C<tools>
list croaks, use the L</openai> or L</anthropic> wrapper for tool calling. A
C<tool_choice> is never sent (a forced one warns).

The native C<input> is one user turn: a plain string, or an array of
C<< { type => 'text', content } >> and C<< { type => 'image', data_url } >>
parts (L<Langertha::Content::Image> goes as a base64 data URL). The endpoint
takes no assistant messages, so a history that contains assistant turns is cut
to the user turn(s) after the last one, with a warning; system messages still
go out as C<system_prompt>. For client-side history use the L</openai> or
L</anthropic> wrapper.

Multi-turn on this wire is server-side state instead: LM Studio stores each
chat (C<store> defaults to true on the server) and answers with a
C<response_id> (L<Langertha::Response/id>). Pass it back as
C<previous_response_id> together with the next user turn only; both
C<previous_response_id> and C<store> are passed through unchanged:

    my $first = await $lmstudio->chat_f( messages => [ 'My name is Ada.' ] );
    my $next  = await $lmstudio->chat_f(
        messages             => [ 'What is my name?' ],
        previous_response_id => $first->id,
    );

    # a throwaway call that leaves no stored chat behind
    await $lmstudio->chat_f( messages => [ 'Hi' ], store => JSON::MaybeXS::false );

Langertha does not send C<store> by default, so every call is stored by the
server. With C<store> false the server returns no C<response_id>, and the
final streamed chunk then carries no C<finish_reason>.

Authentication is optional. If C<api_key> (or C<LANGERTHA_LMSTUDIO_API_KEY>)
is set, requests include C<Authorization: Bearer ...>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

Optional LM Studio API token for bearer authentication. If not provided,
reads from C<LANGERTHA_LMSTUDIO_API_KEY>. When undefined, no bearer header
is sent.

=head2 openapi_file

Returns the bundled native LM Studio OpenAPI spec file
C<share/lmstudio.yaml>.

=head2 openai

    my $oai = $lmstudio->openai;
    my $oai = $lmstudio->openai(model => 'other-model');

Returns a L<Langertha::Engine::LMStudioOpenAI> instance configured for LM Studio's
OpenAI-compatible C</v1> endpoint. Carries over model, api_key,
system_prompt, and temperature by default, and
L<Langertha::Role::HTTP/connect_address> while the url stays on its host.

=head2 anthropic

    my $anthropic = $lmstudio->anthropic;
    my $anthropic = $lmstudio->anthropic(model => 'other-model');

Returns a L<Langertha::Engine::LMStudioAnthropic> instance configured for
LM Studio's Anthropic-compatible C</v1/messages> endpoint. Carries over model,
api_key, system_prompt, and temperature by default, and
L<Langertha::Role::HTTP/connect_address> while the url stays on its host.

=head1 SEE ALSO

=over

=item * L<https://lmstudio.ai/docs/developer> - LM Studio developer docs

=item * L<Langertha::Engine::Ollama> - Another native local engine

=item * L<Langertha::Engine::OpenAI> - Cloud OpenAI engine

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
