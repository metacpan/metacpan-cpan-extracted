use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS qw(decode_json);
use Time::HiRes ();
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Registry;
use Langertha::Skeid::CapacityProbe;
use Langertha::Skeid::CapacityProbe::Registry;

# The Skeid-to-Skeid registry (skeid #18, ADR 0017). A fronting Skeid in front of other Skeids
# otherwise picks a downstream blind: its own inflight per downstream undercounts the moment any
# other path sends traffic there. The downstream already knows its load, so it publishes a
# signed snapshot and the fronting tier reads it as a capacity probe. The load-bearing rules:
# off by default, never unsigned, nothing secret or customer-identifying in the snapshot, and a
# snapshot that is stale, replayed or unverifiable is forgotten -- admission degrades to
# inflight rather than trusting it.

my $SECRET_ENV = 'SKEID_T57_REGISTRY_SECRET';
my $ADMIN_ENV  = 'SKEID_T57_DOWNSTREAM_ADMIN';
$ENV{$SECRET_ENV} = 'registry-shared-secret-57-0123456789abcdef';
$ENV{$ADMIN_ENV}  = 'adm';
my $ADMIN = { Authorization => 'Bearer adm' };

sub quiet_app {
  my ($skeid) = @_;
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level(q{fatal});
  return $app;
}

sub spin {
  my ($seconds) = @_;
  Mojo::IOLoop->timer($seconds => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  return;
}

sub downstream_config {
  my (%extra) = @_;
  return {
    admin => { api_key => 'adm' },
    nodes => [
      { id => 'gpu-hot',  url => 'http://127.0.0.1:1/v1', model => 'm', max_conns => 4, tags => ['local'] },
      { id => 'gpu-cool', url => 'http://127.0.0.1:1/v1', model => 'm', max_conns => 4, tags => ['local'] },
    ],
    %extra,
  };
}

# --- off by default: no route ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub { downstream_config() });
  ok !$skeid->registry_enabled, 'a config without a registry block does not publish';
  my $t = Test::Mojo->new(quiet_app($skeid));
  $t->get_ok('/skeid/registry/snapshot' => $ADMIN)->status_is(404,
    'the snapshot route answers 404 even to the admin key when the registry is not enabled');

  my $explicit_off = Langertha::Skeid->new(config_loader => sub {
    downstream_config(registry => { enabled => 0, secret_env => $SECRET_ENV }) });
  Test::Mojo->new(quiet_app($explicit_off))
    ->get_ok('/skeid/registry/snapshot' => $ADMIN)->status_is(404, 'and so does enabled: false');
}

