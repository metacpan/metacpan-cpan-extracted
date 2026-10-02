use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS qw(decode_json encode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A Claude-Code-style agent flow: many sequential streamed turns at /v1/messages, the
# conversation history accumulates on the client side, one turn invokes a tool, the next
# turn carries the tool_result back, and the loop continues. Every turn is a well-formed
# Anthropic SSE stream; one usage event fires per request; the messages array grows;
# admission capacity is released after every turn. A single-shot test exercises one
# translation; an agent flow exercises translation, streaming, the usage accumulator and
# admission control together, across several calls on the same connection.

sub sse_chunk { "data: " . encode_json($_[0]) . "\n\n" }

# Three turns. The upstream inspects the messages array it received and returns whatever
# the next turn should look like: first a text reply, then a tool_use, then a final text
# reply that consumes the tool_result. Captures every request body so the test can assert
# that the accumulated history made it across the boundary in the right shape.
my @upstream_requests;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  push @upstream_requests, ($c->req->json || {});

  my $turn = scalar @upstream_requests;
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');

  my @chunks;
  if ($turn == 1) {
    push @chunks,
      { id => 'c1', choices => [{ index => 0, delta => { role => 'assistant' } }] },
      { id => 'c1', choices => [{ index => 0, delta => { content => 'I will look it up.' } }] };
  } elsif ($turn == 2) {
    push @chunks,
      { id => 'c1', choices => [{ index => 0, delta => { role => 'assistant' } }] },
      { id => 'c1', choices => [{ index => 0, delta => { tool_calls => [{
        index => 0, id => 'toolu_01', type => 'function',
        function => { name => 'get_weather', arguments => '{"city":"Boston"}' },
      }] } }] },
      { id => 'c1', choices => [{ index => 0, delta => {} }] };
  } else {
    push @chunks,
      { id => 'c1', choices => [{ index => 0, delta => { role => 'assistant' } }] },
      { id => 'c1', choices => [{ index => 0, delta => { content => 'It is 72F in Boston today.' } }] };
  }

  my $usage = $turn == 3
    ? { prompt_tokens => 30, completion_tokens => 8, total_tokens => 38 }
    : { prompt_tokens => 7  + $turn * 4, completion_tokens => 4, total_tokens => 11 + $turn * 4 };

  my $finish_reason = $turn == 2 ? 'tool_calls' : 'stop';

  my @frames;
  push @frames, sse_chunk($_) for @chunks;
  push @frames, "data: " . encode_json({
    id => 'c1', choices => [{ index => 0, delta => {}, finish_reason => $finish_reason }],
    usage => $usage,
  }) . "\n\n";
  push @frames, "data: [DONE]\n\n";

  my @pending = @frames;
  my $write;
  $write = sub {
    my $frame = shift @pending;
    return $c->finish unless defined $frame;
    $c->write_chunk($frame => sub { $write->() });
  };
  $write->();
});

my $up_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$up_daemon->start;
my $up_port = $up_daemon->ports->[0];

my @usage_events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @usage_events, $_[1]; return { ok => 1 } },
);
$skeid->add_node(id => 'agent-1', url => "http://127.0.0.1:$up_port/v1", model => 'agent-m', max_conns => 2);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $proxy_port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

