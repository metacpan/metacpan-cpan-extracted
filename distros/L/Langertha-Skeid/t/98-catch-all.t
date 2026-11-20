#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Mojo::JSON qw( false );
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use Path::Tiny qw( path );
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# The catch-all (skeid k129, ADR 0033): routing.catch_all names, per kind of route, the model an
# unknown model name is routed to. Only a name that matches nothing is bent; from there the
# request is an ordinary request for the target -- the key's policy judges the target, the
# answer names the target, and the usage event carries requested, routed and served model.
#
# Written before the feature (test first): until it exists, an unknown name is a 503. The
# tests that hold today are the ones that say "nothing changes" -- a known name, a config
# without the key, a route that is not bent -- and they guard the feature against bending too
# much. The upstreams are local fakes; nothing leaves the process.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB )};

my $TMP = tempdir(CLEANUP => 1);

my $CHAT_MODEL = 'qwen-flash';     # what the catch-all chat target serves
my $EMB_MODEL  = 'embed-4b';       # what the catch-all embeddings target serves
my $MADE_UP    = 'gpt-4o';         # a name the client was configured with, known to nobody

my (%SEEN, @USAGE);
my $MODE = '';                      # '' answers, 'fail' answers 500
my $CFG  = {};

sub catch_all { return { routing => { catch_all => { chat => $CHAT_MODEL, embeddings => $EMB_MODEL } } } }

# The node answers with the model it was asked for, as a real one does, so "the answer names
# the target" can only come out true if Skeid asked for the target.
sub fake_chat {
  my ($c) = @_;
  my $tag  = $c->stash('tag');
  my $body = eval { decode_json($c->req->body) } || {};
  push @{ $SEEN{$tag} }, { path => $c->req->url->path->to_string, json => $body };
  return $c->render(status => 500, json => { error => { message => 'model overloaded', type => 'server_error' } })
    if $MODE eq 'fail';
  $c->render(json => {
    id => "chatcmpl-$tag", object => 'chat.completion', created => 1790000000, model => $body->{model},
    choices => [ { index => 0, finish_reason => 'stop', message => { role => 'assistant', content => "from $tag" } } ],
    usage => { prompt_tokens => 5, completion_tokens => 3, total_tokens => 8 },
  });
}

