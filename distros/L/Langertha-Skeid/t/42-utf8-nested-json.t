use strict;
use warnings;
use utf8;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS ();
use Encode ();

binmode(Test::More->builder->$_, q{:encoding(UTF-8)}) for qw(output failure_output todo_output);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Anthropic;

# A JSON document nested inside another as a string -- tool_use.input becoming
# function.arguments, a structured tool_result becoming a tool message's content -- must be a
# CHARACTER string. The request body around it is byte-encoded exactly once, when Mojolicious
# sends it upstream; a nested string that is already UTF-8 bytes gets encoded a second time and
# "Köln" reaches the model as "KÃ¶ln" (skeid #33, the pattern core k252 fixed in Langertha).
# The mirror mistake -- decoding already-decoded text with a byte decoder -- mangles or drops
# the same text on the way back, so every path is driven both ways with Latin-1, CJK and an
# emoji outside the BMP.

my $CITY  = 'Köln';
my $TOKYO = '東京';
my $SUSHI = "\x{1F363}";
my $TEXT  = JSON::MaybeXS->new(utf8 => 0, canonical => 1);

# --- request_to_openai: the nested strings are characters ---
{
  my $out = Langertha::Skeid::Protocol::Anthropic->request_to_openai({
    model => 'm1',
    messages => [
      { role => 'assistant', content => [
        { type => 'tool_use', id => 'toolu_1', name => 'weather',
          input => { city => $CITY, other => "$TOKYO $SUSHI" } },
      ] },
      { role => 'user', content => [
        { type => 'tool_result', tool_use_id => 'toolu_1',
          content => [ { type => 'text', text => "Sonne in $CITY, $TOKYO $SUSHI" } ] },
      ] },
    ],
  });

  my $args = $out->{messages}[0]{tool_calls}[0]{function}{arguments};
  is_deeply $TEXT->decode($args), { city => $CITY, other => "$TOKYO $SUSHI" },
    'function.arguments decodes as characters back to the tool_use input';
  ok index($args, $CITY) >= 0, 'function.arguments holds "Köln" as characters';
  unlike $args, qr/K\x{C3}\x{B6}ln/, 'and not its UTF-8 bytes, which the body encoding would encode again';

  my $result = $out->{messages}[1]{content};
  ok index($result, "$TOKYO $SUSHI") >= 0, 'a structured tool_result is nested as characters';
  is_deeply $TEXT->decode($result),
    [ { type => 'text', text => "Sonne in $CITY, $TOKYO $SUSHI" } ],
    'and decodes back to the block array it came from';

  is Langertha::Skeid::Protocol::encode_json_safe({ city => $CITY }),
    Encode::encode_utf8(qq{{"city":"$CITY"}}),
    'encode_json_safe stays a byte encoder: it frames whole SSE/NDJSON lines, sent as-is';
}

# --- end-to-end through the proxy and a mock upstream ---

my @upstream_bodies;
my $mode = 'json';