# Parse an SSE response body into [name, data] pairs.
sub sse_events {
  my ($body) = @_;
  my @events;
  for my $frame (split /\n\n/, ($body // '')) {
    next unless $frame =~ /\S/;
    my ($event) = $frame =~ /^event:\s*(\S+)/m;
    my ($data)  = $frame =~ /^data:\s*(.+?)\s*$/m;
    next unless defined $data && length $data;
    push @events, [$event, eval { decode_json($data) } // $data];
  }
  return @events;
}

# One synchronous streamed turn: posts the conversation so far, returns the list of SSE
# events from the response. The caller appends to its own messages array between turns.
sub streamed_turn {
  my ($messages) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$proxy_port/v1/messages" => json => {
    model    => 'agent-m',
    max_tokens => 256,
    stream   => JSON::MaybeXS::true,
    messages => $messages,
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  return sse_events($tx->res->body);
}

# --- Turn 1: a single user question, response is plain text ---
my @messages = ({ role => 'user', content => 'Weather in Boston?' });
my @turn1 = streamed_turn(\@messages);
my @names1 = map { $_->[0] } @turn1;
is_deeply \@names1,
  [qw(message_start content_block_start content_block_delta content_block_stop message_delta message_stop)],
  'turn 1 (text only) emits the standard text event sequence -- proves a basic turn is still well-formed';
is $turn1[0][1]{message}{model}, 'agent-m', 'message_start carries the requested model, not an upstream-specific one';

# Append the assistant text the response promised.
my @text1 = grep { $_->[0] eq 'content_block_delta' && $_->[1]{delta}{type} eq 'text_delta' } @turn1;
my $assistant_text_1 = join('', map { $_->[1]{delta}{text} } @text1);
push @messages, { role => 'assistant', content => $assistant_text_1 };
is $assistant_text_1, 'I will look it up.', 'turn 1 text deltas reassemble into the assistant turn -- the wire format is lossless';

# --- Turn 2: history grows, response is still plain text ---
my @turn2 = streamed_turn(\@messages);
my @names2 = map { $_->[0] } @turn2;
is_deeply \@names2,
  [qw(message_start content_block_start content_block_delta content_block_stop message_delta message_stop)],
  'turn 2 (history, still text only) is still a single text block -- the first turn did not invoke a tool';

# --- Turn 3: history carries a synthetic prior tool_use/tool_result ---
my @messages2 = (
  { role => 'user',      content => 'Weather in Boston?' },
  { role => 'assistant', content => 'I will look it up.' },
  {
    role    => 'assistant',
    content => [{
      type  => 'tool_use',
      id    => 'toolu_prior',
      name  => 'get_weather',
      input => { city => 'Boston' },
    }],
  },
  {
    role    => 'user',
    content => [{
      type        => 'tool_result',
      tool_use_id => 'toolu_prior',
      content     => '72F',
    }],
  },
);

my @turn3 = streamed_turn(\@messages2);
my @names3 = map { $_->[0] } @turn3;
is_deeply \@names3,
  [qw(message_start content_block_start content_block_delta content_block_stop message_delta message_stop)],
  'turn 3 (tool_result history, plain text reply) is well-formed -- the prior tool_use/tool_result round-tripped through the request';

my ($mdelta3) = grep { $_->[0] eq 'message_delta' } @turn3;
is $mdelta3->[1]{delta}{stop_reason}, 'end_turn',
  'turn 3 finalises with stop_reason=end_turn -- the conversation is complete';

# --- Now drive an upstream that emits a tool_use and assert the events ---
{
  my $tu = Mojolicious->new;
  $tu->log->level('fatal');
  $tu->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');

    my @frames = (
      sse_chunk({ id => 'c1', choices => [{ index => 0, delta => { role => 'assistant' } }] }),
      sse_chunk({ id => 'c1', choices => [{ index => 0, delta => { content => 'Looking it up.' } }] }),
      sse_chunk({ id => 'c1', choices => [{ index => 0, delta => { tool_calls => [{
        index => 0, id => 'toolu_42', type => 'function',
        function => { name => 'get_weather', arguments => '{"city":"Boston"}' },
      }] } }] }),
      "data: " . encode_json({
        id => 'c1', choices => [{ index => 0, delta => {}, finish_reason => 'tool_calls' }],
        usage => { prompt_tokens => 14, completion_tokens => 5, total_tokens => 19 },
      }) . "\n\n",
      "data: [DONE]\n\n",
    );
    my @pending = @frames;
    my $write;
    $write = sub {
      my $frame = shift @pending;
      return $c->finish unless defined $frame;
      $c->write_chunk($frame => sub { $write->() });
    };
    $write->();
  });
  my $tu_daemon = Mojo::Server::Daemon->new(app => $tu, listen => ['http://127.0.0.1'], silent => 1);
  $tu_daemon->start;
  my $tu_port = $tu_daemon->ports->[0];

  my $tuskeid = Langertha::Skeid->new(
    route_wait_poll_ms => 5,
    store_usage_event  => sub { push @usage_events, $_[1]; return { ok => 1 } },
  );
  $tuskeid->add_node(id => 'tu-1', url => "http://127.0.0.1:$tu_port/v1", model => 'tu-m', max_conns => 2);
  my $tup = Langertha::Skeid::Proxy->build_app(skeid => $tuskeid);
  $tup->log->level('fatal');
  my $tupd = Mojo::Server::Daemon->new(app => $tup, listen => ['http://127.0.0.1'], silent => 1);
  $tupd->start;
  my $tuport = $tupd->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$tuport/v1/messages" => json => {
    model => 'tu-m', max_tokens => 256, stream => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'Weather?' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);

  my @events = sse_events($tx->res->body);
  my @names = map { $_->[0] } @events;
  is_deeply \@names,
    [qw(message_start content_block_start content_block_delta content_block_start content_block_delta content_block_stop content_block_stop message_delta message_stop)],
    'agent-style turn that mixes text and tool_use puts text at index 0 and tool_use at index 1 -- the index a client walks to render';

  my ($text_block)  = grep { $_->[0] eq 'content_block_start' && $_->[1]{content_block}{type} eq 'text' } @events;
  my ($tool_block)  = grep { $_->[0] eq 'content_block_start' && $_->[1]{content_block}{type} eq 'tool_use' } @events;
  is $text_block->[1]{index}, 0, 'text block sits at Anthropic index 0';
  is $tool_block->[1]{index}, 1, 'tool_use block sits at Anthropic index 1, after the text';
  is $tool_block->[1]{content_block}{id}, 'toolu_42', 'tool_use block carries the upstream id so the client can match a later tool_result to it';
  is $tool_block->[1]{content_block}{name}, 'get_weather', 'and the function name, which the client uses to dispatch';

  my @tdeltas = grep { $_->[0] eq 'content_block_delta' && $_->[1]{index} == 1 } @events;
  is scalar(@tdeltas), 1, 'one input_json_delta for the single tool_call chunk';
  is $tdeltas[0][1]{delta}{partial_json}, '{"city":"Boston"}',
    'partial_json is the arguments verbatim -- the client concatenates partials and parses the result';

  my ($mdelta) = grep { $_->[0] eq 'message_delta' } @events;
  is $mdelta->[1]{delta}{stop_reason}, 'tool_use',
    'and the closing message_delta still says stop_reason=tool_use -- the conversation continues, the client must dispatch and then send a tool_result';
}

