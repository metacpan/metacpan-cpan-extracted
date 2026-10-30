package Test::Raider::MCPHTTP;
# ABSTRACT: A streamable-HTTP MCP server (revision 2025-06-18) on 127.0.0.1, run by an IO::Async loop

use strict;
use warnings;
use IO::Async::Listener;
use JSON::MaybeXS ();

=head1 SYNOPSIS

    my $srv = Test::Raider::MCPHTTP->new( loop => $loop, sse => 1 );
    my $url = $srv->url;              # http://127.0.0.1:PORT/mcp
    my @req = $srv->requests;         # { method, headers => { lc name => value }, body => {...} }

=head1 DESCRIPTION

Speaks MCP's streamable HTTP as a server of the revision 2025-06-18 does:
C<initialize> answers with C<Mcp-Session-Id: sess-1>; every later request
must carry that session id and C<MCP-Protocol-Version: 2025-06-18>, else
C<400>. Notifications get C<202>, C<DELETE> C<200>. With C<sse> the answers
come as an event stream (a C<ping> request from the server first, then the
response), else as a JSON body. Tools: C<echo_header> (returns the request
header named by C<name>) and C<hello>. Every response closes the
connection.

=cut

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub new {
  my ( $class, %arg ) = @_;
  my $self = bless { loop => $arg{loop}, sse => $arg{sse}, requests => [] }, $class;
  my $listener = IO::Async::Listener->new(
    on_stream => sub {
      my ( undef, $stream ) = @_;
      $stream->configure(
        on_read => sub {
          my ( $s, $buffref, $eof ) = @_;
          return 0 unless $$buffref =~ /\r\n\r\n/;
          my ( $head, $rest ) = split /\r\n\r\n/, $$buffref, 2;
          my ( $line, @h ) = split /\r\n/, $head;
          my %headers = map { my ( $k, $v ) = split /:\s*/, $_, 2; ( lc $k => $v ) } @h;
          my $len = $headers{'content-length'} // 0;
          return 0 if length($rest) < $len;
          $$buffref = '';
          my ( $method ) = $line =~ /\A(\S+)/;
          my $body = $len ? eval { $json->decode(substr $rest, 0, $len) } : undef;
          push @{ $self->{requests} }, { method => $method, headers => \%headers, body => $body };
          $s->write($self->_answer($method, \%headers, $body));
          $s->close_when_empty;
          return 0;
        },
      );
      $self->{loop}->add($stream);
    },
  );
  $self->{loop}->add($listener);
  my $port = $listener->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )
    ->get->read_handle->sockport;
  @{$self}{qw( listener port )} = ( $listener, $port );
  return $self;
}

sub url      { 'http://127.0.0.1:'.$_[0]{port}.'/mcp' }
sub requests { @{ $_[0]{requests} } }

sub _http {
  my ( $status, $type, $body, @extra ) = @_;
  my %reason = ( 200 => 'OK', 202 => 'Accepted', 400 => 'Bad Request' );
  return join "\r\n", "HTTP/1.1 $status ".$reason{$status}, 'Content-Type: '.$type,
    'Content-Length: '.length($body), 'Connection: close', @extra, '', $body;
}

sub _answer {
  my ( $self, $method, $h, $body ) = @_;
  return _http(200, 'text/plain', 'bye') if $method eq 'DELETE';
  return _http(400, 'application/json', $json->encode({ jsonrpc => '2.0', error => { code => -32700, message => 'no body' } }))
    unless ref $body eq 'HASH';
  my $rpc = $body->{method} // '';
  if ($rpc ne 'initialize') {
    return _http(400, 'text/plain', 'Bad Request: missing session') unless ( $h->{'mcp-session-id'} // '' ) eq 'sess-1';
    return _http(400, 'text/plain', 'Bad Request: unsupported protocol version')
      unless ( $h->{'mcp-protocol-version'} // '' ) eq '2025-06-18';
  }
  return _http(202, 'text/plain', '') unless defined $body->{id} && length $rpc;    # a notification or a response
  my $result;
  if ($rpc eq 'initialize') {
    $result = { protocolVersion => '2025-06-18', capabilities => { tools => {} }, serverInfo => { name => 'http-test', version => '1' } };
  }
  elsif ($rpc eq 'tools/list') {
    $result = { tools => [
      { name => 'echo_header', description => 'A request header', inputSchema => { type => 'object', properties => { name => { type => 'string' } } } },
      { name => 'hello', description => 'Says hello', inputSchema => { type => 'object' } },
    ] };
  }
  elsif ($rpc eq 'tools/call') {
    my $name = $body->{params}{name} // '';
    my $text = $name eq 'hello' ? 'hello over http' : ( $h->{ lc( $body->{params}{arguments}{name} // '' ) } // '(none)' );
    $result = { content => [ { type => 'text', text => $text } ] };
  }
  my $msg = defined $result
    ? { jsonrpc => '2.0', id => $body->{id}, result => $result }
    : { jsonrpc => '2.0', id => $body->{id}, error => { code => -32601, message => 'Method not found' } };
  my @extra = $rpc eq 'initialize' ? ( 'Mcp-Session-Id: sess-1' ) : ();
  return _http(200, 'application/json', $json->encode($msg), @extra) unless $self->{sse};
  my $events = 'event: message'."\n".'data: '.$json->encode({ jsonrpc => '2.0', id => 'srv-1', method => 'ping' })."\n\n"
    .'event: message'."\n".'data: '.$json->encode($msg)."\n\n";
  return _http(200, 'text/event-stream', $events, @extra);
}

sub DESTROY {
  my ( $self ) = @_;
  my $l = $self->{listener} or return;
  eval { $l->loop->remove($l) } if $l->loop;
  return;
}

1;
