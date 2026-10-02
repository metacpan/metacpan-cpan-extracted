use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A failed hot reload keeps the previous config in force (skeid #29, all or nothing). The
# failure must not then become the request's (skeid #39): with a config_loader every request
# reloads, so re-raising the error into it turned every request into a 500 until someone fixed
# the config -- an outage caused by a config that was never applied. The request is served
# under the kept config, the failure is logged and shown on /health and /skeid/config, and the
# same broken result is not retried on every request.

my $NOW = 2_000_000;
{
  no warnings 'redefine';
  *Langertha::Skeid::_now = sub { $NOW };
}

my $applies = 0;
{
  my $orig = \&Langertha::Skeid::_apply_config;
  no warnings 'redefine';
  *Langertha::Skeid::_apply_config = sub { $applies++; goto &$orig };
}

sub good_cfg {
  my (%extra) = @_;
  return {
    admin    => { api_key => 'adm' },
    policies => { std => { models => ['m'] } },
    nodes    => [ { id => 'n1', url => ($extra{url} // 'http://n1/v1'), model => 'm' } ],
  };
}

sub broken_cfg {
  my $cfg = good_cfg(url => 'http://broken/v1');
  $cfg->{default_policy} = 'no-such-policy';      # fails _load_policies
  return $cfg;
}

# --- a broken config returned by the loader ---
{
  my $cfg   = good_cfg();
  my $calls = 0;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 1,
    config_loader => sub { $calls++; return $cfg },
  );
  my $nodes = $skeid->nodes;
  is_deeply $skeid->reload_status, { ok => 1 }, 'a good load reports ok';

  $cfg = broken_cfg();
  $NOW += 1;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my ($applies_before, $calls_before) = ($applies, $calls);

  my $listed = eval { $skeid->call_function('nodes.list', {}) };
  ok $listed, 'the dispatch that triggered the failing reload does not die';
  is $listed->{nodes}[0]{url}, 'http://n1/v1', 'and is served under the kept config';
  is $skeid->nodes, $nodes, 'the node list is the previous one';
  is $applies - $applies_before, 1, 'the broken config was tried once';
  is scalar(@warnings), 1, 'and the failure logged once';
  like $warnings[0], qr/config reload failed, keeping the previous config: .*no-such-policy/,
    'saying why';

  my $status = $skeid->reload_status;
  is $status->{ok}, 0, 'reload_status reports the failure';
  like $status->{error}, qr/default_policy 'no-such-policy' is not defined/, 'with its reason';
  like $status->{failed_at}, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, 'and when, as ISO 8601';
  is $status->{failures}, 1, 'one failure so far';

  # Back-off: the next attempt waits base * 2**(failures-1), base = interval (min 1s).
  $skeid->call_function('nodes.list', {}) for 1 .. 20;
  is $calls - $calls_before, 1, '20 more dispatches inside the back-off do not rerun the loader';

  $NOW += 1;
  $skeid->call_function('nodes.list', {});
  is $calls - $calls_before, 2, 'after the first back-off step the loader runs again';
  is $applies - $applies_before, 1, 'but the same broken result is not applied again';
  is scalar(@warnings), 1, 'nor logged again';
  is $skeid->reload_status->{failures}, 2, 'it still counts as a failure';

  $NOW += 1;
  $skeid->call_function('nodes.list', {});
  is $calls - $calls_before, 2, 'the back-off has doubled: one second is not enough now';
  $NOW += 1;
  $skeid->call_function('nodes.list', {});
  is $calls - $calls_before, 3, 'two seconds are';

  # However long it stays broken, a retry is never more than a minute away.
  for (1 .. 12) { $NOW += 61; $skeid->call_function('nodes.list', {}) }
  is $calls - $calls_before, 15, 'the back-off is capped at a minute';
  is $applies - $applies_before, 1, 'and the broken result was still applied only once';

  # Fixed: applied at the next attempt, and the status clears.
  $cfg = good_cfg(url => 'http://fixed/v1');
  $NOW += 61;
  is $skeid->maybe_reload_config, 1, 'the fixed config is applied';
  is $skeid->list_nodes->[0]{url}, 'http://fixed/v1', 'and in force';
  is_deeply $skeid->reload_status, { ok => 1 }, 'the failure is cleared';

  $NOW += 1;
  $calls_before = $calls;
  $skeid->call_function('nodes.list', {});
  is $calls - $calls_before, 1, 'and the loader is back on its normal interval';
}

# --- a loader that dies ---
{
  my $die   = 0;
  my $calls = 0;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader => sub { $calls++; die "vault unreachable\n" if $die; return good_cfg() },
  );
  $die = 1;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $calls_before = $calls;
  ok eval { $skeid->call_function('nodes.list', {}); 1 }, 'a dying loader does not fail the dispatch';
  is $skeid->list_nodes->[0]{id}, 'n1', 'the kept config serves';
  like $skeid->reload_status->{error}, qr/vault unreachable/, 'the loader error is recorded';
  $skeid->call_function('nodes.list', {}) for 1 .. 10;
  is $calls - $calls_before, 1,
    'with interval 0 a failing loader still backs off (at least a second) instead of running per dispatch';
  $NOW += 1;
  $skeid->call_function('nodes.list', {});
  is $calls - $calls_before, 2, 'and is retried after it';
  is scalar(@warnings), 1, 'the same error is logged once, not per retry';
  ok !eval { $skeid->call_function('config.reload', {}); 1 },
    'an explicit config.reload still reports the failure to its caller';
}

# --- through the proxy: requests keep working, the failure is visible ---
my %served;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body = $c->req->json || {};
  $served{count}++;
  $c->render(json => {
    id      => 'chatcmpl-1',
    object  => 'chat.completion',
    model   => ($body->{model} // ''),
    choices => [{ index => 0, message => { role => 'assistant', content => 'hi' }, finish_reason => 'stop' }],
    usage   => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
  });
});
my $up_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$up_daemon->start;
my $up_url = 'http://127.0.0.1:' . $up_daemon->ports->[0] . '/v1';

{
  my $cfg = good_cfg(url => $up_url);
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    route_wait_poll_ms     => 5,
    store_usage_event      => sub { return { ok => 1 } },
    config_loader          => sub { $cfg },
  );
  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $proxy->log->level('fatal');
  my $daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $base = 'http://127.0.0.1:' . $daemon->ports->[0];
  my $ua = Mojo::UserAgent->new;

  my $request = sub {
    my ($method, $path, @args) = @_;
    my $tx;
    my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
    $ua->$method("$base$path" => @args => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    Mojo::IOLoop->remove($guard);
    return $tx;
  };
  my $chat = sub {
    return $request->(post => '/v1/chat/completions',
      { Authorization => 'Bearer sk-test' },
      json => { model => 'm', messages => [{ role => 'user', content => 'hi' }] });
  };

  is $chat->()->res->code, 200, 'a chat request under a good config';
  is $request->(get => '/health')->res->json->{config_reload}{ok}, 1, '/health shows the reload ok';

  $cfg = broken_cfg();
  $NOW += 1;
  local $SIG{__WARN__} = sub { };
  for my $n (1 .. 5) {
    my $tx = $chat->();
    is $tx->res->code, 200, "chat request $n while the config is broken is served, not a 500";
  }
  is $served{count}, 6, 'every one reached the upstream of the kept config';

  my $health = $request->(get => '/health')->res;
  is $health->code, 200, '/health still answers 200: the proxy is serving';
  is $health->json->{status}, 'ok', 'with status ok';
  is $health->json->{config_reload}{ok}, 0, 'but reports the failed reload';
  like $health->json->{config_reload}{failed_at}, qr/Z\z/, 'with its timestamp';
  ok !exists $health->json->{config_reload}{error},
    'and not its message, which can name customers, on the public route';

  my $admin = $request->(get => '/skeid/config', { Authorization => 'Bearer adm' })->res;
  is $admin->code, 200, 'the admin API still works on the kept admin key';
  like $admin->json->{reload}{error}, qr/no-such-policy/, '/skeid/config gives the reason';
  is $admin->json->{reload}{ok}, 0, 'and the state';

  $daemon->stop;
}

done_testing;
