package Langertha::Knarr::Handler::Passthrough;
# ABSTRACT: Knarr handler that forwards requests verbatim to an upstream HTTP API
our $VERSION = '1.102';
use Moose;
use Future;
use Future::AsyncAwait;
use HTTP::Request;
use URI;
use JSON::MaybeXS;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Response;
use Langertha::ToolCall;

with 'Langertha::Knarr::Handler', 'Langertha::Knarr::Role::UpstreamHTTP';


# Forwards the original wire-format request to a real upstream API. The
# protocol's parser already turned the body into a Knarr::Request, so we
# rebuild a body from $request->raw and re-POST it. Headers (especially
# Authorization) are passed through if the caller registers them with the
# session via $request->extra->{forward_headers}.

# Per-protocol upstream URLs. Keys are protocol names ("openai", "anthropic",
# "ollama"). Each value is the base URL of the upstream provider — e.g.
# https://api.openai.com or https://api.anthropic.com. Knarr appends the
# original request path to this base URL.
has upstreams => (
  is       => 'ro',
  isa      => 'HashRef[Str]',
  required => 1,
);

# Optional: a default Authorization header value to inject if the client
# didn't send one. If undef, the client must supply its own.
has default_auth => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has model_id => ( is => 'ro', isa => 'Str', default => 'passthrough' );

has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );

# Per-protocol path the request should hit upstream. We use the protocol
# defaults; this lookup table can be extended.
my %DEFAULT_PATH = (
  openai    => '/v1/chat/completions',
  anthropic => '/v1/messages',
  ollama    => '/api/chat',
);

# Other chat paths a protocol has upstream, reached as the client asked:
# Ollama's /api/generate takes a prompt, not messages, and answers in its
# own shape, so its bytes must reach the upstream's /api/generate (k46).
my %OTHER_PATHS = (
  ollama => { '/api/generate' => 1 },
);

# $client_path: the path the client asked for; used when it is one of the
# protocol's chat paths, else the protocol's default chat path.
sub _upstream_url {
  my ($self, $protocol_name, $client_path) = @_;
  my $base = $self->upstreams->{$protocol_name}
    or die "Passthrough: no upstream configured for protocol '$protocol_name'\n";
  $base =~ s{/+$}{};
  my $path = $DEFAULT_PATH{$protocol_name}
    or die "Passthrough: no default path for protocol '$protocol_name'\n";
  $path = $client_path
    if defined $client_path && $OTHER_PATHS{$protocol_name}{$client_path};
  return "$base$path";
}

# Whether a request in this protocol has anywhere to go: an upstream URL
# and a known chat path -- exactly what _upstream_url needs (k41).
sub serves_protocol {
  my ($self, $protocol_name) = @_;
  return 0 unless defined $protocol_name;
  return $self->upstreams->{$protocol_name} && $DEFAULT_PATH{$protocol_name} ? 1 : 0;
}

# Whether $url lives on this protocol's upstream (k47).
sub is_upstream_for {
  my ($self, $protocol_name, $url) = @_;
  return 0 unless defined $protocol_name && defined $url;
  my $base = $self->upstreams->{$protocol_name} or return 0;
  return $self->same_upstream( $base, $url );
}


# Same scheme, host, port and path (k54): a gateway serves several
# providers under paths of one host. An engine's base URL carries the API
# version the passthrough base leaves out (https://api.openai.com/v1 vs
# https://api.openai.com), so a trailing /v1 is not compared. URI's
# canonical form takes care of host case and default ports.
sub same_upstream {
  my ($self, $base, $url) = @_;
  return 0 unless defined $base && defined $url;
  my ($upstream, $other) = map { URI->new($_)->canonical } $base, $url;
  return 0 unless $upstream->can('host') && $other->can('host');
  return $upstream->scheme eq $other->scheme && $upstream->host eq $other->host
    && $upstream->port == $other->port
    && $self->_upstream_path($upstream) eq $self->_upstream_path($other) ? 1 : 0;
}

sub _upstream_path {
  my ($self, $uri) = @_;
  ( my $path = $uri->path ) =~ s{/+\z}{};
  $path =~ s{/v1\z}{};
  return $path;
}



