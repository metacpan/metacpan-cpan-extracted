#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::Server::Daemon;
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(decode_json encode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# The usage contract (skeid k121): per request, how the answer ended (finish_reason), the time to
# its first token (ttft_ms, streams) and the caller's correlation id from a configured header.
# A truncated answer (length) is the silent quality failure of an agent; it has to be in the row.

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
my @seen_headers;
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  push @seen_headers, $c->req->headers->to_hash;
  my $req = decode_json($c->req->body);
  my $reason = $req->{model} eq 'm-tools' ? 'tool_calls' : $req->{model} eq 'm-odd' ? 'eos_token' : 'length';
  return $c->render(status => 500, json => { error => { message => 'boom' } }) if $req->{model} eq 'm-fail';
  unless ($req->{stream}) {
    return $c->render(json => { id => 'c1', object => 'chat.completion', model => $req->{model},
      choices => [{ index => 0, message => { role => 'assistant', content => 'Hel' }, finish_reason => $reason }],
      usage => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 } });
  }
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"role":"assistant"}}]}\n\n});
  Mojo::IOLoop->timer(0.05 => sub {
    $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"Hel"}}]}\n\n});
    $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [{ index => 0, delta => {}, finish_reason => $reason }] }) . "\n\n");
    $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [], usage => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 } }) . "\n\n");
    $c->write_chunk("data: [DONE]\n\n" => sub { $c->finish });
  });
});
$upstream->routes->post('/v1/embeddings' => sub {
  $_[0]->render(json => { object => 'list', model => 'e', data => [{ index => 0, embedding => [1] }],
    usage => { prompt_tokens => 1, total_tokens => 1 } });
});
my $daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$daemon->start;
my $UP = 'http://127.0.0.1:' . $daemon->ports->[0] . '/v1';

my @events;
my $header = 'X-Correlation-ID';
my $skeid = Langertha::Skeid->new(
  config_reload_interval => 0,
  store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
  config_loader     => sub { +{
    ($header ? (routing => { correlation_header => $header }) : ()),
    nodes => [ map { +{ id => "n-$_", trust => 'internal', url => $UP, model => $_ } } qw( m m-tools m-odd m-fail e ) ],
  } },
);
my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid));
$t->app->log->level('fatal');

sub last_event { @events = (); $_[0]->(); return $events[-1] }
my $msgs = [{ role => 'user', content => 'hi' }];

my $e = last_event(sub {
  $t->post_ok('/v1/chat/completions' => { $header => 'run-1234.abc_X' } => json => { model => 'm', messages => $msgs })
    ->status_is(200);
});
is $e->{finish_reason}, 'length', 'a truncated non-streamed answer records length';
ok !exists $e->{ttft_ms}, 'a non-streamed answer has no time to first token';
is $e->{correlation_id}, 'run-1234.abc_X', 'the correlation id is passed through unchanged';
ok !grep({ my $h = $_; grep { lc($_) eq 'x-correlation-id' } keys %$h } @seen_headers),
  'and the header is not passed on to the node';

$e = last_event(sub {
  $t->post_ok('/v1/chat/completions' => json => { model => 'm-tools', messages => $msgs, stream => \1 })->status_is(200);
});
is $e->{finish_reason}, 'tool_calls', 'a streamed answer records its finish reason';
ok defined($e->{ttft_ms}) && $e->{ttft_ms} >= 40, "and the time to its first token ($e->{ttft_ms} ms)";
cmp_ok $e->{ttft_ms}, '<=', $e->{duration_ms}, 'which is within the duration';
ok !exists $e->{correlation_id}, 'no header, no correlation id';

$e = last_event(sub {
  $t->post_ok('/api/chat' => json => { model => 'm-odd', messages => $msgs, stream => \0 })->status_is(200);
});
is $e->{finish_reason}, 'other', 'a reason outside the contract is other, also through the Ollama face';

$e = last_event(sub {
  $t->post_ok('/v1/messages' => json => { model => 'm', max_tokens => 5, messages => $msgs, stream => \1 })->status_is(200);
});
is $e->{finish_reason}, 'length', 'the Anthropic face records the upstream reason';

