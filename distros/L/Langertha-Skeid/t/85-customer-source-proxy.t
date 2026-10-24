use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Time::HiRes ();
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Customer keys from a database view, seen from the client routes (ADR 0026). A source key is let
# in; removing its row makes the next request after the refresh a 401 in every dialect; changing
# its policy turns a model into a 403. The database is never on the request path: a hundred
# requests cost no fetch, and a fetcher that never answers leaves the proxy serving. Every
# request.start keeps its request.finish.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER )};

my @WARN;
$SIG{__WARN__} = sub { push @WARN, $_[0] };

my $ALICE_KEY = 'sk-alice-from-the-console';
my $FILE_KEY  = 'sk-file-customer';
my $ALICE     = Langertha::Skeid->key_id_for_key($ALICE_KEY);
my $FILE      = Langertha::Skeid->key_id_for_key($FILE_KEY);
my $ADMIN     = 'admin-test-key';
my $MESSAGES  = [{ role => 'user', content => 'hi' }];

{
  package FakeFetcher;
  sub new { my ($class, %a) = @_; return bless { rows => [], silent => 0, fetches => 0, %a }, $class }
  sub fetch {
    my ($self, $cb) = @_;
    $self->{fetches}++;
    return if $self->{silent};
    my $rows = [ map { {%$_} } @{$self->{rows}} ];
    Mojo::IOLoop->timer(0.001 => sub { $cb->(undef, $rows) });
    return;
  }
}

sub wait_until {
  my ($cond, $max) = @_;
  my $end  = Time::HiRes::time() + ($max // 3);
  my $tick = Mojo::IOLoop->recurring(0.005 => sub { });
  Mojo::IOLoop->one_tick until $cond->() || Time::HiRes::time() > $end;
  Mojo::IOLoop->remove($tick);
  return $cond->() ? 1 : 0;
}

sub proxy {
  my ($fake, %source) = @_;
  my $cfg = {
    policies       => { basic => { models => ['m'] }, other => { models => ['m2'] } },
    default_policy => 'basic',
    client_auth    => { keys => [ $FILE ] },
    admin_api_key  => $ADMIN,
    customer_source => { dsn => 'dbi:Pg:dbname=console', relation => 'skeid.customer_keys',
      refresh_interval_s => 0.1, connect_timeout_s => 1, %source },
  };
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms   => 50,
    route_wait_poll_ms      => 5,
    config_reload_interval  => 0,
    config_loader           => sub { $cfg },
    customer_source_fetcher => sub { $fake },
    store_usage_event       => sub { return { ok => 1 } },
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('fatal');
  $app->routes->post('/__up/v1/chat/completions' => sub {
    my ($c) = @_;
    $c->render(json => {
      id => 'c1', object => 'chat.completion', model => $c->req->json->{model},
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 4, completion_tokens => 2, total_tokens => 6 },
    });
  });
  my $t = Test::Mojo->new($app);
  my $up = $t->ua->server->nb_url->clone->path('/__up/v1');
  # Admin-pushed nodes: the config declares no nodes: section, so a reload keeps them.
  $skeid->add_node(id => 'n1', url => "$up", model => 'm',  engine => 'openai', max_conns => 4);
  $skeid->add_node(id => 'n2', url => "$up", model => 'm2', engine => 'openai', max_conns => 4);
  return ($t, $skeid);
}

my %FACES = (
  openai    => [ '/v1/chat/completions', { model => 'm', messages => $MESSAGES } ],
  anthropic => [ '/v1/messages',         { model => 'm', max_tokens => 10, messages => $MESSAGES } ],
  ollama    => [ '/api/chat',            { model => 'm', stream => \0, messages => $MESSAGES } ],
);

sub ask {
  my ($t, $face, $key, %body) = @_;
  my ($path, $base) = @{$FACES{$face}};
  return $t->post_ok($path => { Authorization => "Bearer $key" } => json => { %$base, %body });
}

sub paired {
  my ($skeid, $label) = @_;
  for my $id (qw(n1 n2)) {
    my $m = $skeid->node_metrics($id);
    is $m->{inflight}, 0, "$label: nothing in flight on $id";
    is $m->{ok} + $m->{error}, $m->{started}, "$label: every request.start on $id has its request.finish";
  }
}

