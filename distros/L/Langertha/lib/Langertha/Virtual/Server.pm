package Langertha::Virtual::Server;
# ABSTRACT: HTTP endpoint in front of a Langertha::Engine::Virtual
our $VERSION = '0.504';
use Moose;
use Carp qw( croak );
use Encode ();
use HTTP::Status ();
use IO::Select;
use IO::Socket::INET;
use JSON::MaybeXS ();
use POSIX ();
use Time::HiRes ();


has engine => (
  is       => 'ro',
  isa      => 'Langertha::Engine::Virtual',
  required => 1,
);


has port => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
);


has loop => (
  is        => 'ro',
  predicate => 'has_loop',
);


has debug => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has delay => (
  is      => 'ro',
  isa     => 'Num',
  default => 0,
);


has _listener => ( is => 'rw', init_arg => undef );
has _handle   => ( is => 'rw', init_arg => undef );
has _clients  => ( is => 'ro', init_arg => undef, default => sub { {} } );
has _json     => (
  is      => 'ro',
  default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) },
);

my $MAX_REQUEST = 16 * 1024 * 1024;

sub url {
  my ( $self ) = @_;
  my $listener = $self->_listener or croak ref($self).'->url: the server is not started';
  return 'http://127.0.0.1:'.$listener->sockport.'/v1';
}


sub start {
  my ( $self ) = @_;
  croak ref($self).'->start: already started' if $self->_listener;
  my $listener = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => $self->port, Listen => 16, ReuseAddr => 1,
  ) or croak ref($self).'->start: cannot listen on 127.0.0.1:'.$self->port.": $!";
  $listener->blocking(0);
  $self->_listener($listener);
  if ( $self->has_loop ) {
    require IO::Async::Handle;
    my $handle = IO::Async::Handle->new(
      read_handle   => $listener,
      on_read_ready => sub { $self->_accept },
    );
    $self->loop->add($handle);
    $self->_handle($handle);
  }
  return $self;
}


sub stop {
  my ( $self ) = @_;
  $self->_drop($_) for values %{ $self->_clients };
  if ( my $handle = $self->_handle ) {
    $self->loop->remove($handle);
    $self->_handle(undef);
  }
  if ( my $listener = $self->_listener ) {
    close $listener;
    $self->_listener(undef);
  }
  return;
}


sub DEMOLISH {
  local $@;
  eval { $_[0]->stop };
  return;
}

sub run {
  my ( $self, %opts ) = @_;
  croak ref($self).'->run: not started' unless $self->_listener;
  croak ref($self).'->run: the server is bound to a loop' if $self->has_loop;
  my $parent = $opts{parent};
  while (1) {
    last if defined $parent && getppid() != $parent;
    my $select = IO::Select->new( $self->_listener, map { $_->{socket} } values %{ $self->_clients } );
    for my $ready ( $select->can_read(1) ) {
      if ( $ready == $self->_listener ) { $self->_accept }
      else { $self->_read( $self->_clients->{ fileno $ready } ) }
    }
  }
  return;
}


sub spawn {
  my ( $class, @args ) = @_;
  my %args = @args;
  delete $args{loop};
  my $server = $class->new(%args);
  $server->start;
  my $url    = $server->url;
  my $parent = $$;
  my $pid    = fork // croak "$class->spawn: fork failed: $!";
  unless ($pid) {
    $SIG{TERM} = $SIG{INT} = sub { POSIX::_exit(0) };
    eval { $server->run( parent => $parent ) };
    POSIX::_exit(0);
  }
  $server->stop;
  return ( $pid, $url );
}


sub reap {
  my ( $class, $pid ) = @_;
  return unless $pid;
  kill 'TERM', $pid;
  waitpid $pid, 0;
  return;
}


sub _accept {
  my ( $self ) = @_;
  while ( my $socket = $self->_listener->accept ) {
    $socket->blocking(0);
    my $client = { socket => $socket, buffer => '' };
    if ( $self->has_loop ) {
      my $handle = IO::Async::Handle->new(
        read_handle   => $socket,
        on_read_ready => sub { $self->_read($client) },
      );
      $self->loop->add($handle);
      $client->{handle} = $handle;
    }
    $self->_clients->{ fileno $socket } = $client;
  }
  return;
}

