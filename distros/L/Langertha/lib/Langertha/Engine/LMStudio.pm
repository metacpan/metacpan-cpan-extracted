package Langertha::Engine::LMStudio;
# ABSTRACT: LM Studio native REST API
our $VERSION = '0.305';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use File::ShareDir::ProjectDistDir qw( :all );

extends 'Langertha::Engine::Remote';

with 'Langertha::Role::'.$_ for (qw(
  OpenAPI
  Models
  Temperature
  ResponseSize
  ContextSize
  SystemPrompt
  Streaming
  Chat
));


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
sub default_response_size { 1024 }

sub openapi_file { yaml => dist_file('Langertha','lmstudio.yaml') };


sub _build_openapi_operations {
  require Langertha::Spec::LMStudio;
  return Langertha::Spec::LMStudio::data();
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

sub _normalize_input {
  my ( $messages ) = @_;
  my @items;
  for my $msg (@{$messages}) {
    next unless ref $msg eq 'HASH';
    next if ($msg->{role} // '') eq 'system';
    next unless defined $msg->{content};
    my $content = ref $msg->{content} ? _extract_text($msg->{content}) : $msg->{content};
    push @items, {
      type => 'message',
      content => $content,
    };
  }

  return '' unless @items;
  return $items[0]{content} if @items == 1;
  return \@items;
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

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
  my $system_prompt = _normalize_system_prompt($messages);
  my $input = _normalize_input($messages);

  return $self->generate_request(
    'chat',
    sub { $self->chat_response(shift) },
    model => $self->chat_model,
    input => $input,
    $system_prompt ? ( system_prompt => $system_prompt ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    $self->get_response_size ? ( max_output_tokens => $self->get_response_size ) : (),
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
  my $system_prompt = _normalize_system_prompt($messages);
  my $input = _normalize_input($messages);

  return $self->generate_request(
    'chat',
    sub {},
    model => $self->chat_model,
    input => $input,
    $system_prompt ? ( system_prompt => $system_prompt ) : (),
    stream => JSON->true,
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    $self->get_response_size ? ( max_output_tokens => $self->get_response_size ) : (),
    $self->has_context_size ? ( context_length => $self->get_context_size ) : (),
    %extra,
  );
}

sub parse_stream_chunk {
  my ( $self, $data, $event ) = @_;

  require Langertha::Stream::Chunk;

  # LM Studio native SSE event stream (/api/v1/chat)
  my $type = $data->{type} // $event // '';
  if ($type eq 'error') {
    my $message = ref $data->{error} eq 'HASH' ? ($data->{error}{message} // 'Unknown LM Studio stream error') : 'Unknown LM Studio stream error';
    croak "LMStudio stream error: $message";
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

version 0.305

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

=item * Streaming chat (SSE): C<stream => true>

=item * Model listing: C<GET /api/v1/models>

=item * OpenAI-compatible wrapper via L</openai> (C</v1>)

=item * Anthropic-compatible wrapper via L</anthropic> (C</v1/messages>)

=back

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
system_prompt, and temperature by default.

=head2 anthropic

    my $anthropic = $lmstudio->anthropic;
    my $anthropic = $lmstudio->anthropic(model => 'other-model');

Returns a L<Langertha::Engine::LMStudioAnthropic> instance configured for
LM Studio's Anthropic-compatible C</v1/messages> endpoint. Carries over model,
api_key, system_prompt, and temperature by default.

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

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