# --- let in, revoked (401 per dialect), policy changed (403) ---
{
  my $fake = FakeFetcher->new(rows => [ { key_id => $ALICE, name => 'alice', policy => undef, models => undef } ]);
  my ($t, $skeid) = proxy($fake);
  ok wait_until(sub { $skeid->client_key_allowed($ALICE) }), 'the first fetch ran on the loop';

  ask($t, $_, $ALICE_KEY)->status_is(200, "$_: a source key is let in") for sort keys %FACES;

  $fake->{rows} = [];
  my $n = $fake->{fetches};
  ok wait_until(sub { $fake->{fetches} > $n + 1 }), 'the refresh ran';
  ask($t, 'openai', $ALICE_KEY)->status_is(401, 'openai: revoked key refused')
    ->json_is('/error/code' => 'invalid_api_key');
  ask($t, 'anthropic', $ALICE_KEY)->status_is(401, 'anthropic: revoked key refused')
    ->json_is('/error/type' => 'authentication_error');
  ask($t, 'ollama', $ALICE_KEY)->status_is(401, 'ollama: revoked key refused')
    ->json_like('/error' => qr/Invalid API key/);
  ask($t, 'openai', $FILE_KEY)->status_is(200, 'the file\'s customer is not affected');

  $fake->{rows} = [ { key_id => $ALICE, name => 'alice', policy => 'other', models => undef } ];
  ok wait_until(sub { $skeid->client_key_allowed($ALICE) }), 'the row is back';
  ask($t, 'openai', $ALICE_KEY)->status_is(403, 'policy changed: the model is no longer permitted')
    ->json_is('/error/type' => 'permission_error');
  ask($t, 'openai', $ALICE_KEY, model => 'm2')->status_is(200, 'the new policy\'s model is');

  $t->get_ok('/skeid/config' => { Authorization => "Bearer $ADMIN" })->status_is(200)
    ->json_is('/customer_source/ok' => 1, '/skeid/config carries the source status')
    ->json_is('/customer_source/rows/accepted' => 1)
    ->json_is('/customer_source/relation' => 'skeid.customer_keys');
  $t->get_ok('/health')->status_is(200)->json_is('/status' => 'ok')
    ->json_is('/customer_source/ok' => 1, '/health carries ok');
  ok !exists $t->tx->res->json->{customer_source}{error}, '/health never carries the message';
  ok !exists $t->tx->res->json->{customer_source}{rows}, 'nor the rows';

  paired($skeid, 'revocation');
  $skeid->stop_customer_source;
}

# --- /health stays ok while the source fails, without the message ---
{
  my $fake = FakeFetcher->new(rows => []);
  my ($t, $skeid) = proxy($fake);
  wait_until(sub { $fake->{fetches} >= 1 && ($skeid->customer_source_status->{ok} // 0) });
  $fake->{silent} = 1;
  ok wait_until(sub { !$skeid->customer_source_status->{ok} }, 3), 'a silent fetch times out';
  $t->get_ok('/health')->status_is(200)->json_is('/status' => 'ok', 'still ok: the proxy is serving')
    ->json_is('/customer_source/ok' => 0);
  ok $t->tx->res->json->{customer_source}{failures} >= 1, 'with the failure count';
  ok $t->tx->res->json->{customer_source}{failed_at}, 'and when';
  unlike $t->tx->res->body, qr/timed out/, 'never the message';
  $t->get_ok('/skeid/config' => { Authorization => "Bearer $ADMIN" })
    ->json_like('/customer_source/error' => qr/timed out/, 'the admin route has it');
  $skeid->stop_customer_source;
}

# --- no database on the request path ---
{
  my $fake = FakeFetcher->new(rows => [ { key_id => $ALICE, name => 'alice', policy => undef, models => undef } ]);
  my ($t, $skeid) = proxy($fake, refresh_interval_s => 3600);
  ok wait_until(sub { $skeid->client_key_allowed($ALICE) }), 'first fetch';
  my $n = $fake->{fetches};
  for my $i (1 .. 100) {
    my $face = (qw(openai anthropic ollama))[$i % 3];
    ask($t, $face, $ALICE_KEY);
    $t->get_ok('/skeid/config' => { Authorization => "Bearer $ADMIN" }) if $i % 25 == 0;
  }
  is $fake->{fetches}, $n, '100 requests cause zero fetches';
  paired($skeid, '100 requests');
  $skeid->stop_customer_source;
}

# --- a fetcher that never answers does not block the loop ---
{
  my $fake = FakeFetcher->new(silent => 1);
  my ($t, $skeid) = proxy($fake, connect_timeout_s => 60);
  ok wait_until(sub { $fake->{fetches} >= 1 }), 'the fetch is in flight';
  my $t0 = Time::HiRes::time();
  ask($t, $_, $FILE_KEY)->status_is(200, "$_: served while the fetch hangs") for sort keys %FACES;
  cmp_ok Time::HiRes::time() - $t0, '<', 5, 'promptly';
  ask($t, 'openai', $ALICE_KEY)->status_is(401, 'fail-closed: no snapshot, no source key');
  is $fake->{fetches}, 1, 'still the one fetch';
  paired($skeid, 'hanging fetcher');
  $skeid->stop_customer_source;
}

unlike join('', @WARN), qr/\Q$ALICE_KEY\E|\Q$FILE_KEY\E/, 'no key in any warning';

done_testing;