sub _drop {
  my ( $self, $client ) = @_;
  return unless $client;
  delete $self->_clients->{ fileno $client->{socket} } if defined fileno $client->{socket};
  $self->loop->remove( $client->{handle} ) if $client->{handle} && $self->has_loop;
  close $client->{socket};
  return;
}

sub _read {
  my ( $self, $client ) = @_;
  my $count = sysread $client->{socket}, $client->{buffer}, 65536, length $client->{buffer};
  unless ($count) {
    return if !defined $count && ( $!{EAGAIN} || $!{EWOULDBLOCK} );
    return $self->_drop($client);
  }
  return if $client->{responding};
  my $request = $self->_parse( $client ) or return;
  $client->{responding} = 1;
  if ( ref $request eq 'HASH' ) {
    my $respond = sub { $self->_send( $client, $self->_route($request) ) };
    if ( $self->delay && $request->{path} =~ m{/chat/completions\z} ) {
      if ( $self->has_loop ) { $self->loop->watch_time( after => $self->delay, code => $respond ) }
      else { Time::HiRes::sleep( $self->delay ); $respond->() }
    }
    else { $respond->() }
  }
  else {
    $self->_send( $client, $request );
  }
  return;
}

# A parsed request (HashRef), a ready-made error response (ArrayRef) or
# nothing while the request is incomplete.
sub _parse {
  my ( $self, $client ) = @_;
  my $buffer = \$client->{buffer};
  my $end = index $$buffer, "\r\n\r\n";
  if ( $end < 0 ) {
    return $self->_error_response( 431, 'request header too large' ) if length $$buffer > 65536;
    return;
  }
  my ( $line, @header_lines ) = split /\r\n/, substr( $$buffer, 0, $end );
  my ( $method, $target ) = $line =~ m{\A([A-Z]+) (\S+) HTTP/1\.[01]\z}
    or return $self->_error_response( 400, 'malformed request line' );
  my %header = map { /\A([^:]+):\s*(.*)\z/ ? ( lc $1 => $2 ) : () } @header_lines;
  return $self->_error_response( 411, 'chunked request bodies are not supported' )
    if lc( $header{'transfer-encoding'} // '' ) =~ /chunked/;
  my $length = $header{'content-length'} // 0;
  return $self->_error_response( 400, 'malformed Content-Length' ) unless $length =~ /\A\d+\z/;
  return $self->_error_response( 413, 'request body too large' ) if $length > $MAX_REQUEST;
  return if length($$buffer) - $end - 4 < $length;
  my ( $path ) = $target =~ m{\A([^?]*)};
  return { method => $method, path => $path, body => substr( $$buffer, $end + 4, $length ) };
}

# A response is [ $status, \@headers, $body ] or, for server-sent events,
# [ $status, \@headers, undef, \@chunks ].
sub _route {
  my ( $self, $request ) = @_;
  my ( $method, $path ) = @{$request}{qw( method path )};
  ( my $route = $path ) =~ s{\A/v1(?=/)}{};
  if ( $route eq '/chat/completions' ) {
    return $self->_error_response( 405, "$method is not allowed on $path" ) unless $method eq 'POST';
    return $self->_chat($request);
  }
  if ( $route eq '/models' && $method eq 'GET' ) {
    return $self->_json_response( 200, {
      object => 'list',
      data   => [ map { { id => $_->{id}, object => 'model', created => 0, owned_by => 'virtual' } }
        @{ $self->engine->list_models( full => 1 ) } ],
    } );
  }
  if ( $self->debug && $path eq '/_virtual/requests' && $method eq 'GET' ) {
    return $self->_json_response( 200, {
      requests => $self->engine->requests,
      calls    => $self->engine->calls,
    } );
  }
  return $self->_error_response( 404, "no route for $method $path" );
}

sub _chat {
  my ( $self, $request ) = @_;
  my $body = eval { $self->_json->decode( $request->{body} ) };
  return $self->_error_response( 400, 'the request body is not a JSON object' ) unless ref $body eq 'HASH';
  my $reply = $self->engine->virtual_reply( $request->{method}, $request->{path}, $request->{body} );
  return $self->_error_response( $reply->{code}, $reply->{content} ) unless $reply->{code} == 200;
  return $body->{stream} ? $self->_sse_response( $reply->{content}, $body ) : $self->_json_response( 200, $reply->{content} );
}

sub _sse_response {
  my ( $self, $completion, $body ) = @_;
  my $events = $self->engine->virtual_stream_chunks( $completion,
    include_usage => ref $body->{stream_options} eq 'HASH' && $body->{stream_options}{include_usage} ? 1 : 0 );
  my @chunks = map { 'data: '.$self->_json->encode($_)."\n\n" } @$events;
  push @chunks, "data: [DONE]\n\n";
  return [ 200, [ 'Content-Type' => 'text/event-stream', 'Cache-Control' => 'no-cache' ], undef, \@chunks ];
}

sub _json_response {
  my ( $self, $status, $data ) = @_;
  return [ $status, [ 'Content-Type' => 'application/json' ], $self->_json->encode($data) ];
}

sub _error_response {
  my ( $self, $status, $message ) = @_;
  return $self->_json_response( $status, { error => {
    message => $message, type => $status >= 500 ? 'server_error' : 'invalid_request_error', code => $status,
  } } );
}

sub _send {
  my ( $self, $client, $response ) = @_;
  my ( $status, $headers, $body, $chunks ) = @$response;
  my $reason = HTTP::Status::status_message($status) // 'Unknown';
  $body = Encode::encode( 'UTF-8', $body ) if defined $body && Encode::is_utf8($body);
  my $head = "HTTP/1.1 $status $reason\r\n"
    .join( '', map { "$headers->[$_]: $headers->[$_ + 1]\r\n" } grep { !( $_ % 2 ) } 0 .. $#$headers )
    .( defined $body ? 'Content-Length: '.length($body)."\r\n" : '' )
    ."Connection: close\r\n\r\n";
  local $SIG{PIPE} = 'IGNORE';
  $self->_write( $client, $head.( $body // '' ).join( '', @{ $chunks // [] } ) );
  $self->_drop($client);
  return;
}

# Blocking write of a small buffer to a socket that is otherwise non-blocking.
sub _write {
  my ( $self, $client, $data ) = @_;
  my $socket = $client->{socket};
  my $offset = 0;
  my $select = IO::Select->new($socket);
  while ( $offset < length $data ) {
    my $written = syswrite $socket, $data, 65536, $offset;
    if ( defined $written ) { $offset += $written; next }
    return unless $!{EAGAIN} || $!{EWOULDBLOCK};
    $select->can_write(5) or return;
  }
  return 1;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Virtual::Server - HTTP endpoint in front of a Langertha::Engine::Virtual

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    use Langertha::Engine::Virtual;
    use Langertha::Engine::OpenAI;
    use Langertha::Virtual::Server;
    use Langertha::Virtual::Rules qw( answer tool after );

    my $engine = Langertha::Engine::Virtual->new(
      rules => [ 'Hello' => answer('Hi there!') ],
    );

    # In your own process, inside your event loop
    my $loop   = IO::Async::Loop->new;
    my $server = Langertha::Virtual::Server->new( engine => $engine, loop => $loop );
    $server->start;
    my $client = Langertha::Engine::OpenAI->new( url => $server->url, api_key => 'x' );
    my $text   = $loop->await( $client->simple_chat_f('Hello') );
    $server->stop;

    # In its own process, for programs that take an upstream URL
    my ( $pid, $url ) = Langertha::Virtual::Server->spawn( engine => $engine );
    system( 'some-program', '-o', "url=$url" );
    Langertha::Virtual::Server->reap($pid);

=head1 DESCRIPTION

Serves a L<Langertha::Engine::Virtual> over HTTP on C<127.0.0.1>, so a
program that reaches its upstream by URL (a gateway, a node, an agent with
C<url=...>) can run against a rule-driven engine without network or key. The
reply to each request comes from the engine's own rule evaluation
(L<Langertha::Engine::Virtual/virtual_reply>); this class only speaks HTTP.
The engine keeps the record (L<Langertha::Engine::Virtual/requests>).

Endpoints:

=over

=item * C<POST /v1/chat/completions> - an OpenAI chat completion with
C<tool_calls>, and C<usage> when the engine's reaction or
L<Langertha::Engine::Virtual/default_usage> gives one; with
C<< "stream": true >> the same reply as server-sent events
(C<chat.completion.chunk> events, then C<data: [DONE]>). The reply is
computed whole and then cut into events by
L<Langertha::Engine::Virtual/virtual_stream_chunks>: the text in pieces of
the engine's L<Langertha::Engine::Virtual/stream_chunk_size> characters, each
tool call as an opening fragment followed by its arguments in pieces, the
C<finish_reason>, and with C<< "stream_options": { "include_usage": true } >>
a last event with an empty C<choices> list and the C<usage>. All events go
out in one write.

=item * C<GET /v1/models> - the engine's model, in the OpenAI list format.

=item * C<GET /_virtual/requests> - only with L</debug>: C<< { requests =>
[...], calls => [...] } >> as the engine recorded them, which is how a test
reads them when the server runs in another process.

=item * anything else - C<404> with an OpenAI-style JSON error body.

=back

An L<error|Langertha::Virtual::Rules/error> reaction is the response with
its status and C<< { error => { message, type, code } } >>; a request no rule
answers is C<500>, a body that is not JSON C<400>. The Anthropic dialect
(C</v1/messages>) is not served.

The server is single-threaded and answers one request after another, closing
each connection. Two ways to run it: B<in your event loop> (give C<loop>, an
L<IO::Async::Loop>; the client must then also be asynchronous, a synchronous
call in the same process would wait for a server that cannot run), or B<in its
own process> with L</spawn>.

=head2 engine

The L<Langertha::Engine::Virtual> (or C<Mock>) that answers. Required.

=head2 port

The TCP port on C<127.0.0.1>; C<0> (the default) takes a free one, readable
from L</url> after L</start>.

=head2 loop

An L<IO::Async::Loop> to serve in. Without it, the server only runs through
L</run> or L</spawn>. L<IO::Async> is optional for Langertha; it is loaded
only when C<loop> is set.

=head2 debug

Serve C<GET /_virtual/requests>. Off by default.

=head2 delay

Seconds to wait before answering each chat request, so a client with a
timeout runs into it. Default C<0>. In L</run> and L</spawn> the wait blocks
the whole server; in a loop only that response waits.

=head2 url

    my $url = $server->url;   # http://127.0.0.1:PORT/v1

The base URL for C<url =E<gt> ...> of an engine or program, with C</v1> like
every OpenAI-dialect engine's. Croaks before L</start>.

=head2 start

Binds the listening socket (returns the server). With a C<loop> the server is
then served by it; otherwise call L</run>.

=head2 stop

Stops serving and closes the listening socket and every open connection.
Safe to call twice.

=head2 run

    $server->start->run;

Serves in a blocking loop until the process ends. With C<< parent => $pid >>
it also returns once that process is no longer the parent, so a spawned
server does not outlive a test that died. Croaks if the server has a C<loop>.

=head2 spawn

    my ( $pid, $url ) = Langertha::Virtual::Server->spawn( engine => $engine, debug => 1 );

Class method. Takes the constructor arguments (a C<loop> is ignored), binds
the port, forks, and serves from the child. Returns the child's pid and the
L</url>, ready to be connected to. The child works on its own copy of the
engine, so the parent's L<Langertha::Engine::Virtual/requests> stay empty: use
C<debug> and C<GET /_virtual/requests>. End it with L</reap>.

=head2 reap

    Langertha::Virtual::Server->reap($pid);

Class method. Ends a L</spawn>ed server and waits for it, so no zombie stays.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Virtual> - The engine and its rule language

=item * L<Langertha::Virtual::Rules> - C<answer>, C<tool>, C<tools>, C<after>, C<error>

=item * L<Langertha::Engine::OpenAI> - A client for the endpoint, with C<url =E<gt> $server-E<gt>url>

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
