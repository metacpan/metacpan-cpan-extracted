package Langertha::Knarr::Protocol::Ollama;
# ABSTRACT: Ollama-compatible wire protocol (/api/chat, /api/generate, /api/tags, /api/version, /api/show) for Knarr

our $VERSION = '1.102';
use Moose;
use JSON::MaybeXS;
use Time::HiRes qw( time );
use POSIX qw( strftime );
use Scalar::Util ();
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Image;
use Langertha::Knarr::Reasoning;

with 'Langertha::Knarr::Protocol';

# --- Streaming model ---
# Ollama streams via newline-delimited JSON (NDJSON), NOT SSE.
# Each chunk: { model, created_at, message:{role,content}, done:false }
# Final:     { model, created_at, message:{role,content:""}, done:true,
#              total_duration, eval_count, ... }
# /api/generate carries the text on response instead of message (k48):
#            { model, created_at, response, done, ... }
# Content-Type stays application/x-ndjson (or application/json with chunked).
# ----------------------

has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );

has reasoning => (
  is      => 'ro',
  isa     => 'Langertha::Knarr::Reasoning',
  lazy    => 1,
  builder => '_build_reasoning',
);

sub _build_reasoning { Langertha::Knarr::Reasoning->new }


sub protocol_name { 'ollama' }

sub protocol_routes {
  return [
    { method => 'POST', path => '/api/chat',     action => 'chat'   },
    { method => 'POST', path => '/api/generate', action => 'chat'   },
    { method => 'GET',  path => '/api/tags',     action => 'models' },
    { method => 'GET',  path => '/api/version',  action => 'version' },
    { method => 'POST', path => '/api/show',     action => 'show'    },
  ];
}

# Provider manifest (k14): parse_chat_request below carries tools, format,
# options.temperature and options.seed. Ollama has no tool_choice; a schema
# in `format` is not mapped onto a json_schema response_format, so only
# the loose JSON mode is claimed; num_predict is not forwarded.
sub manifest_endpoint {
  return {
    dialect      => 'ollama',
    path         => '',
    capabilities => [qw(
      chat streaming system_prompt
      tools_native tools_hermes
      response_format_json_object
      temperature seed reasoning_effort
      image_input
    )],
    # A message's images array becomes Langertha::Content::Image objects
    # (k33); an older core gets it as sent, read only by native Ollama.
    image_content_formats => Langertha::Knarr::Image::content_formats(qw( ollama )),
  };
}

sub _ts { strftime( "%Y-%m-%dT%H:%M:%S.000000000Z", gmtime ) }

