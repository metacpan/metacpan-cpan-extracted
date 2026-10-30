package Langertha::Raider::MCP::HTTP;
# ABSTRACT: Internal JSON-RPC over MCP's streamable HTTP transport
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Future;
use HTTP::Request;
use JSON::MaybeXS ();
use Net::Async::HTTP;
use Scalar::Util qw( weaken );
use Langertha::Raider::ConnectCheck qw( connect_error );


has loop    => ( is => 'ro', required => 1 );
has url     => ( is => 'ro', isa => 'Str', required => 1 );
has headers => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

has protocol_version => ( is => 'rw', isa => 'Maybe[Str]' );
has on_notification  => ( is => 'ro', isa => 'Maybe[CodeRef]' );
has session_id       => ( is => 'rw', isa => 'Maybe[Str]' );

# One Net::Async::HTTP client, and one connection, per request: two
# connections that one client (0.50) opens at the same time to the same
# host can leave a request waiting forever, and a single connection would
# hold every call behind a slow one or an event stream left open. A tool
# call is rare enough for its own connection.
sub _do {
  my ( $self, %args ) = @_;
  my $http = Net::Async::HTTP->new(
    user_agent               => 'raider/'.$VERSION,
    max_connections_per_host => 1,
    pipeline                 => 0,
  );
  my $loop = $self->loop;
  $loop->add($http);
  my $f = $http->do_request(%args);
  $f->on_ready(sub { $loop->later(sub { $loop->remove($http) if $http->loop }) });
  return $f;
}

has _next_id  => ( is => 'rw', init_arg => undef, default => 0 );
has _inflight => ( is => 'ro', init_arg => undef, default => sub { {} } );
has _stopped  => ( is => 'rw', init_arg => undef, default => 0 );

sub _json { JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 ) }


sub start       { return }
sub stderr_tail { return }

# The configured headers (without the ones the transport sets itself), then
# the session id and the revision.
sub _headers {
  my ( $self, $method ) = @_;
  my %own = map { lc $_ => 1 } qw( Content-Type Accept Mcp-Session-Id MCP-Protocol-Version Connection );
  # Every request has a client and a connection of its own (_do).
  my @h = ( Connection => 'close' );
  push @h, map { $_ => $self->headers->{$_} } grep { !$own{ lc $_ } } sort keys %{ $self->headers };
  push @h, 'Mcp-Session-Id' => $self->session_id if defined $self->session_id;
  push @h, 'MCP-Protocol-Version' => $self->protocol_version
    if defined $self->protocol_version && $method ne 'initialize';
  return @h;
}

sub _request {
  my ( $self, $method, $message ) = @_;
  my $req = HTTP::Request->new( POST => $self->url, [
    'Content-Type' => 'application/json',
    'Accept'       => 'application/json, text/event-stream',
    $self->_headers($method),
  ] );
  $req->content($self->_json->encode($message));
  return $req;
}

# Holds a future until it is ready, so nothing in flight is lost.
sub _hold {
  my ( $self, $f ) = @_;
  my $key = "$f";
  $self->_inflight->{$key} = $f;
  weaken( my $weak = $self );
  $f->on_ready(sub { delete $weak->_inflight->{$key} if $weak });
  return $f;
}


