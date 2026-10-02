use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use JSON::MaybeXS qw(decode_json encode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Ollama::Stream;

# k57: /api/chat is a translated stream, so an OpenAI tool call must leave the
# translator as an Ollama message.tool_calls entry.  The fragments themselves
# remain Langertha's responsibility; this test exercises the complete proxy
# boundary and checks the Ollama wire shape a client actually receives.

{
  package Local::FailingOllamaStream;
  our @ISA = ('Langertha::Skeid::Protocol::Ollama::Stream');
  sub finish { die "sensitive finish internals\n" }
}

my @upstream_bodies;
my @usage_events;

sub sse {
  my ($payload) = @_;
  return 'data: ' . (ref($payload) ? encode_json($payload) : $payload) . "\n\n";
}

sub write_stream {
  my ($c, @payloads) = @_;
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk(sse($_)) for @payloads;
  $c->write_chunk('' => sub { $c->finish });
}

sub choice_chunk {
  my (%choice) = @_;
  return {
    id      => 'chatcmpl-tools',
    object  => 'chat.completion.chunk',
    created => 1,
    model   => 'm1',
    choices => [{ index => 0, %choice }],
  };
}

my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 1,
  store_usage_event  => sub { push @usage_events, $_[1]; return { ok => 1 } },
);
my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->log->level('fatal');

# The fake OpenAI upstream is mounted on the same application under a path that
# cannot collide with Skeid's public route.  app->ua's embedded server dispatches
# the relative node URL in-process, without a network service or a real provider.
$app->routes->post('/fake/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body = $c->req->json || {};
  push @upstream_bodies, $body;
  my $prompt = $body->{messages}[0]{content} // '';

  if ($prompt eq 'tool only') {
    write_stream($c,
      choice_chunk(delta => { role => 'assistant', content => undef }),
      choice_chunk(delta => { tool_calls => [
        { index => 0, id => 'call_weather', type => 'function',
          function => { name => 'get_weather', arguments => '' } },
        { index => 1, id => 'call_time', type => 'function',
          function => { name => 'get_time', arguments => '' } },
      ] }),
      choice_chunk(delta => { tool_calls => [
        { index => 0, function => { arguments => '{"city":"Kö' } },
        { index => 1, function => { arguments => '{"tz":"Eu' } },
      ] }),
      choice_chunk(delta => { tool_calls => [
        { index => 1, function => { arguments => 'rope/Berlin"}' } },
        { index => 0, function => { arguments => 'ln","units":"celsius"}' } },
      ] }),
      choice_chunk(delta => {}, finish_reason => 'tool_calls'),
      {
        id      => 'chatcmpl-tools',
        model   => 'm1',
        choices => [],
        usage   => { prompt_tokens => 11, completion_tokens => 7, total_tokens => 18 },
      },
      '[DONE]',
    );
    return;
  }

  if ($prompt eq 'tool parser error') {
    write_stream($c,
      choice_chunk(delta => { tool_calls => [{
        index => 0, id => 'call_error', type => 'function',
        function => { name => 'get_weather', arguments => '{"city":"' },
      }] }),
      choice_chunk(
        delta => {},
        error => { message => 'Bearer secret-must-not-leak', code => 'provider_failure' },
      ),
      '[DONE]',
    );
    return;
  }

  if ($prompt eq 'unfinished tool') {
    write_stream($c,
      choice_chunk(delta => { role => 'assistant', content => undef }),
      choice_chunk(delta => { tool_calls => [{
        index => 0, id => 'call_unfinished', type => 'function',
        function => { name => 'get_weather', arguments => '{"city":"Köln"}' },
      }] }),
      {
        id      => 'chatcmpl-tools',
        model   => 'm1',
        choices => [],
        usage   => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 },
      },
      '[DONE]',
    );
    return;
  }

  if ($prompt eq 'finish failure') {
    write_stream($c,
      choice_chunk(delta => { content => 'before finish' }),
      choice_chunk(delta => {}, finish_reason => 'stop'),
      {
        id      => 'chatcmpl-tools',
        model   => 'm1',
        choices => [],
        usage   => { prompt_tokens => 2, completion_tokens => 2, total_tokens => 4 },
      },
      '[DONE]',
    );
    return;
  }

  if ($prompt eq 'mixed') {
    write_stream($c,
      choice_chunk(delta => { content => 'I will check. ' }),
      choice_chunk(delta => { tool_calls => [{
        index => 0, id => 'call_mixed', type => 'function',
        function => { name => 'get_weather', arguments => '{"city":' },
      }] }),
      choice_chunk(delta => { content => 'One moment.', tool_calls => [{
        index => 0, function => { arguments => '"München"}' },
      }] }),
      choice_chunk(delta => {}, finish_reason => 'tool_calls'),
      {
        id      => 'chatcmpl-tools',
        model   => 'm1',
        choices => [],
        usage   => { prompt_tokens => 5, completion_tokens => 4, total_tokens => 9 },
      },
      '[DONE]',
    );
    return;
  }

  # /api/generate has no tool_calls field.  Even a surprising upstream call is
  # not invented on that face; its text and terminal accounting still survive.
  write_stream($c,
    choice_chunk(delta => { content => 'generated text' }),
    choice_chunk(delta => { tool_calls => [{
      index => 0, id => 'call_hidden', type => 'function',
      function => { name => 'must_not_surface', arguments => '{"x":1}' },
    }] }),
    choice_chunk(delta => {}, finish_reason => 'tool_calls'),
    {
      id      => 'chatcmpl-tools',
      model   => 'm1',
      choices => [],
      usage   => { prompt_tokens => 3, completion_tokens => 2, total_tokens => 5 },
    },
    '[DONE]',
  );
});

