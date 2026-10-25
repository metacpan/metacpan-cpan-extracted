use strict;
use warnings;
use Test2::V0;

# Regression (k81): a request body that is not JSON answered 500 with the
# decoder's own text, and JSON that is no object (array, string, number,
# null) died on the dereference or was taken for an empty request. Now both
# are the client's mistake: 400 in the protocol's error shape, with a fixed
# text and none of the decoder's. A2A keeps its JSON-RPC parse error. Natively
# and under PSGI; the body is rejected before any handler runs.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::PSGI;

my $loop = IO::Async::Loop->new;
my $calls = 0;
{
  package BadJsonHandler;
  use Moose;
  use Future;
  with 'Langertha::Knarr::Handler';
  sub handle_chat_f {
    $calls++;
    return Future->done( Langertha::Knarr::Response->new( content => 'fine', model => 'm' ) );
  }
  sub list_models { [ { id => 'x', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

my $json  = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $knarr = Langertha::Knarr->new(
  handler => BadJsonHandler->new, loop => $loop, listen => [ '127.0.0.1:0' ],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

sub post {
  my ($transport, $path, $content) = @_;
  my @h = ( 'Content-Type' => 'application/json' );
  return $transport eq 'native'
    ? $http->do_request( request => HTTP::Request->new(
        POST => "http://127.0.0.1:$port$path", \@h, $content ), timeout => 10 )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $content ) );
}

my %path = (
  openai => '/v1/chat/completions', anthropic => '/v1/messages', ollama => '/api/chat',
  acp => '/runs', agui => '/awp',
);

# What a client of that protocol reads as the message.
my %message = (
  openai    => sub { $_[0]{error}{message} },
  anthropic => sub { ( $_[0]{error}{type} // '' ) eq 'invalid_request_error' ? $_[0]{error}{message} : undef },
  ollama    => sub { $_[0]{error} },
  acp       => sub { ( $_[0]{code} // '' ) eq 'invalid_input' ? $_[0]{message} : undef },
  agui      => sub { ( $_[0]{type} // '' ) eq 'RUN_ERROR' && ( $_[0]{code} // '' ) eq 'invalid_input' ? $_[0]{message} : undef },
);

my @cases = (
  [ 'not JSON'    => '{"model": ' ],
  [ 'garbage'     => 'this is not json' ],
  [ 'array'       => '[1,2]' ],
  [ 'string'      => '"hello"' ],
  [ 'number'      => '42' ],
  [ 'null'        => 'null' ],
  [ 'number zero' => '0' ],
);

for my $transport (qw( native psgi )) {
  for my $proto (qw( openai anthropic ollama acp agui )) {
    for my $case (@cases) {
      my ($what, $body) = @$case;
      my $label = "$transport $proto, $what";
      my $before = $calls;
      my $resp = post( $transport, $path{$proto}, $body );
      is( $resp->code, 400, "$label: 400" );
      my $d = eval { $json->decode( $resp->content ) };
      ok( ref $d eq 'HASH', "$label: the protocol's JSON error" ) or next;
      my $msg = $message{$proto}->($d);
      like( $msg, qr/\Arequest body (?:is not valid JSON|must be a JSON object)\z/, "$label: protocol shape, fixed text" );
      unlike( $resp->content, qr/malformed|offset|character|expected|JSON::|\bline \d|\.pm\b|Not a HASH/i,
        "$label: no decoder text" );
      is( $calls, $before, "$label: no handler ran" );
    }
  }

  # A2A keeps its JSON-RPC answer: bad JSON is -32700, a non-object -32600.
  for my $case ( [ 'not JSON' => '{"id": ', -32700 ], [ 'array' => '[1]', -32600 ], [ 'string' => '"x"', -32600 ],
    [ 'null' => 'null', -32600 ], [ 'number' => '42', -32600 ] ) {
    my ($what, $body, $code) = @$case;
    my $resp = post( $transport, '/', $body );
    is( $resp->code, 400, "$transport a2a, $what: 400" );
    my $d = eval { $json->decode( $resp->content ) } || {};
    is( $d->{error}{code}, $code, "$transport a2a, $what: JSON-RPC code $code" );
    unlike( $resp->content, qr/malformed|offset|JSON::|\.pm\b/i, "$transport a2a, $what: no decoder text" );
  }
}

# An empty body is still the empty object, as before.
{
  my $resp = post( 'native', $path{openai}, '' );
  isnt( $resp->code, 500, 'an empty body is no crash' );
}

done_testing;