# --- config validation: never unsigned, secrets never in the file ---
{
  my $load = sub {
    my ($cfg) = @_;
    my $ok = eval { Langertha::Skeid->new(config_loader => sub { $cfg }); 1 };
    return $ok ? '' : "$@";
  };

  like $load->(downstream_config(registry => { enabled => 1 })), qr/secret_env is required/,
    'enabled without secret_env does not load';
  {
    local $ENV{SKEID_T57_UNSET};
    delete $ENV{SKEID_T57_UNSET};
    like $load->(downstream_config(registry => { enabled => 1, secret_env => 'SKEID_T57_UNSET' })),
      qr/not set.*never\s+published unsigned/s, 'enabled with an empty secret variable does not load';
  }
  like $load->(downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV, secret => 'x' })),
    qr/unknown key 'secret'/, 'a secret written into the config is refused, not ignored';
  like $load->(downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV, ttl_s => 0 })),
    qr/ttl_s must be a positive/, 'a zero ttl does not load';
  {
    local $ENV{SKEID_T57_SHORT} = 'x' x 31;
    like $load->(downstream_config(registry => { enabled => 1, secret_env => 'SKEID_T57_SHORT' })),
      qr/fewer than 32 bytes/, 'a secret shorter than 32 bytes does not load';
  }
  {
    my $cfg = downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV });
    delete $cfg->{admin};
    like $load->($cfg), qr/needs a credential to read the snapshot/,
      'enabled without an admin key or a read key does not load: nobody could read the snapshot';
  }
  {
    # skeid #49: the read key alone is enough -- a downstream need not have an admin API at all.
    local $ENV{SKEID_T57_READ} = 'read-only-57';
    my $cfg = downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV,
      read_key_env => 'SKEID_T57_READ' });
    delete $cfg->{admin};
    is $load->($cfg), '', 'enabled with only a read key loads';
  }
  {
    local $ENV{SKEID_T57_UNSET};
    delete $ENV{SKEID_T57_UNSET};
    like $load->(downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV,
      read_key_env => 'SKEID_T57_UNSET' })), qr/read_key_env names 'SKEID_T57_UNSET', which is not set/,
      'a read_key_env naming an empty variable does not load, admin key or not';
  }
  like $load->(downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV, read_key => 'x' })),
    qr/unknown key 'read_key'/, 'the read key itself in the config is refused, not ignored';

  my $probe_node = sub {
    my (%cap) = @_;
    return { nodes => [ { id => 'peer', url => 'http://peer/v1', model => 'm',
      capacity => { probe => 'registry', %cap } } ] };
  };
  like $load->($probe_node->(admin_key_env => $ADMIN_ENV)), qr/secret_env is required/,
    'a registry probe without secret_env does not load';
  like $load->($probe_node->(secret_env => $SECRET_ENV)), qr/read_key_env \(or admin_key_env\) is required/,
    'nor without read_key_env or admin_key_env';
  is $load->($probe_node->(secret_env => $SECRET_ENV, read_key_env => 'SKEID_T57_READ')), '',
    'read_key_env alone is enough on the probe';
  like $load->($probe_node->(secret_env => $SECRET_ENV, admin_key_env => $ADMIN_ENV, secret => 'x')),
    qr/unknown key 'secret'/, 'nor with the secret itself in the block';
  like $load->($probe_node->(secret_env => $SECRET_ENV, admin_key_env => $ADMIN_ENV, url => 'ftp://x')),
    qr/absolute http/, 'nor with a non-http url';
  is $load->($probe_node->(secret_env => $SECRET_ENV, admin_key_env => $ADMIN_ENV)), '',
    'a complete block loads';
  is $load->({ nodes => [ { id => 'peer', url => 'http://peer/v1', model => 'm',
      capacity => { type => 'registry', secret_env => $SECRET_ENV, admin_key_env => $ADMIN_ENV } } ] }), '',
    'type: registry is accepted as well as probe: registry';

  # The admin API adds nodes too; a bad block is a 400 there, not a silently forgetting probe.
  my $skeid = Langertha::Skeid->new(admin_api_key => 'adm');
  Test::Mojo->new(quiet_app($skeid))
    ->post_ok('/skeid/nodes' => $ADMIN => json => { id => 'peer', url => 'http://peer/v1',
      capacity => { probe => 'registry', admin_key_env => $ADMIN_ENV } })
    ->status_is(400);
}

# --- the published snapshot: signed, schema v1, nothing it must not carry ---
{
  my $customer_key = 'sk-customer-secret-57';
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    my $cfg = downstream_config(
      registry => { enabled => 1, secret_env => $SECRET_ENV, ttl_s => 7, instance_id => 'skeid-b' },
    );
    $cfg->{nodes}[0]{url} = 'http://secret-host-57.internal:8000/v1';
    $cfg->{nodes}[0]{api_key_ref} = 'secret/skeid/remote/groq57';
    $cfg->{nodes}[0]{api_key_env} = 'GROQ57_KEY';
    $cfg->{nodes}[0]{metadata} = { owner => 'metadata-marker-57' };
    $cfg->{policies} = { premium => {} };
    $cfg->{keys} = { Langertha::Skeid->key_id_for_key($customer_key) => 'premium' };
    return $cfg;
  });
  my $key_id = $skeid->key_id_for_key($customer_key);

  $skeid->start_request('gpu-hot') for 1 .. 3;
  $skeid->finish_request('gpu-hot', ok => 0);
  $skeid->start_request('gpu-hot');
  $skeid->record_usage(node_id => 'gpu-hot', api_key_id => $key_id, model => 'm',
    usage => { prompt_tokens => 5, completion_tokens => 5 });

  my $t = Test::Mojo->new(quiet_app($skeid));
  $t->get_ok('/skeid/registry/snapshot')->status_is(401, 'the snapshot is behind the admin key');

  $t->get_ok('/skeid/registry/snapshot' => $ADMIN)->status_is(200)
    ->header_is('Cache-Control' => 'no-store', 'and never cached -- a cached snapshot is a stale one');
  my $body = $t->tx->res->body;
  my $signature = $t->tx->res->headers->header('X-Skeid-Registry-Signature');
  like $signature, qr/\Asha256=[0-9a-f]{64}\z/, 'signed with HMAC-SHA256';
  ok(Langertha::Skeid::Registry->verify($body, $signature, $ENV{$SECRET_ENV}),
    'the signature covers the exact body with the shared secret');
  ok(!Langertha::Skeid::Registry->verify($body . ' ', $signature, $ENV{$SECRET_ENV}),
    'and one changed byte breaks it');
  ok(!Langertha::Skeid::Registry->verify($body, $signature, 'other-secret'), 'as does another secret');

  my $snap = decode_json($body);
  is $snap->{version}, 1, 'schema version 1';
  is $snap->{instance}, 'skeid-b', 'instance id from the config';
  is $snap->{ttl}, 7, 'ttl inside the signed body';
  ok abs($snap->{generated_at} - Time::HiRes::time()) < 5, 'generated_at inside the signed body';
  my %node = map { $_->{id} => $_ } @{$snap->{nodes}};
  is $node{'gpu-hot'}{inflight}, 3, 'per-node inflight';
  is $node{'gpu-hot'}{max_conns}, 4, 'per-node max_conns (this process share)';
  is $node{'gpu-hot'}{errors_in_window}, 1, 'errors in the window';
  ok $node{'gpu-hot'}{last_failure_at}, 'and when the last one was';
  is $node{'gpu-cool'}{last_failure_at}, undef, 'a node that never failed has none';
  is $node{'gpu-hot'}{healthy}, 1, 'health';
  is_deeply $node{'gpu-hot'}{tags}, ['local'], 'tags';
  is_deeply [sort keys %{$node{'gpu-hot'}}],
    [sort qw(id tags healthy inflight max_conns errors_in_window last_failure_at)],
    'exactly the whitelisted fields per node -- nothing else can slip in';

  # A scan of the bytes, not of the decoded fields: whatever reaches the wire is what leaks.
  for my $forbidden ($customer_key, $key_id, substr($key_id, 0, 14), 'secret-host-57', 'groq57',
                     'GROQ57_KEY', 'metadata-marker-57', 'premium', $ENV{$SECRET_ENV}, 'adm"',
                     'api_key', 'prompt_tokens', 'usage') {
    unlike $body, qr/\Q$forbidden\E/, "the snapshot does not carry '$forbidden'";
  }
}

