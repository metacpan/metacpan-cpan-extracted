use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS qw(decode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Skeid makes one shape of upstream call and translates at the client edge (ADR 0001). For a
# stream that means rewriting OpenAI SSE into the client's own protocol -- which for Anthropic
# is an event protocol, not a sequence of deltas: the client is told a message began, a block
# opened, then the text, then that both closed, and it reads its token counts from the closing
# events. None of that exists in an OpenAI stream; it is synthesised at the right moments.

my @upstream_bodies;

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  push @upstream_bodies, ($c->req->json || {});

  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"role":"assistant"}}]}\n\n});
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"Hel"}}]}\n\n});
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"lo"}}]}\n\n});
  my $final = '{"id":"c1","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],'
            . '"usage":{"prompt_tokens":7,"completion_tokens":3,"total_tokens":10}}';
  $c->write_chunk("data: $final\n\n");
  $c->write_chunk(qq{data: [DONE]\n\n});
  $c->write_chunk('' => sub { $c->finish });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my @events;

# Builds an SSE "data: ..." frame from a Perl hashref. Used for upstream chunks whose
# arguments value is itself a JSON string -- encode_json handles all the inner quoting
# correctly, so the test never has to thread escape sequences through source.
sub sse_chunk { return "data: " . JSON::MaybeXS::encode_json($_[0]) . "\n\n" }

my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$upstream_port/v1", model => 'm1', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $proxy_port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

sub post_stream {
  my ($path, $payload) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$proxy_port$path" => json => $payload => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx;
}

