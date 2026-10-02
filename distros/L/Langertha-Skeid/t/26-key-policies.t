use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Scalar::Util qw(refaddr);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Per-key routing policy (ADR 0008). A customer key decides which models it may ask for and
# which node groups it may be served from -- "our local GPUs only", "local first but cloud is
# fine", "this alias and nothing else". The policy is resolved once at config load; a request
# costs a hash lookup.
#
# The load-bearing property of the whole layer is that it cannot be talked around. A denied
# key must not reach a denied node by any spelling of the request, and must not be able to
# rename itself into someone else's policy.

# --- resolution ---
{
  my $skeid = Langertha::Skeid->new;

  $skeid->set_policy('local-only', { deny_tags => ['cloud'] });
  is_deeply($skeid->policies->{'local-only'}{deny_tags}, ['cloud'], 'a profile normalizes its deny tags');
  is($skeid->policies->{'local-only'}{allow_models}, undef,
    'and grants every model when it does not say otherwise');

  my $limited = $skeid->resolve_policy({ models => ['house-model', 'house-fast'] });
  is_deeply([sort keys %{$limited->{allow_models}}], ['house-fast', 'house-model'],
    'models becomes a lookup of what the key may ask for');

  my $star = $skeid->resolve_policy({ models => ['*'] });
  is($star->{allow_models}, undef, "an explicit '*' means the same as saying nothing");

  my $csv = $skeid->resolve_policy({ models => 'a, b' });
  is_deeply([sort keys %{$csv->{allow_models}}], ['a', 'b'], 'a comma-separated string works too');
}

# --- config: profiles, a default, and sparse per-key exceptions ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    return {
      policies => {
        standard => { deny_tags => ['cloud'] },
        premium  => {},
      },
      default_policy => 'standard',
      keys => {
        # The three shapes a key entry can take.
        'k_named'    => 'premium',
        'k_profile'  => { policy => 'premium' },
        'k_override' => { policy => 'standard', deny_tags => [] },
        'k_narrow'   => { models => ['house-model'] },
      },
    };
  });

  is($skeid->policy_for_key('k_unlisted'), $skeid->default_policy,
    'an unlisted key takes the default -- which is what makes ten thousand identical customers '
    . 'a config with zero key entries');
  is_deeply($skeid->policy_for_key('k_unlisted')->{deny_tags}, ['cloud'], 'and inherits its denials');

  is_deeply($skeid->policy_for_key('k_named')->{deny_tags}, [], 'a bare string names a profile');
  is_deeply($skeid->policy_for_key('k_override')->{deny_tags}, [],
    'an override replaces the profile field it names');
  is($skeid->policy_for_key('k_narrow')->{allow_models}{'house-model'}, 1,
    'an override without a profile still falls back to the default for what it does not say');
  is_deeply($skeid->policy_for_key('k_narrow')->{deny_tags}, ['cloud'],
    'so k_narrow keeps the default deny while narrowing its models');

  # Identical resolutions share one object. This is the reason a thousand keys on three
  # profiles cost three policies and a thousand pointers, not a thousand policies.
  is(refaddr($skeid->policy_for_key('k_named')), refaddr($skeid->policy_for_key('k_profile')),
    'keys resolving to the same policy share one object');
  is(refaddr($skeid->policy_for_key('k_override')), refaddr($skeid->policy_for_key('k_named')),
    'including one that arrives there through an override');

  ok(!$skeid->policy_for_key('k_unlisted')->{allow_models}, 'the default grants all models');
}

# --- a config that names something that does not exist is a config error, not a silent allow ---
{
  ok(!eval {
    Langertha::Skeid->new(config_loader => sub { { policies => {}, default_policy => 'nope' } });
    1;
  }, 'an undefined default_policy croaks');

  ok(!eval {
    Langertha::Skeid->new(config_loader => sub {
      { policies => { p => {} }, keys => { alice => 'nope' } };
    });
    1;
  }, 'a key referencing an undefined policy croaks -- failing open here would hand out access');
}

# --- planning under a policy ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    return {
      policies => {
        'local-only' => { deny_tags => ['cloud'] },
        'one-model'  => { models => ['house-model'] },
      },
      keys => {
        k_local => 'local-only',
        k_one   => 'one-model',
      },
      aliases => {
        'house-model' => {
          tiers => [
            { tags => ['local'], model => 'qwen3-32b' },
            { tags => ['cloud'], model => 'llama-3.3-70b' },
          ],
        },
      },
    };
  });

  my $open = $skeid->route_plan(model => 'house-model', api_key_id => 'k_nobody');
  is(scalar(@{$open->{tiers}}), 2, 'a key with no policy sees both tiers');

  my $denied = $skeid->route_plan(model => 'house-model', api_key_id => 'k_local');
  ok($denied->{permitted}, 'a denied tag does not deny the model when another tier survives');
  is(scalar(@{$denied->{tiers}}), 1, 'the cloud tier is dropped');
  is($denied->{tiers}[0]{model}, 'qwen3-32b', 'leaving the local one');
  is_deeply($denied->{tiers}[0]{deny_tags}, ['cloud'],
    'and the surviving tier carries the denial down into node selection');

  my $refused = $skeid->route_plan(model => 'gpt-4o', api_key_id => 'k_one');
  ok(!$refused->{permitted}, 'a model outside the allow list is refused');
  is($refused->{reason}, 'model_not_permitted', 'and says why');
  is(scalar(@{$refused->{tiers}}), 0, 'with nothing to try');

  $skeid->set_model_alias('cloud-only', { tiers => [{ tags => ['cloud'], model => 'llama-3.3-70b' }] });
  my $all_denied = $skeid->route_plan(model => 'cloud-only', api_key_id => 'k_local');
  ok(!$all_denied->{permitted}, 'an alias whose every tier is denied is refused, not routed');
  is($all_denied->{reason}, 'all_tiers_denied',
    'and is distinguishable from a model the key was never granted');
}