# --- mapping a snapshot to a reading ---
{
  my $map = sub { Langertha::Skeid::Registry->reading_from_snapshot({ nodes => [@_] }) };
  my $hot  = { id => 'h', healthy => 1, inflight => 4, max_conns => 4, tags => ['local'] };
  my $cool = { id => 'c', healthy => 1, inflight => 1, max_conns => 4, tags => ['cloud'] };

  is_deeply $map->($hot, $cool), { used => 5, limit => 8 },
    'one hot and one cool node: limit is the summed max_conns, used what is not free';
  is_deeply(Langertha::Skeid::Registry->reading_from_snapshot({ nodes => [$hot, $cool] }, tags => ['cloud']),
    { used => 1, limit => 4 }, 'tags narrow which downstream nodes count');
  is_deeply $map->({ %$cool, healthy => 0 }, $hot), { used => 4, limit => 4 },
    'an unhealthy node offers no slots';
  is_deeply $map->({ %$hot, healthy => 0 }), { used => 1, limit => 1 },
    'no healthy node at all reads as full, so routing goes elsewhere';
  is_deeply $map->({ %$cool, inflight => 9 }), { used => 4, limit => 4 },
    'over-full clamps at the limit';
  is_deeply $map->({ %$cool, capacity => { used => 3, limit => 4 } }), { used => 3, limit => 4 },
    "a node's own probe reading narrows its free slots when it is tighter than inflight";
  is_deeply $map->({ %$cool, capacity => { retry_after => Time::HiRes::time() + 30 } }),
    { used => 4, limit => 4 }, 'a pending backoff has no free slots';
  is_deeply $map->({ %$cool, max_conns => 0 }), { used => undef, limit => undef },
    'an unlimited node makes the downstream unbounded: the reading does not narrow admission';
}

# --- readings from two sources: the tighter one wins, and forgetting is per source ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'peer', url => 'http://peer/v1', model => 'm', max_conns => 8);
  $skeid->observe_response_headers('peer', {}, status => 429);
  $skeid->set_capacity_reading('peer', source => 'registry', used => 0, limit => 8);
  is $skeid->capacity_reading('peer')->{source}, 'ratelimit',
    'a registry saying "empty" does not lift a 429 backoff the response just recorded';
  ok !$skeid->forget_capacity('peer', source => 'registry'), 'a registry forget does not drop it either';
  ok $skeid->capacity_reading('peer'), 'the backoff stands';

  $skeid->forget_capacity('peer');
  $skeid->set_capacity_reading('peer', source => 'registry', used => 2, limit => 8, interval_ms => 2000);
  $skeid->set_capacity_reading('peer', source => 'custom', used => 7, limit => 8);
  is $skeid->capacity_reading('peer')->{used}, 7, 'a tighter reading from another source replaces it';
  $skeid->set_capacity_reading('peer', source => 'registry', used => 1, limit => 8, interval_ms => 2000);
  is $skeid->capacity_reading('peer')->{used}, 7,
    'and a looser one does not, while the tighter one is younger than its poll interval';
  $skeid->_capacity->{peer}{at} = Time::HiRes::time() - 3;
  $skeid->set_capacity_reading('peer', source => 'registry', used => 1, limit => 8, interval_ms => 2000);
  is_deeply [@{$skeid->capacity_reading('peer')}{qw(source used)}], ['registry', 1],
    'once the tighter one is older than a poll of the incoming source, the fresh reading replaces it';
  $skeid->set_capacity_reading('peer', source => 'custom', used => 7, limit => 8);
  $skeid->set_capacity_reading('peer', source => 'custom', used => 1, limit => 8);
  is $skeid->capacity_reading('peer')->{used}, 1, 'a source always replaces its own last reading';

  $skeid->forget_capacity('peer');
  $skeid->set_capacity_reading('peer', source => 'registry', used => 1, limit => 8,
    at => Time::HiRes::time(), expires_at => Time::HiRes::time() - 0.01);
  ok !$skeid->capacity_reading('peer'), 'a reading past its expires_at is gone inside capacity_max_age_ms';
}