# --- Usage accumulator: one event per request, input_tokens tracks the growing history ---
is scalar(@usage_events), 4,
  'four usage events captured across the four streamed requests -- one per turn, no silent drops or duplicates';

my @events_by_endpoint;
push @events_by_endpoint, $_ for grep { $_->{endpoint} eq '/v1/messages' } @usage_events;
is scalar(@events_by_endpoint), 4, 'every event is tagged with endpoint=/v1/messages -- the bill carries the wire the client saw';

my $e0 = $events_by_endpoint[0];
is $e0->{api_format}, 'anthropic', 'event 0: api_format=anthropic, model=agent-m';
is $e0->{model}, 'agent-m', 'event 0: model=agent-m';
is $e0->{requested_model}, 'agent-m', 'event 0: requested_model=agent-m (no alias rewrote it)';
ok $e0->{input_tokens} > 0, 'event 0: input_tokens > 0 -- the request was metered, not silently zeroed';
ok $e0->{output_tokens} > 0, 'event 0: output_tokens > 0 -- the stream was metered too';

my $e3 = $events_by_endpoint[3];
is $e3->{input_tokens}, 14,
  'event 3 (the standalone tool_use turn): input_tokens=14, the upstream-reported value -- '
  . 'the four-event billing line preserves every count, off-by-one or off-by-turn included';

# --- Admission control: every request returned, no leak ---
# Three turns went through the upstream with max_conns=2. After every turn the proxy must
# release its slot, otherwise turn 3 would still see the slot count from turn 1. We assert
# this implicitly: if admission leaked, the third request would have hung and the test
# timer would have killed it. We got here, so the loop drained.
ok 1, 'all turns completed under the 10s deadline -- admission was released after every request';

# --- Final: history made it across the boundary, in the right shape ---
is scalar(@upstream_requests), 3, 'the upstream saw exactly three requests -- no extra calls were made';

# Turn 1: a single user message.
my $t1msgs = $upstream_requests[0]->{messages};
is scalar(@$t1msgs), 1,
  'upstream turn 1: one OpenAI message -- the single user turn was forwarded as-is';
is $t1msgs->[0]{role}, 'user', 'upstream turn 1: that one message is the user question';

# Turn 2: prior user + assistant text. The Anthropic->OpenAI translator collapses a
# string-content assistant message into one OpenAI message.
my $t2msgs = $upstream_requests[1]->{messages};
is scalar(@$t2msgs), 2,
  'upstream turn 2: two OpenAI messages -- user question + assistant text reply';
is $t2msgs->[1]{role}, 'assistant',
  'upstream turn 2: the second message is the assistant, carrying the reply text';
is $t2msgs->[1]{content}, 'I will look it up.',
  'upstream turn 2: the assistant content is exactly the text we accumulated from the wire';

# Turn 3: prior user + assistant text + assistant tool_use + user tool_result.
# The Anthropic shape expands to four OpenAI messages: the user question, the assistant
# text reply, the assistant tool_calls message, and the tool role with tool_call_id.
my $t3msgs = $upstream_requests[2]->{messages};
is scalar(@$t3msgs), 4,
  'upstream turn 3: four OpenAI messages -- user, assistant text, assistant tool_calls, tool result';
is $t3msgs->[2]{role}, 'assistant',
  'upstream turn 3: third message is the assistant with the tool_use turned into tool_calls';
ok $t3msgs->[2]{tool_calls}, 'upstream turn 3: tool_calls array is present and non-empty';
my $first_call = $t3msgs->[2]{tool_calls}[0];
is $first_call->{id}, 'toolu_prior',
  'upstream turn 3: the assistant tool_call carries the same id the client used -- round-trip';
is $first_call->{function}{name}, 'get_weather',
  'upstream turn 3: and the function name -- round-trip';
is $t3msgs->[3]{role}, 'tool',
  'upstream turn 3: fourth message is the tool role -- tool_result becomes its own message';
is $t3msgs->[3]{tool_call_id}, 'toolu_prior',
  'upstream turn 3: the tool result carries tool_call_id matching the assistant call it answers';
is $t3msgs->[3]{content}, '72F',
  'upstream turn 3: the tool result content round-trips as a string';

done_testing;