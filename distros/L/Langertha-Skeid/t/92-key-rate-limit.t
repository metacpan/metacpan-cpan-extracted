#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::Server::Daemon;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A request rate per customer key (skeid k125): a caller that runs away is stopped at the proxy,
# answered 429 with Retry-After before anything is routed, and the refusal is a usage event
# without content. A key without a rate is unlimited, as before.

my $NOW = 1_000_000;
no warnings 'redefine';
local *Langertha::Skeid::_now = sub { $NOW };
use warnings 'redefine';

my $SLOW = 'sk-test-slow';
my $FAST = 'sk-test-fast';
my $FREE = 'sk-test-free';
my $SLOW_ID = Langertha::Skeid->key_id_for_key($SLOW);
my $FAST_ID = Langertha::Skeid->key_id_for_key($FAST);
my $FREE_ID = Langertha::Skeid->key_id_for_key($FREE);
my $ADMIN = 'sk-admin-test-only';

# --- the control plane: buckets, refill, Retry-After ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub { +{
    policies => {
      slow   => { rate => { per_s => 1, burst => 1 } },
      minute => { rate => { per_min => 2 } },
      open   => {},
    },
    keys => { $SLOW_ID => 'slow', $FAST_ID => 'minute', $FREE_ID => 'open' },
  } });

  is_deeply $skeid->rate_admit($SLOW_ID), { ok => 1 }, 'per_s 1, burst 1: the first request passes';
  is_deeply $skeid->rate_admit($SLOW_ID), { ok => 0, retry_after => 1 }, 'the second within the second is refused, retry after 1 s';
  $NOW += 0.5;
  ok !$skeid->rate_admit($SLOW_ID)->{ok}, 'half a second later still refused';
  $NOW += 0.5;
  ok $skeid->rate_admit($SLOW_ID)->{ok}, 'after the wait the next one passes';

  ok $skeid->rate_admit($FAST_ID)->{ok} && $skeid->rate_admit($FAST_ID)->{ok}, 'per_min 2: two pass';
  is_deeply $skeid->rate_admit($FAST_ID), { ok => 0, retry_after => 30 }, 'the third waits for the minute bucket';

  ok !grep({ !$skeid->rate_admit($FREE_ID)->{ok} } 1 .. 100), 'a key without a rate is unlimited';
  ok !grep({ !$skeid->rate_admit(undef)->{ok} } 1 .. 100), 'as is a request without a key and no default rate';

  is_deeply $skeid->key_metrics, { $SLOW_ID => { rate_limited => 2 }, $FAST_ID => { rate_limited => 1 } },
    'refusals are counted per key id';
}

# --- without client_auth, made-up keys share one bucket (no bypass, no growth) ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub { +{
    policies => { std => { rate => { per_s => 1, burst => 1 } } }, default_policy => 'std' } });
  my $passed = grep { $skeid->rate_admit('k_' . sprintf('%040x', $_))->{ok} } 1 .. 50;
  is $passed, 1, 'fifty different unlisted keys share the default policy\'s one bucket';
  is scalar(keys %{ $skeid->_rate_buckets }), 1, 'and hold one bucket';
}

# --- the rate is divided among the processes, like max_conns ---
{
  my $skeid = Langertha::Skeid->new(worker_count => 2, config_loader => sub { +{
    policies => { p => { rate => { per_s => 4, burst => 4 } } }, default_policy => 'p' } });
  my $passed = grep { $skeid->rate_admit('k')->{ok} } 1 .. 10;
  is $passed, 2, 'two workers: each takes half the burst';
}

# --- keys entries override, a reload re-judges and prunes ---
{
  my $rate = { per_s => 1, burst => 1 };
  my $skeid = Langertha::Skeid->new(config_reload_interval => 0, config_loader => sub { +{
    policies => { open => {} },
    keys     => { $SLOW_ID => { policy => 'open', rate => $rate } },
  } });
  ok $skeid->rate_admit($SLOW_ID)->{ok} && !$skeid->rate_admit($SLOW_ID)->{ok}, 'a keys entry sets its own rate';
  $rate = undef;
  $skeid->call_function('nodes.list', {});
  ok $skeid->rate_admit($SLOW_ID)->{ok} && $skeid->rate_admit($SLOW_ID)->{ok}, 'rate: null on reload lifts it';
  is_deeply $skeid->_rate_buckets, {}, 'and the bucket is dropped';
}

