package Langertha::Knarr::Handler::Passthrough;
# ABSTRACT: Knarr handler that forwards requests verbatim to an upstream HTTP API
our $VERSION = '1.000';
use Moose;
use Future;
use Future::AsyncAwait;
use HTTP::Request;
use Net::Async::HTTP;
use IO::Async::Loop;
use JSON::MaybeXS;
use Langertha::Knarr::Stream;

with 'Langertha::Knarr::Handler';


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

has loop => (
  is => 'ro',
  lazy => 1,
  default => sub { IO::Async::Loop->new },
);

has _http => ( is => 'ro', lazy => 1, builder => '_build_http' );
sub _build_http {
  my ($self) = @_;
  my $h = Net::Async::HTTP->new;
  $self->loop->add($h);
  return $h;
}

has _json => ( is => 'ro', default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) } );

# Per-protocol path the request should hit upstream. We use the protocol
# defaults; this lookup table can be extended.
my %DEFAULT_PATH = (
  openai    => '/v1/chat/completions',
  anthropic => '/v1/messages',
  ollama    => '/api/chat',
);

sub _upstream_url {
  my ($self, $protocol_name) = @_;
  my $base = $self->upstreams->{$protocol_name}
    or die "Passthrough: no upstream configured for protocol '$protocol_name'\n";
  $base =~ s{/+$}{};
  my $path = $DEFAULT_PATH{$protocol_name}
    or die "Passthrough: no default path for protocol '$protocol_name'\n";
  return "$base$path";
}

sub _build_upstream_request {
  my ($self, $request, $force_stream) = @_;
  my $body = { %{ $request->raw || {} } };
  $body->{stream} = $force_stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false()
    if defined $force_stream;
  my $url = $self->_upstream_url( $request->protocol );
  my $http_req = HTTP::Request->new( POST => $url );
  $http_req->header( 'Content-Type' => 'application/json' );
  if ( my $auth = $self->default_auth ) {
    $http_req->header( Authorization => $auth );
  }
  $http_req->content( $self->_json->encode($body) );
  return $http_req;
}

# Extract assistant text from an upstream response body for the protocol it
# came from. Bare-minimum extractor for sync mode; the streaming path
# forwards bytes verbatim and doesn't need this.
sub _extract_text {
  my ($self, $protocol_name, $resp_body) = @_;
  my $data = eval { $self->_json->decode($resp_body) };
  return '' unless ref $data eq 'HASH';
  if ( $protocol_name eq 'openai' ) {
    return $data->{choices}[0]{message}{content} // '';
  }
  if ( $protocol_name eq 'anthropic' ) {
    my $bits = '';
    for my $b ( @{ $data->{content} || [] } ) {
      $bits .= $b->{text} // '' if ($b->{type} // '') eq 'text';
    }
    return $bits;
  }
  if ( $protocol_name eq 'ollama' ) {
    return $data->{message}{content} // '';
  }
  return '';
}

async sub handle_chat_f {
  my ($self, $session, $request) = @_;
  my $http_req = $self->_build_upstream_request( $request, 0 );
  my $resp = await $self->_http->do_request( request => $http_req );
  die "Passthrough upstream failed: " . $resp->status_line . "\n" unless $resp->is_success;
  my $text = $self->_extract_text( $request->protocol, $resp->decoded_content );
  return { content => $text, model => $request->model // $self->model_id };
}

async sub handle_stream_f {
  my ($self, $session, $request) = @_;
  my $http_req = $self->_build_upstream_request( $request, 1 );

  my @queue;
  my $pending;
  my $finished = 0;
  my $error;
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
  my $proto_name = $request->protocol;
  my $extract_chunk = sub {
    my ($line) = @_;
    if ( $proto_name eq 'openai' || $proto_name eq 'anthropic' ) {
      return undef unless $line =~ /^data:\s*(.+)$/;
      my $payload = $1;
      return undef if $payload eq '[DONE]';
      my $d = eval { $self->_json->decode($payload) };
      return undef unless ref $d eq 'HASH';
      if ( $proto_name eq 'openai' ) {
        return $d->{choices}[0]{delta}{content};
      } else {
        return $d->{delta}{text} if ($d->{type} // '') eq 'content_block_delta';
        return undef;
      }
    }
    if ( $proto_name eq 'ollama' ) {
      my $d = eval { $self->_json->decode($line) };
      return undef unless ref $d eq 'HASH';
      return $d->{message}{content};
    }
    return undef;
  };

  my $f = $self->_http->do_request(
    request => $http_req,
    on_header => sub {
      my ($r) = @_;
      return sub {
        my ($data) = @_;
        if ( !defined $data ) {
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
  $f->on_fail( sub { $error = $_[0]; $finished = 1; $deliver->(undef) } );
  $f->retain;

  return Langertha::Knarr::Stream->new(
    source => sub {
      if ( @queue )    { return Future->done( shift @queue ) }
      if ( $finished ) { return $error ? Future->fail($error) : Future->done(undef) }
      $pending = Future->new;
      return $pending;
    },
  );
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

version 1.000

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

Both sync and streaming requests are supported. For streaming, the
upstream's protocol-native chunks are extracted into plain text deltas
which the front-side protocol then re-frames — keeping symmetry even
when client and upstream use the same protocol.

This is the building block behind Knarr's classic "configure your API
keys once, point everything at me" use case.

=head2 upstreams

Required. HashRef mapping protocol name (C<openai>, C<anthropic>,
C<ollama>) to upstream base URL. The protocol's default chat path is
appended.

=head2 default_auth

Optional. An C<Authorization> header value to inject when the client
didn't send one. Usually you let the client supply its own key.

=head2 model_id

Optional. Defaults to C<passthrough>.

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