sub sse_chunk { return 'data: ' . JSON::MaybeXS::encode_json($_[0]) . "\n\n" }

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  # Decoded from the bytes on the wire, the way a real upstream reads them.
  push @upstream_bodies, JSON::MaybeXS::decode_json($c->req->body);

  if ($mode eq 'json') {
    return $c->render(json => {
      id => 'chatcmpl-u', object => 'chat.completion', model => 'm1',
      choices => [{
        index => 0,
        message => {
          role => 'assistant', content => "Wetter in $CITY",
          tool_calls => [{
            id => 'call_1', type => 'function',
            function => { name => 'weather', arguments => $TEXT->encode({ city => "$TOKYO $SUSHI" }) },
          }],
        },
        finish_reason => 'tool_calls',
      }],
      usage => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 },
    });
  }

  if ($mode eq 'hermes') {
    return $c->render(json => {
      id => 'chatcmpl-h', object => 'chat.completion', model => 'm1',
      choices => [{
        index => 0,
        message => {
          role => 'assistant',
          content => '<tool_call>' . $TEXT->encode({ name => 'weather', arguments => { city => $CITY } }) . '</tool_call>',
        },
        finish_reason => 'stop',
      }],
      usage => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 },
    });
  }

  # stream: text in one delta, tool arguments split across two
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  my $full = $TEXT->encode({ city => "$TOKYO $SUSHI" });
  my $cut  = int(length($full) / 2);
  $c->write_chunk(sse_chunk({ id => 's1', choices => [{ index => 0, delta => { role => 'assistant', content => "Hallo $CITY $SUSHI" } }] }));
  $c->write_chunk(sse_chunk({ id => 's1', choices => [{ index => 0, delta => { tool_calls => [{ index => 0, id => 'call_s', type => 'function',
    function => { name => 'weather', arguments => substr($full, 0, $cut) } }] } }] }));
  $c->write_chunk(sse_chunk({ id => 's1', choices => [{ index => 0, delta => { tool_calls => [{ index => 0,
    function => { arguments => substr($full, $cut) } }] } }] }));
  $c->write_chunk(sse_chunk({ id => 's1', choices => [{ index => 0, delta => {}, finish_reason => 'tool_calls' }],
    usage => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 } }));
  $c->write_chunk("data: [DONE]\n\n");
  $c->write_chunk('' => sub { $c->finish });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$upstream_port/v1", model => 'm1', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