# An Ollama /api/generate request: its upstream answer carries the text on
# response, not message.content, and no tool calls (k48).
sub _is_ollama_generate {
  my ($self, $request) = @_;
  return $request->protocol eq 'ollama'
    && ( $request->extra->{path} // '' ) eq '/api/generate' ? 1 : 0;
}

sub _build_upstream_request {
  my ($self, $request, $force_stream) = @_;
  my $body = { %{ $request->raw || {} } };
  $body->{stream} = $force_stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false()
    if defined $force_stream;
  # The client's path, where the protocol's parser recorded it: an Ollama
  # /api/generate goes to the upstream's /api/generate (k48).
  my $url = $self->_upstream_url( $request->protocol, $request->extra->{path} );
  my $http_req = HTTP::Request->new( POST => $url );
  $http_req->header( 'Content-Type' => 'application/json' );
  # Forward client auth headers (captured by protocol parsers), each line
  # added, not set: a header sent twice reaches the upstream twice, in its
  # order (k60).
  $http_req->push_header(@$_) for $request->forward_header_pairs;
  if ( my $auth = $self->default_auth ) {
    $http_req->header( Authorization => $auth ) unless $http_req->header('Authorization');
  }
  $http_req->content( $self->_json->encode($body) );
  return $http_req;
}

# Read an upstream response body for the protocol it came from: the
# assistant text, the tool calls as Langertha::ToolCall objects (through
# core's canonical inbound door, the same one the streaming path uses) and
# the terminal reason verbatim -- the client-side protocol maps it (k21).
# $generate: the body is an Ollama /api/generate answer, the text on
# response instead of message.content (k48).
sub _parse_response {
  my ($self, $protocol_name, $resp_body, $generate) = @_;
  my %parsed = ( content => '', tool_calls => [], finish_reason => undef );
  my $data = eval { $self->_json->decode($resp_body) };
  return %parsed unless ref $data eq 'HASH';
  if ( $protocol_name eq 'openai' ) {
    $parsed{content}       = $data->{choices}[0]{message}{content} // '';
    $parsed{finish_reason} = $data->{choices}[0]{finish_reason};
  }
  elsif ( $protocol_name eq 'anthropic' ) {
    for my $b ( @{ $data->{content} || [] } ) {
      $parsed{content} .= $b->{text} // '' if ($b->{type} // '') eq 'text';
    }
    $parsed{finish_reason} = $data->{stop_reason};
  }
  elsif ( $protocol_name eq 'ollama' ) {
    $parsed{content}       = ( $generate ? $data->{response} : $data->{message}{content} ) // '';
    $parsed{finish_reason} = $data->{done_reason};
  }
  else {
    return %parsed;
  }
  $parsed{tool_calls} = [ Langertha::ToolCall->extract( $protocol_name, $data ) ];
  return %parsed;
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my $http_req = $self->_build_upstream_request( $request, 0 );
  my $resp = await $self->_upstream_request_f( request => $http_req );
  die "Passthrough upstream failed: " . $resp->status_line . "\n" unless $resp->is_success;
  return Langertha::Knarr::Response->new(
    $self->_parse_response( $request->protocol, $resp->decoded_content,
      $self->_is_ollama_generate($request) ),
    model => $request->model // $self->model_id,
  );
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $http_req = $self->_build_upstream_request( $request, 1 );

  my @queue;
  my $pending;
  my $finished = 0;
  my @error;
  my $buffer = '';

  my $deliver = sub {
    my ($v) = @_;
    if ( $pending ) { my $p = $pending; $pending = undef; $p->done($v) }
    else            { push @queue, $v }
  };

  # Streaming request: hand the body chunks straight back as deltas. The
  # upstream already speaks the same wire format the client requested, so
  # we forward bytes 1:1 by extracting just the text content from each
  # protocol-native chunk. The Knarr core then re-frames them via the
  # client-side protocol's format_stream_chunk — keeping symmetry even
  # when client and upstream use the same protocol.
  my $stream = Langertha::Knarr::Stream->new(
    source => sub {
      if ( @queue )    { return Future->done( shift @queue ) }
      if ( $finished ) { return $error[0] ? Future->fail(@error) : Future->done(undef) }
      $pending = Future->new;
      return $pending;
    },
  );

  my $proto_name = $request->protocol;
  my $generate   = $self->_is_ollama_generate($request);
  # The upstream's terminal reason, verbatim; the client-side protocol maps
  # it when it closes the stream (k18).
  my $note_finish = sub {
    my ($reason) = @_;
    $stream->finish_reason($reason) if defined $reason && length $reason;
  };
  # The upstream's tool calls, assembled into complete Langertha::ToolCall
  # objects: OpenAI delta.tool_calls fragments per index until the stream
  # ends, Anthropic tool_use blocks with their input_json_delta until
  # content_block_stop, Ollama message.tool_calls whole. The client-side
  # protocol frames them when it closes the stream (k19).
  my %openai_calls;
  my %anthropic_blocks;
  my $note_calls = sub {
    my @calls = @_;
    $stream->tool_calls( [ @{ $stream->tool_calls }, @calls ] ) if @calls;
  };
  my $finish_openai_calls = sub {
    return unless %openai_calls;
    my @raw = map { $openai_calls{$_} } sort { $a <=> $b } keys %openai_calls;
    %openai_calls = ();
    $note_calls->( Langertha::ToolCall->extract( 'openai',
      { choices => [ { message => { tool_calls => \@raw } } ] } ) );
  };
  my $extract_chunk = sub {
    my ($line) = @_;
    if ( $proto_name eq 'openai' || $proto_name eq 'anthropic' ) {
      return undef unless $line =~ /^data:\s*(.+)$/;
      my $payload = $1;
      return undef if $payload eq '[DONE]';
      my $d = eval { $self->_json->decode($payload) };
      return undef unless ref $d eq 'HASH';
      if ( $proto_name eq 'openai' ) {
        $note_finish->( $d->{choices}[0]{finish_reason} );
        my $frags = $d->{choices}[0]{delta}{tool_calls};
        for my $frag ( ref $frags eq 'ARRAY' ? @$frags : () ) {
          next unless ref $frag eq 'HASH';
          my $call = $openai_calls{ $frag->{index} // 0 } //=
            { id => '', type => 'function', function => { name => '', arguments => '' } };
          $call->{id} = $frag->{id} if defined $frag->{id} && length $frag->{id};
          my $fn = ref $frag->{function} eq 'HASH' ? $frag->{function} : {};
          $call->{function}{name} = $fn->{name} if defined $fn->{name} && length $fn->{name};
          $call->{function}{arguments} .= $fn->{arguments} // '';
        }
        return $d->{choices}[0]{delta}{content};
      } else {
        my $type = $d->{type} // '';
        $note_finish->( $d->{delta}{stop_reason} ) if $type eq 'message_delta';
        my $index = $d->{index} // 0;
        if ( $type eq 'content_block_start'
          && ref $d->{content_block} eq 'HASH'
          && ( $d->{content_block}{type} // '' ) eq 'tool_use' ) {
          $anthropic_blocks{$index} = { %{ $d->{content_block} }, json => '' };
          return undef;
        }
        if ( $type eq 'content_block_delta' && $anthropic_blocks{$index} ) {
          $anthropic_blocks{$index}{json} .= $d->{delta}{partial_json} // '';
          return undef;
        }
        if ( $type eq 'content_block_stop' && ( my $block = delete $anthropic_blocks{$index} ) ) {
          my $json = delete $block->{json};
          $block->{input} = $json if length $json;
          $note_calls->( grep { defined } Langertha::ToolCall->from_anthropic($block) );
          return undef;
        }
        return $d->{delta}{text} if $type eq 'content_block_delta';
        return undef;
      }
    }
    if ( $proto_name eq 'ollama' ) {
      my $d = eval { $self->_json->decode($line) };
      return undef unless ref $d eq 'HASH';
      $note_finish->( $d->{done_reason} ) if $d->{done};
      return $d->{response} if $generate;
      $note_calls->( Langertha::ToolCall->extract( 'ollama', $d ) );
      return $d->{message}{content};
    }
    return undef;
  };

  my $f = $self->_upstream_request_f(
    request => $http_req,
    on_header => sub {
      my ($r) = @_;
      return sub {
        my ($data) = @_;
        if ( !defined $data ) {
          $finish_openai_calls->();
          $finished = 1;
          $deliver->(undef);
          return;
        }
        $buffer .= $data;
        # Frame separator: blank line for SSE, single \n for NDJSON.
        my $sep = $proto_name eq 'ollama' ? qr/\n/ : qr/\n\n/;
        while ( $buffer =~ s/^(.*?)$sep//s ) {
          my $frame = $1;
          for my $line ( split /\n/, $frame ) {
            next unless length $line;
            my $delta = $extract_chunk->($line);
            $deliver->($delta) if defined $delta && length $delta;
          }
        }
      };
    },
  );
  # A read already waiting gets the failure itself (a timeout included,
  # k35), not an undef that would end the stream as if it were complete.
  # The whole failure, so a timeout keeps its category (k36).
  $f->on_fail( sub {
    @error = @_;
    $finished = 1;
    if ( $pending ) { my $p = $pending; $pending = undef; $p->fail(@error) }
  } );
  $f->retain;

  return $stream;
}

sub list_models {
  my ($self) = @_;
  return [ { id => $self->model_id, object => 'model' } ];
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Handler::Passthrough - Knarr handler that forwards requests verbatim to an upstream HTTP API

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    use Langertha::Knarr::Handler::Passthrough;

    my $handler = Langertha::Knarr::Handler::Passthrough->new(
        upstreams => {
            openai    => 'https://api.openai.com',
            anthropic => 'https://api.anthropic.com',
            ollama    => 'http://localhost:11434',
        },
    );

=head1 DESCRIPTION

Forwards the original wire-format request verbatim to a real upstream
API. The protocol's parser already turned the body into a
L<Langertha::Knarr::Request>; Passthrough rebuilds the upstream JSON
from C<$request-E<gt>raw> and re-POSTs it.

Both sync and streaming requests are supported. A sync answer carries
the upstream's text, its tool calls as L<Langertha::ToolCall> objects
and its finish reason (verbatim; the front-side protocol maps it). For
streaming, the
upstream's protocol-native chunks are extracted into plain text deltas,
the upstream's tool calls are assembled into complete
L<Langertha::ToolCall> objects on the stream's C<tool_calls>
which the front-side protocol then re-frames — keeping symmetry even
when client and upstream use the same protocol.

The client's auth headers go along as the protocol's parser captured them
in C<< $request->extra->{forward_headers} >>: C<Authorization> for OpenAI
and Ollama, C<x-api-key>, C<anthropic-version> and C<Authorization> for
Anthropic. L<Langertha::Knarr> takes its own proxy key out of them first
(see L<Langertha::Knarr/auth_token>). Each header line the client sent
reaches the upstream as a line of its own, in its order (see
L<Langertha::Knarr::Request/forward_header_pairs>). Under
L<Langertha::Knarr::PSGI> the PSGI server has already joined a header sent
twice into one value with C<, >, and that value goes on as one line.

This is the building block behind Knarr's classic "configure your API
keys once, point everything at me" use case.

=head2 upstreams

Required. HashRef mapping protocol name (C<openai>, C<anthropic>,
C<ollama>) to upstream base URL. The protocol's default chat path is
appended (C</v1/chat/completions>, C</v1/messages>, C</api/chat>); an
Ollama C</api/generate> request goes to the upstream's C</api/generate>,
here and on the raw passthrough of L<Langertha::Knarr>, and its answer is
read from C<response>.

=head2 default_auth

Optional. An C<Authorization> header value to inject when the client
didn't send one. Usually you let the client supply its own key.

=head2 model_id

Optional. Defaults to C<passthrough>.

=head2 timeout

=head2 stall_timeout

Upstream timeouts in seconds from L<Langertha::Knarr::Role::UpstreamHTTP>:
C<timeout> (default C<300>) is the total time of a non-streaming request,
C<stall_timeout> (default C<120>) the time a streaming one may go without
data. C<0> disables either. They also apply to the raw passthrough of
L<Langertha::Knarr> and L<Langertha::Knarr::PSGI>, which answer an expired
one with C<504> in the client protocol's error shape. When this handler
itself times out, its failure carries the category C<timeout> or
C<stall_timeout> through the handler chain, and the client gets the same
C<504> or stream error frame.

=head2 is_upstream_for

    my $same = $passthrough->is_upstream_for( 'anthropic', $engine->url );

True when C<$url> is the upstream configured for the protocol, as
L</same_upstream> compares them. L<Langertha::Knarr> uses it to send a
model discovered from that very upstream to the raw passthrough.

=head2 same_upstream

    my $same = Langertha::Knarr::Handler::Passthrough->same_upstream(
      'https://api.openai.com', 'https://api.openai.com/v1' );   # 1

True when both URLs name the same upstream: same scheme, host, port and
path, host case and default ports normalised, and a trailing C</v1> (the
API version an engine's base URL carries) ignored. A gateway serving
several providers under paths of one host
(C<https://gateway.example/gw/openai>, C<.../gw/groq>) is several upstreams.
Needs no instance; L<Langertha::Knarr::Router> calls it on the class.

=head2 serves_protocol

    next unless $passthrough->serves_protocol( $request->protocol );

True when this handler can forward a request of the given protocol: an
upstream is configured for it and the protocol has a known chat path
(C<openai>, C<anthropic>, C<ollama>). L<Langertha::Knarr> and
L<Langertha::Knarr::Handler::Router> only send a request to the passthrough
when this is true; any other request goes to the default engine instead.

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
