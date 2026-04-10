use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $handler = Langertha::Knarr::Handler::Code->new(
  code => sub {
    my ($s, $r) = @_;
    my $last = $r->messages->[-1] // {};
    return "echo: " . ( $last->{content} // '' );
  },
);

my $sb = Langertha::Knarr->new( handler => $handler, port => 0 );

# Load every default protocol
my $protos = $sb->_protocol_objects;
ok( scalar @$protos >= 6, 'all default protocols loaded' );
my %by_name = map { $_->protocol_name => $_ } @$protos;
for my $n (qw( openai anthropic ollama a2a acp agui )) {
  ok( $by_name{$n}, "$n protocol present" );
}

# Per-protocol: each must produce non-empty stream framing for a delta.
for my $name (qw( openai anthropic ollama a2a acp agui )) {
  my $proto = $by_name{$name};
  my $req_body;
  if ( $name eq 'openai' ) {
    $req_body = $json->encode({ model => 'm', messages => [ { role => 'user', content => 'hi' } ], stream => JSON::MaybeXS::true() });
  } elsif ( $name eq 'anthropic' ) {
    $req_body = $json->encode({ model => 'm', messages => [ { role => 'user', content => 'hi' } ], stream => JSON::MaybeXS::true() });
  } elsif ( $name eq 'ollama' ) {
    $req_body = $json->encode({ model => 'm', messages => [ { role => 'user', content => 'hi' } ] });
  } elsif ( $name eq 'a2a' ) {
    $req_body = $json->encode({
      jsonrpc => '2.0', id => 1, method => 'tasks/sendSubscribe',
      params => { id => 't1', message => { role => 'user', parts => [ { type => 'text', text => 'hi' } ] } },
    });
  } elsif ( $name eq 'acp' ) {
    $req_body = $json->encode({
      agent_name => 'm', mode => 'stream',
      input => [ { parts => [ { content_type => 'text/plain', content => 'hi' } ] } ],
    });
  } elsif ( $name eq 'agui' ) {
    $req_body = $json->encode({
      threadId => 'th1', runId => 'r1',
      messages => [ { role => 'user', content => 'hi' } ],
    });
  }

  my $fake_http = bless {}, 'TestFakeReq';
  sub TestFakeReq::header { undef }

  my $req = $proto->parse_chat_request( $fake_http, \$req_body );
  is( $req->protocol, $name, "$name: protocol stamped" );
  is( $req->stream, 1, "$name: stream flag detected" );

  my $open  = $proto->format_stream_open($req);
  my $chunk = $proto->format_stream_chunk('Hi', $req);
  my $close = $proto->format_stream_close($req);
  my $done  = $proto->format_stream_done($req);

  ok( length $chunk, "$name: stream chunk non-empty" );
  ok( $proto->stream_content_type, "$name: has stream content type" );
  if ( $name eq 'ollama' ) {
    is( $proto->stream_content_type, 'application/x-ndjson', 'ollama uses ndjson' );
  } else {
    is( $proto->stream_content_type, 'text/event-stream', "$name uses SSE" );
  }
  # Lifecycle frames may be empty for OpenAI/Ollama; chunk must always work.

  # Sync response path also works
  my $rh = $handler->handle_chat_f( $sb->session, $req )->get;
  my ($status, $headers, $body) = $proto->format_chat_response( $rh, $req );
  is( $status, 200, "$name: sync response 200" );
  ok( length $body, "$name: sync response body" );
}

done_testing;