$app->ua->server->app($app);
$skeid->add_node(
  id        => 'n1',
  url       => '/fake/v1',
  model     => 'm1',
  max_conns => 4,
);

my $t = Test::Mojo->new($app);

sub post_ndjson {
  my ($path, $payload) = @_;
  $t->post_ok($path => json => $payload)->status_is(200);
  like $t->tx->res->headers->content_type, qr{application/x-ndjson},
    "$path answers Ollama NDJSON";
  return map { decode_json($_) }
    grep { length } split /\n/, ($t->tx->res->body // '');
}

sub tool_stream_with_fragment {
  my (%args) = @_;
  my $stream = Langertha::Skeid::Protocol::Ollama::Stream->new(model => 'm1');
  my $first = $stream->delta(choice_chunk(delta => { tool_calls => [{
    index => 0,
    id => ($args{id} // 'call_boundary'),
    type => 'function',
    function => {
      name => ($args{name} // 'lookup'),
      arguments => ($args{arguments} // '{"value":"'),
    },
  }] }));
  is $first, '', 'an unfinished tool fragment emits no Ollama line';
  return $stream;
}

subtest 'tool-only stream assembles parallel fragmented calls once' => sub {
  @upstream_bodies = ();
  @usage_events = ();
  my @lines = post_ndjson('/api/chat', {
    model    => 'm1',
    messages => [{ role => 'user', content => 'tool only' }],
    tools    => [{ type => 'function', function => {
      name => 'get_weather', parameters => { type => 'object' },
    }}],
  });

  ok $upstream_bodies[0]{stream}, 'Ollama default streaming requests an upstream stream';
  ok $upstream_bodies[0]{stream_options}{include_usage},
    'and asks for the usage-only terminal frame';

  my @tool_lines = grep { ref($_->{message}{tool_calls}) eq 'ARRAY' } @lines;
  is scalar(@tool_lines), 1,
    'the final choice renders the calls once; the following usage-only frame does not repeat them';
  is $tool_lines[0]{done}, 0, 'the call message is a non-terminal Ollama chunk';
  is $tool_lines[0]{message}{content}, '', 'a tool-only call keeps empty assistant content';
  is_deeply $tool_lines[0]{message}{tool_calls}, [
    {
      id       => 'call_weather',
      function => {
        name      => 'get_weather',
        arguments => { city => 'Köln', units => 'celsius' },
      },
    },
    {
      id       => 'call_time',
      function => {
        name      => 'get_time',
        arguments => { tz => 'Europe/Berlin' },
      },
    },
  ], 'parallel fragments are assembled by index and rendered in Ollama shape with Unicode intact';

  ok $lines[-1]{done}, 'one terminal line still closes the stream';
  is $lines[-1]{done_reason}, 'tool_calls', 'the terminal reason is unchanged';
  is $lines[-1]{prompt_eval_count}, 11, 'usage-only prompt tokens reach the terminal line';
  is $lines[-1]{eval_count}, 7, 'usage-only completion tokens reach the terminal line';
  ok !exists $lines[-1]{message}{tool_calls}, 'the terminal usage line does not duplicate calls';
  is scalar(@usage_events), 1, 'the stream still records one usage event';
  is $usage_events[0]{input_tokens}, 11, 'recorded input usage is unchanged';
  is $usage_events[0]{output_tokens}, 7, 'recorded output usage is unchanged';
};

subtest 'mixed text and tool stream preserves both' => sub {
  my @lines = post_ndjson('/api/chat', {
    model    => 'm1',
    stream   => JSON::MaybeXS::true,
    messages => [{ role => 'user', content => 'mixed' }],
  });

  is join('', map { $_->{message}{content} // '' } @lines),
    'I will check. One moment.', 'text deltas are unchanged beside a tool call';
  my @tool_lines = grep { ref($_->{message}{tool_calls}) eq 'ARRAY' } @lines;
  is scalar(@tool_lines), 1, 'the mixed stream renders its call exactly once';
  is_deeply $tool_lines[0]{message}{tool_calls}, [{
    id       => 'call_mixed',
    function => {
      name      => 'get_weather',
      arguments => { city => 'München' },
    },
  }], 'the mixed stream renders the completed Langertha tool call';
  is $lines[-1]{prompt_eval_count}, 5, 'mixed-stream usage still reaches the close';
  is $lines[-1]{eval_count}, 4, 'mixed-stream output usage still reaches the close';
};

subtest 'tool parser failure becomes one safe Ollama error line' => sub {
  @usage_events = ();
  my @lines = post_ndjson('/api/chat', {
    model    => 'm1',
    messages => [{ role => 'user', content => 'tool parser error' }],
  });

  is scalar(@lines), 1, 'the fragment itself emits nothing and the parser failure emits one line';
  is_deeply [sort keys %{$lines[0]}], ['error'], 'the failure uses the Ollama error shape';
  unlike $lines[0]{error}, qr/secret-must-not-leak/, 'the provider payload is not reflected';
  ok !(grep { $_->{done} } @lines), 'no done:true line follows the parser failure';
  is scalar(@usage_events), 1, 'the failed stream still records one usage event';
  ok !$usage_events[0]{ok}, 'the failed stream is accounted as failed';
};

subtest 'unfinished tool stream fails metering before admission is released' => sub {
  @usage_events = ();
  my %before = %{$skeid->node_metrics('n1')};
  my @lines = post_ndjson('/api/chat', {
    model    => 'm1',
    messages => [{ role => 'user', content => 'unfinished tool' }],
  });

  is scalar(@lines), 1, 'a pending tool fragment is replaced by one terminal error line';
  is_deeply [sort keys %{$lines[0]}], ['error'], 'the terminal failure uses the Ollama error shape';
  ok !(grep { $_->{done} } @lines), 'the failed stream never emits done:true';
  is scalar(@usage_events), 1, 'the terminal failure records one usage event';
  ok !$usage_events[0]{ok}, 'the terminal failure is recorded with ok=0';

  my $after = $skeid->node_metrics('n1');
  is $after->{error}, $before{error} + 1, 'the node error counter includes the terminal failure';
  is $after->{ok}, $before{ok}, 'the node ok counter does not include the terminal failure';
  is $after->{inflight}, 0, 'the terminal failure releases admission';
};

subtest 'interleaved translators keep request-local fragment state' => sub {
  my $one = Langertha::Skeid::Protocol::Ollama::Stream->new(model => 'm1');
  my $two = Langertha::Skeid::Protocol::Ollama::Stream->new(model => 'm1');

  $one->delta(choice_chunk(delta => { tool_calls => [{
    index => 0, id => 'call_one', type => 'function',
    function => { name => 'lookup_one', arguments => '{"value":"' },
  }] }));
  $two->delta(choice_chunk(delta => { tool_calls => [{
    index => 0, id => 'call_two', type => 'function',
    function => { name => 'lookup_two', arguments => '{"value":"' },
  }] }));
  $one->delta(choice_chunk(delta => { tool_calls => [{
    index => 0, function => { arguments => 'first"}' },
  }] }));
  $two->delta(choice_chunk(delta => { tool_calls => [{
    index => 0, function => { arguments => 'second"}' },
  }] }));

  my $one_line = decode_json($one->delta(choice_chunk(delta => {}, finish_reason => 'tool_calls')));
  my $two_line = decode_json($two->delta(choice_chunk(delta => {}, finish_reason => 'tool_calls')));
  is_deeply $one_line->{message}{tool_calls}, [{
    id       => 'call_one',
    function => { name => 'lookup_one', arguments => { value => 'first' } },
  }], 'the first request renders only its own Langertha ToolCall';
  is_deeply $two_line->{message}{tool_calls}, [{
    id       => 'call_two',
    function => { name => 'lookup_two', arguments => { value => 'second' } },
  }], 'the interleaved request keeps its own id, name, and arguments';

  $one->finish;
  $two->finish;
};

subtest 'all Langertha parser failures stay inside the Ollama boundary' => sub {
  my @cases = (
    [ 'choice error', choice_chunk(
        delta => {},
        error => { message => 'Bearer choice-secret', code => 'provider_failure' },
      ) ],
    [ 'top-level scalar error', {
        error => 'Bearer top-level-secret',
        choices => [],
      } ],
    [ 'finish_reason error', choice_chunk(delta => {}, finish_reason => 'error') ],
  );

  for my $case (@cases) {
    my ($name, $frame) = @$case;
    my $stream = tool_stream_with_fragment(id => "call_$name");
    my ($line, $exception);
    {
      local $@;
      eval { $line = $stream->delta($frame); 1 } or $exception = $@;
    }
    is $exception, undef, "$name does not escape as an exception";
    next if defined $exception;
    my $error = decode_json($line);
    is_deeply [sort keys %$error], ['error'], "$name becomes an Ollama error line";
    unlike $error->{error}, qr/Bearer|secret/, "$name does not expose the parser or provider payload";
    ok $stream->errored, "$name marks the translator errored";
    is $stream->finish, '', "$name cannot be followed by done:true";
  }
};

subtest 'missing finish reason rejects pending tool calls' => sub {
  for my $case (
    [ 'complete JSON', '{"value":"complete"}' ],
    [ 'truncated JSON', '{"value":"cut' ],
  ) {
    my ($name, $arguments) = @$case;
    my $stream = tool_stream_with_fragment(arguments => $arguments);
    my ($line, $exception);
    {
      local $@;
      local $SIG{__WARN__} = sub {};
      eval { $line = $stream->finish; 1 } or $exception = $@;
    }
    is $exception, undef, "$name without finish_reason does not escape from finish";
    next if defined $exception;
    my $error = decode_json($line);
    is_deeply [sort keys %$error], ['error'], "$name without finish_reason is an error, not a successful end";
    ok $stream->errored, "$name without finish_reason marks the stream errored";
    ok !exists $error->{done}, "$name never fabricates a done:true line";
  }
};

subtest 'undecodable finished arguments do not become an invented empty object' => sub {
  my $stream = tool_stream_with_fragment(arguments => '{"value":');
  my $line = $stream->delta(choice_chunk(delta => {}, finish_reason => 'tool_calls'));
  my $error = decode_json($line);
  is_deeply [sort keys %$error], ['error'], 'undecodable arguments fail the translated stream';
  unlike $line, qr/"arguments"\s*:\s*\{\}/, 'no empty arguments object is invented';
  ok $stream->errored, 'undecodable arguments mark the stream errored';
  is $stream->finish, '', 'no successful terminal line follows';
};

subtest 'translator finish exceptions stay inside the proxy callback' => sub {
  @usage_events = ();
  my %before = %{$skeid->node_metrics('n1')};
  my $base_new = Langertha::Skeid::Protocol::Ollama::Stream->can('new');
  my @reactor_errors;
  my $reactor = Mojo::IOLoop->singleton->reactor;
  my $on_reactor_error = sub { push @reactor_errors, $_[1] };
  $reactor->on(error => $on_reactor_error);
  my $old_timeout = $t->ua->request_timeout;
  $t->ua->request_timeout(1);

  my @lines;
  {
    no warnings 'redefine';
    local *Langertha::Skeid::Protocol::Ollama::Stream::new = sub {
      my ($class, @args) = @_;
      return $base_new->('Local::FailingOllamaStream', @args);
    };
    @lines = post_ndjson('/api/chat', {
      model    => 'm1',
      messages => [{ role => 'user', content => 'finish failure' }],
    });
  }

  $t->ua->request_timeout($old_timeout);
  $reactor->unsubscribe(error => $on_reactor_error);

  is scalar(@reactor_errors), 0, 'the finalizer exception does not escape the proxy callback';
  is_deeply [sort keys %{$lines[-1]}], ['error'], 'the exception becomes an Ollama error line';
  unlike $lines[-1]{error}, qr/sensitive finish internals/, 'finish internals are not exposed';
  ok !(grep { $_->{done} } @lines), 'no successful terminal line follows the exception';
  is scalar(@usage_events), 1, 'the finalizer exception records one usage event';
  ok !$usage_events[0]{ok}, 'the finalizer exception is recorded with ok=0';

  my $after = $skeid->node_metrics('n1');
  is $after->{error}, $before{error} + 1, 'the finalizer exception increments the node error counter';
  is $after->{ok}, $before{ok}, 'the finalizer exception does not increment the node ok counter';
  is $after->{inflight}, 0, 'the finalizer exception releases admission';
};

subtest '/api/generate does not acquire chat tool calls' => sub {
  my @lines = post_ndjson('/api/generate', {
    model  => 'm1',
    prompt => 'generate only',
  });

  is join('', map { $_->{response} // '' } @lines), 'generated text',
    'generate text stays on response';
  ok !(grep { exists $_->{message} || exists $_->{tool_calls} } @lines),
    'generate emits neither chat messages nor a tool_calls field';
  is $lines[-1]{prompt_eval_count}, 3, 'generate usage is unchanged';
  is $lines[-1]{eval_count}, 2, 'generate output usage is unchanged';
};

is $skeid->node_metrics('n1')->{inflight}, 0, 'all translated streams release admission';

done_testing;