# --- a malformed rate fails the load ---
for my $case (
  [ { per_s => 0 },                qr/per_s must be a number above 0/ ],
  [ { burst => 3 },                qr/needs per_s or per_min/ ],
  [ { per_min => 5, burst => 3 },  qr/burst needs per_s/ ],
  [ { per_s => 1, burst => 0.5 },  qr/burst must be a whole number/ ],
  [ { per_s => 1, per_hour => 9 }, qr/unknown field per_hour/ ],
  [ 'fast',                        qr/must be a mapping/ ],
) {
  my ($rate, $error) = @$case;
  ok !eval { Langertha::Skeid->new(config_loader => sub { +{ policies => { p => { rate => $rate } } } }); 1 },
    'a malformed rate fails the load';
  like $@, $error, "... ($error)";
}

# --- through the proxy: 429, Retry-After, face-shaped, nothing upstream, one usage event ---
{
  my $upstream_calls = 0;
  my $upstream = Mojolicious->new;
  $upstream->log->level('fatal');
  $upstream->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $upstream_calls++;
    $c->render(json => { id => 'c1', object => 'chat.completion', model => 'm1',
      choices => [{ index => 0, message => { role => 'assistant', content => 'Hi' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 } });
  });

  my $daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $up_url = 'http://127.0.0.1:' . $daemon->ports->[0] . '/v1';

  my @events;
  my $skeid = Langertha::Skeid->new(
    admin_api_key     => $ADMIN,
    store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
    config_loader     => sub { +{
      policies => { slow => { rate => { per_s => 1, burst => 1 } } },
      keys     => { $SLOW_ID => 'slow' },
      nodes    => [{ id => 'n1', trust => 'internal', url => $up_url, model => 'm1' }],
    } },
  );
  my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid));
  $t->app->log->level('fatal');

  my %h = (Authorization => "Bearer $SLOW");
  my $chat = { model => 'm1', messages => [{ role => 'user', content => 'secret prompt text' }] };

  $t->post_ok('/v1/chat/completions' => \%h => json => $chat)->status_is(200);
  is $upstream_calls, 1, 'the first request reaches the node';

  @events = ();
  $t->post_ok('/v1/chat/completions' => \%h => json => $chat)->status_is(429)
    ->header_is('Retry-After' => 1)
    ->json_is('/error/type' => 'rate_limit_exceeded')
    ->json_is('/error/code' => 'key_rate_limited');
  is $upstream_calls, 1, 'the refused request does not reach the node';
  is scalar(@events), 1, 'one usage event for the refusal';
  is $events[0]{status_code}, 429, 'with status 429';
  is $events[0]{error_type}, 'key_rate_limited', 'and a stable error_type';
  is $events[0]{api_key_id}, $SLOW_ID, 'for the key';
  is $events[0]{node_id}, '', 'and no node';
  unlike join(' ', map { $_ // '' } %{$events[0]}), qr/secret prompt/, 'without request content';

  $t->post_ok('/api/chat' => \%h => json => { %$chat, stream => \0 })->status_is(429)
    ->header_is('Retry-After' => 1);
  ok !ref($t->tx->res->json->{error}), 'the Ollama face gets its own error shape';

  $t->get_ok('/skeid/metrics/keys' => { Authorization => "Bearer $ADMIN" })->status_is(200)
    ->json_is("/metrics/$SLOW_ID/rate_limited" => 2);

  $NOW += 1;
  $t->post_ok('/v1/chat/completions' => \%h => json => $chat)->status_is(200);
  is $upstream_calls, 2, 'after the wait the key is served again';
}

done_testing;