# Parses an SSE body into [ [event, data], ... ]
sub sse_events {
  my ($body) = @_;
  my @out;
  for my $frame (split /\n\n/, ($body // '')) {
    my ($name) = $frame =~ /^event:\s*(\S+)/m;
    my ($data) = $frame =~ /^data:\s*(.+)$/m;
    next unless defined $name;
    push @out, [$name, ($data ? decode_json($data) : undef)];
  }
  return @out;
}

# --- Anthropic ---
{
  @upstream_bodies = ();
  @events = ();
  my $tx = post_stream('/v1/messages', {
    model      => 'm1',
    max_tokens => 64,
    stream     => JSON::MaybeXS::true,
    messages   => [{ role => 'user', content => 'hi' }],
  });

  is $tx->res->code, 200, 'a streaming Anthropic request is served, not refused with 501';
  like $tx->res->headers->content_type, qr{text/event-stream}, 'as SSE';
  is $tx->res->headers->header('x-skeid-node'), 'n1', 'from the routed node';

  ok $upstream_bodies[0]{stream}, 'the upstream was asked to stream';
  ok $upstream_bodies[0]{stream_options}{include_usage},
    'with include_usage, because an Anthropic client reads token counts from message_delta and '
    . 'an OpenAI stream omits usage unless asked';

  my @got = sse_events($tx->res->body);
  my @names = map { $_->[0] } @got;
  is_deeply \@names,
    [qw(message_start content_block_start content_block_delta content_block_delta
        content_block_stop message_delta message_stop)],
    'the client sees a complete, correctly ordered Anthropic event sequence';

  my ($start) = grep { $_->[0] eq 'message_start' } @got;
  is $start->[1]{message}{role}, 'assistant', 'message_start names the role';
  is $start->[1]{message}{model}, 'm1', 'and the model the client asked for';

  my @deltas = grep { $_->[0] eq 'content_block_delta' } @got;
  is join('', map { $_->[1]{delta}{text} } @deltas), 'Hello',
    'the text arrives intact across chunks';
  is $deltas[0][1]{delta}{type}, 'text_delta', 'as text_delta, which is what a client dispatches on';

  my ($mdelta) = grep { $_->[0] eq 'message_delta' } @got;
  is $mdelta->[1]{delta}{stop_reason}, 'end_turn', "OpenAI's stop becomes Anthropic's end_turn";
  is $mdelta->[1]{usage}{output_tokens}, 3,
    'and the token count reaches the client, which is the whole reason message_delta exists';

  unlike $tx->res->body, qr/\[DONE\]/,
    "OpenAI's [DONE] sentinel is not relayed -- it is not part of this protocol";
  unlike $tx->res->body, qr/"choices"/, 'and no OpenAI-shaped payload leaks through';

  is scalar(@events), 1, 'one usage event';
  is $events[0]{api_format}, 'anthropic', 'recorded under the format the client used';
  is $events[0]{output_tokens}, 3, 'with the tokens the stream carried';
  is $events[0]{input_tokens}, 7, 'and the prompt tokens, so a translated stream still bills';
}

# --- streamed tool_use: one tool call, arguments fully in the first chunk ---
# An OpenAI chunk can carry id+name+arguments together when the call is short enough that
# the whole JSON fits in one delta. The Anthropic client still has to see an opened block,
# a single input_json_delta carrying the full arguments, and a closed block -- otherwise
# Claude Code dispatches on nothing and assumes the model hung.
{
  my $single = Mojolicious->new;
  $single->log->level('fatal');
  $single->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    push @upstream_bodies, ($c->req->json || {});

    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"role":"assistant"}}]}\n\n});
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, id => 'call_1', type => 'function', function => {name => 'get_weather', arguments => '{"city":"Boston"}'}}]}}]}));
    my $final = '{"id":"c1","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}],'
              . '"usage":{"prompt_tokens":7,"completion_tokens":4,"total_tokens":11}}';
    $c->write_chunk("data: $final\n\n");
    $c->write_chunk(qq{data: [DONE]\n\n});
    $c->write_chunk('' => sub { $c->finish });
  });
  my $single_daemon = Mojo::Server::Daemon->new(app => $single, listen => ['http://127.0.0.1'], silent => 1);
  $single_daemon->start;
  my $single_port = $single_daemon->ports->[0];

  my $sskeid = Langertha::Skeid->new(route_wait_poll_ms => 5);
  $sskeid->add_node(id => 'sn1', url => "http://127.0.0.1:$single_port/v1", model => 'm1', max_conns => 2);
  my $sproxy = Langertha::Skeid::Proxy->build_app(skeid => $sskeid);
  $sproxy->log->level('fatal');
  my $spd = Mojo::Server::Daemon->new(app => $sproxy, listen => ['http://127.0.0.1'], silent => 1);
  $spd->start;
  my $sport = $spd->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$sport/v1/messages" => json => {
    model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  my @got = sse_events($tx->res->body);
  my @names = map { $_->[0] } @got;
  is_deeply \@names,
    [qw(message_start content_block_start content_block_delta content_block_stop message_delta message_stop)],
    'one tool call whose arguments arrive in a single chunk still produces a complete tool_use '
    . 'event sequence -- no missing events, no duplicated indices';

  my ($start_event) = grep { $_->[0] eq 'message_start' } @got;
  is $start_event->[1]{type}, 'message_start',
    'message_start carries type "message_start" in its data -- the SDKs dispatch on that field, '
    . 'not on the event line, and "message" there is a frame they ignore';
  is $start_event->[1]{message}{type}, 'message',
    'while the message object inside it is typed "message", as the API specifies';

  my ($tool_open) = grep { $_->[0] eq 'content_block_start' } @got;
  is $tool_open->[1]{index}, 0, 'the tool_use block opens at Anthropic index 0';
  is $tool_open->[1]{content_block}{type}, 'tool_use', 'typed tool_use, which is what a client dispatches on';
  is $tool_open->[1]{content_block}{id}, 'call_1', 'carries the upstream id verbatim';
  is $tool_open->[1]{content_block}{name}, 'get_weather', 'and the function name from the same chunk';
  is_deeply $tool_open->[1]{content_block}{input}, {},
    'and an empty input -- the arguments arrive via the input_json_delta, not in the start';

  my @tdeltas = grep { $_->[0] eq 'content_block_delta' } @got;
  is scalar(@tdeltas), 1, 'one input_json_delta for a one-chunk tool_call';
  is $tdeltas[0][1]{delta}{type}, 'input_json_delta', 'typed input_json_delta';
  is_deeply decode_json($tdeltas[0][1]{delta}{partial_json}), { city => 'Boston' },
    'the single partial_json carries the full arguments string -- which is what a non-streaming '
    . 'client would have parsed from input, just deferred to the delta';

  my ($tool_close) = grep { $_->[0] eq 'content_block_stop' } @got;
  is $tool_close->[1]{index}, 0,
    'content_block_stop closes the same index the tool_use opened -- an Anthropic client keys '
    . 'the close to its matching open, so a mismatch silently drops the call';

  my ($mdelta) = grep { $_->[0] eq 'message_delta' } @got;
  is $mdelta->[1]{delta}{stop_reason}, 'tool_use',
    "OpenAI's tool_calls finish_reason becomes Anthropic's tool_use -- the signal a client uses "
    . 'to keep the conversation going and dispatch the call';
  is $mdelta->[1]{usage}{output_tokens}, 4,
    'and the generated token count still reaches the client on this path';

  is $sskeid->node_metrics('sn1')->{inflight}, 0, 'no admission leaked on the tool_use path';
}

