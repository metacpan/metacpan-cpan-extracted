use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode);
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::RawBody;

# The OpenAI face forwards the client's body as the bytes it sent, with only `model` replaced.
# Decoding and re-encoding sorts every object's keys, and the chat template of a node renders
# tool definitions in the order they arrive: a re-encoded request is a different prompt.

my $with = \&Langertha::Skeid::Protocol::RawBody::with_top_level;

# --- the replacement, on bytes ---
{
  is($with->('{"model":"a","x":1}', model => 'b'), '{"model":"b","x":1}', 'the value is replaced');
  is($with->(qq({ "z" : [1,2] ,\n  "model"  :  "a" , "a":{"model":"inner"} }), model => 'b'),
    qq({ "z" : [1,2] ,\n  "model"  :  "b" , "a":{"model":"inner"} }),
    'order and whitespace stay, and a nested key of the same name is not the top-level one');
  is($with->('{"model":"a","m":"x","model":"c"}', model => 'b'), '{"model":"b","m":"x","model":"b"}',
    'a key spelled twice is replaced twice, so no parser can read a model the route did not see');
  is($with->('{"model":"a"}', model => 'b'), '{"model":"b"}', 'an escaped key is still the key');
  is($with->('{"t":"a \" } ] { [ , \\\\","model":"a"}', model => 'b'), '{"t":"a \" } ] { [ , \\\\","model":"b"}',
    'brackets, quotes and backslashes inside a string are text');
  is($with->('{"model":null,"n":-1.5e3,"b":true}', model => 'b'), '{"model":"b","n":-1.5e3,"b":true}',
    'a value that was not a string is replaced by one');
  is($with->('{"model":"a"}', model => qq(we"ird\\name)), '{"model":"we\"ird\\\\name"}', 'the new value is JSON-escaped');
  is($with->(encode('UTF-8', '{"t":"Grüße — 日本","model":"a"}'), model => 'b'),
    encode('UTF-8', '{"t":"Grüße — 日本","model":"b"}'), 'UTF-8 bytes pass through untouched');

  is($with->('{"x":1}', model => 'b'), undef, 'no such key: undef');
  is($with->('[{"model":"a"}]', model => 'b'), undef, 'not an object: undef');
  is($with->('{"model":"a"', model => 'b'), undef, 'cut off: undef');
  is($with->('{"model":"a"} trailing', model => 'b'), undef, 'trailing text: undef');
  is($with->('{"model" "a"}', model => 'b'), undef, 'no colon: undef');
  is($with->(undef, model => 'b'), undef, 'no body: undef');
  is($with->('{}', model => 'b'), undef, 'empty object: undef');
}

# --- integration: what the node receives ---
my @received;    # { path, body (bytes) }

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  push @received, { path => $c->req->url->path->to_string, body => $c->req->body };
  my $body = $c->req->json || {};
  if ($body->{stream}) {
    $c->res->headers->content_type('text/event-stream');
    $c->write(qq(data: {"id":"s","object":"chat.completion.chunk","model":"served-model","choices":[{"index":0,"delta":{"content":"hi"}}]}\n\n));
    $c->write("data: [DONE]\n\n");
    $c->finish;
    return;
  }
  $c->render(json => {
    id => 'c', object => 'chat.completion', model => ($body->{model} // ''),
    choices => [{ index => 0, message => { role => 'assistant', content => 'hi' }, finish_reason => 'stop' }],
    usage   => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 },
  });
});
$upstream->routes->post('/v1/embeddings' => sub {
  my ($c) = @_;
  push @received, { path => $c->req->url->path->to_string, body => $c->req->body };
  $c->render(json => {
    object => 'list', model => 'served-embed', data => [{ object => 'embedding', index => 0, embedding => [0.1] }],
    usage  => { prompt_tokens => 2, total_tokens => 2 },
  });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my @events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$upstream_port/v1", model => 'served-model', max_conns => 4);
$skeid->add_node(id => 'e1', url => "http://127.0.0.1:$upstream_port/v1", model => 'served-embed', max_conns => 4);
$skeid->set_model_alias('house',       { tiers => [{ model => 'served-model' }] });
$skeid->set_model_alias('house-embed', { tiers => [{ model => 'served-embed' }] });

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $proxy_port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

sub _post {
  my ($path, $bytes) = @_;
  my ($tx, $done);
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$proxy_port$path" => { 'Content-Type' => 'application/json' } => $bytes => sub {
    (undef, $tx) = @_;
    $done = 1;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start unless $done;
  Mojo::IOLoop->remove($guard);
  return $tx;
}

# A tool definition spelled the way clients spell it: type before function, name before
# description before parameters, a schema with type first -- every one of them out of
# alphabetical order -- plus spacing and non-ASCII text a re-encoder would also change.
my $tools = '[ {"type": "function", "function": {"name": "write_file", "description": "Schreibt eine Datei — ganz.",'
  . ' "parameters": {"type": "object", "properties": {"path": {"type": "string", "description": "Ziel"},'
  . ' "content": {"type": "string"}}, "required": ["path", "content"]}}} ]';

sub _chat {
  my ($model, %extra) = @_;
  my $more = join '', map { qq(, "$_": $extra{$_}) } sort keys %extra;
  return encode('UTF-8', qq({"model": "$model", "messages": [{"role": "user", "content": "hi"}], "tools": $tools$more}));
}

{
  @received = ();
  @events = ();
  my $sent = _chat('served-model');
  my $tx = _post('/v1/chat/completions', $sent);
  is($tx->res->code, 200, 'a chat request under the served name succeeds');
  is(scalar(@received), 1, 'and reaches the node once');
  is($received[0]{body}, $sent, 'as exactly the bytes the client sent');
  is($events[0]{model}, 'served-model', 'the usage event still names the model');
}

{
  @received = ();
  @events = ();
  my $tx = _post('/v1/chat/completions', _chat('house'));
  is($tx->res->code, 200, 'a chat request under an alias succeeds');
  is($received[0]{body}, _chat('served-model'), 'the node gets the same bytes with only the model replaced');
  is($events[0]{requested_model}, 'house', 'the usage event keeps the requested name');
  is($events[0]{model}, 'served-model', 'next to the served one');
}

{
  @received = ();
  my $tx = _post('/v1/chat/completions', _chat('house', stream => 'true'));
  is($tx->res->code, 200, 'a streamed chat request succeeds');
  like($tx->res->body, qr/\[DONE\]/, 'and the stream arrives');
  is($received[0]{body}, _chat('served-model', stream => 'true'), 'its body went upstream verbatim too');
}

{
  @received = ();
  my $sent = encode('UTF-8', '{"model": "allowed-nowhere", "messages": [], "model": "house"}');
  my $tx = _post('/v1/chat/completions', $sent);
  is($tx->res->code, 200, 'a body that names the model twice is routed on the one the decoder reads');
  is($received[0]{body}, '{"model": "served-model", "messages": [], "model": "served-model"}',
    'and the node sees the served model in both places');
}

{
  @received = ();
  my $sent = '{"input": ["zwei", "eins"], "model": "house-embed", "encoding_format": "float"}';
  my $tx = _post('/v1/embeddings', $sent);
  is($tx->res->code, 200, 'an embeddings request under an alias succeeds');
  is($received[0]{body}, '{"input": ["zwei", "eins"], "model": "served-embed", "encoding_format": "float"}',
    'and is forwarded verbatim with the model replaced');
}

{
  @received = ();
  my $sent = qq(\n {"messages": [], "model": "house"} \n);
  my $tx = _post('/v1/chat/completions', $sent);
  is($tx->res->code, 200, 'a body with whitespace around it is served');
  is($received[0]{body}, qq(\n {"messages": [], "model": "served-model"} \n), 'and keeps it');
}

# --- the translated faces: the body is new, the tool definitions are the client's ---
{
  my $encode = \&Langertha::Skeid::Protocol::RawBody::encode_with_schemas;
  my $schemas = \&Langertha::Skeid::Protocol::RawBody::tool_schemas;

  my $client = '{"tools":[{"name":"a","input_schema":{"type":"object","required":[],"properties":{}}},{"name":"b"}]}';
  is_deeply($schemas->($client, 'input_schema'), ['{"type":"object","required":[],"properties":{}}', undef],
    'one schema text per tool, undef where a tool has none');
  is($schemas->('{"x":1}', 'input_schema'), undef, 'no tools: undef');
  is($schemas->('{"tools":{}}', 'input_schema'), undef, 'tools that are no array: undef');

  my $tool = sub { { type => 'function', function => { name => $_[0], description => 'd', parameters => $_[1] } } };
  my $body = { model => 'm', tools => [$tool->('a', { type => 'object', required => [], properties => {} })] };
  is($encode->($body, ['{"type":"object","required":[],"properties":{}}']),
    '{"model":"m","tools":[{"type":"function","function":{"name":"a","description":"d","parameters":{"type":"object","required":[],"properties":{}}}}]}',
    'the definition is spelled type, function, name, description, parameters -- the schema as the text');
  like($encode->($body, ['{"type":"object","required":["changed"],"properties":{}}']), qr/"parameters":\{"properties":\{\},"required":\[\],"type":"object"\}/,
    'a text that no longer says what the tool carries is not used');
  like($encode->($body, [undef]), qr/"parameters":\{"properties"/, 'nor is a missing one');
  is($encode->($body, []), undef, 'a tool count that does not match: undef');
  is($encode->({ model => 'm' }, []), undef, 'no tools: undef');
  is($encode->({ tools => [$tool->('a', {})] }, ['{}']), '{"tools":[{"type":"function","function":{"name":"a","description":"d","parameters":{}}}]}',
    'a body of tools alone is still one object');
}

my $schema = '{"type": "object", "properties": {"path": {"type": "string", "description": "Ziel — Datei"},'
  . ' "content": {"type": "string"}}, "required": ["path", "content"]}';
my $spelled = '"tools":[{"type":"function","function":{"name":"write_file","description":"Schreibt.","parameters":' . $schema . '}}]';

for my $stream (0, 1) {
  @received = ();
  my $sent = encode('UTF-8', '{"model": "house", "max_tokens": 64, ' . ($stream ? '"stream": true, ' : '')
    . '"messages": [{"role": "user", "content": "hi"}],'
    . ' "tools": [{"name": "write_file", "description": "Schreibt.", "input_schema": ' . $schema . '}]}');
  my $tx = _post('/v1/messages', $sent);
  is($tx->res->code, 200, 'an Anthropic request with a tool succeeds' . ($stream ? ' (streamed)' : ''));
  my $got = $received[0]{body} // '';
  ok(index($got, encode('UTF-8', $spelled)) >= 0, 'its tool reaches the node spelled in wire order, the schema as the client wrote it')
    or diag($got);
  like($got, qr/"model":"served-model"/, 'in a body that names the served model');
}

{
  @received = ();
  my $sent = encode('UTF-8', '{"model": "house", "stream": false, "messages": [{"role": "user", "content": "hi"}],'
    . ' "tools": [{"type": "function", "function": {"name": "write_file", "description": "Schreibt.", "parameters": ' . $schema . '}}]}');
  my $tx = _post('/api/chat', $sent);
  is($tx->res->code, 200, 'an Ollama request with a tool succeeds');
  my $got = $received[0]{body} // '';
  ok(index($got, encode('UTF-8', $spelled)) >= 0, 'and its tool reaches the node the same way') or diag($got);
}

{
  @received = ();
  my $tx = _post('/v1/messages', '{"model": "house", "max_tokens": 8, "messages": [{"role": "user", "content": "hi"}]}');
  is($tx->res->code, 200, 'an Anthropic request without tools is served as before');
  unlike($received[0]{body}, qr/"tools"/, 'with no tools member invented');
}

done_testing;