sub fake_embeddings {
  my ($c) = @_;
  my $tag  = $c->stash('tag');
  my $body = eval { decode_json($c->req->body) } || {};
  push @{ $SEEN{$tag} }, { path => $c->req->url->path->to_string, json => $body };
  return $c->render(status => 500, json => { error => { message => 'model overloaded', type => 'server_error' } })
    if $MODE eq 'fail';
  my @in = ref($body->{input}) eq 'ARRAY' ? @{ $body->{input} } : ($body->{input});
  $c->render(json => {
    object => 'list', model => $body->{model},
    data  => [ map { +{ object => 'embedding', index => $_, embedding => [ 0.25, -0.5 ] } } 0 .. $#in ],
    usage => { prompt_tokens => 7, total_tokens => 7 },
  });
}

my $UP;
sub proxy {
  my (%opts) = @_;
  $CFG = delete($opts{config}) || {};
  my $nodes = exists $opts{nodes} ? delete($opts{nodes}) : 1;
  %SEEN = ();
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
  $app->routes->post('/__up/:tag/v1/chat/completions' => \&fake_chat);
  $app->routes->post('/__up/:tag/v1/embeddings'       => \&fake_embeddings);
  my $t = Test::Mojo->new($app);
  $UP = $t->ua->server->nb_url->clone;
  if ($nodes) {
    node($skeid, 'chat-1', model => $CHAT_MODEL);
    node($skeid, 'emb-1',  model => $EMB_MODEL);
  }
  return ($t, $skeid);
}

sub node {
  my ($skeid, $id, %extra) = @_;
  return $skeid->add_node(
    id => $id, trust => 'internal', url => $UP->clone->path("/__up/$id/v1")->to_string,
    engine => 'openaibase', max_conns => 4, %extra,
  );
}

sub last_model { my ($id) = @_; return ($SEEN{$id} && $SEEN{$id}[-1]) ? $SEEN{$id}[-1]{json}{model} : undef }
sub count { my ($id) = @_; return scalar(@{ $SEEN{$id} || [] }) }

sub paired {
  my ($skeid, $id, $label) = @_;
  my $m = $skeid->node_metrics($id);
  is $m->{inflight}, 0, "$label: nothing in flight on $id";
  is $m->{ok} + $m->{error} + $m->{aborted}, $m->{started}, "$label: every request.start on $id has its request.finish";
}

sub chat      { my ($t, $model, %h) = @_; return $t->post_ok('/v1/chat/completions' => \%h
  => json => { (defined $model ? (model => $model) : ()), messages => [ { role => 'user', content => 'Köln?' } ] }) }
sub embed     { my ($t, $model, %h) = @_; return $t->post_ok('/v1/embeddings' => \%h
  => json => { (defined $model ? (model => $model) : ()), input => 'Köln' }) }
sub anthropic { my ($t, $model, %h) = @_; return $t->post_ok('/v1/messages' => \%h
  => json => { model => $model, max_tokens => 16, messages => [ { role => 'user', content => 'Köln?' } ] }) }

# --- 1. OpenAI chat -----------------------------------------------------------------------

subtest '/v1/chat/completions: an unknown name is answered by the catch-all chat target' => sub {
  my ($t, $skeid) = proxy(config => catch_all());
  chat($t, $MADE_UP)->status_is(200, 'an unknown name is bent, not a 503')
    ->header_is('x-skeid-node' => 'chat-1');
  is count('chat-1'), 1, 'the chat target was asked once';
  is count('emb-1'), 0, 'and the embeddings node was not';
  is $SEEN{'chat-1'}[0]{json}{model}, $CHAT_MODEL, 'the node is asked for the target\'s served model, not the made-up name';
  is $SEEN{'chat-1'}[0]{json}{messages}[0]{content}, 'Köln?', 'the rest of the request is untouched';
  $t->json_is('/model' => $CHAT_MODEL, 'the answer names the model the node answered, not the made-up name');
  unlike $t->tx->res->body, qr/\Q$MADE_UP\E/, 'the made-up name appears nowhere in the answer';
  paired($skeid, 'chat-1', 'bent');
};

subtest 'a request with no model name at all is bent as well' => sub {
  my ($t) = proxy(config => catch_all());
  chat($t, undef)->status_is(200, 'no name matches nothing');
  is $SEEN{'chat-1'}[0]{json}{model}, $CHAT_MODEL, 'and the node is asked for the target';
};

# --- 2. the kind comes from the route ------------------------------------------------------

subtest 'the same unknown name goes to the target of the route\'s kind' => sub {
  my ($t) = proxy(config => catch_all());
  my $name = 'some-made-up-name';
  chat($t, $name)->status_is(200)->header_is('x-skeid-node' => 'chat-1');
  embed($t, $name)->status_is(200, 'an embeddings request is bent too')->header_is('x-skeid-node' => 'emb-1');
  is count('chat-1'), 1, 'the chat route reached the chat node once';
  is count('emb-1'), 1, 'the embeddings route reached the embeddings node once';
  is $SEEN{'emb-1'}[0]{path}, '/__up/emb-1/v1/embeddings', 'and it was an embeddings call';
  is $SEEN{'emb-1'}[0]{json}{model}, $EMB_MODEL, 'asking the embeddings target for its served model';
  $t->json_is('/model' => $EMB_MODEL, 'the answer names the target')
    ->json_is('/data/0/index' => 0, 'and is the node\'s answer');
};

# --- 3. Ollama ----------------------------------------------------------------------------

subtest 'Ollama faces: each route is bent to the target of its kind' => sub {
  my ($t) = proxy(config => catch_all());

  $t->post_ok('/api/chat' => json => { model => 'llama3', stream => false,
    messages => [ { role => 'user', content => 'hi' } ] })
    ->status_is(200, '/api/chat: an unknown name is bent')->json_is('/model' => $CHAT_MODEL, '/api/chat: the answer names the target');
  is last_model('chat-1'), $CHAT_MODEL, '/api/chat: the node is asked for the target';

  $t->post_ok('/api/generate' => json => { model => 'llama3', stream => false, prompt => 'hi' })
    ->status_is(200, '/api/generate: an unknown name is bent')->json_is('/model' => $CHAT_MODEL, '/api/generate: the answer names the target');
  is count('chat-1'), 2, '/api/generate went to the chat node as well';
  is count('emb-1'), 0, 'neither chat route touched the embeddings node';

  $t->post_ok('/api/embed' => json => { model => 'nomic-embed', input => [ 'a', 'b' ] })
    ->status_is(200, '/api/embed: an unknown name is bent')->json_is('/model' => $EMB_MODEL, '/api/embed: the answer names the target');
  is last_model('emb-1'), $EMB_MODEL, '/api/embed: the embeddings node is asked for the target';
  is scalar(@{ $t->tx->res->json->{embeddings} || [] }), 2, '/api/embed: one vector per input';

  $t->post_ok('/api/embeddings' => json => { model => 'nomic-embed', prompt => 'hi' })
    ->status_is(200, '/api/embeddings: an unknown name is bent');
  is count('emb-1'), 2, '/api/embeddings reached the embeddings node';
  is last_model('emb-1'), $EMB_MODEL, '/api/embeddings: asking for the target';
  is count('chat-1'), 2, 'and the chat node saw nothing more';
};

# --- 4. Anthropic -------------------------------------------------------------------------

subtest '/v1/messages: an unknown name is bent to the chat target, and the answer names it' => sub {
  my ($t, $skeid) = proxy(config => catch_all());
  anthropic($t, 'claude-3-5-sonnet-latest')->status_is(200, 'an unknown name is bent')
    ->json_is('/model' => $CHAT_MODEL, 'the answer names the target, not the made-up name')
    ->json_is('/type' => 'message', 'in the Anthropic shape');
  is $SEEN{'chat-1'}[0]{json}{model}, $CHAT_MODEL, 'the node is asked for the target';
  is count('emb-1'), 0, 'the embeddings node is not involved';
  paired($skeid, 'chat-1', 'anthropic bent');
};

# --- 5. a known name is routed as before ---------------------------------------------------

subtest 'a known name is not bent (guards the feature against bending too much)' => sub {
  my ($t, $skeid) = proxy(config => {
    %{ catch_all() },
    aliases => { 'house-chat' => { tiers => [ { model => 'other-model' } ] } },
  });
  node($skeid, 'other-1', model => 'other-model');

  chat($t, 'other-model')->status_is(200)->header_is('x-skeid-node' => 'other-1');
  is count('chat-1'), 0, 'a node model reaches its own node, not the catch-all target';
  chat($t, 'house-chat')->status_is(200)->header_is('x-skeid-node' => 'other-1');
  is $SEEN{'other-1'}[1]{json}{model}, 'other-model', 'an alias resolves through its own tiers';
  is count('chat-1'), 0, 'and does not reach the catch-all target either';

  embed($t, 'other-model')->status_is(200, 'a chat model name on the embeddings route is known too')
    ->header_is('x-skeid-node' => 'other-1');
  is count('emb-1'), 0, 'known on either kind of route, it is not bent to the embeddings target';

  $skeid->set_node_health('other-1', 0);
  chat($t, 'other-model')->status_is(503, 'a known model whose node is down stays 503')
    ->json_is('/error/type' => 'model_not_found');
  is count('chat-1'), 0, 'it is not rescued by the catch-all';
  chat($t, 'house-chat')->status_is(503, 'and so does an alias whose tiers are down');
  is count('chat-1'), 0, 'not rescued either';
  chat($t, $MADE_UP)->status_is(200, 'while an unknown name is still bent');
  is count('chat-1'), 1, 'to the healthy target';
};

subtest 'a node without a model serves every name, so the catch-all never applies' => sub {
  my ($t, $skeid) = proxy(config => catch_all(), nodes => 0);
  node($skeid, 'any-1');
  node($skeid, 'chat-1', model => $CHAT_MODEL);
  chat($t, $MADE_UP)->status_is(200)->header_is('x-skeid-node' => 'any-1');
  is $SEEN{'any-1'}[0]{json}{model}, $MADE_UP, 'the model-less node is asked for the name the client sent';
  is count('chat-1'), 0, 'the catch-all target is not used: no name is unknown';
};

# --- 6. policy ----------------------------------------------------------------------------

subtest 'the key\'s policy judges the target, not the made-up name' => sub {
  my %id = map { $_ => Langertha::Skeid->key_id_for_key("sk-test-$_") } qw( grants denies other );
  my ($t, $skeid) = proxy(config => {
    %{ catch_all() },
    policies => {
      grants => { models => [$CHAT_MODEL] },
      denies => { models => ['something-else'] },
      other  => { models => ['other-model'] },
    },
    keys => { $id{grants} => 'grants', $id{denies} => 'denies', $id{other} => 'other' },
  });
  node($skeid, 'other-1', model => 'other-model');
  my %auth = map { $_ => { Authorization => "Bearer sk-test-$_" } } keys %id;

  chat($t, $MADE_UP, %{ $auth{grants} })->status_is(200, 'a key whose models grant the target is served with an unknown name')
    ->header_is('x-skeid-node' => 'chat-1');
  chat($t, $MADE_UP, %{ $auth{denies} })->status_is(403, 'a key whose models do not grant the target gets 403')
    ->json_is('/error/type' => 'permission_error');
  is count('chat-1'), 1, 'and the refused request reached no node';
  chat($t, $CHAT_MODEL, %{ $auth{denies} })->status_is(403, 'asking for the ungranted target by name is the same 403');
  chat($t, 'other-model', %{ $auth{grants} })->status_is(403, 'a known name the key does not grant stays 403 (not bent to what it may have)')
    ->json_is('/error/type' => 'permission_error');
  chat($t, $MADE_UP, %{ $auth{other} })->status_is(403, 'a key granted another model is not bent to the target either');
  is count('other-1'), 0, 'and not rescued onto the model it may have';
  embed($t, $MADE_UP, %{ $auth{grants} })->status_is(403, 'the embeddings target is judged too: this key does not grant it');
  is count('emb-1'), 0, 'so it never reached the embeddings node';
  paired($skeid, 'chat-1', 'policy');
};

subtest 'deny_tags that forbid every node serving the target refuse a bent request' => sub {
  my $id = Langertha::Skeid->key_id_for_key('sk-test-nocloud');
  my ($t, $skeid) = proxy(config => {
    %{ catch_all() },
    policies => { 'no-cloud' => { deny_tags => ['cloud'] } },
    keys     => { $id => 'no-cloud' },
  }, nodes => 0);
  node($skeid, 'chat-1', model => $CHAT_MODEL, tags => ['cloud']);
  chat($t, $CHAT_MODEL, Authorization => 'Bearer sk-test-nocloud')->status_is(403, 'by name: refused');
  chat($t, $MADE_UP, Authorization => 'Bearer sk-test-nocloud')->status_is(403, 'by an unknown name: the same refusal')
    ->json_is('/error/type' => 'permission_error');
  is count('chat-1'), 0, 'the node was never asked';
};

# --- 7. usage -----------------------------------------------------------------------------

subtest 'the usage event of a bent request carries requested, routed and served model' => sub {
  my ($t, $skeid) = proxy(config => catch_all());
  chat($t, $MADE_UP)->status_is(200);
  is scalar(@USAGE), 1, 'one event';
  is $USAGE[0]{requested_model}, $MADE_UP, 'requested_model is the name the client sent';
  is $USAGE[0]{routed_model}, $CHAT_MODEL, 'routed_model is the catch-all target';
  is $USAGE[0]{model}, $CHAT_MODEL, 'model is the served model';

  embed($t, 'text-embedding-3-small')->status_is(200);
  is $USAGE[1]{requested_model}, 'text-embedding-3-small', 'embeddings: requested_model';
  is $USAGE[1]{routed_model}, $EMB_MODEL, 'embeddings: routed_model';
  is $USAGE[1]{model}, $EMB_MODEL, 'embeddings: model';

  anthropic($t, 'claude-x')->status_is(200);
  is $USAGE[2]{requested_model}, 'claude-x', 'Anthropic face: requested_model';
  is $USAGE[2]{routed_model}, $CHAT_MODEL, 'Anthropic face: routed_model';

  $t->post_ok('/api/chat' => json => { model => 'llama3', stream => false, messages => [ { role => 'user', content => 'hi' } ] })
    ->status_is(200);
  is $USAGE[3]{requested_model}, 'llama3', 'Ollama face: requested_model';
  is $USAGE[3]{routed_model}, $CHAT_MODEL, 'Ollama face: routed_model';
};

subtest 'a catch-all target that is an alias: three different names in the event' => sub {
  my ($t) = proxy(config => {
    routing => { catch_all => { chat => 'house-chat' } },
    aliases => { 'house-chat' => { tiers => [ { model => $CHAT_MODEL } ] } },
  });
  chat($t, $MADE_UP)->status_is(200)->json_is('/model' => $CHAT_MODEL, 'the answer names the served model');
  is $SEEN{'chat-1'}[0]{json}{model}, $CHAT_MODEL, 'the node is asked for the served model of the alias tier';
  is $USAGE[0]{requested_model}, $MADE_UP, 'requested_model: what the client sent';
  is $USAGE[0]{routed_model}, 'house-chat', 'routed_model: the alias the catch-all names';
  is $USAGE[0]{model}, $CHAT_MODEL, 'model: what the node served';

  chat($t, 'house-chat')->status_is(200);
  is $USAGE[1]{requested_model}, 'house-chat', 'an ordinary request for the alias: requested_model';
  is $USAGE[1]{model}, $CHAT_MODEL, 'and model';
  ok !exists($USAGE[1]{routed_model}), 'and no routed_model: that is what tells an alias request from a bent one';
};

subtest 'a request that was not bent has no routed_model' => sub {
  my ($t) = proxy(config => catch_all());
  chat($t, $CHAT_MODEL)->status_is(200);
  embed($t, $EMB_MODEL)->status_is(200);
  is scalar(@USAGE), 2, 'two events';
  ok !exists($_->{routed_model}), 'a known name: the event has no routed_model key' for @USAGE;
};

subtest 'a bent request that fails upstream is one failed event with routed_model, and no leaked slot' => sub {
  my ($t, $skeid) = proxy(config => catch_all());
  $MODE = 'fail';
  chat($t, $MADE_UP);
  is $t->tx->res->code, 500, 'the upstream status is the client\'s status';
  is scalar(@USAGE), 1, 'one event';
  is $USAGE[0]{ok}, 0, 'a failed one';
  is $USAGE[0]{routed_model}, $CHAT_MODEL, 'it still says what the request was routed under';
  is $USAGE[0]{requested_model}, $MADE_UP, 'and what was asked';
  paired($skeid, 'chat-1', 'bent, upstream 500');
};

subtest 'a bent request refused at admission leaves the slot count where it was and no event' => sub {
  my ($t, $skeid) = proxy(config => catch_all(), nodes => 0);
  node($skeid, 'chat-1', model => $CHAT_MODEL, max_conns => 1);
  $skeid->set_capacity_reading('chat-1', used => 1, limit => 1, source => 'prometheus');
  chat($t, $MADE_UP)->status_is(429, 'a saturated target is 429, as it is for a request for the target by name')
    ->json_is('/error/type' => 'rate_limit_error');
  is count('chat-1'), 0, 'never forwarded';
  is scalar(@USAGE), 0, 'so no event';
  paired($skeid, 'chat-1', 'bent, refused');
};

subtest 'jsonlog writes routed_model only when it is set' => sub {
  my $dir = tempdir(CLEANUP => 1, DIR => $TMP);
  my ($t) = proxy(usage_store => { backend => 'jsonlog', log_path => "$dir/usage.jsonl" }, config => catch_all());
  chat($t, $MADE_UP)->status_is(200);
  chat($t, $CHAT_MODEL)->status_is(200);
  my @lines = map { decode_json($_) } grep { length } split /\n/, path("$dir/usage.jsonl")->slurp_utf8;
  is scalar(@lines), 2, 'two lines';
  is $lines[0]{routed_model}, $CHAT_MODEL, 'the bent request: routed_model written';
  is $lines[0]{requested_model}, $MADE_UP, 'with the name the client sent beside it';
  ok !exists($lines[1]{routed_model}), 'the request that was not bent: no routed_model key at all';
};

subtest 'the sqlite store keeps routed_model in a nullable column and upgrades an older table' => sub {
  eval { require DBI; require DBD::SQLite; 1 } or plan skip_all => 'DBI/DBD::SQLite not available';

  # A bent and an unbent event through the proxy and the store.
  my $db = "$TMP/proxy.sqlite";
  my ($t) = proxy(usage_store => { backend => 'sqlite', sqlite_path => $db }, config => catch_all());
  chat($t, $MADE_UP)->status_is(200);
  chat($t, $CHAT_MODEL)->status_is(200);
  my $rows;
  for (1 .. 40) {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
    $rows = eval { $dbh->selectall_arrayref('SELECT requested_model, routed_model, model FROM usage_events ORDER BY id') };
    $dbh->disconnect;
    last if $rows && @$rows == 2;
    Mojo::IOLoop->timer(0.05 => sub { Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
  }
  is_deeply $rows, [ [ $MADE_UP, $CHAT_MODEL, $CHAT_MODEL ], [ $CHAT_MODEL, undef, $CHAT_MODEL ] ],
    'a bent request stores its three names, an unbent one has NULL, not an empty string';

  # A table from before the column gains it on prepare, once; its old rows read NULL.
  my $old = "$TMP/old.sqlite";
  my $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1, PrintError => 0 });
  $odbh->do(q{
    CREATE TABLE usage_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL, request_id TEXT, api_format TEXT, endpoint TEXT,
      api_key_id TEXT, provider TEXT, engine TEXT, model TEXT, requested_model TEXT,
      node_id TEXT, route_url TEXT, status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0,
      duration_ms INTEGER, input_tokens INTEGER NOT NULL DEFAULT 0,
      output_tokens INTEGER NOT NULL DEFAULT 0, total_tokens INTEGER NOT NULL DEFAULT 0,
      cached_tokens INTEGER, cache_write_tokens INTEGER, content_bytes INTEGER,
      tool_calls INTEGER NOT NULL DEFAULT 0, cost_input_usd REAL NOT NULL DEFAULT 0,
      cost_output_usd REAL NOT NULL DEFAULT 0, cost_total_usd REAL NOT NULL DEFAULT 0,
      cost_cache_read_usd REAL, cost_cache_write_usd REAL, audio_seconds REAL,
      error_type TEXT, error_message TEXT
    )
  });
  $odbh->do(q{INSERT INTO usage_events (created_at, api_key_id, model, ok, total_tokens)
    VALUES ('2026-09-01T00:00:00Z', 'k_old', 'chat', 1, 7)});
  $odbh->disconnect;

  my $upgraded = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  my $written = $upgraded->call_function('usage.record', {
    api_key_id => 'k_new', model => 'served', requested_model => 'made-up', routed_model => 'target',
    status_code => 200, ok => 1, metrics => { usage => { input => 1, output => 1, total => 2 } },
  });
  ok $written->{ok}, 'an event still writes against a table that predates the column';
  Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1, PrintError => 0 });
  my @cols = grep { $_->{name} eq 'routed_model' }
    @{ $odbh->selectall_arrayref('PRAGMA table_info(usage_events)', { Slice => {} }) };
  is scalar(@cols), 1, 'the column is added to the older table, and only once';
  ok !$cols[0]{notnull}, 'and it is nullable';
  is_deeply eval { $odbh->selectcol_arrayref('SELECT routed_model FROM usage_events ORDER BY id') },
    [ undef, 'target' ], 'the old row reads NULL, the new one its target';
  $odbh->disconnect;
};