# --- streamed tool_use: arguments split across chunks ---
# Most real-world tool calls split the arguments across several chunks. The Anthropic client
# concatenates partial_jsons itself to reconstruct input; the translator must emit every
# piece separately and never lose one.
{
  my $split = Mojolicious->new;
  $split->log->level('fatal');
  $split->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    push @upstream_bodies, ($c->req->json || {});

    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"role":"assistant"}}]}\n\n});
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, id => 'call_1', type => 'function', function => {name => 'get_weather', arguments => ''}}]}}]}));
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, function => {arguments => '{"city":"Bos'}}]}}]}));
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, function => {arguments => "ton\"}"}}]}}]}));
    my $final = '{"id":"c1","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}],'
              . '"usage":{"prompt_tokens":7,"completion_tokens":4,"total_tokens":11}}';
    $c->write_chunk("data: $final\n\n");
    $c->write_chunk(qq{data: [DONE]\n\n});
    $c->write_chunk('' => sub { $c->finish });
  });
  my $split_daemon = Mojo::Server::Daemon->new(app => $split, listen => ['http://127.0.0.1'], silent => 1);
  $split_daemon->start;
  my $split_port = $split_daemon->ports->[0];

  my $pskeid = Langertha::Skeid->new(route_wait_poll_ms => 5);
  $pskeid->add_node(id => 'pn1', url => "http://127.0.0.1:$split_port/v1", model => 'm1', max_conns => 2);
  my $pproxy = Langertha::Skeid::Proxy->build_app(skeid => $pskeid);
  $pproxy->log->level('fatal');
  my $ppd = Mojo::Server::Daemon->new(app => $pproxy, listen => ['http://127.0.0.1'], silent => 1);
  $ppd->start;
  my $pport = $ppd->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$pport/v1/messages" => json => {
    model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  my @got = sse_events($tx->res->body);
  my @names = map { $_->[0] } @got;
  is_deeply \@names,
    [qw(message_start content_block_start content_block_delta content_block_delta content_block_stop message_delta message_stop)],
    'split arguments produce one input_json_delta per chunk, in order, with the same tool_use '
    . 'envelope around them';

  my ($tool_open) = grep { $_->[0] eq 'content_block_start' } @got;
  is $tool_open->[1]{index}, 0, 'the tool_use block still opens at index 0';
  is $tool_open->[1]{content_block}{id}, 'call_1', 'carrying the id from the opening chunk';
  is $tool_open->[1]{content_block}{name}, 'get_weather', 'and the name from the opening chunk';

  my @tdeltas = grep { $_->[0] eq 'content_block_delta' } @got;
  is scalar(@tdeltas), 2, 'two input_json_deltas -- one per arguments chunk';
  is_deeply [map { $_->[1]{delta}{type} } @tdeltas], ['input_json_delta', 'input_json_delta'],
    'and both are typed input_json_delta';

  # The contract is that concatenated partial_jsons reconstruct the arguments string. A client
  # that drops a piece parses broken JSON, so this is the assertion that proves nothing was
  # silently swallowed.
  my $joined = join('', map { $_->[1]{delta}{partial_json} } @tdeltas);
  is_deeply decode_json($joined), { city => 'Boston' },
    'the concatenated partial_jsons decode to the full arguments -- the client reassembles '
    . 'input this way itself, so any dropped chunk is a broken call';

  my ($tool_close) = grep { $_->[0] eq 'content_block_stop' } @got;
  is $tool_close->[1]{index}, 0, 'the close still matches the open index';

  my ($mdelta) = grep { $_->[0] eq 'message_delta' } @got;
  is $mdelta->[1]{delta}{stop_reason}, 'tool_use',
    'split arguments still finish with stop_reason=tool_use';
}

