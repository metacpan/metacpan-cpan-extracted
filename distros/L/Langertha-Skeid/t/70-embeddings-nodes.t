use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use Path::Tiny qw( path );
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Embedding servers are nodes (skeid k93). POST /v1/embeddings goes through the same routing and
# admission as a chat request -- alias tiers, health, max_conns, capacity readings -- and its
# usage event carries the tokens the node reports, priced by the model's input rate. Until this
# file the suite called the route with one node only, so nothing held it to that: a node
# inventory of several embedding servers could have stopped sharing load, ignored max_conns or
# metered nothing without a test going red. The upstreams are local fakes of vLLM, TEI and
# infinity.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB )};

my $TMP = tempdir(CLEANUP => 1);

my $MODEL = 'BAAI/bge-m3';
my $E     = '/v1/embeddings';

my (%SEEN, @USAGE);
my $MODE  = '';   # '' answers, 'slow' answers after $DELAY, 'fail' answers 500
my $DELAY = 0.3;
my %PEAK;
my %NOW;

my $CFG = {};

sub settle {
  my ($seconds) = @_;
  Mojo::IOLoop->timer(($seconds // 0.05) => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
}

# The answers of the three servers as bytes, written by hand with spaces and a trailing newline
# a JSON encoder would not produce, so an answer Skeid decoded and encoded again is not the
# answer the node gave. The usage keys are the ones the real servers use.
sub answer_bytes {
  my ($flavour, $body, $tag) = @_;
  my $n = ref($body->{input}) eq 'ARRAY' ? scalar(@{ $body->{input} }) : 1;
  my $tokens = 7 * $n;
  my $data = join(', ', map { qq[{ "object": "embedding", "index": $_, "embedding": [0.25, -0.5, $_] }] } 0 .. $n - 1);
  my $model = '"' . $body->{model} . '"';
  return qq[{ "object": "list", "data": [ $data ], "model": $model, "usage": { "prompt_tokens": $tokens, "total_tokens": $tokens } }\n]
    if $flavour eq 'tei';
  return qq[{ "object": "list", "data": [ $data ], "model": $model, "usage": { "prompt_tokens": $tokens, "total_tokens": $tokens },]
    . qq[ "id": "infinity-$tag", "created": 1790000000 }\n]
    if $flavour eq 'infinity';
  return qq[{ "id": "embd-$tag", "object": "list", "created": 1790000001, "model": $model, "data": [ $data ],]
    . qq[ "usage": { "prompt_tokens": $tokens, "total_tokens": $tokens, "completion_tokens": 0 } }\n];
}

sub fake_upstream {
  my ($c) = @_;
  my $tag    = $c->stash('tag');
  my $req    = $c->req;
  my $seen   = {
    path => $req->url->path->to_string, raw => $req->body, json => scalar(eval { decode_json($req->body) }),
    flavour => $c->stash('flavour'),
  };
  push @{ $SEEN{$tag} }, $seen;
  my $send = sub {
    $NOW{$tag}--;
    $seen->{sent} = answer_bytes($seen->{flavour}, $seen->{json}, $tag);
    $c->render(data => $seen->{sent}, format => 'json');
  };
  $NOW{$tag}++;
  $PEAK{$tag} = $NOW{$tag} if $NOW{$tag} > ($PEAK{$tag} // 0);
  if ($MODE eq 'fail') {
    $NOW{$tag}--;
    return $c->render(status => 500, json => { error => 'model overloaded', error_type => 'Backend' });
  }
  return $send->() unless $MODE eq 'slow';
  $c->render_later;
  Mojo::IOLoop->timer($DELAY => $send);
  return;
}

my $UP;
sub proxy {
  my (%opts) = @_;
  $CFG = delete($opts{config}) || {};
  %SEEN = %PEAK = %NOW = ();
  @USAGE = ();
  $MODE = '';
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms  => 60,
    route_wait_poll_ms     => 5,
    config_reload_interval => 0,
    config_loader          => sub { $CFG },
    ($opts{usage_store} ? () : (store_usage_event => sub { push @USAGE, $_[1]; return { ok => 1 } })),
    %opts,
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('fatal');
  $app->routes->post('/__up/:flavour/:tag/v1/embeddings' => \&fake_upstream);
  my $t = Test::Mojo->new($app);
  $UP = $t->ua->server->nb_url->clone;
  return ($t, $skeid);
}

sub add_node {
  my ($skeid, $id, %extra) = @_;
  my $flavour = delete($extra{flavour}) // 'vllm';
  return $skeid->add_node(
    id => $id, url => $UP->clone->path("/__up/$flavour/$id/v1")->to_string,
    model => $MODEL, engine => 'openaibase', max_conns => 2, %extra,
  );
}

sub embed { my ($t, $body) = @_; return $t->post_ok($E => json => { model => $MODEL, input => 'Köln', %{ $body || {} } }) }

sub count { my ($id) = @_; return scalar(@{ $SEEN{$id} || [] }) }

sub paired {
  my ($skeid, $id, $label) = @_;
  my $m = $skeid->node_metrics($id);
  is $m->{inflight}, 0, "$label: nothing in flight on $id";
  is $m->{ok} + $m->{error} + $m->{aborted}, $m->{started},
    "$label: every request.start on $id has its request.finish";
}

# N requests at once on the test's user agent; returns the statuses.
sub concurrent {
  my ($t, $n) = @_;
  my @status;
  for my $i (1 .. $n) {
    $t->ua->post($t->ua->server->nb_url->clone->path($E) => json => { model => $MODEL, input => "doc $i" }
      => sub { push @status, $_[1]->res->code; Mojo::IOLoop->stop if @status == $n });
  }
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return sort @status;
}

subtest 'two nodes of one model share the load, in turn' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'emb-a');
  add_node($skeid, 'emb-b');

  my @served;
  for (1 .. 6) {
    embed($t)->status_is(200);
    push @served, $t->tx->res->headers->header('x-skeid-node');
  }
  is count('emb-a'), 3, 'six sequential requests: three on the first node';
  is count('emb-b'), 3, 'and three on the second';
  isnt $served[0], $served[1], 'consecutive requests do not stay on one node';
  is scalar(@USAGE), 6, 'one usage event per request';
  is_deeply [ map { $_->{node_id} } @USAGE ], \@served, 'each event names the node that served it';
  paired($skeid, $_, 'sequential') for qw( emb-a emb-b );
};

subtest 'weights are respected' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'emb-big', weight => 3, max_conns => 0);
  add_node($skeid, 'emb-small', weight => 1, max_conns => 0);
  embed($t)->status_is(200) for 1 .. 8;
  is count('emb-big'), 6, 'weight 3 against 1: six of eight requests';
  is count('emb-small'), 2, 'and two for the light node';
};