# --- a snapshot that fails to build says nothing about why (review M4) ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV }) });
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('error');
  my @logged;
  $app->log->unsubscribe('message');
  $app->log->on(message => sub { my (undef, $level, @lines) = @_; push @logged, "$level: @lines" });
  no warnings 'redefine';
  local *Langertha::Skeid::Registry::encode = sub { die "internal detail t57-marker\n" };
  my $t = Test::Mojo->new($app);
  $t->get_ok('/skeid/registry/snapshot' => $ADMIN)->status_is(500)
    ->json_is('/error/type', 'server_error');
  unlike $t->tx->res->body, qr/t57-marker|secret/i, 'the answer carries neither the cause nor a false "secret not set"';
  ok scalar(grep { /registry snapshot failed: internal detail t57-marker/ } @logged), 'the cause is logged';
}

# --- a passive reading nobody refreshes cannot block a fresh probe (review I1) ---
# The last response before traffic stopped said remaining: 0. Without traffic no response ever
# updates it, and with capacity_max_age_ms 0 it never ages out. Tighter-wins alone kept every
# probe that later said "empty" out for good, and the node was never admitted again.
{
  my $skeid = Langertha::Skeid->new(capacity_max_age_ms => 0);
  $skeid->add_node(id => 'n', url => 'http://n/v1', model => 'm', max_conns => 10);
  $skeid->observe_response_headers('n',
    { 'x-ratelimit-remaining-requests' => 0, 'x-ratelimit-limit-requests' => 10 });
  ok !$skeid->_capacity_allows('n'), 'a used-up ratelimit reading stops admission';
  $skeid->set_capacity_reading('n', source => 'prometheus', used => 0, limit => 10);
  is $skeid->capacity_reading('n')->{source}, 'prometheus',
    'a fresh probe reading replaces a stale passive one with no backoff pending';
  ok $skeid->_capacity_allows('n'), 'and the node is admissible again';

  # The hold window is the longer of the two sources' intervals, not only the incoming one's.
  # A roomy response right after a fresh, tight probe reading does not lift it...
  $skeid->forget_capacity('n');
  $skeid->set_capacity_reading('n', source => 'registry', used => 10, limit => 10, interval_ms => 5000);
  $skeid->observe_response_headers('n',
    { 'x-ratelimit-remaining-requests' => 90, 'x-ratelimit-limit-requests' => 100 });
  is_deeply [@{$skeid->capacity_reading('n')}{qw(source used)}], ['registry', 10],
    'a passive reading does not replace a fresh, tighter probe reading inside that probe\'s interval';
  # ...and neither does a faster, looser probe before the slow one has polled again.
  $skeid->set_capacity_reading('n', source => 'prometheus', used => 0, limit => 10, interval_ms => 500);
  $skeid->_capacity->{n}{at} = Time::HiRes::time() - 0.6;
  $skeid->set_capacity_reading('n', source => 'prometheus', used => 0, limit => 10, interval_ms => 500);
  is $skeid->capacity_reading('n')->{source}, 'registry',
    'a fast, looser probe does not replace a slow, tighter one after only its own interval';
  $skeid->_capacity->{n}{at} = Time::HiRes::time() - 6;
  $skeid->set_capacity_reading('n', source => 'prometheus', used => 0, limit => 10, interval_ms => 500);
  is $skeid->capacity_reading('n')->{source}, 'prometheus',
    'once the slow probe\'s own interval has passed, the fresh looser reading replaces it';

  # A backoff is different: it is a statement about the future, and it still holds.
  $skeid->observe_response_headers('n', { 'retry-after' => 30 }, status => 429);
  $skeid->set_capacity_reading('n', source => 'prometheus', used => 0, limit => 10, interval_ms => 2000);
  is $skeid->capacity_reading('n')->{source}, 'ratelimit', 'a pending backoff is not lifted by a probe';
}