# --- 8. off by default ---------------------------------------------------------------------

subtest 'without routing.catch_all an unknown name is a 503, and its event has no routed_model' => sub {
  my ($t, $skeid) = proxy(config => {});
  chat($t, $MADE_UP)->status_is(503)->json_is('/error/type' => 'model_not_found');
  embed($t, $MADE_UP)->status_is(503)->json_is('/error/type' => 'model_not_found');
  anthropic($t, $MADE_UP)->status_is(503);
  is count('chat-1') + count('emb-1'), 0, 'nothing reached a node';
  is scalar(@USAGE), 0, 'a request that was never forwarded has no event';
  chat($t, $CHAT_MODEL)->status_is(200);
  ok !exists($USAGE[0]{routed_model}), 'a served request has no routed_model';
};

subtest 'a kind the key does not name is not bent' => sub {
  my ($t) = proxy(config => { routing => { catch_all => { chat => $CHAT_MODEL } } });
  chat($t, $MADE_UP)->status_is(200, 'chat is configured');
  embed($t, $MADE_UP)->status_is(503, 'embeddings is not: an unknown name stays 503')->json_is('/error/type' => 'model_not_found');
  $t->post_ok('/api/embed' => json => { model => $MADE_UP, input => 'x' })->status_is(503, 'also on the Ollama embed route');
  is count('emb-1'), 0, 'the embeddings node was never asked';

  my ($t2) = proxy(config => { routing => { catch_all => { embeddings => $EMB_MODEL } } });
  embed($t2, $MADE_UP)->status_is(200, 'embeddings only: bent');
  chat($t2, $MADE_UP)->status_is(503, 'and chat is not');
};