subtest 'health is the operator\'s switch, and takes a node in and out of rotation' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'emb-a');
  add_node($skeid, 'emb-b');

  $skeid->set_node_health('emb-a', 0);
  embed($t)->status_is(200) for 1 .. 4;
  is count('emb-a'), 0, 'a node set unhealthy gets nothing';
  is count('emb-b'), 4, 'the other takes all of it';

  $skeid->set_node_health('emb-a', 1);
  embed($t)->status_is(200) for 1 .. 4;
  is count('emb-a'), 2, 'back in rotation, the node takes its half again';

  $skeid->set_node_health($_, 0) for qw( emb-a emb-b );
  my $before = @USAGE;
  embed($t)->status_is(503, 'no healthy node for the model is 503, not a wait for capacity')
    ->json_is('/error/type' => 'model_not_found');
  is scalar(@USAGE), $before, 'a request that was never forwarded leaves no usage event';
};

subtest 'max_conns holds per node under concurrency; the surplus is 429, and nothing leaks' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'emb-a');
  add_node($skeid, 'emb-b');
  $MODE = 'slow';

  my @status = concurrent($t, 6);
  is_deeply \@status, [ 200, 200, 200, 200, 429, 429 ],
    'six at once on two nodes of two slots: four served, two refused as saturated';
  cmp_ok $PEAK{'emb-a'}, '<=', 2, 'the first node never saw more than its max_conns';
  cmp_ok $PEAK{'emb-b'}, '<=', 2, 'nor the second';
  is $PEAK{'emb-a'} + $PEAK{'emb-b'}, 4, 'and the four admitted were all in flight together';
  settle(0.1);
  paired($skeid, $_, 'concurrent') for qw( emb-a emb-b );
  is scalar(@USAGE), 4, 'only a forwarded request has an event: four, not six';
  ok !(grep { !$_->{ok} } @USAGE), 'and all of them succeeded';

  $MODE = '';
  embed($t)->status_is(200, 'the slots are free again');
};

subtest 'a capacity reading that says full keeps a node out, as for chat' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'emb-a', max_conns => 8);
  add_node($skeid, 'emb-b', max_conns => 8);

  $skeid->set_capacity_reading('emb-a', used => 8, limit => 8, source => 'prometheus');
  embed($t)->status_is(200) for 1 .. 4;
  is count('emb-a'), 0, 'the node the probe reports full is skipped although inflight is 0';
  is count('emb-b'), 4, 'the other takes the traffic';

  $skeid->set_capacity_reading('emb-b', used => 8, limit => 8, source => 'prometheus');
  embed($t)->status_is(429, 'both full: saturation is 429')->json_is('/error/type' => 'rate_limit_error');
  is scalar(@USAGE), 4, 'the refused request was never forwarded, so it has no event';
  paired($skeid, $_, 'capacity') for qw( emb-a emb-b );
};