# --- names: a readable-name -> key-id registry that lives in the config (karr #17, ADR 0008) ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    return {
      policies => {
        standard  => { deny_tags => ['cloud'] },
        burstable => {},
      },
      default_policy => 'standard',
      names => {
        alice   => 'k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b',
        bigcorp => 'k_9c8b7a6f5e4de5f60718293a4b5c6d7e8f901a2b',
      },
      keys => {
        alice          => 'burstable',                 # written by readable name ...
        bigcorp        => { policy => 'standard', deny_tags => [] },
        k_1122334455aae5f60718293a4b5c6d7e8f901a2b => 'burstable',                 # ... or still by the raw key id
      },
    };
  });

  is($skeid->key_id_for_name('alice'), 'k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b', 'a name resolves to the customer key id it was given');
  is($skeid->key_id_for_name('nobody'), undef, 'an unregistered name resolves to nothing');

  # The registry is a config-authoring convenience: it is resolved to ids at load, so the
  # request path still keys on the derived id the caller's key produces, one hash lookup.
  is_deeply($skeid->policy_for_key('k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b')->{deny_tags}, [],
    'a keys: entry written by name attaches its policy to the id the name maps to');
  is_deeply($skeid->policy_for_key('k_9c8b7a6f5e4de5f60718293a4b5c6d7e8f901a2b')->{deny_tags}, [],
    "the named override reaches the mapped id, not the name");
  is_deeply($skeid->policy_for_key('k_1122334455aae5f60718293a4b5c6d7e8f901a2b')->{deny_tags}, [],
    'and a raw-id entry alongside the named ones still resolves');

  # The name itself is never a customer key id, so it must not be a policy key -- looking it up
  # as one falls through to the default, proving the name never leaks onto the request path.
  is($skeid->policy_for_key('alice'), $skeid->default_policy,
    'the readable name is not itself an identity -- as a key id it takes the default');
}

# --- names: the config errors fail loud rather than granting the wrong access ---
{
  ok(!eval {
    Langertha::Skeid->new(config_loader => sub {
      { names => { alice => { id => 'k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b' } } };
    });
    1;
  }, 'a name mapping to a structure croaks -- a name points at one key id, not an object');

  ok(!eval {
    Langertha::Skeid->new(config_loader => sub { { names => { alice => '' } } });
    1;
  }, 'a name mapping to an empty id croaks');

  ok(!eval {
    Langertha::Skeid->new(config_loader => sub {
      {
        policies => { p => {} },
        names    => { alice => 'k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b' },
        keys     => { alice => 'p', k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b => 'p' },
      };
    });
    1;
  }, 'a name and its own id both listed in keys: croaks rather than silently letting one win');
}

# --- integration: the policy has to survive contact with a client that is trying to get around it ---
my %served;

sub _upstream {
  my ($label) = @_;
  my $app = Mojolicious->new;
  $app->log->level('fatal');
  $app->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    my $body = $c->req->json || {};
    push @{ $served{$label} }, ($body->{model} // '');
    $c->render(json => {
      id      => "chatcmpl-$label",
      object  => 'chat.completion',
      model   => ($body->{model} // ''),
      choices => [{ index => 0, message => { role => 'assistant', content => "hi from $label" }, finish_reason => 'stop' }],
      usage   => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 },
    });
  });
  my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  return ($daemon, $daemon->ports->[0]);
}

my ($local_daemon, $local_port) = _upstream('local');
my ($cloud_daemon, $cloud_port) = _upstream('cloud');

my $LOCAL_KEY   = 'sk-test-local-only';
my $CLOUD_KEY   = 'sk-test-may-use-cloud';
my $LOCAL_ID    = Langertha::Skeid->key_id_for_key($LOCAL_KEY);
my $CLOUD_ID    = Langertha::Skeid->key_id_for_key($CLOUD_KEY);

like($LOCAL_ID, qr/^k_[0-9a-f]{40}$/, 'a key id is derived from the key the caller presents');
isnt($LOCAL_ID, $CLOUD_ID, 'and differs per key');