# --- streamed tool_use: text plus a tool call in one response ---
# Claude Code's most common shape: a one-line "I'll look that up" then a tool_use block.
# The Anthropic client expects the prose as a text block at index 0 and the call at index 1;
# mixing the indices up here is what makes the client's display lose either the prose or
# the tool's metadata.
{
  my $mixed = Mojolicious->new;
  $mixed->log->level('fatal');
  $mixed->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    push @upstream_bodies, ($c->req->json || {});

    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"role":"assistant"}}]}\n\n});
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"Looking it up."}}]}\n\n});
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, id => 'call_1', type => 'function', function => {name => 'get_weather', arguments => ''}}]}}]}));
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, function => {arguments => '{"city":"Boston"}'}}]}}]}));
    my $final = '{"id":"c1","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}],'
              . '"usage":{"prompt_tokens":7,"completion_tokens":6,"total_tokens":13}}';
    $c->write_chunk("data: $final\n\n");
    $c->write_chunk(qq{data: [DONE]\n\n});
    $c->write_chunk('' => sub { $c->finish });
  });
  my $mixed_daemon = Mojo::Server::Daemon->new(app => $mixed, listen => ['http://127.0.0.1'], silent => 1);
  $mixed_daemon->start;
  my $mixed_port = $mixed_daemon->ports->[0];

  my $mskeid = Langertha::Skeid->new(route_wait_poll_ms => 5);
  $mskeid->add_node(id => 'mn1', url => "http://127.0.0.1:$mixed_port/v1", model => 'm1', max_conns => 2);
  my $mproxy = Langertha::Skeid::Proxy->build_app(skeid => $mskeid);
  $mproxy->log->level('fatal');
  my $mpd = Mojo::Server::Daemon->new(app => $mproxy, listen => ['http://127.0.0.1'], silent => 1);
  $mpd->start;
  my $mport = $mpd->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$mport/v1/messages" => json => {
    model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  my @got = sse_events($tx->res->body);
  my @names = map { $_->[0] } @got;
  is_deeply \@names,
    [qw(message_start content_block_start content_block_delta content_block_start content_block_delta content_block_stop content_block_stop message_delta message_stop)],
    'text then tool_use produces text at index 0, tool_use at index 1, both opened and closed '
    . 'before message_delta -- the order an Anthropic client walks to render the message';

  my @opens = grep { $_->[0] eq 'content_block_start' } @got;
  is $opens[0][1]{index}, 0, 'text opens at index 0 because it arrives first';
  is $opens[0][1]{content_block}{type}, 'text', 'as a text block';
  is $opens[1][1]{index}, 1, 'tool_use opens at index 1 because it is the second block';
  is $opens[1][1]{content_block}{type}, 'tool_use', 'as a tool_use block';
  is $opens[1][1]{content_block}{name}, 'get_weather',
    'and the tool_use block carries the function name -- the field a client uses to dispatch';

  my @text_deltas = grep { $_->[0] eq 'content_block_delta' && $_->[1]{delta}{type} eq 'text_delta' } @got;
  is join('', map { $_->[1]{delta}{text} } @text_deltas), 'Looking it up.',
    'the prose survives intact through the same delta path it does on a text-only response';

  my @json_deltas = grep { $_->[0] eq 'content_block_delta' && $_->[1]{delta}{type} eq 'input_json_delta' } @got;
  is $json_deltas[0][1]{index}, 1, 'the input_json_delta lands at index 1, not 0 -- the client '
    . 'rebuilds input for block 1 and would silently misroute a misplaced delta';

  my @stops = grep { $_->[0] eq 'content_block_stop' } @got;
  is_deeply [map { $_->[1]{index} } @stops], [0, 1],
    'both blocks are closed -- an Anthropic client buffers the message until every open block '
    . 'has a stop, so a missing close holds the conversation in limbo';

  my ($mdelta) = grep { $_->[0] eq 'message_delta' } @got;
  is $mdelta->[1]{delta}{stop_reason}, 'tool_use',
    'a mixed text-plus-tool_use response still finishes with stop_reason=tool_use -- the text '
    . 'is preamble, the conversation continues on the tool dispatch';
}

