use strict;
use warnings;
use Test2::V0;

BEGIN {
  eval { require Plack::Test; require HTTP::Request; require HTTP::Request::Common; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $sb = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Code->new(
    code => sub { 'psgi-said-hi' },
    stream_code => sub { my @p = ('a','b','c'); sub { @p ? shift @p : undef } },
  ),
  port => 0,
);

my $app = Langertha::Knarr::PSGI->new( knarr => $sb )->to_app;
my $test = Plack::Test->create($app);

# Non-streaming OpenAI
{
  my $res = $test->request(
    POST '/v1/chat/completions',
      Content_Type => 'application/json',
      Content => $json->encode({
        model => 'm',
        messages => [ { role => 'user', content => 'hi' } ],
      }),
  );
  is( $res->code, 200, 'psgi non-stream 200' );
  my $d = $json->decode($res->decoded_content);
  is( $d->{choices}[0]{message}{content}, 'psgi-said-hi', 'psgi content' );
}

# Buffered streaming OpenAI
{
  my $res = $test->request(
    POST '/v1/chat/completions',
      Content_Type => 'application/json',
      Content => $json->encode({
        model => 'm',
        messages => [ { role => 'user', content => 'hi' } ],
        stream => JSON::MaybeXS::true(),
      }),
  );
  is( $res->code, 200, 'psgi stream 200' );
  is( $res->header('Content-Type'), 'text/event-stream', 'SSE content type' );
  my $body = $res->decoded_content;
  like( $body, qr/"a"/, 'chunk a' );
  like( $body, qr/"b"/, 'chunk b' );
  like( $body, qr/"c"/, 'chunk c' );
  like( $body, qr/\[DONE\]/, 'done marker' );
}

# Models endpoint
{
  my $res = $test->request( GET '/v1/models' );
  is( $res->code, 200, 'models 200' );
  my $d = $json->decode($res->decoded_content);
  is( $d->{object}, 'list', 'list object' );
}

# Ollama buffered stream
{
  my $res = $test->request(
    POST '/api/chat',
      Content_Type => 'application/json',
      Content => $json->encode({
        model => 'm',
        messages => [ { role => 'user', content => 'hi' } ],
      }),
  );
  is( $res->code, 200, 'ollama 200' );
  is( $res->header('Content-Type'), 'application/x-ndjson', 'ndjson type' );
  my @lines = grep { length } split /\n/, $res->decoded_content;
  ok( scalar(@lines) >= 4, 'multiple ndjson lines (3 chunks + done)' );
}

done_testing;