# --- 9. config load ------------------------------------------------------------------------

subtest 'a catch_all that is not chat and embeddings fails the config load' => sub {
  my $load = sub { my ($catch_all) = @_;
    return eval { Langertha::Skeid->new(config_loader => sub { +{ routing => { catch_all => $catch_all } } }); 1 } };
  ok  $load->({ chat => 'm' }), 'chat alone loads';
  ok  $load->({ embeddings => 'm' }), 'embeddings alone loads';
  ok  $load->({ chat => 'a-target-no-node-serves-yet' }), 'a target no node serves loads: a node file or a reload can bring it';
  ok !$load->({ chat => 'm', rerank => 'm' }), 'an unknown key (rerank) fails the load';
  ok !$load->({ audio => 'm' }), 'so does another one';
  ok !$load->({ chat => '' }), 'an empty target fails';
  ok !$load->({ chat => [ 'm' ] }), 'a list as target fails';
  ok !$load->({ chat => { model => 'm' } }), 'a hash as target fails';
  ok !$load->('chat-model'), 'catch_all that is not a mapping fails';
};

subtest 'a reload that drops routing.catch_all turns it off, and one that adds it turns it on' => sub {
  my ($t) = proxy(config => catch_all());
  chat($t, $MADE_UP)->status_is(200, 'on');
  $CFG = {};
  chat($t, $MADE_UP)->status_is(503, 'the key removed: an unknown name is a 503 again')
    ->json_is('/error/type' => 'model_not_found');
  embed($t, $MADE_UP)->status_is(503, 'for the other kind too');
  $CFG = { routing => { catch_all => { embeddings => $EMB_MODEL } } };
  embed($t, $MADE_UP)->status_is(200, 'a reload that names one kind turns that kind on');
  chat($t, $MADE_UP)->status_is(503, 'and not the other');
};