# --- a probe forgets only its own reading (review I3) ---
{
  require Langertha::Skeid::CapacityProbe::Prometheus;
  my $skeid = Langertha::Skeid->new(capacity_max_age_ms => 60_000);
  $skeid->add_node(id => 'n', url => 'http://127.0.0.1:1/v1', model => 'm', max_conns => 4);
  for my $class (qw(Langertha::Skeid::CapacityProbe::Prometheus Langertha::Skeid::CapacityProbe::Registry)) {
    my $probe = $class->new(skeid => $skeid, node_id => 'n',
      config => { secret_env => $SECRET_ENV, admin_key_env => $ADMIN_ENV });
    $skeid->forget_capacity('n');
    $skeid->observe_response_headers('n', { 'retry-after' => 30 }, status => 429);
    $probe->stop;
    is $skeid->capacity_reading('n')->{source}, 'ratelimit',
      "$class stopping keeps a 429 backoff another source recorded";
    $skeid->forget_capacity('n');
    $skeid->set_capacity_reading('n', source => $probe->source, used => 1, limit => 4);
    $probe->stop;
    ok !$skeid->capacity_reading('n'), "$class stopping forgets its own reading";
  }

  # A metrics endpoint that answers 500: the poll forgets, but only the Prometheus reading.
  my $app = Mojolicious->new;
  $app->log->level('fatal');
  $app->routes->get('/metrics' => sub { $_[0]->render(text => 'down', status => 500) });
  my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $probe = Langertha::Skeid::CapacityProbe::Prometheus->new(skeid => $skeid, node_id => 'n',
    config => { url => 'http://127.0.0.1:' . $daemon->ports->[0] . '/metrics' });
  $skeid->forget_capacity('n');
  $skeid->observe_response_headers('n', { 'retry-after' => 30 }, status => 429);
  $probe->poll;
  spin(0.3);
  is $skeid->capacity_reading('n')->{source}, 'ratelimit',
    'an unreachable metrics endpoint does not wipe the backoff';
}

# --- a probe that polls no more often than readings live is reported (review M8) ---
{
  my $skeid = Langertha::Skeid->new(capacity_max_age_ms => 1000);
  $skeid->add_node(id => 'n', url => 'http://127.0.0.1:1/v1', model => 'm', max_conns => 4);
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my $slow = Langertha::Skeid::CapacityProbe::Registry->new(skeid => $skeid, node_id => 'n',
    interval_ms => 2000, config => {});
  $slow->start;
  $slow->stop;
  is scalar(grep { /must be below capacity_max_age_ms/ } @warnings), 1,
    'an interval at or above capacity_max_age_ms warns at start';
  @warnings = ();
  my $fast = Langertha::Skeid::CapacityProbe::Registry->new(skeid => $skeid, node_id => 'n',
    interval_ms => 500, config => {});
  $fast->start;
  $fast->stop;
  is scalar(grep { /capacity_max_age_ms/ } @warnings), 0, 'a shorter interval does not';
}

# --- a reload that drops a node drops its reading and error history (re-review) ---
{
  my $cfg = { nodes => [
    { id => 'keep', url => 'http://keep/v1', model => 'm', max_conns => 4 },
    { id => 'gone', url => 'http://gone/v1', model => 'm', max_conns => 4 },
  ] };
  my $skeid = Langertha::Skeid->new(config_loader => sub { $cfg });
  for my $id (qw(keep gone)) {
    $skeid->set_capacity_reading($id, source => 'custom', used => 1, limit => 4);
    $skeid->start_request($id);
    $skeid->finish_request($id, ok => 0);
  }
  $cfg = { nodes => [ { id => 'keep', url => 'http://keep/v1', model => 'm', max_conns => 4 } ] };
  $skeid->reload_config;
  ok !exists $skeid->_capacity->{gone}, 'the dropped node\'s reading is gone';
  ok !exists $skeid->_failures->{gone}, 'and so is its failure history';
  ok $skeid->capacity_reading('keep') && $skeid->_failures->{keep}, 'a node that stays keeps both';
}

# --- removing a node drops its error history with its reading (review M5) ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n', url => 'http://n/v1', model => 'm', max_conns => 4);
  $skeid->start_request('n');
  $skeid->finish_request('n', ok => 0);
  ok $skeid->_failures->{n}, 'a failed request is recorded';
  $skeid->remove_node('n');
  ok !exists $skeid->_failures->{n}, 'removal forgets it';
  $skeid->add_node(id => 'n', url => 'http://other/v1', model => 'm', max_conns => 4);
  my ($node) = @{$skeid->registry_snapshot->{nodes}};
  is_deeply [@{$node}{qw(errors_in_window last_failure_at)}], [0, undef],
    'a node re-added under the same id starts without the old machine\'s errors';
}