sub post_json {
  my ($path, $payload) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port$path" => json => $payload => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

my $anthropic_request = {
  model => 'm1', max_tokens => 64,
  messages => [
    { role => 'user', content => "Wetter in $CITY?" },
    { role => 'assistant', content => [
      { type => 'tool_use', id => 'toolu_1', name => 'weather', input => { city => $CITY } },
    ] },
    { role => 'user', content => [
      { type => 'tool_result', tool_use_id => 'toolu_1', content => [ { type => 'text', text => "$TOKYO $SUSHI" } ] },
    ] },
  ],
};

# --- Anthropic, non-streamed: request up, response down ---
{
  @upstream_bodies = ();
  $mode = 'json';
  my $res = post_json('/v1/messages', $anthropic_request);
  is $res->code, 200, 'Anthropic request with non-ASCII tool traffic is served';

  my $up = $upstream_bodies[0];
  is $up->{messages}[0]{content}, "Wetter in $CITY?", 'plain text reaches the upstream intact';
  my $args = $up->{messages}[1]{tool_calls}[0]{function}{arguments};
  is_deeply $TEXT->decode($args), { city => $CITY },
    'function.arguments reaches the upstream as "Köln", not "KÃ¶ln"';
  is_deeply $TEXT->decode($up->{messages}[2]{content}), [ { type => 'text', text => "$TOKYO $SUSHI" } ],
    'the structured tool_result reaches the upstream with its CJK and emoji intact';

  my $body = $res->json;
  my ($text)  = grep { $_->{type} eq 'text' } @{ $body->{content} };
  my ($tool)  = grep { $_->{type} eq 'tool_use' } @{ $body->{content} };
  is $text->{text}, "Wetter in $CITY", 'the response text reaches the Anthropic client intact';
  is_deeply $tool->{input}, { city => "$TOKYO $SUSHI" }, 'upstream tool arguments become tool_use.input intact';
}

# --- Ollama, non-streamed ---
{
  @upstream_bodies = ();
  $mode = 'json';
  my $res = post_json('/api/chat', {
    model => 'm1', stream => JSON::MaybeXS::false,
    messages => [ { role => 'user', content => "Wetter in $CITY? $SUSHI" } ],
  });
  is $res->code, 200, 'Ollama request is served';
  is $upstream_bodies[0]{messages}[0]{content}, "Wetter in $CITY? $SUSHI", 'Ollama text reaches the upstream intact';

  my $body = $res->json;
  is $body->{message}{content}, "Wetter in $CITY", 'Ollama response text intact';
  is_deeply $body->{message}{tool_calls}[0]{function}{arguments}, { city => "$TOKYO $SUSHI" },
    'Ollama tool_calls arguments intact';
}

# --- OpenAI face: passthrough both ways ---
{
  @upstream_bodies = ();
  $mode = 'json';
  my $res = post_json('/v1/chat/completions', {
    model => 'm1',
    messages => [
      { role => 'assistant', content => '', tool_calls => [
        { id => 'call_0', type => 'function', function => { name => 'weather', arguments => $TEXT->encode({ city => $CITY }) } },
      ] },
      { role => 'tool', tool_call_id => 'call_0', content => "$TOKYO $SUSHI" },
    ],
  });
  is $res->code, 200, 'OpenAI request is served';
  my $up = $upstream_bodies[0];
  is_deeply $TEXT->decode($up->{messages}[0]{tool_calls}[0]{function}{arguments}), { city => $CITY },
    'OpenAI-face arguments pass through un-reencoded';
  is $up->{messages}[1]{content}, "$TOKYO $SUSHI", 'OpenAI-face tool content passes through intact';

  my $args = $res->json->{choices}[0]{message}{tool_calls}[0]{function}{arguments};
  is_deeply $TEXT->decode($args), { city => "$TOKYO $SUSHI" }, 'OpenAI-face response arguments intact';
}

# --- Anthropic stream: text deltas and split argument deltas ---
{
  $mode = 'stream';
  my $res = post_json('/v1/messages', { %$anthropic_request, stream => JSON::MaybeXS::true });
  is $res->code, 200, 'Anthropic stream is served';

  my (@text, $partial);
  for my $frame (split /\n\n/, $res->body) {
    my ($data) = $frame =~ /^data:\s*(.+)$/m or next;
    my $event = JSON::MaybeXS::decode_json($data);   # the wire is UTF-8 bytes
    next unless ($event->{type} // '') eq 'content_block_delta';
    push @text, $event->{delta}{text} if $event->{delta}{type} eq 'text_delta';
    $partial .= $event->{delta}{partial_json} if $event->{delta}{type} eq 'input_json_delta';
  }
  is join('', @text), "Hallo $CITY $SUSHI", 'streamed text reaches the Anthropic client intact';
  is_deeply $TEXT->decode($partial // ''), { city => "$TOKYO $SUSHI" },
    'the partial_json pieces reassemble to the upstream arguments intact';
}

# --- Ollama stream: NDJSON lines ---
{
  $mode = 'stream';
  my $res = post_json('/api/chat', { model => 'm1', messages => [ { role => 'user', content => $CITY } ] });
  is $res->code, 200, 'Ollama stream is served';
  my @lines = map { JSON::MaybeXS::decode_json($_) } grep { length } split /\n/, $res->body;
  is join('', map { $_->{message}{content} // '' } @lines), "Hallo $CITY $SUSHI",
    'streamed NDJSON text reaches the Ollama client intact';
}

# --- Hermes calls recovered from text ---
SKIP: {
  # Recovering a <tool_call> block from text is Langertha's job; before core k252 it ran the
  # decoded text through a byte decoder and a non-ASCII call vanished. Skeid only relays it.
  require Langertha::Role::JSON;
  skip 'Langertha without k252 decodes Hermes tool calls as bytes', 2
    unless Langertha::Role::JSON->can('encode_json_text');
  $mode = 'hermes';
  my $res = post_json('/v1/messages', $anthropic_request);
  my ($tool) = grep { $_->{type} eq 'tool_use' } @{ $res->json->{content} // [] };
  ok $tool, 'a Hermes tool call with non-ASCII arguments is recovered';
  is_deeply $tool && $tool->{input}, { city => $CITY }, 'with its arguments intact';
}

done_testing;