# --- 10. nothing else changes --------------------------------------------------------------

subtest 'the model lists are the same with and without the catch-all' => sub {
  my @lists;
  for my $cfg ({}, catch_all()) {
    my ($t) = proxy(config => { %$cfg, aliases => { 'house-chat' => { tiers => [ { model => $CHAT_MODEL } ] } } });
    $t->get_ok('/v1/models')->status_is(200);
    my $j = $t->tx->res->json;
    push @lists, [ sort map { $_->{id} } @{ $j->{data} } ];
    $t->get_ok('/api/tags')->status_is(200);
    push @lists, [ sort map { $_->{name} } @{ $t->tx->res->json->{models} } ];
  }
  is_deeply $lists[2], $lists[0], '/v1/models is unchanged';
  is_deeply $lists[3], $lists[1], '/api/tags is unchanged';
  ok scalar(@{ $lists[0] }), 'and not empty (the comparison is not of two empty lists)';
  ok !(grep { /catch/i } map { @$_ } @lists), 'the catch-all is not a name';
};

subtest 'a route that is not bent keeps answering an unknown name as before' => sub {
  my ($t) = proxy(config => catch_all());
  $t->post_ok('/v1/rerank' => json => { model => $MADE_UP, query => 'q', documents => [ 'a', 'b' ] })
    ->status_is(503, 'rerank: an unknown name is a 503')->json_is('/error/type' => 'model_not_found');
  is count('chat-1') + count('emb-1'), 0, 'and it was not sent to the chat or the embeddings target';
  $t->post_ok('/rerank' => json => { model => $MADE_UP, query => 'q', documents => [ 'a' ] })
    ->status_is(503, 'the /rerank spelling as well');
  is scalar(@USAGE), 0, 'no event';
};