# --- streamed tool_use: two tool calls in parallel ---
# An agent that fans out (search A and search B at the same time) produces two parallel
# tool_calls in one OpenAI stream. Anthropic numbers them by appearance order; the
# translator has to keep the two OpenAI tool_calls[i].index values mapped to two distinct
# Anthropic indices and never cross the deltas.
{
  my $parallel = Mojolicious->new;
  $parallel->log->level('fatal');
  $parallel->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    push @upstream_bodies, ($c->req->json || {});

    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"role":"assistant"}}]}\n\n});
    # First tool opens in its own chunk.
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, id => 'call_A', type => 'function', function => {name => 'search', arguments => ''}}]}}]}));
    # Second tool opens in the next chunk -- still in the same message, just later.
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 1, id => 'call_B', type => 'function', function => {name => 'lookup', arguments => ''}}]}}]}));
    # Then arguments arrive interleaved across both: one piece of A, one piece of B, the rest of A, the rest of B.
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, function => {arguments => '{"q":"Bos'}}]}}]}));
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 1, function => {arguments => '{"q":"Oak'}}]}}]}));
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 0, function => {arguments => "ton weather\"}"}}]}}]}));
    $c->write_chunk(sse_chunk({id => 'c1', choices => [{index => 0, delta => {tool_calls => [{index => 1, function => {arguments => "land events\"}"}}]}}]}));
    my $final = '{"id":"c1","choices":[{"index":0,"delta":{},"finish_reason":"tool_calls"}],'
              . '"usage":{"prompt_tokens":7,"completion_tokens":8,"total_tokens":15}}';
    $c->write_chunk("data: $final\n\n");
    $c->write_chunk(qq{data: [DONE]\n\n});
    $c->write_chunk('' => sub { $c->finish });
  });
  my $parallel_daemon = Mojo::Server::Daemon->new(app => $parallel, listen => ['http://127.0.0.1'], silent => 1);
  $parallel_daemon->start;
  my $parallel_port = $parallel_daemon->ports->[0];

  my $rlskeid = Langertha::Skeid->new(route_wait_poll_ms => 5);
  $rlskeid->add_node(id => 'rln1', url => "http://127.0.0.1:$parallel_port/v1", model => 'm1', max_conns => 2);
  my $rlproxy = Langertha::Skeid::Proxy->build_app(skeid => $rlskeid);
  $rlproxy->log->level('fatal');
  my $rlpd = Mojo::Server::Daemon->new(app => $rlproxy, listen => ['http://127.0.0.1'], silent => 1);
  $rlpd->start;
  my $rlport = $rlpd->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$rlport/v1/messages" => json => {
    model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  my @got = sse_events($tx->res->body);
  my @names = map { $_->[0] } @got;
  is_deeply \@names,
    [qw(message_start content_block_start content_block_start content_block_delta content_block_delta content_block_delta content_block_delta content_block_stop content_block_stop message_delta message_stop)],
    'two parallel tool calls open as two blocks and receive interleaved deltas in arrival order, '
    . 'then both close -- a fan-out agent cannot lose a tool this way';

  my @opens = grep { $_->[0] eq 'content_block_start' } @got;
  is_deeply [map { $_->[1]{index} } @opens], [0, 1],
    'the two tool_use blocks occupy Anthropic indices 0 and 1, in the order they first appeared';
  is_deeply [map { $_->[1]{content_block}{id} } @opens], ['call_A', 'call_B'],
    'and each Anthropic block carries the OpenAI id that opened it -- the client keys '
    . 'tool_result messages back to the right call by this id';
  is_deeply [map { $_->[1]{content_block}{name} } @opens], ['search', 'lookup'],
    'and the function names stay attached to the block that owns them, not cross-wired';

  my @json_deltas = grep { $_->[0] eq 'content_block_delta' && $_->[1]{delta}{type} eq 'input_json_delta' } @got;
  is scalar(@json_deltas), 4, 'four input_json_deltas -- one per arguments chunk in arrival order';

  # Group deltas by index: every delta for index 0 must reconstruct A's arguments, and every
  # delta for index 1 must reconstruct B's arguments. Crossing indices here means a client
  # dispatches the wrong tool with the wrong arguments.
  my %by_index;
  push @{$by_index{$_->[1]{index}}}, $_->[1]{delta}{partial_json} for @json_deltas;
  is_deeply decode_json(join('', @{$by_index{0}})), { q => 'Boston weather' },
    'all deltas for index 0 concatenate to A\'s full arguments -- partials for the same call '
    . 'must never end up split across calls';
  is_deeply decode_json(join('', @{$by_index{1}})), { q => 'Oakland events' },
    'and the parallel call\'s arguments are not crossed with A\'s -- a misroute would call '
    . 'search with Oakland\'s arguments or lookup with Boston\'s';

  my @stops = grep { $_->[0] eq 'content_block_stop' } @got;
  is_deeply [map { $_->[1]{index} } @stops], [0, 1],
    'both tool_use blocks are closed before message_delta -- a stop in the wrong order leaves '
    . 'a client waiting on the unclosed block';

  my ($mdelta) = grep { $_->[0] eq 'message_delta' } @got;
  is $mdelta->[1]{delta}{stop_reason}, 'tool_use',
    'parallel tool calls also finish with stop_reason=tool_use -- the conversation continues '
    . 'until every parallel call has been answered';
}