$e = last_event(sub { $t->post_ok('/v1/chat/completions' => json => { model => 'm-fail', messages => $msgs }) });
is $e->{finish_reason}, 'error', 'a failed request is error';

$e = last_event(sub {
  $t->post_ok('/v1/chat/completions' => { $header => 'short' } => json => { model => 'nope', messages => $msgs });
});
ok !@events || !exists($events[-1]{correlation_id}), 'a correlation id outside the pattern is not recorded';

$e = last_event(sub { $t->post_ok('/v1/embeddings' => json => { model => 'e', input => 'x' })->status_is(200) });
ok !exists $e->{finish_reason}, 'an embeddings answer has no finish reason';

$e = last_event(sub {
  $t->post_ok('/v1/chat/completions' => { $header => ('x' x 65) } => json => { model => 'm', messages => $msgs });
});
ok !exists $e->{correlation_id}, 'nor one above 64 characters';

$header = undef;
$e = last_event(sub {
  $t->post_ok('/v1/chat/completions' => { 'X-Correlation-ID' => 'run-1234.abc_X' } => json => { model => 'm', messages => $msgs });
});
ok !exists $e->{correlation_id}, 'without routing.correlation_header nothing is recorded';

ok !eval { Langertha::Skeid->new(config_loader => sub { +{ routing => { correlation_header => "X-A\r\nB" } } }); 1 },
  'a correlation_header that is no header name fails the load';

# --- a client that hangs up is not an error of the answer ---
{
  my %args = (ok => 0, status_code => 499, error_type => 'client_abort');
  is_deeply { Langertha::Skeid::Proxy::_finish_reason_field({ %args }) }, { finish_reason => 'other' },
    'a client abort before any finish reason is other';
  is_deeply { Langertha::Skeid::Proxy::_finish_reason_field({ %args, finish_reason => 'length' }) },
    { finish_reason => 'length' }, 'after one it keeps that reason';
  is_deeply { Langertha::Skeid::Proxy::_finish_reason_field({ ok => 0, status_code => 502, error_type => 'upstream_error', finish_reason => 'stop' }) },
    { finish_reason => 'error' }, 'an upstream failure stays error';
}

# --- the SQLite store keeps the three columns, and an old table gains them ---
SKIP: {
  eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 4;
  my $dir = tempdir(CLEANUP => 1);
  my $db  = "$dir/old.sqlite";
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  $dbh->do(q{CREATE TABLE usage_events (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at TEXT NOT NULL,
    request_id TEXT, api_format TEXT, endpoint TEXT, api_key_id TEXT, provider TEXT, engine TEXT,
    model TEXT, node_id TEXT, route_url TEXT, status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0,
    duration_ms INTEGER, input_tokens INTEGER NOT NULL DEFAULT 0, output_tokens INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER NOT NULL DEFAULT 0, tool_calls INTEGER NOT NULL DEFAULT 0,
    cost_input_usd REAL NOT NULL DEFAULT 0, cost_output_usd REAL NOT NULL DEFAULT 0,
    cost_total_usd REAL NOT NULL DEFAULT 0, error_type TEXT, error_message TEXT)});
  $dbh->disconnect;

  my $store = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  ok $store->call_function('usage.record', { api_key_id => 'k', model => 'm', ok => 1, status_code => 200,
    finish_reason => 'length', ttft_ms => 123, correlation_id => 'run-1234' })->{ok}, 'an event writes against an upgraded table';
  ok $store->call_function('usage.record', { api_key_id => 'k2', model => 'm', ok => 1, status_code => 200 })->{ok},
    'and one without the three fields';
  $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  is_deeply $dbh->selectrow_hashref(q{SELECT finish_reason, ttft_ms, correlation_id FROM usage_events WHERE api_key_id = 'k'}),
    { finish_reason => 'length', ttft_ms => 123, correlation_id => 'run-1234' }, 'the row carries all three';
  is_deeply $dbh->selectrow_hashref(q{SELECT finish_reason, ttft_ms, correlation_id FROM usage_events WHERE api_key_id = 'k2'}),
    { finish_reason => undef, ttft_ms => undef, correlation_id => undef }, 'and NULL where they are not known';
}

done_testing;