subtest 'an alias with tiers asks the node for the served model, and the event keeps both names' => sub {
  my ($t, $skeid) = proxy(config => {
    aliases => { 'house-embed' => { tiers => [ { model => $MODEL } ] } },
  });
  add_node($skeid, 'emb-a');

  embed($t, { model => 'house-embed', encoding_format => 'float', dimensions => 3 });
  $t->status_is(200);
  is $SEEN{'emb-a'}[0]{json}{model}, $MODEL, 'the node is asked for the served model';
  is_deeply $SEEN{'emb-a'}[0]{json},
    { model => $MODEL, input => 'Köln', encoding_format => 'float', dimensions => 3 },
    'and for nothing else that changed: encoding_format and dimensions go through';
  is $USAGE[0]{model}, $MODEL, 'event model is the served one (what costs money)';
  is $USAGE[0]{requested_model}, 'house-embed', 'event requested_model is what the client asked for';

  embed($t, { model => 'not-served-anywhere' })->status_is(503)->json_is('/error/type' => 'model_not_found');
  is scalar(@USAGE), 1, 'an unknown model is no forwarded request';
};

subtest 'tokens and cost come from the node\'s usage, for a string input and for a batch' => sub {
  my ($t, $skeid) = proxy(config => {
    pricing => { $MODEL => { input_per_million => 2, output_per_million => 50 } },
  });
  add_node($skeid, 'emb-a');

  embed($t, { input => 'one string' })->status_is(200);
  embed($t, { input => [ 'a', 'b', 'c', 'd' ] })->status_is(200);
  is scalar(@USAGE), 2, 'one event per forwarded request, whatever its batch size';

  for my $case ([ 0, 7, 'a string input' ], [ 1, 28, 'a batch of four' ]) {
    my ($i, $tokens, $label) = @$case;
    my $ev = $USAGE[$i];
    is $ev->{endpoint}, $E, "$label: endpoint /v1/embeddings";
    is $ev->{api_format}, 'openai', "$label: OpenAI face";
    is $ev->{ok}, 1, "$label: ok";
    is $ev->{input_tokens}, $tokens, "$label: usage.prompt_tokens is the input tokens";
    is $ev->{total_tokens}, $tokens, "$label: usage.total_tokens is the total";
    is $ev->{output_tokens}, 0, "$label: an embedding has no output tokens";
    cmp_ok abs($ev->{cost_total_usd} - $tokens * 2 / 1e6), '<', 1e-12, "$label: priced at input_per_million";
    is $ev->{cost_output_usd}, 0, "$label: nothing at the output rate";
  }
  is_deeply $SEEN{'emb-a'}[1]{json}{input}, [ 'a', 'b', 'c', 'd' ], 'a batch reaches the node as one request';
  is $skeid->node_metrics('emb-a')->{started}, 2, 'and costs one slot each, whatever the batch size';
};

subtest 'vLLM, TEI and infinity answers come back byte for byte' => sub {
  my ($t, $skeid) = proxy();
  for my $flavour (qw( vllm tei infinity )) {
    add_node($skeid, "n-$flavour", flavour => $flavour, model => "m-$flavour", tags => [$flavour]);
  }
  for my $flavour (qw( vllm tei infinity )) {
    $t->post_ok($E => json => { model => "m-$flavour", input => [ 'x', 'y' ] })->status_is(200)
      ->header_is('x-skeid-node' => "n-$flavour");
    is $t->tx->res->body, $SEEN{"n-$flavour"}[0]{sent}, "$flavour: the node's bytes, not a re-encoding";
    is $USAGE[-1]{input_tokens}, 14, "$flavour: tokens read from the usage keys they share";
  }
  like $SEEN{'n-infinity'}[0]{sent}, qr/"id": "infinity-n-infinity"/, 'the infinity answer kept its extra fields';
};

subtest 'an upstream error or an unreachable node is one failed event and no leaked slot' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'emb-a');
  $MODE = 'fail';
  embed($t);
  is $t->tx->res->code, 500, 'the upstream status is the client\'s status';
  is scalar(@USAGE), 1, 'one event';
  is $USAGE[0]{ok}, 0, 'a failed one';
  is $USAGE[0]{status_code}, 500, 'with the upstream status';
  paired($skeid, 'emb-a', 'upstream 500');

  my ($t2, $skeid2) = proxy();
  my $port = Mojo::IOLoop::Server->generate_port;
  $skeid2->add_node(id => 'gone', url => "http://127.0.0.1:$port/v1", model => $MODEL, max_conns => 2);
  embed($t2);
  cmp_ok $t2->tx->res->code, '>=', 500, 'an unreachable node is a server-side failure for the client';
  is scalar(@USAGE), 1, 'one event';
  is $USAGE[0]{ok}, 0, 'a failed one';
  paired($skeid2, 'gone', 'unreachable');
};

subtest 'a usage store sees the same events' => sub {
  my $dir = tempdir(CLEANUP => 1, DIR => $TMP);
  my ($t, $skeid) = proxy(
    usage_store => { backend => 'jsonlog', log_path => "$dir/usage.jsonl" },
    config => { pricing => { $MODEL => { input_per_million => 2 } } },
  );
  add_node($skeid, 'emb-a');
  embed($t, { input => [ 'a', 'b' ] })->status_is(200);
  my @lines = grep { length } split /\n/, path("$dir/usage.jsonl")->slurp_utf8;
  is scalar(@lines), 1, 'one line written';
  my $ev = decode_json($lines[0]);
  is $ev->{endpoint}, $E, 'the endpoint';
  is $ev->{input_tokens}, 14, 'the node\'s tokens';
};

done_testing;