my @events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
  config_loader      => sub {
    return {
      policies => {
        'local-only' => { deny_tags => ['cloud'] },
        'anywhere'   => {},
      },
      default_policy => 'local-only',
      keys => { $CLOUD_ID => 'anywhere' },
      routing => { wait_timeout_ms => 60, wait_poll_ms => 5 },
      aliases => {
        'house-model' => {
          tiers => [
            { tags => ['local'], model => 'qwen3-32b' },
            { tags => ['cloud'], model => 'llama-3.3-70b' },
          ],
        },
      },
    };
  },
);
$skeid->add_node(id => 'local-1', url => "http://127.0.0.1:$local_port/v1",
  model => 'qwen3-32b', tags => ['local'], max_conns => 1);
$skeid->add_node(id => 'cloud-1', url => "http://127.0.0.1:$cloud_port/v1",
  model => 'llama-3.3-70b', tags => ['cloud'], max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $proxy_port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

sub _ask {
  my ($model, $key, %headers) = @_;
  my $tx;
  my $done = 0;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$proxy_port/v1/chat/completions" => {
    Authorization => "Bearer $key",
    %headers,
  } => json => {
    model    => $model,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub {
    (undef, $tx) = @_;
    $done = 1;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start unless $done;
  Mojo::IOLoop->remove($guard);
  return $tx;
}

{
  %served = ();
  @events = ();
  my $tx = _ask('house-model', $LOCAL_KEY);
  is($tx->res->code, 200, 'the local-only key is served');
  is($tx->res->headers->header('x-skeid-node'), 'local-1', 'from a local node');
  is($events[0]{api_key_id}, $LOCAL_ID, 'and is billed under the id derived from its key');
}

# The whole point of deny_tags: saturation must not become an exception to the policy.
{
  %served = ();
  ok($skeid->start_request('local-1'), 'occupy the only local slot');

  my $tx = _ask('house-model', $LOCAL_KEY);
  is($tx->res->code, 429,
    'a local-only key waits for local capacity instead of falling through to cloud -- the '
    . 'cheapest moment to break a policy is exactly when capacity runs out, so this is where '
    . 'it has to hold');
  is($tx->res->json->{error}{type}, 'rate_limit_error',
    'and it is a load answer, not a permission one: the key may have this model, just not now');
  ok(!exists $served{cloud}, 'no cloud node saw the request');

  my $allowed = _ask('house-model', $CLOUD_KEY);
  is($allowed->res->code, 200, 'while a key that may use cloud gets it');
  is($allowed->res->headers->header('x-skeid-node'), 'cloud-1', 'from the cloud tier');

  $skeid->finish_request('local-1', ok => 1);
}

# ADR 0008: the alias is a product name, not a security boundary. Denying the cloud tier of an
# alias is worthless if the same node answers to its own model name.
{
  %served = ();
  my $tx = _ask('llama-3.3-70b', $LOCAL_KEY);
  is($tx->res->code, 403,
    'asking a denied node for its raw model name is refused -- the deny is enforced at node '
    . 'selection, not only by dropping a tier from the plan');
  is($tx->res->json->{error}{type}, 'permission_error', 'as a permission answer');
  ok(!exists $served{cloud}, 'and the node was never contacted');

  my $allowed = _ask('llama-3.3-70b', $CLOUD_KEY);
  is($allowed->res->code, 200, 'a key without that denial may still ask for it by name');
}

# 403 and 503 mean different things and a client acts on them differently: one is "ask someone
# to change your plan", the other is "try again later". Collapsing them would be a support cost.
{
  my $tx = _ask('no-such-model-anywhere', $LOCAL_KEY);
  is($tx->res->code, 503, 'a model nobody serves stays a 503 even under a policy');
  is($tx->res->json->{error}{type}, 'model_not_found', 'because it is not a permission problem');
}

# --- the key id may not come from the client ---
{
  %served = ();
  is($skeid->trust_key_id_header, 0, 'the key id header is not trusted by default');

  my $tx = _ask('llama-3.3-70b', $LOCAL_KEY, 'x-skeid-key-id' => $CLOUD_ID);
  is($tx->res->code, 403,
    'a client cannot name itself into another key\'s policy -- identity comes from the key it '
    . 'had to present, never from a header it can type');
  ok(!exists $served{cloud}, 'so the denied node stays unreachable');

  @events = ();
  _ask('house-model', $LOCAL_KEY, 'x-skeid-key-id' => 'someone-elses-invoice');
  is($events[0]{api_key_id}, $LOCAL_ID,
    'and cannot bill its usage to somebody else either');
}

{
  # Deployments that authenticate in front of Skeid do need the header, and say so.
  $skeid->trust_key_id_header(1);
  my $tx = _ask('llama-3.3-70b', $LOCAL_KEY, 'x-skeid-key-id' => $CLOUD_ID);
  is($tx->res->code, 200, 'with routing.trust_key_id_header the header names the customer again');
  $skeid->trust_key_id_header(0);
}

is($skeid->node_metrics('local-1')->{inflight}, 0, 'no admission leaked across all of the above');
is($skeid->node_metrics('cloud-1')->{inflight}, 0, 'on either node');

done_testing;