sub request_f {
  my ( $self, $method, $params ) = @_;
  return Future->fail('MCP server connection is closed') if $self->_stopped;
  if (my $error = connect_error($self->url)) { return Future->fail($error) }
  my $id = $self->_next_id + 1;
  $self->_next_id($id);
  my $message = { jsonrpc => '2.0', id => $id, method => $method, ( defined $params ? ( params => $params ) : () ) };
  my $answer = $self->loop->new_future;
  my ( $sse, $buffer ) = ( 0, '' );
  weaken( my $weak = $self );
  my $http_f = $self->_do(
    request   => $self->_request($method, $message),
    on_header => sub {
      my ( $header ) = @_;
      if ($method eq 'initialize' && defined( my $sid = $header->header('Mcp-Session-Id') )) {
        $weak->session_id($sid) if $weak;
      }
      $sse = $header->is_success && ( $header->content_type // '' ) =~ m{\Atext/event-stream}i ? 1 : 0;
      return sub {
        return $header unless @_;
        return unless defined $_[0];
        if ($sse) {
          # Handled on the next loop turn: what an event starts (the
          # caller's next request, an answer to the server) must not run
          # inside the HTTP client's own read callback.
          $buffer .= $_[0];
          $weak->loop->later(sub { $weak->_sse_events(\$buffer, $id, $answer) if $weak }) if $weak;
        }
        else {
          $header->add_content($_[0]);
        }
        return;
      };
    },
  );
  $self->_hold($http_f);
  # Settled on a later loop turn too, after the events still queued.
  $http_f->on_ready(sub {
    my ( $f ) = @_;
    $self->loop->later(sub {
      return if $answer->is_ready;
      return $answer->fail('HTTP request failed: '.( split /\n/, ''.( $f->failure )[0] )[0]) if $f->is_failed;
      return $answer->fail('HTTP request cancelled') if $f->is_cancelled;
      my ( $res ) = $f->get;
      return $answer->fail($self->_http_error($res)) unless $res->is_success;
      return $answer->fail('the event stream ended without a response') if $sse;
      my $data = eval { $self->_json->decode($res->content) };
      my ( $msg ) = ref $data eq 'ARRAY' ? grep { ref $_ eq 'HASH' && ( $_->{id} // '' ) eq $id } @$data : ( $data );
      return $answer->fail('the answer is not a JSON-RPC response') unless ref $msg eq 'HASH';
      $self->_settle($answer, $msg);
    });
  });
  return $answer;
}

sub _http_error {
  my ( $self, $res ) = @_;
  my $body = $res->decoded_content // '';
  my ( $first ) = grep { /\S/ } split /\n/, $body;
  if (defined $first) {
    my $data = eval { $self->_json->decode($body) };
    $first = $data->{error}{message} if ref $data eq 'HASH' && ref $data->{error} eq 'HASH' && defined $data->{error}{message};
    $first = substr($first, 0, 200);
  }
  return 'HTTP '.$res->status_line.( defined $first ? ': '.$first : '' );
}

sub _settle {
  my ( $self, $f, $msg ) = @_;
  return if $f->is_ready;
  if (ref $msg->{error} eq 'HASH') {
    my $e = $msg->{error};
    return $f->fail('MCP error '.( $e->{code} // '?' ).': '.( $e->{message} // 'unknown error' ), mcp => $e);
  }
  return $f->done($msg->{result});
}

# Complete events of an event stream: the response to $id settles $answer,
# a request from the server is answered, everything else is ignored.
sub _sse_events {
  my ( $self, $buffer, $id, $answer ) = @_;
  $$buffer =~ s/\r\n?/\n/g;
  while ($$buffer =~ s/\A(.*?)\n\n//s) {
    my $event = $1;
    my $data = join "\n", map { s/\Adata: ?//r } grep { /\Adata:/ } split /\n/, $event;
    next unless length $data;
    my $msg = eval { $self->_json->decode($data) };
    for my $m (ref $msg eq 'ARRAY' ? @$msg : ( $msg )) {
      next unless ref $m eq 'HASH';
      if (defined $m->{method}) {
        if (defined $m->{id}) { $self->_answer_server($m) }
        elsif (my $cb = $self->on_notification) { eval { $cb->($m->{method}, $m->{params} // {}) } }
        next;
      }
      $self->_settle($answer, $m) if defined $m->{id} && $m->{id} eq $id;
    }
  }
  return;
}

sub _answer_server {
  my ( $self, $m ) = @_;
  my $reply = { jsonrpc => '2.0', id => $m->{id},
    ( $m->{method} eq 'ping' ? ( result => {} ) : ( error => { code => -32601, message => 'Method not found: '.$m->{method} } ) ) };
  $self->_hold($self->_do( request => $self->_request(q(), $reply) )->else_done);
  return;
}


sub notify_f {
  my ( $self, $method, $params ) = @_;
  return Future->done if $self->_stopped || connect_error($self->url);
  my $message = { jsonrpc => '2.0', method => $method, ( defined $params ? ( params => $params ) : () ) };
  return $self->_hold($self->_do( request => $self->_request($method, $message) ))->then_done->else_done;
}


sub notify {
  my ( $self, @args ) = @_;
  $self->notify_f(@args);
  return;
}


sub stop_f {
  my ( $self ) = @_;
  return Future->done if $self->_stopped;
  $self->_stopped(1);
  $_->cancel for grep { !$_->is_ready } values %{ $self->_inflight };
  return Future->done unless defined $self->session_id && !connect_error($self->url);
  my $req = HTTP::Request->new( DELETE => $self->url, [ $self->_headers('DELETE') ] );
  return $self->_do( request => $req, timeout => 2 )->then_done->else_done;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::MCP::HTTP - Internal JSON-RPC over MCP's streamable HTTP transport

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $wire = Langertha::Raider::MCP::HTTP->new(
      loop    => $loop,
      url     => 'https://mcp.example.com/mcp',
      headers => { Authorization => 'Bearer ...' },
    );
    my $init = await $wire->request_f( 'initialize', { ... } );
    $wire->protocol_version( $init->{protocolVersion} );
    await $wire->notify_f( 'notifications/initialized' );
    await $wire->stop_f;

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The streamable HTTP transport of MCP (revisions 2025-03-26 and later, ADR
0029 E<sect>10): every message is a C<POST> of one JSON-RPC message to
L</url> with C<Accept: application/json, text/event-stream>; the answer is
either a JSON body or an event stream (C<text/event-stream>) whose C<data:>
lines carry JSON-RPC messages until the response to the request arrives. The
C<Mcp-Session-Id> a server hands out with the C<initialize> response is
sent with every later request, and so is C<MCP-Protocol-Version> once
L</protocol_version> is set. L</stop_f> ends the session with a C<DELETE>.
Requests the server sends inside an event stream are answered with a
C<POST> (C<ping> with an empty result, everything else "Method not found");
notifications are ignored. No standalone C<GET> stream is opened.

Written for raider because the installed L<Net::Async::MCP::Transport::HTTP>
speaks only the 2026-07-28 revision: it never sends C<Mcp-Session-Id> and
always sends C<MCP-Protocol-Version: 2026-07-28>, which servers of the
earlier revisions refuse.

=head2 loop

The L<IO::Async::Loop>. Required.

=head2 url

The endpoint. Required.

=head2 headers

Headers sent with every request (C<Authorization>, ...). Default none.

=head2 protocol_version

The negotiated revision; once set, sent as C<MCP-Protocol-Version>.

=head2 on_notification

C<< sub { my ( $method, $params ) = @_; ... } >>, called for a notification
in the event stream of a request's answer (there is no standalone stream).
Optional.

=head2 session_id

The C<Mcp-Session-Id> the server handed out, or C<undef>.

=head2 start

Nothing to start: the first request connects. For the interface it shares
with L<Langertha::Raider::MCP::Stdio>.

=head2 stderr_tail

Empty: a remote server has no stderr here.

=head2 request_f

    my $result = await $wire->request_f( $method, \%params );

Sends a request; done with its C<result>, failed with C<MCP error CODE:
MESSAGE> (category C<mcp>) for a JSON-RPC error, with C<HTTP STATUS ...>
for an HTTP error, or when the module a connection needs does not load
(L<Langertha::Raider::ConnectCheck>).

=head2 notify_f

    await $wire->notify_f( 'notifications/initialized' );

Sends a notification; done whatever the server answers (C<202> is what it
should).

=head2 notify

L</notify_f> without waiting.

=head2 stop_f

Ends the session: cancels what is in flight, then a C<DELETE> with the
session id (when there is one; answer ignored, at most 2 seconds).

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::MCP::Server>

=item * L<Langertha::Raider::MCP::Stdio>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

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

L<https://raudssus.de/>

=cut