# The path the client asked for, recorded by parse_chat_request as
# extra->{path} (k48). /api/generate answers in its own shape, and a
# passthrough handler in the chain sends it to the upstream's /api/generate.
sub _is_generate {
  my ($self, $request) = @_;
  return ( $request->extra->{path} // '' ) eq '/api/generate' ? 1 : 0;
}

# The client's answer text and the fields around it: message for /api/chat,
# response for /api/generate.
sub _text_fields {
  my ($self, $request, $text, $tool_calls) = @_;
  return ( response => $text ) if $self->_is_generate($request);
  my $message = { role => 'assistant', content => $text };
  $message->{tool_calls} = [ map { $_->to_ollama } @$tool_calls ]
    if $tool_calls && @$tool_calls;
  return ( message => $message );
}

sub parse_chat_request {
  my ($self, $http_req, $body_ref) = @_;
  my $data = $self->_json->decode( $$body_ref || '{}' );
  # The native server's request and the PSGI adapter's both know the path;
  # which of the two chat routes the request came in on picks the answer's
  # shape (k48).
  my $path = $http_req && Scalar::Util::blessed($http_req) && $http_req->can('path')
    ? $http_req->path : undef;
  # Capture auth headers for passthrough, like the OpenAI and Anthropic
  # parsers: a Handler::Passthrough in the chain forwards them to an
  # authenticated remote Ollama (k49), one pair per line (k60). Knarr takes
  # its own key out.
  my $fwd = $self->_forward_headers( $http_req, qw( authorization ) );
  my @msgs;
  if ( $data->{messages} ) {
    @msgs = @{ Langertha::Knarr::Image::ollama_messages( $data->{messages} ) };
  }
  elsif ( defined $data->{prompt} ) {
    my %msg = ( role => 'user', content => $data->{prompt} );
    # /api/generate carries images on the request, not a message (k34).
    # They go onto the user message in Ollama's message shape: translated
    # like chat images, or as sent on an older core.
    $msg{images} = $data->{images}
      if ref $data->{images} eq 'ARRAY' && @{ $data->{images} };
    @msgs = @{ Langertha::Knarr::Image::ollama_messages( [ \%msg ] ) };
  }
  return Langertha::Knarr::Request->new(
    protocol        => 'ollama',
    raw             => $data,
    model           => $data->{model},
    messages        => \@msgs,
    stream          => exists $data->{stream} ? ( $data->{stream} ? 1 : 0 ) : 1,  # Ollama defaults to stream
    temperature     => $data->{options}{temperature},
    seed            => $data->{options}{seed},
    reasoning_effort => scalar $self->reasoning->from_ollama( $data->{think}, $data->{reasoning_effort} ),
    tools           => $data->{tools},
    response_format => $data->{format},
    extra           => { forward_headers => $fwd, defined $path ? ( path => $path ) : () },
  );
}

# Ollama's done_reason vocabulary is stop / length (plus load / unload for
# model-management answers, which carry no generation). Tool calls end with
# stop on Ollama's own wire. Every other reason -- tool_calls, end_turn,
# content_filter, Gemini SAFETY, ... -- has no Ollama counterpart and
# becomes stop.
my %DONE_REASON = (
  ( map { $_ => $_ } qw( stop length load unload ) ),
  max_tokens => 'length',
);

sub _done_reason {
  my ($finish_reason) = @_;
  return 'stop' unless defined $finish_reason;
  return $DONE_REASON{ lc $finish_reason } // 'stop';
}

sub format_chat_response {
  my ($self, $response, $request) = @_;
  my $r = Langertha::Knarr::Response->coerce($response);
  my $payload = {
    model      => $r->model // $request->model // 'unknown',
    created_at => _ts(),
    $self->_text_fields( $request, $r->content, $r->has_tool_calls ? $r->tool_calls : [] ),
    done       => JSON::MaybeXS::true(),
    done_reason => _done_reason( $r->finish_reason ),
  };
  if ( $r->usage && $r->usage->can('to_ollama_format') ) {
    my $u = $r->usage->to_ollama_format;
    $payload->{$_} = $u->{$_} for keys %$u;
  }
  return ( 200, { 'Content-Type' => 'application/json' }, $self->_json->encode($payload) );
}


sub format_models_response {
  my ($self, $models) = @_;
  my @data = map {
    my $id = ref $_ eq 'HASH' ? $_->{id} : "$_";
    { name => $id, model => $id, modified_at => _ts(), size => 0 }
  } @$models;
  return ( 200, { 'Content-Type' => 'application/json' },
    $self->_json->encode({ models => \@data }) );
}

# GET /api/version (k27). Ollama clients read this as the server's Ollama
# version and may gate features on it, so it carries the Ollama version
# Knarr's endpoints are compatible with, never Knarr's own version.
sub format_version_response {
  my ($self, $version) = @_;
  return ( 200, { 'Content-Type' => 'application/json' },
    $self->_json->encode({ version => "$version" }) );
}


sub format_error_response {
  my ($self, $status, $message) = @_;
  return ( $status, { 'Content-Type' => 'application/json' },
    $self->_json->encode({ error => "$message" }) );
}


sub format_show_response {
  my ($self, $model, $info) = @_;
  my %model_info;
  if ( defined $info->{context_length} ) {
    %model_info = (
      'general.architecture' => 'knarr',
      'knarr.context_length' => $info->{context_length} + 0,
    );
  }
  my $payload = {
    modified_at  => _ts(),
    capabilities => [ @{ $info->{capabilities} || [] } ],
    details      => {
      parent_model       => '',
      format             => '',
      family             => '',
      families           => [],
      parameter_size     => '',
      quantization_level => '',
    },
    model_info => \%model_info,
    template   => '',
    parameters => '',
    license    => '',
  };
  return ( 200, { 'Content-Type' => 'application/json' }, $self->_json->encode($payload) );
}

sub format_stream_chunk {
  my ($self, $delta_text, $request) = @_;
  my $payload = {
    model      => $request->model // 'unknown',
    created_at => _ts(),
    $self->_text_fields( $request, $delta_text ),
    done       => JSON::MaybeXS::false(),
  };
  return $self->_json->encode($payload) . "\n";
}

sub stream_content_type { 'application/x-ndjson' }

# Ollama ends a failed stream with an {"error":"..."} line.
sub format_stream_error {
  my ($self, $status, $message) = @_;
  return $self->_json->encode({ error => "$message" }) . "\n";
}

# The routed stream carries the backend's tool calls complete; Ollama's own
# wire sends message.tool_calls whole, so they ride on the done line (k19),
# and so do the usage counters, as Ollama's own done line has them.
sub format_stream_done {
  my ($self, $request, $finish_reason, $tool_calls, $usage) = @_;
  my $payload = {
    model      => $request->model // 'unknown',
    created_at => _ts(),
    $self->_text_fields( $request, '', $tool_calls ),
    done       => JSON::MaybeXS::true(),
    done_reason => _done_reason($finish_reason),
  };
  if ( $usage && $usage->can('to_ollama_format') ) {
    my $u = $usage->to_ollama_format;
    $payload->{$_} = $u->{$_} for keys %$u;
  }
  return $self->_json->encode($payload) . "\n";
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Protocol::Ollama - Ollama-compatible wire protocol (/api/chat, /api/generate, /api/tags, /api/version, /api/show) for Knarr

=head1 VERSION

version 1.102

=head1 DESCRIPTION

Implements the Ollama wire format on top of
L<Langertha::Knarr::Protocol>. Loaded by default.

=over

=item * C<POST /api/chat>, C<POST /api/generate> — chat with NDJSON streaming;
C</api/generate> answers in Ollama's generate shape, the text on C<response>
instead of C<message> (see L</format_chat_response>)

=item * C<GET /api/tags> — model listing

=item * C<GET /api/version> — version probe, answered with Ollama's shape
C<{"version":"x.y.z"}> and the Ollama version Knarr claims compatibility
with (L<Langertha::Knarr/ollama_compat_version>), not Knarr's own version

=item * C<POST /api/show> — model details for a listed model (see
L</format_show_response>); C<model> or the legacy C<name> in the body,
C<400> without one, Ollama's C<404> C<{"error":"model 'x' not found"}> for
a model Knarr does not list

=back

The client's C<Authorization> header is kept as C<forward_headers>, like
the OpenAI and Anthropic protocols do, so a
L<Langertha::Knarr::Handler::Passthrough> in the handler chain reaches an
authenticated remote Ollama with it.

Streaming uses newline-delimited JSON (NDJSON) rather than SSE — the
C<Content-Type> is C<application/x-ndjson> and each chunk is a single
JSON object per line. The final chunk has C<done: true>.

=head2 reasoning

The L<Langertha::Knarr::Reasoning> that maps the body's C<think> (a boolean
or a level string) onto the request's C<reasoning_effort>. Pass your own to
override the level C<think: true> maps to.

=head2 format_chat_response

    my ($status, $headers, $body) = $proto->format_chat_response( $response, $request );

The non-streaming answer: C<model>, C<created_at>, C<done>, C<done_reason>
and the usage counters (C<prompt_eval_count>, C<eval_count>, ...) when the
backend reported usage. A C</api/chat> request gets the text on C<message>
(with C<tool_calls>), a C</api/generate> request on C<response>, as Ollama
answers it -- streaming alike, where every chunk carries its piece on
C<message.content> or C<response> and the final C<{"done": true}> line an
empty one, with the usage counters when the backend reported usage.

=head2 format_error_response

    my ($status, $headers, $body) = $proto->format_error_response( 404, "model 'x' not found" );

Ollama's error answer: C<{"error":"..."}> with a plain string, not the
C<{"error":{"message":...}}> object of the OpenAI wire.

=head2 format_show_response

    my ($status, $headers, $body) = $proto->format_show_response( $model, {
        capabilities   => [ 'completion', 'tools' ],
        context_length => 131072,   # optional
    } );

The C<POST /api/show> answer for a model Knarr serves (k29). Only what
Knarr knows is claimed: C<capabilities> as given, C<model_info> with
C<general.architecture> (C<knarr>) and C<knarr.context_length> when a
context length is known -- the pair VS Code Copilot reads, C<{}> otherwise
-- and empty C<details>, C<template> and C<parameters>, since there are no
local weights, template or Modelfile behind a routed model.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