# --- 11. GET /skeid/config -----------------------------------------------------------------

# Shape picked (the ADR names none): a top-level `catch_all` object beside `nodes`, as `nodes`
# is where node trust is shown. {chat, embeddings}, only the kinds configured; the key is absent
# when nothing is configured.
subtest 'GET /skeid/config shows the catch-all in effect' => sub {
  my $adm = { Authorization => 'Bearer adm-test' };
  my ($t) = proxy(config => catch_all(), admin_api_key => 'adm-test');
  $t->get_ok('/skeid/config' => $adm)->status_is(200)
    ->json_is('/catch_all/chat' => $CHAT_MODEL)->json_is('/catch_all/embeddings' => $EMB_MODEL);

  my ($t2) = proxy(config => { routing => { catch_all => { chat => $CHAT_MODEL } } }, admin_api_key => 'adm-test');
  $t2->get_ok('/skeid/config' => $adm)->status_is(200)->json_is('/catch_all/chat' => $CHAT_MODEL);
  ok !exists($t2->tx->res->json->{catch_all}{embeddings}), 'a kind that is not configured is not shown';

  my ($t3) = proxy(config => {}, admin_api_key => 'adm-test');
  $t3->get_ok('/skeid/config' => $adm)->status_is(200);
  ok !exists($t3->tx->res->json->{catch_all}), 'without the key there is no catch_all section';

  $CFG = catch_all();
  $t3->get_ok('/skeid/config' => $adm)->json_is('/catch_all/chat' => $CHAT_MODEL, 'a reload is picked up');
  $CFG = {};
  $t3->get_ok('/skeid/config' => $adm);
  ok !exists($t3->tx->res->json->{catch_all}), 'and its removal as well';
};

done_testing;