# --- Ollama ---
{
  @upstream_bodies = ();
  @events = ();
  my $tx = post_stream('/api/chat', {
    model    => 'm1',
    stream   => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  });

  is $tx->res->code, 200, 'a streaming Ollama request is served';
  like $tx->res->headers->content_type, qr{application/x-ndjson},
    'as newline-delimited JSON, not SSE -- relaying text/event-stream would tell an Ollama '
    . 'client to parse something it does not speak';

  my @lines = grep { length } split /\n/, ($tx->res->body // '');
  my @objs = map { decode_json($_) } @lines;
  ok scalar(@objs) >= 3, 'several lines, one per delta plus the closing one';

  is join('', map { $_->{message}{content} // '' } @objs), 'Hello', 'the text arrives intact';
  ok !$objs[0]{done}, 'the first line is not done';
  ok $objs[-1]{done}, 'and the last one is';
  is $objs[-1]{done_reason}, 'stop', 'carrying the reason';
  is $objs[-1]{prompt_eval_count}, 7, 'and the prompt tokens';
  is $objs[-1]{eval_count}, 3,
    'and the generated tokens -- an Ollama client reads its statistics from this line and '
    . 'treats the stream as unfinished without it';

  is $events[0]{api_format}, 'ollama', 'usage is recorded for the client format';
}

# Ollama defaults stream to true when the field is absent, unlike everyone else.
{
  @upstream_bodies = ();
  my $tx = post_stream('/api/chat', {
    model    => 'm1',
    messages => [{ role => 'user', content => 'hi' }],
  });
  like $tx->res->headers->content_type, qr{application/x-ndjson},
    'an Ollama request that omits stream still gets one -- that is Ollama\'s default, and a '
    . 'client that omits it is waiting for NDJSON';
}

{
  my $tx = post_stream('/api/chat', {
    model    => 'm1',
    stream   => JSON::MaybeXS::false,
    messages => [{ role => 'user', content => 'hi' }],
  });
  like $tx->res->headers->content_type, qr{application/json},
    'and stream:false still gets a single JSON reply';
  ok $tx->res->json->{done}, 'marked done';
}

# --- OpenAI is untouched ---
{
  @upstream_bodies = ();
  my $tx = post_stream('/v1/chat/completions', {
    model    => 'm1',
    stream   => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  });

  is $tx->res->code, 200, 'an OpenAI stream still works';
  like $tx->res->body, qr/\[DONE\]/,
    'and is relayed byte for byte, sentinel included -- the untranslated path is the only one '
    . 'that cannot lose anything, so it stays a pass-through';
  like $tx->res->body, qr/"delta"/, 'with OpenAI payloads intact';
}

# --- finish_reason == "length" maps to the protocol's own "truncated" reason ---
{
  my $length = Mojolicious->new;
  $length->log->level('fatal');
  $length->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"half"}}]}\n\n});
    my $final = '{"id":"c1","choices":[{"index":0,"delta":{},"finish_reason":"length"}],'
              . '"usage":{"prompt_tokens":4,"completion_tokens":1,"total_tokens":5}}';
    $c->write_chunk("data: $final\n\n");
    $c->write_chunk(qq{data: [DONE]\n\n});
    $c->write_chunk('' => sub { $c->finish });
  });
  my $len_daemon = Mojo::Server::Daemon->new(app => $length, listen => ['http://127.0.0.1'], silent => 1);
  $len_daemon->start;
  my $len_port = $len_daemon->ports->[0];

  my $skeid3 = Langertha::Skeid->new(route_wait_poll_ms => 5);
  $skeid3->add_node(id => 'len1', url => "http://127.0.0.1:$len_port/v1", model => 'm1', max_conns => 2);
  my $proxy3 = Langertha::Skeid::Proxy->build_app(skeid => $skeid3);
  $proxy3->log->level('fatal');
  my $pd3 = Mojo::Server::Daemon->new(app => $proxy3, listen => ['http://127.0.0.1'], silent => 1);
  $pd3->start;
  my $port3 = $pd3->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port3/v1/messages" => json => {
    model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  my ($mdelta) = grep { $_->[0] eq 'message_delta' } sse_events($tx->res->body);
  is $mdelta->[1]{delta}{stop_reason}, 'max_tokens',
    'finish_reason=length maps to Anthropic max_tokens -- a token-budget run-out is what the '
    . 'client needs to know happened';

  my $tx2;
  my $guard2 = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port3/api/chat" => json => {
    model => 'm1', stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx2) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard2);

  my @lines = grep { length } split /\n/, ($tx2->res->body // '');
  my @objs = map { decode_json($_) } @lines;
  is $objs[-1]{done_reason}, 'length',
    'and Ollama done_reason carries the same OpenAI finish_reason through verbatim';

  is $skeid3->node_metrics('len1')->{inflight}, 0, 'no admission leaked on the length path';
}

