use strict;
use warnings;
use Test2::V0;

# Regression (k79), on top of k78's error shapes:
#  (1) a Perl die's "at /path/Module.pm line N." never reaches a client; the
#      full message stays in the log;
#  (2) a failure without a category in the middle of a stream is the
#      protocol's own error frame, not an "[error: ...]" text chunk;
#  (3) A2A answers an error with a JSON-RPC error object.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::MaybeXS;
use Log::Any::Adapter;

use Langertha::Knarr;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Stream;

my @logs;
Log::Any::Adapter->set( 'Capture', to => \@logs, log_level => 'trace' );

my $loop = IO::Async::Loop->new;

my $PATH_DIE = "kaboom at /srv/perl/lib/Langertha/Chat.pm line 123.\n";
my $PATH_RE  = qr{\.pm\b|\bline \d+|/srv/perl};

{
  package PathHandler;
  use Moose;
  use Future;
  with 'Langertha::Knarr::Handler';

  has loop => ( is => 'ro', required => 1 );

  # The user's text picks the behaviour.
  sub _text { my ($r) = @_; $r->messages->[-1]{content} }

  sub handle_chat_f {
    my ($self, $session, $request) = @_;
    return Future->fail($PATH_DIE) if _text($request) eq 'die';
    return Future->done( Langertha::Knarr::Response->new( content => 'fine', model => 'm' ) );
  }

  sub handle_stream_f {
    my ($self, $session, $request) = @_;
    my $text = _text($request);
    my $loop = $self->loop;
    return Future->done( Langertha::Knarr::Stream->from_callback( sub {
      my ($emit, $done, $fail) = @_;
      if    ( $text eq 'die' ) { $loop->later( sub { $fail->($PATH_DIE) } ) }
      elsif ( $text eq 'mid' ) { $emit->('a'); $loop->later( sub { $fail->("cut at /srv/perl/lib/X.pm line 9.\n") } ) }
      else                     { $loop->later( sub { $emit->('fine'); $done->() } ) }
    } ) );
  }

  sub list_models { [ { id => 'x', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

my $json  = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $knarr = Langertha::Knarr->new(
  handler => PathHandler->new( loop => $loop ),
  loop    => $loop,
  listen  => [ '127.0.0.1:0' ],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my %route = (
  openai    => '/v1/chat/completions',
  anthropic => '/v1/messages',
  ollama    => '/api/chat',
  a2a       => '/',
  acp       => '/runs',
  agui      => '/awp',
);

sub body_for {
  my ($proto, $text, $stream) = @_;
  my $t = $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
  return { openai => { model => 'x', messages => [ { role => 'user', content => $text } ], stream => $t },
    anthropic => { model => 'x', max_tokens => 5, messages => [ { role => 'user', content => $text } ], stream => $t },
    ollama    => { model => 'x', messages => [ { role => 'user', content => $text } ], stream => $t },
    a2a  => { jsonrpc => '2.0', id => 7, method => $stream ? 'tasks/sendSubscribe' : 'tasks/send',
              params => { id => 'task-1', message => { parts => [ { type => 'text', text => $text } ] } } },
    acp  => { agent_name => 'x', mode => $stream ? 'stream' : 'sync',
              input => [ { parts => [ { content_type => 'text/plain', content => $text } ] } ] },
    agui => { threadId => 't', runId => 'r', model => 'x', messages => [ { role => 'user', content => $text } ] },
  }->{$proto};
}

sub send_request {
  my ($transport, $proto, $text, $stream) = @_;
  my @h = ( 'Content-Type' => 'application/json' );
  my $body = $json->encode( body_for( $proto, $text, $stream ) );
  return $transport eq 'native'
    ? $http->do_request( request => HTTP::Request->new(
        POST => "http://127.0.0.1:$port$route{$proto}", \@h, $body ), timeout => 10 )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$route{$proto}", \@h, $body ) );
}

# (1) + (3): the answer of a failed request, sync and before the first chunk
for my $transport (qw( native psgi )) {
  for my $proto (qw( openai anthropic ollama a2a acp agui )) {
    for my $stream ( 0, 1 ) {
      next if $proto eq 'agui' && !$stream;
      my $label = "$transport $proto ".( $stream ? 'stream' : 'sync' );
      @logs = ();
      my $resp = send_request( $transport, $proto, 'die', $stream );
      is( $resp->code, 500, "$label: 500" );
      unlike( $resp->content, $PATH_RE, "$label: the client sees no Perl path or line" );
      like( $resp->content, qr/kaboom/, "$label: ... but the cause" );
      my $all = join "\n", map { $_->[2] // '' } @logs;
      like( $all, qr{kaboom at /srv/perl/lib/Langertha/Chat\.pm line 123}, "$label: the log has the full message" );

      if ( $proto eq 'a2a' ) {
        my $d = $json->decode( $resp->content );
        is( $d, hash {
          field jsonrpc => '2.0';
          field id      => 7;
          field error   => hash { field code => -32603; field message => match qr/kaboom/; etc };
          end;
        }, "$label: a JSON-RPC error object with the request's id" );
      }
    }
  }
}

# (2): a failure without a category after the first chunk, natively
{
  my %frame = (
    openai    => sub { my ($c) = @_; like( $c, qr/^data: \{"error":\{"message":"cut"\}\}$/m, 'openai: data: error object' ) },
    anthropic => sub { my ($c) = @_; like( $c, qr/^event: error\ndata: \{"error":\{"message":"cut","type":"api_error"\},"type":"error"\}$/m, 'anthropic: event: error' ) },
    ollama    => sub { my ($c) = @_; like( [ split /\n/, $c ]->[-1], qr/^\{"error":"cut"\}$/, 'ollama: {"error":...} is the last NDJSON line' ) },
    a2a       => sub { my ($c) = @_; like( $c, qr/^data: \{"error":\{"code":-32603,"data":\{"status":500\},"message":"cut"\},"id":7,"jsonrpc":"2\.0"\}$/m, 'a2a: JSON-RPC error event' ) },
    acp       => sub { my ($c) = @_; like( $c, qr/^event: run\.failed$/m, 'acp: event: run.failed' ); like( $c, qr/"code":"server_error"/, 'acp: error code' ) },
    agui      => sub { my ($c) = @_; like( $c, qr/"type":"RUN_ERROR"/, 'agui: RUN_ERROR event' ); unlike( $c, qr/RUN_FINISHED/, 'agui: no RUN_FINISHED after RUN_ERROR' ) },
  );
  for my $proto (qw( openai anthropic ollama a2a acp agui )) {
    @logs = ();
    my $resp = send_request( 'native', $proto, 'mid', 1 );
    is( $resp->code, 200, "native $proto mid-stream failure: the stream had started" );
    my $c = $resp->content;
    unlike( $c, qr/\[error:/, "native $proto: no [error: ...] text chunk" );
    unlike( $c, $PATH_RE, "native $proto: no Perl path in the frame" );
    $frame{$proto}->($c);
    unlike( $c, qr/\[DONE\]|message_stop|"done":true|run\.completed|RUN_FINISHED|"final":true/,
      "native $proto: the error frame ends the stream, no success end marker" )
      unless $proto eq 'a2a';
    my $all = join "\n", map { $_->[2] // '' } @logs;
    like( $all, qr{cut at /srv/perl/lib/X\.pm line 9}, "native $proto: the log has the full message" );
  }
}

# (2) under PSGI nothing is out yet: the failure is a status
for my $proto (qw( openai anthropic ollama a2a acp agui )) {
  my $resp = send_request( 'psgi', $proto, 'mid', 1 );
  is( $resp->code, 500, "psgi $proto mid-stream failure: 500" );
  unlike( $resp->content, $PATH_RE, "psgi $proto: no Perl path" );
}

subtest '_error_text: what a client may be told' => sub {
  my $t = \&Langertha::Knarr::_error_text;
  is( $t->("boom at /a/b/C.pm line 3.\n"), 'boom', 'at FILE line N.' );
  is( $t->("boom at /a/b/C.pm line 3, <\$fh> line 7.\n"), 'boom', '... with the handle' );
  is( $t->("boom at (eval 12) line 1.\n"), 'boom', '... in an eval' );
  is( $t->("Can't locate Foo/Bar.pm in \@INC (you may need to install the Foo::Bar module) (\@INC entries checked: /a /b) at /x/Y.pm line 4.\n"),
    "Can't locate Foo/Bar.pm in \@INC (you may need to install the Foo::Bar module)", 'the @INC list goes' );
  is( $t->("boom at /a/C.pm line 3.\n\tFoo::bar() called at /a/D.pm line 8\n\tmain::run() called at /a/E.pm line 1\n"),
    'boom', 'a confess stack goes' );
  is( $t->('failed to open /usr/lib/perl5/Foo.pm'), 'failed to open <file>', 'a remaining source path goes' );
  is( $t->("at /a/C.pm line 3.\n"), 'internal error', 'nothing left: internal error' );
  is( $t->('backend refused'), 'backend refused', 'a plain message stays' );
};

done_testing;