# --- the registry read key (skeid #49): the snapshot route, and nothing else ---
# The fronting tier used to need the downstream's full admin key, which can add a node pointing
# at any host under a key reference the downstream resolves -- a compromised fronting tier
# could exfiltrate provider keys. The read key must open the snapshot and no other route.
{
  local $ENV{SKEID_T57_READ} = 'read-only-57';
  my $READ = { Authorization => 'Bearer read-only-57' };
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV, read_key_env => 'SKEID_T57_READ' }) });
  my $t = Test::Mojo->new(quiet_app($skeid));

  $t->get_ok('/skeid/registry/snapshot' => $READ)->status_is(200, 'the read key reads the snapshot')
    ->header_like('X-Skeid-Registry-Signature' => qr/\Asha256=/, 'signed as ever');
  $t->get_ok('/skeid/registry/snapshot' => $ADMIN)->status_is(200, 'the admin key still does (compat)');
  $t->get_ok('/skeid/registry/snapshot' => { Authorization => 'Bearer read-only-5' })
    ->status_is(401, 'a prefix of the read key does not')
    ->header_is('WWW-Authenticate' => 'Bearer realm="skeid-admin"');
  $t->get_ok('/skeid/registry/snapshot')->status_is(401, 'nor does no key');

  $t->get_ok('/skeid/nodes' => $READ)->status_is(401, 'the read key does not list nodes');
  $t->post_ok('/skeid/nodes' => $READ => json => { id => 'evil', url => 'http://attacker.example/v1',
    model => 'm', api_key_env => 'GROQ_API_KEY' })->status_is(401, 'nor add one');
  ok !(grep { $_->{id} eq 'evil' } @{$skeid->nodes}), 'and no node was added';
  $t->post_ok('/skeid/nodes/gpu-hot/health' => $READ => json => { healthy => 0 })
    ->status_is(401, 'nor flip health');
  $t->get_ok("/skeid/$_" => $READ)->status_is(401, "nor read /skeid/$_") for qw(config metrics/nodes usage);
  $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200, 'while the admin key keeps the admin API');

  # A downstream with only a read key has no admin API at all.
  my $read_only = Langertha::Skeid->new(config_loader => sub {
    my $cfg = downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV,
      read_key_env => 'SKEID_T57_READ' });
    delete $cfg->{admin};
    return $cfg;
  });
  my $t2 = Test::Mojo->new(quiet_app($read_only));
  $t2->get_ok('/skeid/registry/snapshot' => $READ)->status_is(200, 'read key without admin key serves');
  $t2->get_ok('/skeid/nodes' => $READ)->status_is(404, 'and the admin API stays closed');

  # The fronting probe sends the read key when it has one, never the admin key alongside.
  my $saw_auth;
  my $app = Mojolicious->new;
  $app->log->level('fatal');
  $app->routes->get('/skeid/registry/snapshot' => sub {
    my ($c) = @_;
    $saw_auth = $c->req->headers->authorization;
    my $body = Langertha::Skeid::Registry->encode({ version => 1, instance => 'b', ttl => 10,
      workers => 1, generated_at => Time::HiRes::time(),
      nodes => [ { id => 'n', healthy => 1, inflight => 1, max_conns => 4, tags => [] } ] });
    $c->res->headers->header('X-Skeid-Registry-Signature'
      => Langertha::Skeid::Registry->sign($body, $ENV{$SECRET_ENV}));
    $c->render(data => $body, format => 'json');
  });
  my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $port = $daemon->ports->[0];

  my $front = Langertha::Skeid->new(capacity_max_age_ms => 60_000);
  $front->add_node(id => 'peer', url => "http://127.0.0.1:$port/v1", model => 'm', max_conns => 16,
    capacity => { probe => 'registry', secret_env => $SECRET_ENV,
      read_key_env => 'SKEID_T57_READ', admin_key_env => $ADMIN_ENV });
  my $probe = Langertha::Skeid::CapacityProbe->for_node($front, $front->nodes->[0]);
  local $SIG{__WARN__} = sub { };
  $probe->poll; spin(0.3);
  is $saw_auth, 'Bearer read-only-57', 'the probe prefers the read key over the admin key';
  is $probe->state, 'accepted', 'and the snapshot is accepted';

  undef $saw_auth;
  {
    local $ENV{SKEID_T57_READ} = '';
    $probe->poll; spin(0.3);
  }
  is $saw_auth, undef, 'an empty read key variable does not fall back to sending the admin key';
  is $probe->state, 'missing_secret', 'it forgets instead';
  ok !$front->capacity_reading('peer'), 'and holds no reading';
  $daemon->stop;
}