# --- an upstream that dies mid-stream still closes the client's protocol ---
{
  my $flaky = Mojolicious->new;
  $flaky->log->level('fatal');
  $flaky->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"par"}}]}\n\n});
    # No finish_reason, no usage, no [DONE] -- the upstream simply stops talking.
    Mojo::IOLoop->timer(0.05 => sub { $c->finish });
  });
  my $flaky_daemon = Mojo::Server::Daemon->new(app => $flaky, listen => ['http://127.0.0.1'], silent => 1);
  $flaky_daemon->start;
  my $flaky_port = $flaky_daemon->ports->[0];

  my $skeid2 = Langertha::Skeid->new(route_wait_poll_ms => 5);
  $skeid2->add_node(id => 'f1', url => "http://127.0.0.1:$flaky_port/v1", model => 'm1', max_conns => 2);
  my $proxy2 = Langertha::Skeid::Proxy->build_app(skeid => $skeid2);
  $proxy2->log->level('fatal');
  my $pd2 = Mojo::Server::Daemon->new(app => $proxy2, listen => ['http://127.0.0.1'], silent => 1);
  $pd2->start;
  my $port2 = $pd2->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port2/v1/messages" => json => {
    model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  my @names = map { $_->[0] } sse_events($tx->res->body);
  is $names[-1], 'message_stop',
    'a truncated upstream still ends with message_stop -- an Anthropic client waits for it, so '
    . 'leaving it out turns an upstream hiccup into a client that hangs';
  ok scalar(grep { $_ eq 'content_block_stop' } @names), 'and the open block is closed';

  is $skeid2->node_metrics('f1')->{inflight}, 0, 'no admission leaked on the error path';
}

is $skeid->node_metrics('n1')->{inflight}, 0, 'no admission leaked';

done_testing;