# --- the probe against a snapshot endpoint: every rejection forgets ---
{
  my %serve = (status => 200, body => '{}', signature => undef);
  my $app = Mojolicious->new;
  $app->log->level('fatal');
  my $saw_auth;
  $app->routes->get('/skeid/registry/snapshot' => sub {
    my ($c) = @_;
    $saw_auth = $c->req->headers->authorization;
    $c->res->headers->header('X-Skeid-Registry-Signature' => $serve{signature}) if defined $serve{signature};
    $c->render(data => $serve{body}, status => $serve{status}, format => 'json');
  });
  my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $port = $daemon->ports->[0];

  my $skeid = Langertha::Skeid->new(capacity_max_age_ms => 60_000);
  $skeid->add_node(id => 'peer', url => "http://127.0.0.1:$port/v1", model => 'm', max_conns => 16,
    capacity => { probe => 'registry', secret_env => $SECRET_ENV, admin_key_env => $ADMIN_ENV });
  my $probe = Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[0]);
  isa_ok $probe, 'Langertha::Skeid::CapacityProbe::Registry';
  is $probe->url, "http://127.0.0.1:$port/skeid/registry/snapshot", 'the URL is derived from the node URL';

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $serve_snapshot = sub {
    my (%args) = @_;
    my $snap = {
      version => 1, instance => 'b', ttl => ($args{ttl} // 10), workers => 1,
      generated_at => ($args{generated_at} // Time::HiRes::time()),
      nodes => [ { id => 'n', healthy => 1, inflight => ($args{inflight} // 2), max_conns => 4, tags => [] } ],
    };
    my $body = Langertha::Skeid::Registry->encode($snap);
    %serve = (status => 200, body => $body,
      signature => Langertha::Skeid::Registry->sign($body, $args{secret} // $ENV{$SECRET_ENV}));
    return $snap;
  };
  my $poll = sub { $probe->poll; spin(0.3) };

  my $first = $serve_snapshot->(inflight => 3);
  $poll->();
  is $saw_auth, 'Bearer adm', 'the probe authenticates with the downstream admin key';
  my $reading = $skeid->capacity_reading('peer');
  ok $reading, 'a valid snapshot is accepted';
  is_deeply [@{$reading}{qw(source used limit)}], ['registry', 3, 4], 'and mapped to a reading';
  is $reading->{at}, $first->{generated_at}, 'stamped with the snapshot generated_at, not the arrival time';
  is $probe->state, 'accepted', 'state accepted';
  is scalar(@warnings), 0, 'the first success is not logged';

  $serve_snapshot->(secret => 'wrong-secret');
  $poll->();
  ok !$skeid->capacity_reading('peer'), 'a bad signature forgets the reading';
  is $probe->state, 'bad_signature', 'state bad_signature';
  $poll->();
  is scalar(grep { /bad_signature/ } @warnings), 1, 'logged once per state change, not per poll';

  $serve_snapshot->();
  $serve{signature} = undef;
  $poll->();
  ok !$skeid->capacity_reading('peer'), 'an unsigned snapshot is not believed';

  $serve_snapshot->(inflight => 1);
  $poll->();
  ok $skeid->capacity_reading('peer'), 'recovers with a valid one';

  $serve_snapshot->(generated_at => Time::HiRes::time() - 30, ttl => 10);
  $poll->();
  ok !$skeid->capacity_reading('peer'), 'a snapshot older than its ttl is stale and forgotten';
  is $probe->state, 'stale', 'state stale';

  $serve_snapshot->(generated_at => Time::HiRes::time() + 60);
  $poll->();
  ok !$skeid->capacity_reading('peer'), 'a snapshot from the future is not believed';
  is $probe->state, 'future', 'state future';

  my $newer = $serve_snapshot->(generated_at => Time::HiRes::time());
  $poll->();
  ok $skeid->capacity_reading('peer'), 'a fresh one is accepted';
  $serve_snapshot->(generated_at => $newer->{generated_at} - 1);
  $poll->();
  ok !$skeid->capacity_reading('peer'),
    'an older snapshot replayed inside its ttl is rejected -- the signature alone does not prove it is current';
  is $probe->state, 'replayed', 'state replayed';

  $serve_snapshot->();
  %serve = (%serve, status => 500);
  $poll->();
  ok !$skeid->capacity_reading('peer'), 'an unreachable downstream is unknown, not "as last time"';

  $serve_snapshot->();
  {
    local $ENV{$SECRET_ENV} = '';
    $poll->();
    ok !$skeid->capacity_reading('peer'), 'a missing secret on the fronting side forgets';
    is $probe->state, 'missing_secret', 'state missing_secret';
  }

  $serve_snapshot->();
  $poll->();
  ok $skeid->capacity_reading('peer'), 'and it recovers once the secret is there';
  like join('', @warnings), qr/'peer': accepted/, 'recovery after a failure is logged';

  $skeid->observe_response_headers('peer', {}, status => 429);
  $serve_snapshot->(secret => 'wrong-secret');
  $poll->();
  is $skeid->capacity_reading('peer')->{source}, 'ratelimit',
    "a rejected snapshot forgets only the registry's own reading, never a backoff another source set";
  $probe->stop;
}

# --- end to end: a fronting Skeid routes away from the hot downstream ---
{
  my $llm = Mojolicious->new;
  $llm->log->level('fatal');
  $llm->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $c->render(json => {
      id => 'chatcmpl-57', object => 'chat.completion', model => 'm',
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
    });
  });
  my $llm_daemon = Mojo::Server::Daemon->new(app => $llm, listen => ['http://127.0.0.1'], silent => 1);
  $llm_daemon->start;
  my $llm_url = 'http://127.0.0.1:' . $llm_daemon->ports->[0] . '/v1';

  my %downstream;
  for my $name (qw(hot cool)) {
    my $skeid = Langertha::Skeid->new(config_loader => sub {
      my $cfg = downstream_config(registry => { enabled => 1, secret_env => $SECRET_ENV });
      $_->{url} = $llm_url for @{$cfg->{nodes}};
      return $cfg;
    });
    my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
    $app->log->level('fatal');
    my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1);
    $daemon->start;
    $downstream{$name} = { skeid => $skeid, daemon => $daemon, port => $daemon->ports->[0] };
  }

  # Traffic the fronting tier never sent -- another frontend, a batch job. Its own inflight for
  # this peer stays 0, which is exactly the number that would send half the requests there.
  my $hot = $downstream{hot}{skeid};
  $hot->start_request('gpu-hot')  for 1 .. 4;
  $hot->start_request('gpu-cool') for 1 .. 4;
  my $hot_started = sub { my $n = 0; $n += $_->{started} for @{$hot->node_metrics}; $n };
  my $cool_started = sub { my $n = 0; $n += $_->{started} for @{$downstream{cool}{skeid}->node_metrics}; $n };
  is $hot_started->(), 8, 'the hot downstream is full with traffic from elsewhere';

  my $front = Langertha::Skeid->new(route_wait_timeout_ms => 200, route_wait_poll_ms => 10);
  for my $name (qw(hot cool)) {
    $front->add_node(
      id => "peer-$name", url => "http://127.0.0.1:$downstream{$name}{port}/v1", model => 'm',
      max_conns => 16,
      capacity => { probe => 'registry', secret_env => $SECRET_ENV, admin_key_env => $ADMIN_ENV,
                    interval_ms => 200 },
    );
  }
  my $front_app = Langertha::Skeid::Proxy->build_app(skeid => $front);
  $front_app->log->level('fatal');
  my $front_daemon = Mojo::Server::Daemon->new(app => $front_app, listen => ['http://127.0.0.1'], silent => 1);
  $front_daemon->start;
  my $front_port = $front_daemon->ports->[0];

  spin(0.5);   # build_app started the probes; let their first polls land
  is_deeply [@{$front->capacity_reading('peer-hot') || {}}{qw(source used limit)}], ['registry', 8, 8],
    'the fronting tier reads the hot downstream as full';
  is_deeply [@{$front->capacity_reading('peer-cool') || {}}{qw(source used limit)}], ['registry', 0, 8],
    'and the cool one as empty';

  my $ua = Mojo::UserAgent->new;
  my @codes;
  for (1 .. 6) {
    my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
    $ua->post("http://127.0.0.1:$front_port/v1/chat/completions" => json => {
      model => 'm', messages => [{ role => 'user', content => 'hi' }],
    } => sub { my (undef, $tx) = @_; push @codes, $tx->res->code; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    Mojo::IOLoop->remove($guard);
  }
  is_deeply \@codes, [(200) x 6], 'every request is served';
  is $hot_started->(), 8, 'none of them went to the hot downstream';
  is $cool_started->(), 6, 'all of them went to the cool one';
  is $front->node_metrics('peer-hot')->{started}, 0,
    'round-robin would have sent half there -- the registry reading is what kept them away';

  # The hot one drains: the next snapshot says so, and it takes traffic again.
  $hot->finish_request('gpu-hot', ok => 1) for 1 .. 4;
  $hot->finish_request('gpu-cool', ok => 1) for 1 .. 4;
  spin(0.6);
  is $front->capacity_reading('peer-hot')->{used}, 0, 'a drained downstream reads as empty on the next poll';
  is $front->route_state(model => 'm')->{available_count}, 2, 'and is admissible again';
}

done_testing;
