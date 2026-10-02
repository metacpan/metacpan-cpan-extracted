package Langertha::Skeid::Proxy;
our $VERSION = '0.003';
# ABSTRACT: Multi-format LLM proxy (OpenAI, Anthropic, Ollama) powered by Langertha::Skeid routing
use strict;
use warnings;
use Mojolicious;
use Mojo::IOLoop;
use Time::HiRes qw(time);
use JSON::MaybeXS qw(decode_json);
use Scalar::Util qw(blessed weaken);
use Langertha::Skeid;
use Langertha::Skeid::CapacityProbe;
use Langertha::Skeid::Registry;
use Langertha::Skeid::Secret;
use Langertha::Skeid::Proxy::RelayContent;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Anthropic;
use Langertha::Skeid::Protocol::Anthropic::Stream;
use Langertha::Skeid::Protocol::Ollama;
use Langertha::Skeid::Protocol::Ollama::Stream;
use Langertha::ToolCall;


sub build_app {
  my ($class, %opts) = @_;

  # Auto-detect OpenBao KeyBroker if OPENBAO_ROLE_ID is set
  my @skeid_opts = ($opts{config_file} ? (config_file => $opts{config_file}) : ());
  if ($ENV{OPENBAO_ROLE_ID} && $ENV{OPENBAO_SECRET_ID}) {
    eval {
      require Langertha::Skeid::KeyBroker::OpenBao;
      push @skeid_opts, key_broker => Langertha::Skeid::KeyBroker::OpenBao->new(
        addr      => $ENV{OPENBAO_ADDR} // 'http://127.0.0.1:8200',
        role_id   => $ENV{OPENBAO_ROLE_ID},
        secret_id => $ENV{OPENBAO_SECRET_ID},
      );
    };
    warn "Failed to initialize OpenBao KeyBroker: $@" if $@;
  }

  # The explicit admin API key goes into new(), so it is in force for the first config already
  # (a registry block checks for it); an existing Skeid gets it set (skeid k64).
  push @skeid_opts, admin_api_key => $opts{admin_api_key}
    if defined($opts{admin_api_key}) && length($opts{admin_api_key});
  my $skeid = $opts{skeid} || Langertha::Skeid->new(@skeid_opts);
  $skeid->set_admin_api_key($opts{admin_api_key}) if exists $opts{admin_api_key};
  # How many processes share these nodes. Set before anything reads max_conns or starts a
  # timer, since both are divided by it (ADR 0010).
  if (defined $opts{worker_count} && $opts{worker_count} > 0) {
    $skeid->worker_count(0 + $opts{worker_count});
  }

  # Renew the vault token on a timer rather than when a request discovers it expired. A request
  # that has to renew first pays the round-trip in its own latency, and it is the request least
  # able to afford it -- the first one after a quiet period.
  if ($skeid->has_key_broker && $skeid->key_broker->can('start_renewal')) {
    $skeid->key_broker->start_renewal;
  }

  # Capacity probes (ADR 0009). Held by the app, because a probe that goes out of scope stops
  # polling. Nodes with no capacity block get none, which is plain inflight admission.
  my $probes = Langertha::Skeid::CapacityProbe->start_for_skeid($skeid);
  my $probe_key = $skeid->_probe_inventory_key;

  my $app = Mojolicious->new;
  $app->secrets(['skeid-proxy']);

  # A write-behind usage store (usage_store.flush_interval_ms) writes after the request was
  # answered, so its failures cannot come back through _record_usage_event; they come here and
  # get the same log line (skeid k78). Weak: the app holds the skeid, the skeid holds this.
  weaken(my $weak_app = $app);
  $skeid->on_usage_lost(sub {
    my ($skeid, $event, $err) = @_;
    return _log_lost_usage_event($weak_app, $skeid, $event, $err) if $weak_app;
    warn 'skeid: usage event lost: request_id=' . ($event->{request_id} // '') . ': '
      . ($err // 'unknown error') . "\n";
    return;
  });
  $app->ua->connect_timeout(10);
  # One number for how long an upstream may take and how long it may be silent: a model that
  # thinks sends nothing until its first token, and Mojo::UserAgent closes a connection that
  # was silent for 40s whatever the request timeout allows. The client's side follows the same
  # number per request, see _extend_client_timeout.
  my $upstream_timeout
    = (defined($ENV{SKEID_UPSTREAM_TIMEOUT}) && $ENV{SKEID_UPSTREAM_TIMEOUT} =~ /^\d+$/
      && $ENV{SKEID_UPSTREAM_TIMEOUT} > 0)
    ? 0 + $ENV{SKEID_UPSTREAM_TIMEOUT}
    : 300;
  $app->ua->request_timeout($upstream_timeout);
  $app->ua->inactivity_timeout($upstream_timeout);
  # Mojo::UserAgent pools 5 upstream connections by default. A proxy serving more concurrent
  # requests than that reconnects for the surplus on every request, which shows up as latency
  # that grows with concurrency for no visible reason. Sized for the concurrency a single
  # Skeid process can actually sustain, not for the number of nodes.
  $app->ua->max_connections(
    (defined($ENV{SKEID_UPSTREAM_POOL}) && $ENV{SKEID_UPSTREAM_POOL} =~ /^\d+$/)
      ? 0 + $ENV{SKEID_UPSTREAM_POOL}
      : 100
  );
  $app->helper(skeid => sub { $skeid });

  # A config reload replaces the whole inventory, so probes have to follow it or they keep
  # polling for nodes that are gone and never start for new ones. They follow the probe key,
  # not the inventory generation: a health flip moves the generation but not what a probe
  # polls, and a restart makes every probe forget its own reading (skeid #40) -- readings from
  # other sources, such as a rate-limit backoff, survive it. The key is recomputed only when the
  # generation has moved, so an unchanged inventory costs an integer compare per request.
  $app->hook(before_dispatch => sub {
    my $key = $skeid->_probe_inventory_key;
    return if $key eq $probe_key;
    $probe_key = $key;
    $_->stop for values %$probes;
    $probes = Langertha::Skeid::CapacityProbe->start_for_skeid($skeid);
  });

  # The request's id is fixed here, before anything can fail or hang up: the client gets it back
  # as x-request-id whatever the answer turns out to be, and the usage event and the lost-event
  # log line carry the same one. It lives in the stash because a request whose client is gone
  # has no transaction to read it from any more.
  $app->hook(before_dispatch => sub {
    my ($c) = @_;
    my $id = _request_id($c);
    $c->stash('skeid.request_id' => $id);
    $c->res->headers->header('x-request-id' => $id);
  });

  my $r = $app->routes;

  # Still 'ok' while a config reload is failing: the proxy serves under the config it kept, so
  # it is not unhealthy, and a probe that restarted it would lose that config. The reload
  # state is shown without its message, which can name customers; that is on /skeid/config.
  $r->get('/health' => sub {
    my ($c) = @_;
    my $reload = $c->skeid->reload_status;
    delete $reload->{error};
    $c->render(json => { status => 'ok', proxy => 'skeid', config_reload => $reload });
  });

  # Provider manifest (skeid #29, ADR 0015): per customer key, never the whole catalog.
  $r->get('/.well-known/langertha.json' => sub {
    my ($c) = @_;
    _handle_manifest($c);
  });

  # OpenAI format
  $r->get('/v1/models' => sub {
    my ($c) = @_;
    my @data = map {
      +{
        id       => $_->{model},
        object   => 'model',
        created  => int(time),
        owned_by => 'skeid',
      }
    } @{$c->skeid->list_models(api_key_id => _request_api_key_id($c))};
    $c->render(json => { object => 'list', data => \@data });
  });

  $r->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    _handle_openai_chat($c);
  });

  $r->post('/v1/embeddings' => sub {
    my ($c) = @_;
    _handle_openai_embeddings($c);
  });

  # Anthropic format
  $r->post('/v1/messages' => sub {
    my ($c) = @_;
    # Every error this request produces, wherever it is rendered, has to be Anthropic-shaped
    # (core karr #224). _render_error reads this.
    $c->stash('skeid.error_format' => 'anthropic');
    _handle_anthropic_messages($c);
  });

  # Ollama format. Every error on these routes has to be Ollama-shaped, {"error": "<string>"}:
  # an Ollama client decodes the error as a string and fails on the OpenAI object (skeid #47).
  # _render_error reads this.
  my $ollama = $r->under('/api' => sub {
    my ($c) = @_;
    $c->stash('skeid.error_format' => 'ollama');
    return 1;
  });

  $ollama->post('/chat' => sub {
    my ($c) = @_;
    _handle_ollama($c, 'chat');
  });

  $ollama->post('/generate' => sub {
    my ($c) = @_;
    _handle_ollama($c, 'generate');
  });

  $ollama->get('/tags' => sub {
    my ($c) = @_;
    $c->render(json => Langertha::Skeid::Protocol::Ollama->tags_from_models(
      $c->skeid->list_models(api_key_id => _request_api_key_id($c))));
  });

  $ollama->get('/ps' => sub {
    my ($c) = @_;
    $c->render(json => { models => [] });
  });

  # Skeid-to-Skeid registry (skeid #18, ADR 0017): a fronting tier's CapacityProbe::Registry
  # pulls this. 404 unless registry.enabled, and never unsigned. No store may keep it: a cached
  # snapshot is a stale one. It is registered before the /skeid admin block so it is not behind
  # _authorize_admin: it also takes the registry read key (skeid #49), which that block must
  # never accept -- the read key opens this one route and nothing else.
  $r->get('/skeid/registry/snapshot' => sub {
    my ($c) = @_;
    return unless _authorize_registry_read($c);
    my $skeid = $c->skeid;
    $c->res->headers->header('Cache-Control' => 'no-store');
    unless ($skeid->registry_enabled) {
      $c->render(status => 404,
        json => { error => { message => 'No registry snapshot is published here', type => 'not_found' } });
      return;
    }
    my ($body, $signature) = eval { Langertha::Skeid::Registry->signed_snapshot($skeid) };
    unless (defined $body) {
      my $err = $@ || 'unknown error';
      unless (length($skeid->registry_secret // '')) {
        $c->render(status => 503,
          json => { error => { message => 'Registry secret is not set', type => 'unavailable' } });
        return;
      }
      # Anything else is a bug in building the snapshot. The operator gets the cause in the
      # log; the caller gets nothing that could describe this process's internals.
      $err =~ s/\s+\z//;
      $c->app->log->error("registry snapshot failed: $err");
      $c->render(status => 500,
        json => { error => { message => 'Registry snapshot could not be built', type => 'server_error' } });
      return;
    }
    $c->res->headers->header(Langertha::Skeid::Registry->SIGNATURE_HEADER => $signature);
    $c->render(data => $body, format => 'json');
  });

  # Lightweight admin API for live control-plane updates.
  my $admin = $r->under('/skeid' => sub {
    my ($c) = @_;
    return _authorize_admin($c);
  });

  $admin->get('/nodes' => sub {
    my ($c) = @_;
    $c->render(json => { nodes => $c->skeid->list_nodes });
  });

  $admin->post('/nodes' => sub {
    my ($c) = @_;
    my $body = $c->req->json || {};
    my $ok = eval { $c->skeid->call_function('nodes.add', $body)->{ok} };
    if (!$ok || $@) {
      my $msg = $@ ? "$@" : 'invalid node payload';
      $msg =~ s/\s+$//;
      $c->render(json => { error => { message => $msg, type => 'invalid_request_error' } }, status => 400);
      return;
    }
    $c->render(json => { ok => 1, nodes => $c->skeid->list_nodes });
  });

  $admin->post('/nodes/:id/health' => sub {
    my ($c) = @_;
    my $body = $c->req->json || {};
    my $id = $c->param('id');
    my $ok = $c->skeid->call_function('nodes.set_health', {
      id      => $id,
      healthy => ($body->{healthy} ? 1 : 0),
    })->{ok};
    $c->render(json => { ok => $ok ? 1 : 0 });
  });

  $admin->get('/config' => sub {
    my ($c) = @_;
    $c->render(json => { reload => $c->skeid->call_function('config.status', {}) });
  });

  $admin->get('/metrics/nodes' => sub {
    my ($c) = @_;
    $c->render(json => { metrics => $c->skeid->node_metrics });
  });

  $admin->get('/usage' => sub {
    my ($c) = @_;
    my $report = $c->skeid->call_function('usage.report', {
      (defined($c->param('since')) && length($c->param('since')) ? (since => $c->param('since')) : ()),
      (defined($c->param('api_key_id')) && length($c->param('api_key_id')) ? (api_key_id => $c->param('api_key_id')) : ()),
      (defined($c->param('model')) && length($c->param('model')) ? (model => $c->param('model')) : ()),
      limit => ($c->param('limit') // 50),
    });
    my $status = ($report->{ok} ? 200 : 400);
    $c->render(status => $status, json => $report);
  });

  return $app;
}

sub _authorize_admin {
  my ($c) = @_;
  $c->skeid->maybe_reload_config;

  my $admin_api_key = $c->skeid->admin_api_key // '';
  if (!length($admin_api_key)) {
    $c->render(status => 404, text => 'Not Found');
    return undef;
  }

  my $auth = $c->req->headers->authorization // '';
  my ($scheme, $token) = $auth =~ /\A(\S+)\s+(.+)\z/;
  my $ok = defined($scheme) && lc($scheme) eq 'bearer' && defined($token)
    && Langertha::Skeid::Secret->equal($token, $admin_api_key);
  if (!$ok) {
    $c->res->headers->header('WWW-Authenticate' => 'Bearer realm="skeid-admin"');
    $c->render(
      status => 401,
      json   => {
        error => {
          type    => 'unauthorized',
          message => 'Missing or invalid admin bearer token',
        },
      },
    );
    return undef;
  }
  return 1;
}

# The snapshot route's gate: the admin API key (compat) or the registry read key, each compared
# in constant time. 404 when neither is configured, like every closed /skeid route; 401 with the
# admin route's challenge otherwise.
sub _authorize_registry_read {
  my ($c) = @_;
  my $skeid = $c->skeid;
  $skeid->maybe_reload_config;

  my @accepted = grep { length } ($skeid->admin_api_key // '', $skeid->registry_read_key // '');
  unless (@accepted) {
    $c->render(status => 404, text => 'Not Found');
    return undef;
  }

  my $auth = $c->req->headers->authorization // '';
  my ($scheme, $token) = $auth =~ /\A(\S+)\s+(.+)\z/;
  my $ok = 0;
  if (defined($scheme) && lc($scheme) eq 'bearer' && defined($token)) {
    # No short-circuit: both candidates are compared whichever one matches.
    $ok |= Langertha::Skeid::Secret->equal($token, $_) for @accepted;
  }
  return 1 if $ok;

  $c->res->headers->header('WWW-Authenticate' => 'Bearer realm="skeid-admin"');
  $c->render(
    status => 401,
    json   => {
      error => {
        type    => 'unauthorized',
        message => 'Missing or invalid registry bearer token',
      },
    },
  );
  return undef;
}

# What a key is shown depends on who presents it, so no cache may hand one key's answer to
# another: every answer -- 404/401/403 included -- is private, not stored, and varies on each
# header that can carry the identity. It does not reload the config: a public route anybody can
# hit must not be a way to rerun the loader (and restart the node probes) per anonymous GET;
# like /v1/models it serves what the last load resolved. 404 when nothing is published (disabled, or a Langertha without
# Langertha::Manifest), 401 without a key (ADR 0015: no anonymous manifest, not even a minimal
# one), 403 for a key without a manifest: grant, else the manifest built for that key id.
sub _handle_manifest {
  my ($c) = @_;
  my $skeid = $c->skeid;

  my $headers = $c->res->headers;
  $headers->header('Cache-Control' => 'private, no-store');
  $headers->header(Vary => 'Authorization, X-Api-Key, X-Skeid-Key-Id, X-Api-Key-Id');

  unless ($skeid->manifest_enabled && $skeid->manifest_available) {
    $c->render(status => 404,
      json => { error => { message => 'No provider manifest is published here', type => 'not_found' } });
    return;
  }

  my $api_key_id = _request_api_key_id($c);
  if (!defined($api_key_id) || $api_key_id eq 'anonymous') {
    $headers->header('WWW-Authenticate' => 'Bearer realm="skeid"');
    $c->render(status => 401,
      json => { error => { message => 'An API key is required for the provider manifest', type => 'unauthorized' } });
    return;
  }

  my $json = $skeid->manifest_for_key($api_key_id);
  unless (defined $json) {
    $c->render(status => 403,
      json => { error => { message => 'No provider manifest is published for this key', type => 'permission_error' } });
    return;
  }

  $c->render(data => $json, format => 'json');
  return;
}

# The client's connection is silent while the upstream works, and the server closes a connection
# that was silent for its inactivity timeout (30s unless the server was told otherwise). So a
# request that calls an upstream gets, on top of that, what the upstream may take: the client
# outlasts the upstream and is still there for the answer, or for the error. Read from the user
# agent rather than kept beside it, so the two sides cannot drift apart. It holds for this
# request only: the server sets its own timeout again for the next one on the connection. A
# timeout of 0 is none, on either side, and stays none.
sub _extend_client_timeout {
  my ($c) = @_;
  my $stream = Mojo::IOLoop->stream($c->tx->connection // '') or return;
  my $own = $stream->timeout;
  my $upstream = $c->app->ua->request_timeout;
  $stream->timeout(($own && $upstream) ? $own + $upstream : 0);
  return;
}

sub _handle_openai_chat {
  my ($c) = @_;
  _extend_client_timeout($c);
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    $c->render(json => { error => { message => 'Invalid JSON body', type => 'invalid_request_error' } }, status => 400);
    return;
  }

  my $model = $body->{model} // '';
  my $api_key_id = _request_api_key_id($c);
  _begin_route_async($c, $model, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    # The alias layer means the model the client asked for and the model the node is asked for
    # are two different strings (ADR 0008). The upstream body carries the served model; the
    # usage event carries both, or cost attribution silently loses which product was used.
    my $served_model = _served_model($tier, $model);
    $body->{model} = $served_model if ref($body) eq 'HASH';

    my $url = _endpoint_url_for_node($route->{url}, '/chat/completions');
    my $meta = {
      api_format => 'openai',
      endpoint   => '/v1/chat/completions',
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model            => $served_model,
      requested_model  => $model,
      route_url        => ($route->{url} // ''),
    };

    if ($body->{stream}) {
      _proxy_openai_stream($c, $url, $body, $node_id, $started, $meta);
      return;
    }

    $c->render_later;
    _proxy_openai_json_async($c, $url, $body, $node_id, $started, $meta, sub {
      my ($res, $err, $status) = @_;
      return if $err;
      _render_upstream_response($c, $res, $node_id);
    });
  });
}

sub _handle_openai_embeddings {
  my ($c) = @_;
  _extend_client_timeout($c);
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    $c->render(json => { error => { message => 'Invalid JSON body', type => 'invalid_request_error' } }, status => 400);
    return;
  }

  my $model = $body->{model} // '';
  my $api_key_id = _request_api_key_id($c);
  _begin_route_async($c, $model, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    # The alias layer means the model the client asked for and the model the node is asked for
    # are two different strings (ADR 0008). The upstream body carries the served model; the
    # usage event carries both, or cost attribution silently loses which product was used.
    my $served_model = _served_model($tier, $model);
    $body->{model} = $served_model if ref($body) eq 'HASH';

    my $url = _endpoint_url_for_node($route->{url}, '/embeddings');
    my $meta = {
      api_format => 'openai',
      endpoint   => '/v1/embeddings',
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model            => $served_model,
      requested_model  => $model,
      route_url        => ($route->{url} // ''),
    };
    $c->render_later;
    _proxy_openai_json_async($c, $url, $body, $node_id, $started, $meta, sub {
      my ($res, $err, $status) = @_;
      return if $err;
      _render_upstream_response($c, $res, $node_id);
    });
  });
}

sub _handle_anthropic_messages {
  my ($c) = @_;
  _extend_client_timeout($c);
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    _render_error($c, 400, 'Invalid JSON body', 'invalid_request_error');
    return;
  }

  my $wants_stream = $body->{stream} ? 1 : 0;

  # Translation reads the client's body, so a failure there is the client's malformed request
  # -- a provider built-in tool skeid cannot forward, or a shape the translator cannot read.
  # Uncaught it escapes as Mojolicious' HTML 500; answer a 400 an Anthropic SDK can parse, before
  # anything is routed or metered (core karr #216).
  my $openai_body = eval { Langertha::Skeid::Protocol::Anthropic->request_to_openai($body) };
  unless ($openai_body) {
    # A deliberate refusal carries a message written for the client. Any other exception can quote
    # the request, so its text is neither sent nor logged (k75, k82).
    my $err = $@;
    my $msg = blessed($err) && $err->isa('Langertha::Skeid::Protocol::Refusal')
      ? $err->message : 'Invalid request';
    _render_error($c, 400, $msg, 'invalid_request_error');
    return;
  }
  my $model = $openai_body->{model} // '';
  my $api_key_id = _request_api_key_id($c);

  _begin_route_async($c, $model, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    # The alias layer means the model the client asked for and the model the node is asked for
    # are two different strings (ADR 0008). The upstream body carries the served model; the
    # usage event carries both, or cost attribution silently loses which product was used.
    my $served_model = _served_model($tier, $model);
    $openai_body->{model} = $served_model;

    my $url = _endpoint_url_for_node($route->{url}, '/chat/completions');
    my $meta = {
      api_format => 'anthropic',
      endpoint   => '/v1/messages',
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model            => $served_model,
      requested_model  => $model,
      route_url        => ($route->{url} // ''),
    };

    if ($wants_stream) {
      # Ask upstream for a stream in the one dialect Skeid speaks to nodes, and rewrite it at
      # the client edge (ADR 0001). include_usage because Anthropic clients read token counts
      # from message_delta, and an OpenAI stream omits usage unless asked.
      $openai_body->{stream} = \1;
      $openai_body->{stream_options} = { include_usage => \1 };
      _proxy_openai_stream($c, $url, $openai_body, $node_id, $started, $meta,
        Langertha::Skeid::Protocol::Anthropic::Stream->new(model => $model));
      return;
    }

    delete $openai_body->{stream};
    $c->render_later;
    _proxy_openai_json_async($c, $url, $openai_body, $node_id, $started, $meta, sub {
      my ($res, $err, $status, $upstream, $payload) = @_;
      return if $err;
      $c->res->code($status || 200);
      $c->res->headers->header('x-skeid-node' => $node_id);
      $c->render(json => $payload);
    }, sub {
      # response_from_openai reads a decoded OpenAI response ($upstream->{choices}, ...); the
      # raw Mojo $res would read as all-undef and yield a well-formed but empty envelope (karr #26).
      return Langertha::Skeid::Protocol::Anthropic->response_from_openai($_[0], $model);
    });
  });
}

# Serves both Ollama completion routes. /api/chat and /api/generate differ only at the edge --
# generate's prompt/system/images become one chat conversation on the way up, and the answer
# carries `response` instead of `message` on the way back (skeid #43) -- so they share the
# route, admission, metering and pricing below and cannot drift apart.
my %OLLAMA_FACE = (
  chat => {
    endpoint => '/api/chat',
    request  => 'request_to_openai',
    response => 'response_from_openai',
    shape    => 'chat',
  },
  generate => {
    endpoint => '/api/generate',
    request  => 'generate_request_to_openai',
    response => 'generate_response_from_openai',
    shape    => 'generate',
  },
);

sub _handle_ollama {
  my ($c, $kind) = @_;
  _extend_client_timeout($c);
  my $face = $OLLAMA_FACE{$kind};
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    _render_error($c, 400, 'Invalid JSON body', 'invalid_request_error');
    return;
  }

  # Ollama defaults stream to true when the field is absent, unlike everyone else. A client
  # that omits it is asking for a stream and will sit waiting for newline-delimited JSON.
  my $wants_stream = exists $body->{stream} ? ($body->{stream} ? 1 : 0) : 1;

  my $request_method = $face->{request};
  # A body the translator cannot read is the client's malformed request. Uncaught it escapes as
  # Mojolicious' HTML 500; answer a 400 in Ollama's shape before anything is routed or metered.
  # The exception's text stays out of the answer and the log, as with a dying response translator.
  my $openai_body = eval { Langertha::Skeid::Protocol::Ollama->$request_method($body) };
  unless (ref($openai_body) eq 'HASH') {
    _render_error($c, 400, 'Invalid request', 'invalid_request_error');
    return;
  }
  my $model = $openai_body->{model} // '';
  my $api_key_id = _request_api_key_id($c);

  _begin_route_async($c, $model, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    # The alias layer means the model the client asked for and the model the node is asked for
    # are two different strings (ADR 0008). The upstream body carries the served model; the
    # usage event carries both, or cost attribution silently loses which product was used.
    my $served_model = _served_model($tier, $model);
    $openai_body->{model} = $served_model;

    my $url = _endpoint_url_for_node($route->{url}, '/chat/completions');
    my $meta = {
      api_format      => 'ollama',
      endpoint        => $face->{endpoint},
      api_key_id      => _request_api_key_id($c),
      provider        => 'skeid',
      engine          => ($route->{engine} // 'openaibase'),
      model           => $served_model,
      requested_model => $model,
      route_url       => ($route->{url} // ''),
    };

    if ($wants_stream) {
      $openai_body->{stream} = \1;
      $openai_body->{stream_options} = { include_usage => \1 };
      _proxy_openai_stream($c, $url, $openai_body, $node_id, $started, $meta,
        Langertha::Skeid::Protocol::Ollama::Stream->new(model => $model, shape => $face->{shape}));
      return;
    }

    delete $openai_body->{stream};
    $c->render_later;
    _proxy_openai_json_async($c, $url, $openai_body, $node_id, $started, $meta, sub {
      my ($res, $err, $status, $upstream, $payload) = @_;
      return if $err;
      $c->res->code($status || 200);
      $c->res->headers->header('x-skeid-node' => $node_id);
      $c->render(json => $payload);
    }, sub {
      # See the Anthropic path above: the translator needs the decoded upstream body, not the
      # Mojo response object, or every field reads undef and the client gets empty content (karr #26).
      my $response_method = $face->{response};
      return Langertha::Skeid::Protocol::Ollama->$response_method($_[0]);
    });
  });
}

# Walks the tiers of a requested model (ADR 0008) until one admits the request.
#
# The two ways a tier can fail are not the same and must not be treated the same. A tier with
# no eligible node is skipped immediately -- waiting cannot conjure a node that does not exist.
# A tier whose nodes are all busy is waited on for its own wait_ms, because capacity comes back.
# Only when every tier is exhausted does the request fail, and which failure it is depends on
# whether any tier ever had an eligible node: none did means the model is unroutable (503),
# some did means everything was busy (429).
#
# $cb is called with ($route, $node_id, $started, $tier) on success and with nothing on failure,
# after the error has been rendered.
sub _begin_route_async {
  my ($c, $model, $api_key_id, $cb) = @_;
  $cb ||= sub { };
  my $wait_poll_ms = 0 + ($c->skeid->route_wait_poll_ms // 25);
  $wait_poll_ms = 1 if $wait_poll_ms < 1;

  my $decision = $c->skeid->call_function('route.plan', {
    model      => ($model // ''),
    api_key_id => $api_key_id,
  });

  # The key's policy does not grant this model, or grants it but forbids every tier that serves
  # it. Both are permission answers, and neither improves by retrying -- so neither may be
  # reported as a capacity problem.
  if (!$decision->{permitted}) {
    _render_error($c, 403, "Model '$model' is not available for this key", 'permission_error');
    $cb->();
    return;
  }

  my $plan = $decision->{tiers} || [];
  my $started = time;
  my $saw_eligible = 0;
  my $last_node_id = '';
  my $index = 0;
  my $tier_deadline = 0;

  my $tick;
  my $wait_timer;
  my $fail = sub {
    # Nothing eligible can mean two different things once a policy is in play: the model is
    # unroutable, or it is routable and this key is not allowed at the nodes that serve it.
    # Only the failure path pays for telling them apart.
    if (!$saw_eligible && grep { @{$_->{deny_tags} || []} } @$plan) {
      my $without_deny = 0;
      for my $tier (@$plan) {
        my $state = $c->skeid->call_function('route.state', {
          model => ($tier->{model} // ''),
          tags  => ($tier->{tags} || []),
        });
        $without_deny = 1, last if ref($state) eq 'HASH' && $state->{has_eligible};
      }
      if ($without_deny) {
        _render_error($c, 403, "Model '$model' is not available for this key", 'permission_error');
        undef $tick;
        $cb->();
        return;
      }
    }

    if (!$saw_eligible) {
      _render_error($c, 503, "No healthy node available for model '$model'", 'model_not_found');
    } else {
      my $waited_ms = int((time - $started) * 1000);
      my $msg = length($last_node_id)
        ? "Timed out waiting for free capacity on node '$last_node_id' (waited ${waited_ms}ms)"
        : "Timed out waiting for free capacity for model '$model' (waited ${waited_ms}ms)";
      _render_error($c, 429, $msg, 'rate_limit_error');
    }
    undef $tick;
    $cb->();
    return;
  };

  $tick = sub {
    return $fail->() if $index > $#$plan;

    my $tier = $plan->[$index];
    my %selector = (
      model     => ($tier->{model} // ''),
      tags      => ($tier->{tags} || []),
      deny_tags => ($tier->{deny_tags} || []),
      (length($tier->{engine} // '') ? (engine => $tier->{engine}) : ()),
    );

    my $state = $c->skeid->call_function('route.state', \%selector);
    if (ref($state) eq 'HASH' && $state->{has_eligible}) {
      $saw_eligible = 1;

      my $route = $c->skeid->call_function('route.next', \%selector)->{node};
      if ($route && ref($route) eq 'HASH') {
        my $node_id = $route->{id};
        $last_node_id = $node_id if defined $node_id;
        if ($c->skeid->call_function('request.start', { id => $node_id })->{ok}) {
          # Break the recursive callback's self-reference before control moves into the upstream
          # lifecycle. The active call frame keeps it alive until this invocation returns.
          undef $tick;
          $cb->($route, $node_id, $started, $tier);
          return;
        }
      }

      # Eligible but nothing free: this tier is worth waiting on, up to its own window.
      if (time < $tier_deadline) {
        $wait_timer = Mojo::IOLoop->timer($wait_poll_ms / 1000, $tick);
        return;
      }
    }

    $index++;
    $tier_deadline = time + (($plan->[$index] ? ($plan->[$index]{wait_ms} // 0) : 0) / 1000);
    $tick->();
    return;
  };

  # A client that hangs up while its request waits for capacity stops waiting: the next poll
  # would take a slot for nobody and never give it back. $tick is set exactly as long as
  # admission is undecided, which tells this finish from the one every answered request emits
  # as well. Nothing is rendered, there is nobody to read it. A stand-in controller has no
  # transaction.
  if ($c->can('tx') && $c->tx) {
    $c->tx->on(finish => sub {
      return unless $tick;
      Mojo::IOLoop->remove($wait_timer) if defined $wait_timer;
      undef $tick;
      $cb->();
    });
  }

  $tier_deadline = time + ((@$plan ? ($plan->[0]{wait_ms} // 0) : 0) / 1000);
  $tick->();
  return;
}

# True once the client of this request cannot be answered any more: its transaction was closed,
# or is destroyed already -- the controller holds it weakly. Only asked before anything was
# rendered, because a transaction that was answered is finished as well.
sub _client_gone {
  my ($c) = @_;
  my $tx = $c->tx;
  return (!$tx || $tx->is_finished) ? 1 : 0;
}

# Ends an upstream transaction in flight by closing its connection. The user agent then drops
# the connection instead of pooling it and runs the transaction's completion callback, and the
# node sees the connection close, which is what makes it stop generating. A transaction that
# is still connecting is closed as soon as it has a connection -- one tick later, because the
# user agent is in the middle of setting that connection up when it announces it. A finished
# transaction is left alone: its connection may be serving another request by now.
sub _cancel_upstream {
  my ($tx) = @_;
  my $close = sub {
    my ($id) = @_;
    return if $tx->is_finished;
    my $stream = Mojo::IOLoop->stream($id) or return;
    $stream->close;
    return;
  };
  if (defined(my $id = $tx->connection)) {
    $close->($id);
    return;
  }
  $tx->once(connection => sub {
    my (undef, $id) = @_;
    Mojo::IOLoop->next_tick(sub { $close->($id) });
  });
  return;
}

# What a request its client abandoned records (ADR 0004): failed, under the status nginx made
# the convention for "client closed request" -- no answer was delivered, and 499 can be told
# from every status a node or Skeid itself answers with.
sub _client_abort_event {
  return (
    status_code   => 499,
    ok            => 0,
    error_type    => 'client_abort',
    error_message => 'Client closed the connection before the response was complete',
  );
}

# $translate is an optional coderef that turns the decoded upstream answer into what the client
# gets. It runs before the request is finished and metered, so a translator that dies is one
# failed request -- one usage event with ok => 0, an error in the face's own shape -- and the
# callback gets the translated payload as its fifth argument, or nothing after an error.
sub _proxy_openai_json_async {
  my ($c, $url, $body, $node_id, $started, $meta, $cb, $translate) = @_;
  $meta ||= {};
  $cb ||= sub { };

  my %fwd_headers = _forward_headers($c);
  _inject_node_auth_async(\%fwd_headers, $c->skeid, $node_id, sub {
  my ($no_key) = @_;

  # The client hung up while the node key was being resolved, whether or not it resolved -- asked
  # before the refusal, which would meter and answer a transaction nobody holds any more. Nothing went upstream: the slot
  # is given back and nothing is metered, as for every request that was not forwarded.
  if (_client_gone($c)) {
    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => 0,
      aborted => 1,
      duration_ms => _duration_ms($started),
    });
    $cb->(undef, 1, 499);
    return;
  }

  if (defined $no_key) {
    _refuse_unkeyed_node($c, $node_id, $started, $meta, $no_key);
    $cb->(undef, 1, 503);
    return;
  }
  my $tx = $c->app->ua->build_tx(POST => $url, \%fwd_headers, json => $body);

  # Set by whichever comes first, the upstream's completion or the client hanging up, so that
  # request.finish and the usage event happen once.
  my $closed = 0;

  $c->tx->on(finish => sub {
    return if $closed;
    $closed = 1;
    my $duration_ms = _duration_ms($started);
    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => 0,
      aborted => 1,
      duration_ms => $duration_ms,
    });
    _record_usage_event($c, {
      %$meta,
      _client_abort_event(),
      node_id     => $node_id,
      duration_ms => $duration_ms,
      metrics     => {},
    });
    _cancel_upstream($tx);
    $cb->(undef, 1, 499);
  });

  $c->app->ua->start($tx => sub {
    my ($ua, $done) = @_;
    # The client hung up and its request was closed then; this is the cancelled transaction.
    return if $closed;
    $closed = 1;
    my $duration_ms = _duration_ms($started);
    my $res = $done->res;

    # Mojo reports an HTTP 4xx/5xx through tx->error too. Observe the response that actually
    # arrived before taking that error return, so a 429's Retry-After can gate the next request.
    # A transport failure has no useful status or headers and _observe_capacity records nothing.
    _observe_capacity($c, $node_id, $res);

    if (my $err = $done->error) {
      $c->skeid->call_function('request.finish', {
        id => $node_id,
        ok => 0,
        duration_ms => $duration_ms,
      });
      _record_usage_event($c, {
        %$meta,
        node_id       => $node_id,
        status_code   => ($err->{code} || 502),
        ok            => 0,
        duration_ms   => $duration_ms,
        error_type    => 'upstream_error',
        error_message => ($err->{message} // 'unknown'),
        metrics       => {},
      });
      _render_error($c, ($err->{code} || 502),
        'Upstream error: ' . _upstream_error_message($err, $done->res->body), 'upstream_error');
      $cb->(undef, 1, ($err->{code} || 502));
      return;
    }

    my $status = $res->code // 200;
    my $payload = eval { $res->json };

    my $translated;
    if ($translate) {
      $translated = eval { $translate->(ref($payload) eq 'HASH' ? $payload : {}) };
      unless (defined $translated) {
        $c->app->log->error('Translating the answer of node ' . $node_id . ' failed');
        $c->skeid->call_function('request.finish', {
          id => $node_id,
          ok => 0,
          duration_ms => $duration_ms,
        });
        _record_usage_event($c, {
          %$meta,
          node_id       => $node_id,
          status_code   => 500,
          ok            => 0,
          duration_ms   => $duration_ms,
          error_type    => 'translation_error',
          error_message => 'Response translation failed',
          metrics       => {},
        });
        _render_error($c, 500, 'Response translation failed', 'api_error');
        $cb->(undef, 1, 500);
        return;
      }
    }

    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => ($status < 500) ? 1 : 0,
      duration_ms => $duration_ms,
    });

    my $metrics = {};
    if (ref($payload) eq 'HASH') {
      my $tool_calls = eval { [ map { $_->to_hash } Langertha::ToolCall->extract('openai', $payload) ] } || [];
      $metrics = _priced_metrics($c, $meta, $body, $duration_ms, $payload, $tool_calls);
    }

    _record_usage_event($c, {
      %$meta,
      node_id      => $node_id,
      status_code  => $status,
      ok           => ($status < 500) ? 1 : 0,
      duration_ms  => $duration_ms,
      metrics      => $metrics,
    });

    $cb->($res, 0, $status, (ref($payload) eq 'HASH' ? $payload : {}), $translated);
  });
  });

  return;
}

# $stream is an optional translator (Protocol::*::Stream). Without one the upstream's bytes are
# relayed untouched, which is what an OpenAI client wants and the only path that cannot lose
# anything in translation. With one, each OpenAI chunk is decoded and re-emitted in the
# client's own format -- the same edge-translation seam as the non-streaming path (ADR 0001).
sub _proxy_openai_stream {
  my ($c, $url, $body, $node_id, $started, $meta, $stream) = @_;
  $meta ||= {};

  my %fwd_headers = _forward_headers($c);

  # render_later before the key resolution, not after: a cold cache means the callback runs on
  # a later tick, and Mojolicious would have rendered an empty response by then.
  $c->render_later;

  _inject_node_auth_async(\%fwd_headers, $c->skeid, $node_id, sub {
  my ($no_key) = @_;

  # The client hung up while the node key was being resolved, whether or not it resolved -- asked
  # before the refusal, which would meter and answer a transaction nobody holds any more. Nothing
  # went upstream: the slot is given back and nothing is metered, as for every request that was
  # not forwarded. Nothing is set up yet, so there is nothing to take apart.
  if (_client_gone($c)) {
    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => 0,
      aborted => 1,
      duration_ms => _duration_ms($started),
    });
    return;
  }

  return _refuse_unkeyed_node($c, $node_id, $started, $meta, $no_key) if defined $no_key;
  my $tx = $c->app->ua->build_tx(POST => $url, \%fwd_headers, json => $body);
  # Mojolicious would parse an unchunked, exactly-text/event-stream body into its own `sse`
  # events and never emit `read` -- the relay would forward nothing (skeid karr #30).
  $tx->res->content(Langertha::Skeid::Proxy::RelayContent->new);

  my $headers_sent = 0;
  my $had_error = 0;
  # Taken now: the header goes out before the first byte, and the request may be past its
  # transaction by then.
  my $request_id = _request_id($c);
  # A translator that can report errors in its own format (Anthropic, Ollama) takes the failure
  # paths too: an upstream error status before the stream opens becomes a plain HTTP error in
  # the client's shape, a failure after it becomes an in-band error event (core karr #224).
  my $stream_errors = $stream && $stream->can('error_event');
  my $upstream_failed = 0;
  my $upstream_error_body = '';
  my $status = 200;
  # The upstream's own usage block, verbatim, so a stream is priced by the same metrics.normalize
  # call as a non-streamed answer (skeid #41). undef until a frame carries one.
  my $upstream_usage;
  my $accumulated_content_bytes = 0;
  # UTF-8 bytes of the content this stream relayed or translated, for the usage event (skeid #36).
  # A relayed stream counts off the OpenAI deltas it read along; a translated one takes its
  # translator's own count -- the text it actually wrote in the client's format. An observation
  # recorded beside the token counts, never a substitute for them.
  my $content_bytes = sub { $stream ? 0 + ((($stream->usage)[2]) // 0) : $accumulated_content_bytes };

  # Upstream chunks arrive faster than they can be written out, so they are queued and drained
  # one at a time. Writing each chunk directly would end the response after the first one:
  # a dynamic Mojolicious response with no drain callback is finished once its write queue
  # empties, and every later chunk then hits a destroyed transaction. The client sees headers,
  # no body, and no error.
  my @queue;
  my $draining = 0;
  my $upstream_done = 0;
  my $finished = 0;

  my $drain;
  $drain = sub {
    if (!@queue) {
      $draining = 0;
      if ($upstream_done && !$finished) {
        $finished = 1;
        $c->finish;
        # write_chunk retains its last drain callback. Clear the recursive callback scalar once
        # the queue is complete so that callback cannot retain the controller through $drain.
        undef $drain;
      }
      return;
    }
    $draining = 1;
    my $chunk = shift @queue;
    $c->write_chunk($chunk => sub { $drain->() if $drain });
  };

  # SSE frames do not respect read boundaries: one read can carry half a frame, and the half
  # that completes it arrives in the next. Parsing per read would silently drop the split
  # frame -- usually the last one, which is the one carrying usage.
  my $pending = '';

  # Set by whichever comes first, the upstream's completion, the client hanging up or a
  # translator that died, so that request.finish and the usage event happen once.
  my $closed = 0;

  # A translator that dies on a chunk ends the request here, not in the upstream callback the
  # exception would escape from: the upstream is cancelled, the slot given back, one failed usage
  # event written, and the client answered in its own face's error shape -- an HTTP error when
  # nothing was queued for it yet, an in-band error event when the stream is open. The
  # exception's text is neither logged nor sent: it is the translator's own and may quote the
  # request.
  my $wrote = 0;
  my $fail_translation = sub {
    return if $closed;
    $closed = 1;
    $tx->res->content->unsubscribe('read');
    my $duration_ms = _duration_ms($started);
    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => 0,
      duration_ms => $duration_ms,
    });
    _record_usage_event($c, {
      %$meta,
      node_id       => $node_id,
      status_code   => 500,
      ok            => 0,
      duration_ms   => $duration_ms,
      error_type    => 'translation_error',
      error_message => 'Stream translation failed',
      content_bytes => $content_bytes->(),
      metrics       => _stream_metrics($c, $meta, $body, $duration_ms, $upstream_usage),
    });
    _cancel_upstream($tx);
    $upstream_done = 1;
    if (!$wrote) {
      $c->res->headers->remove($_) for @{$c->res->headers->names};
      $c->res->headers->header('x-request-id' => $request_id);
      _render_error($c, 500, 'Stream translation failed', 'api_error');
      undef $drain;
      return;
    }
    my $frame = eval { $stream_errors ? $stream->error_event(500, 'Stream translation failed') : '' };
    push @queue, $frame if defined $frame && length $frame;
    $drain->() unless $draining;
    if (!$draining && !$finished) {
      $finished = 1;
      $c->finish;
      undef $drain;
    }
  };

  $tx->res->content->unsubscribe('read')->on(read => sub {
    my ($content, $bytes) = @_;
    # Kept only to lift the upstream's own error message into the error the client gets.
    return $upstream_error_body .= $bytes if $upstream_failed;
    unless ($headers_sent) {
      $status = $tx->res->code // 200;
      # The upstream refused before streaming anything. Opening an SSE response for it would
      # hand the client a 4xx/5xx event stream with no events in it; leave the response unsent
      # and let the completion callback answer it as an error, as the non-streaming path does.
      if ($stream_errors && $status >= 400) {
        $upstream_failed = 1;
        $upstream_error_body .= $bytes;
        return;
      }
      $c->res->code($status);
      for my $name (@{$tx->res->headers->names}) {
        my $lc = lc($name);
        next if $lc eq 'content-length' || $lc eq 'transfer-encoding' || $lc eq 'content-encoding';
        # A translated stream is not the upstream's media type any more. Relaying
        # text/event-stream to an Ollama client tells it to parse something it does not speak.
        next if $stream && $lc eq 'content-type';
        $c->res->headers->header($name => $tx->res->headers->header($name));
      }
      $c->res->headers->header('content-type' => $stream->content_type) if $stream;
      $c->res->headers->header('x-skeid-node' => $node_id);
      $c->res->headers->header('x-request-id' => $request_id);
      $headers_sent = 1;
    }

    # Parse SSE lines and accumulate usage + content bytes. Without a translator the relayed
    # bytes are never modified -- this reads along, it does not rewrite.
    $pending .= $bytes;
    my $translated = '';
    while ($pending =~ s/\A([^\n]*)\n//) {
      my $line = $1;
      next unless $line =~ /^data: (.+?)\s*$/;
      my $payload = $1;

      # OpenAI closes with a literal [DONE] sentinel, which is not JSON and has no equivalent
      # in either target format -- the translated stream ends with its own closing events.
      next if $payload eq '[DONE]';

      my $json = eval { decode_json($payload) };
      next unless $json && ref($json) eq 'HASH';

      if (my $delta = $json->{choices}[0]{delta}) {
        if (my $delta_content = $delta->{content}) {
          $accumulated_content_bytes += Langertha::Skeid::Protocol::utf8_length($delta_content);
        }
      }

      if (ref($json->{usage}) eq 'HASH') {
        $upstream_usage = _merge_usage($upstream_usage, $json->{usage});
      }

      if ($stream) {
        my $out = eval { $stream->delta($json) };
        unless (defined $out) {
          $c->app->log->error('Translating a stream chunk failed for node ' . $node_id);
          return $fail_translation->();
        }
        $translated .= $out;
      }
    }

    # The first read event fires with an empty chunk as soon as the upstream headers are
    # parsed, and writing an empty chunk finalizes a Mojolicious response. Relaying it would
    # end the stream before its first token -- headers, no body, no error.
    if ($stream) {
      return unless length $translated;
      $wrote = 1;
      push @queue, $translated;
    } else {
      return unless length $bytes;
      $wrote = 1;
      push @queue, $bytes;
    }
    $drain->() unless $draining;
  });

  $c->tx->on(finish => sub {
    # Also emitted when the answer is complete, and then there is nothing left to do here. When
    # the client hung up, what is queued has no reader and the drain callback that would take
    # the next chunk does not run again: drop the queue and the callback's self-reference, or
    # they keep the controller alive.
    @queue = ();
    $finished = 1;
    undef $drain;
    return if $closed;
    $closed = 1;
    $tx->res->content->unsubscribe('read');

    # Billed from what the stream reported before the client left; the node spent that, whoever
    # read it (ADR 0004).
    my $duration_ms = _duration_ms($started);
    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => 0,
      aborted => 1,
      duration_ms => $duration_ms,
    });
    _record_usage_event($c, {
      %$meta,
      _client_abort_event(),
      node_id       => $node_id,
      duration_ms   => $duration_ms,
      content_bytes => $content_bytes->(),
      metrics       => _stream_metrics($c, $meta, $body, $duration_ms, $upstream_usage),
    });
    _cancel_upstream($tx);
  });

  $c->app->ua->start($tx => sub {
    my ($ua, $tx_done) = @_;

    # The read listener closes over both the upstream transaction and the client controller.
    # Completion means no further bytes can arrive, so remove it before returning from any path;
    # otherwise the completed transaction owns the listener that owns the transaction forever.
    $tx_done->res->content->unsubscribe('read');

    # The client hung up and its request was closed then; this is the cancelled transaction.
    return if $closed;
    $closed = 1;

    # As on the JSON path, an HTTP error is still a response whose capacity headers matter.
    # Observe it before the pre-stream error return; transport failures contribute nothing.
    _observe_capacity($c, $node_id, $tx_done->res);

    if (my $err = $tx_done->error) {
      $had_error = 1;
      unless ($headers_sent) {
        my $duration_ms = _duration_ms($started);
        my $err_status = $err->{code} || 502;
        $c->skeid->call_function('request.finish', {
          id => $node_id,
          ok => 0,
          duration_ms => $duration_ms,
        });
        _record_usage_event($c, {
          %$meta,
          node_id       => $node_id,
          status_code   => $err_status,
          ok            => 0,
          duration_ms   => $duration_ms,
          error_type    => 'upstream_error',
          error_message => ($err->{message} // 'unknown'),
          content_bytes => $content_bytes->(),
          metrics       => _stream_metrics($c, $meta, $body, _duration_ms($started), $upstream_usage),
        });
        _render_error($c, $err_status,
          'Upstream error: ' . _upstream_error_message($err, $upstream_error_body), 'upstream_error');
        undef $drain;
        return;
      }
    }

    # The stream is open, so the status is already sent. Mojo::UserAgent reports an upstream
    # that hangs up mid-body as no error at all once the status line has arrived, so the body's
    # own framing (the chunked terminator, Content-Length) is the witness for that case; a
    # close-delimited body cannot be told apart from a complete one. A cut stream failed on
    # every face: the usage event and request.finish must not mean something different
    # depending on the client's dialect (ADR 0004).
    my $cut = 0;
    if ($headers_sent && !$had_error) {
      my $content = $tx_done->res->content;
      my $framed = $content->is_chunked || length($content->headers->content_length // '');
      $cut = $framed && !$content->is_finished;
      $had_error = 1 if $cut;
    }

    # A translator that can say so in-band ends a failed stream with its error event instead of
    # a closing sequence that would read as a complete answer.
    if ($stream_errors && $headers_sent) {
      if ($had_error) {
        my $reason = $cut ? 'Premature connection close' : ($tx_done->error->{message} // 'unknown');
        my $frame = $stream->error_event(500, "Upstream error: $reason");
        if (length $frame) {
          push @queue, $frame;
          $drain->() unless $draining;
        }
      }
    }

    # Finalize a translated stream before closing admission or recording its Usage event: a
    # translator can discover a terminal error only when it sees that no more upstream frames
    # are coming. Its tail is queued like any other chunk so it still lands after deltas already
    # in flight. Keep an unexpected finalizer exception inside the callback boundary and use the
    # translator's existing in-band error shape without reflecting internal details.
    if ($stream && $headers_sent) {
      my $tail = '';
      my $finalized = eval {
        $tail = $stream->finish;
        1;
      };
      unless ($finalized) {
        $had_error = 1;
        $tail = eval { $stream_errors
          ? $stream->error_event(500, 'Stream translation failed')
          : '' };
      }
      $tail = '' unless defined $tail;
      if (length $tail) {
        push @queue, $tail;
        $drain->() unless $draining;
      }
    }

    # An upstream that reported its failure inside the stream, or a translator that could only
    # detect one while finalizing, was answered with an error event; the request still failed.
    $had_error = 1 if $stream && $stream->can('errored') && $stream->errored;

    my $duration_ms = _duration_ms($started);
    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => ($had_error || $status >= 500) ? 0 : 1,
      duration_ms => $duration_ms,
    });

    # Priced from whatever usage the stream carried, also when it was cut: a cut stream still
    # spent what its frames reported, and one that reported nothing records zero (ADR 0004).
    _record_usage_event($c, {
      %$meta,
      node_id      => $node_id,
      status_code  => $status,
      ok           => ($had_error || $status >= 500) ? 0 : 1,
      duration_ms  => $duration_ms,
      content_bytes => $content_bytes->(),
      metrics      => _stream_metrics($c, $meta, $body, $duration_ms, $upstream_usage),
    });

    # Only finish once the queue has drained, or the tail of the stream is cut off. If the
    # drain loop is still running it will finish for us when it empties.
    $upstream_done = 1;
    if (!$draining && !$finished) {
      $finished = 1;
      $c->finish;
      undef $drain;
    }
  });
  });
}

# Renders an error in the shape of the face the client called. The Anthropic Messages face
# gets Anthropic's envelope, {type: "error", error: {type, message}}, with the type taken from
# the HTTP status, because that is what an Anthropic SDK parses and raises on (core karr #224).
# The Ollama face gets Ollama's {error: "<message>"}, a plain string, because that is what the
# Ollama clients decode (skeid #47). Every other face keeps the OpenAI shape it always had, with
# $openai_type as its type. The face is read off the stash, which the /v1/messages and /api/*
# routes set; a controller without one (a unit test's stand-in) is an OpenAI face.
sub _render_error {
  my ($c, $status, $message, $openai_type) = @_;
  my $format = $c->can('stash') ? ($c->stash('skeid.error_format') // '') : '';
  if ($format eq 'anthropic') {
    $c->render(json => Langertha::Skeid::Protocol::Anthropic->error_body($status, $message),
      status => $status);
    return;
  }
  if ($format eq 'ollama') {
    $c->render(json => Langertha::Skeid::Protocol::Ollama->error_body($message), status => $status);
    return;
  }
  $c->render(json => { error => { message => $message, type => $openai_type } }, status => $status);
  return;
}

# The message to put after "Upstream error: ". Mojo sets $err->{message} to the HTTP reason
# phrase for a 4xx/5xx ("Bad Request"); the upstream usually said more in its own body, in the
# OpenAI dialect every node speaks (ADR 0001), and that is what the client needs to act on.
sub _upstream_error_message {
  my ($err, $body) = @_;
  my $json = (defined($body) && length($body)) ? eval { decode_json($body) } : undef;
  if (ref($json) eq 'HASH') {
    my $e = $json->{error};
    my $msg = ref($e) eq 'HASH' ? $e->{message} : $e;
    return "$msg" if defined($msg) && !ref($msg) && length($msg);
  }
  return $err->{message} // 'unknown';
}

sub _render_upstream_response {
  my ($c, $res, $node_id) = @_;

  $c->res->code($res->code);
  for my $name (@{$res->headers->names}) {
    my $lc = lc($name);
    next if $lc eq 'content-length' || $lc eq 'transfer-encoding' || $lc eq 'content-encoding';
    $c->res->headers->header($name => $res->headers->header($name));
  }
  $c->res->headers->header('x-skeid-node' => $node_id);
  $c->res->headers->header('x-request-id' => _request_id($c));
  $c->res->body($res->body);
  $c->rendered;
}

# Hop-by-hop headers describe the client's connection to Skeid, not the request. Forwarding
# them upstream is wrong per RFC 7230 and expensive here in particular: a client that sends
# `Connection: close` -- most benchmark tools and plenty of HTTP libraries do -- made Skeid
# tear down its own upstream connection after every single request, so the connection pool
# never held anything and each request paid for a fresh TCP handshake.
my %HOP_BY_HOP = map { $_ => 1 } qw(
  connection
  keep-alive
  proxy-authenticate
  proxy-authorization
  te
  trailer
  transfer-encoding
  upgrade
);

sub _forward_headers {
  my ($c) = @_;
  my %fwd_headers;
  for my $name (@{$c->req->headers->names}) {
    my $lc = lc($name);
    next if $HOP_BY_HOP{$lc};
    next if $lc eq 'host' || $lc eq 'content-length' || $lc eq 'accept-encoding';
    $fwd_headers{$name} = $c->req->headers->header($name);
  }
  return %fwd_headers;
}

# Sets the upstream Authorization header for the selected node, from the KeyBroker
# (api_key_ref) or from the environment (api_key_env), overriding whatever the client sent.
# The callback runs exactly once, and always. It is called with nothing when the request may go
# upstream: the node's key is in place, or the node names no key source and forwards the
# client's header untouched. It is called with a reason when the node names a key source and
# none produced a key, or when the node is no longer in the inventory and what it named cannot
# be known -- the caller must then refuse the request (_refuse_unkeyed_node) rather than call
# the node, because the only credential left in the headers is the customer's own, and the
# pass-through would hand it to the provider (ADR 0003). The reason names the node, the key
# reference and the variable, never a key, and is for the log and the usage event.
#
# Wherever the client's header is not what goes upstream -- a key was injected, or the request
# is refused -- the client's credentials are taken out of the headers first, in any spelling.
#
# Async because resolution can mean a vault round-trip, and this sits between routing and the
# upstream call -- doing it synchronously stalls every other in-flight request for that
# round-trip (ADR 0005). key_async answers from cache without touching the loop, so the
# blocking case is a cold cache, and even then only one request per reference pays for it.
sub _inject_node_auth_async {
  my ($headers_ref, $skeid, $node_id, $cb) = @_;
  $cb ||= sub { };

  my ($node) = grep { ($_->{id} // '') eq $node_id } @{$skeid->nodes};
  unless ($node) {
    _drop_client_credentials($headers_ref);
    return $cb->("node '$node_id' is no longer in the inventory, its key source is unknown");
  }

  my $ref = $node->{api_key_ref};
  $ref = undef unless defined($ref) && length($ref);
  my $env_name = $node->{api_key_env};
  $env_name = undef unless defined($env_name) && length($env_name);

  my $apply = sub {
    my ($key, $ref_failure) = @_;

    # Fallback: env var
    if (!defined($key) || !length($key)) {
      if (defined $env_name) {
        $key = $ENV{$env_name} // '';
      }
    }

    if (defined($key) && length($key)) {
      _drop_client_credentials($headers_ref);
      $headers_ref->{Authorization} = "Bearer $key";
      return $cb->();
    }

    # A node with no key of its own: the documented pass-through.
    return $cb->() unless defined($ref) || defined($env_name);

    # A key source was named and produced nothing. Take the client's credentials out of what
    # would go upstream as well, so a caller that ignored the reason still could not leak them.
    _drop_client_credentials($headers_ref);
    $cb->(join('; ',
      (defined($ref) ? "api_key_ref '$ref' $ref_failure" : ()),
      (defined($env_name)
        ? "api_key_env '$env_name' is " . (defined($ENV{$env_name}) ? 'empty' : 'not set')
        : ()),
    ));
  };

  if (defined($ref) && $skeid->has_key_broker) {
    $skeid->key_broker->key_async($ref, sub {
      my ($key, $error) = @_;
      # The reference may be logged; what it resolves to may not, and neither may a vault
      # response body that might carry it (ADR 0003).
      warn "KeyBroker resolve failed for '$ref': $error"
        if defined($error) && !defined($key);
      $apply->($key, 'did not resolve');
    });
    return;
  }

  $apply->(undef, 'has no key broker to resolve it');
  return;
}

# Header names are case-insensitive and Mojolicious hands an unknown one on as the client
# spelled it, so `X-Api-Key` is as much the client's key as `x-api-key`. An exact-case delete
# lets it travel upstream beside the node's own key.
sub _drop_client_credentials {
  my ($headers_ref) = @_;
  delete @{$headers_ref}{
    grep { lc($_) eq 'authorization' || lc($_) eq 'x-api-key' } keys %$headers_ref
  };
  return;
}

# The answer to a request whose node names a key source that produced no key: no upstream call,
# and everything an admitted request is owed -- its request.finish, one usage event, an error in
# the shape of the face that was called. 503, not 502: no upstream was asked, so nothing came
# back bad; this Skeid cannot serve the request until its broker or its environment is put
# right, and a client may retry. The client is told no more than that -- the reason carries a
# key reference, which belongs in the log and the usage event, not in a customer's answer.
sub _refuse_unkeyed_node {
  my ($c, $node_id, $started, $meta, $reason) = @_;
  my $duration_ms = _duration_ms($started);
  $c->app->log->error("No upstream key for node '$node_id', request refused: $reason");
  $c->skeid->call_function('request.finish', {
    id => $node_id,
    ok => 0,
    duration_ms => $duration_ms,
  });
  _record_usage_event($c, {
    %$meta,
    node_id       => $node_id,
    status_code   => 503,
    ok            => 0,
    duration_ms   => $duration_ms,
    error_type    => 'upstream_key_unavailable',
    error_message => $reason,
    metrics       => {},
  });
  _render_error($c, 503, 'The upstream key for this model is not available',
    'upstream_key_unavailable');
  return;
}

# The free capacity probe (ADR 0009): a commercial provider will not tell us its queue depth,
# but it puts its rate-limit state on every response we already have in hand. Reading it costs
# no extra request -- which is the whole reason this is worth doing on the request path at all.
#
# Pulls the handful of headers by name rather than walking all of them; this runs per response.
my @CAPACITY_HEADERS = Langertha::Skeid->capacity_header_names;

sub _observe_capacity {
  my ($c, $node_id, $res) = @_;
  return unless defined($node_id) && length($node_id);
  return unless $res;
  my $headers = $res->headers or return;

  my %found;
  for my $name (@CAPACITY_HEADERS) {
    my $value = $headers->header($name);
    $found{$name} = $value if defined $value;
  }
  my $status = $res->code // 0;
  return unless %found || $status == 429;

  $c->skeid->call_function('capacity.observe', {
    id      => $node_id,
    headers => \%found,
    status  => $status,
  });
  return;
}

sub _extract_request_api_key {
  my ($c) = @_;
  my $auth = $c->req->headers->authorization;
  my $x_api_key = $c->req->headers->header('x-api-key');
  my $raw = defined($auth) ? $auth : (defined($x_api_key) ? $x_api_key : '');
  my $api_key = $raw // '';
  $api_key =~ s/^Bearer\s+//i;
  return ($raw, $api_key);
}

# Who the caller is. Everything downstream hangs off this: the routing policy that decides
# which nodes they may reach, and the usage event they get billed for. So it may only be
# derived from something the caller had to prove -- the key they presented.
#
# x-skeid-key-id is honoured only when the deployment says it authenticates the caller before
# Skeid sees the request (routing.trust_key_id_header). Believing it unconditionally would let
# any client name itself into another customer's policy, and into another customer's bill.
sub _request_api_key_id {
  my ($c) = @_;

  if ($c->skeid->trust_key_id_header) {
    my $forced = $c->req->headers->header('x-skeid-key-id')
      // $c->req->headers->header('x-api-key-id');
    return $forced if defined($forced) && length($forced);
  }

  my (undef, $api_key) = _extract_request_api_key($c);
  return $c->skeid->key_id_for_key($api_key);
}

# The id taken when the request arrived; a client's own x-request-id is taken over, else one is
# made up. Before that hook ran (a bare controller) it is worked out from the request, and once
# the transaction is gone it must come from the stash.
sub _request_id {
  my ($c) = @_;
  my $kept = $c->stash('skeid.request_id');
  return $kept if defined($kept) && length($kept);
  my $rid = $c->req->headers->header('x-request-id');
  return $rid if defined($rid) && length($rid);
  return 'req_' . int(time * 1000) . '_' . int(rand(1_000_000));
}

sub _record_usage_event {
  my ($c, $args) = @_;
  $args ||= {};
  my $metrics = ref($args->{metrics}) eq 'HASH' ? $args->{metrics} : {};
  my $usage = ref($metrics->{usage}) eq 'HASH' ? $metrics->{usage} : {};
  my $safe_metrics = {
    %$metrics,
    usage => {
      input  => 0 + ($usage->{input} // $usage->{prompt_tokens} // 0),
      output => 0 + ($usage->{output} // $usage->{completion_tokens} // 0),
      total  => 0 + ($usage->{total} // 0),
      # This reshaping drops prompt_tokens_details, so the cache count has to be carried across
      # it explicitly or record_usage never sees it. Both paths carry it as a flat
      # metrics->{cached_tokens}, from metrics.normalize or the raw payload (k27, skeid #41).
      cached => (_cached_tokens($usage) || 0 + ($metrics->{cached_tokens} // 0)),
    },
  };

  my $request_id = _request_id($c);
  my $recorded = eval {
    $c->skeid->call_function('usage.record', {
      created_at    => Langertha::Skeid::Protocol::iso8601_now(),
      request_id    => $request_id,
      api_format    => ($args->{api_format} // ''),
      requested_model => ($args->{requested_model} // $args->{model} // ''),
      endpoint      => ($args->{endpoint} // ''),
      api_key_id    => ($args->{api_key_id} // 'anonymous'),
      provider      => ($args->{provider} // 'skeid'),
      engine        => ($args->{engine} // ''),
      model         => ($args->{model} // ''),
      node_id       => ($args->{node_id} // ''),
      route_url     => ($args->{route_url} // ''),
      status_code   => 0 + ($args->{status_code} // 0),
      ok            => ($args->{ok} ? 1 : 0),
      duration_ms   => 0 + ($args->{duration_ms} // 0),
      error_type    => ($args->{error_type} // ''),
      error_message => ($args->{error_message} // ''),
      # Streamed requests only; absent otherwise, so the event says "not measured" (skeid #36).
      (defined($args->{content_bytes}) ? (content_bytes => 0 + $args->{content_bytes}) : ()),
      metrics       => $safe_metrics,
    });
  };
  my $err;
  if ($@) {
    $err = "$@";
    $recorded = { ok => 0, error => $err };
  } elsif (ref($recorded) eq 'HASH' && !$recorded->{ok} && ($recorded->{enabled} // 1)) {
    # A store reports a failed write in its answer (the JsonLog contract); no sink at all
    # answers enabled => 0 and has nothing to lose.
    $err = $recorded->{error} // 'unknown error';
  }
  if (defined $err) {
    _log_lost_usage_event($c->app, $c->skeid, {
      request_id  => $request_id,
      api_key_id  => ($args->{api_key_id} // 'anonymous'),
      model       => $args->{model},
      status_code => $args->{status_code},
    }, $err);
  }

  return $recorded;
}

# The event is the billing unit (ADR 0004) and it is gone: say so at a level production keeps,
# with what an operator needs to reconcile it by hand. The request id and the key id, never the
# key -- the key id is a digest (ADR 0016), the key is a secret (ADR 0003). One line for both
# ways an event is lost: a write that failed while the request waited, and a queued one a
# write-behind flush could not write later (skeid k78).
sub _log_lost_usage_event {
  my ($app, $skeid, $event, $err) = @_;
  $err //= 'unknown error';
  $err =~ s/\s+$//;
  $app->log->error('usage event lost: request_id=' . ($event->{request_id} // '')
    . ' store=' . _usage_sink_name($skeid)
    . ' api_key_id=' . ($event->{api_key_id} // 'anonymous')
    . ' model=' . ($event->{model} // '')
    . ' status=' . ($event->{status_code} // 0)
    . ': ' . $err);
  return;
}

# Which sink a lost usage event was meant for, for the log line: the store's backend name, or
# how the embedding application took the event over. Never the DSN or path, which may carry
# credentials.
sub _usage_sink_name {
  my ($skeid) = @_;
  return 'store_usage_event' if $skeid->has_store_usage_event;
  my $cfg = $skeid->usage_store;
  return (ref($cfg) eq 'HASH' && length($cfg->{backend} // '')) ? $cfg->{backend} : 'custom';
}

# The prompt-cache read count off a raw OpenAI-shaped upstream usage hash (k27). OpenAI nests it
# under prompt_tokens_details.cached_tokens; some OpenAI-compatible servers expose a flat
# cached_tokens, an Anthropic-spelled block cache_read_input_tokens, and a caller of usage.record may pass it as `cached`. Missing -> 0, the
# same fault-tolerance the other token reads here have. This reads a count off a response Skeid
# already holds -- every upstream answers in the OpenAI dialect (ADR 0001) -- it does not
# translate a client format. Both paths prefer the count metrics.normalize reads through
# Langertha::Usage and prices (skeid #28, #41); this is the fallback on Langertha 0.503.
sub _cached_tokens {
  my ($usage) = @_;
  return 0 unless ref($usage) eq 'HASH';
  my $details = $usage->{prompt_tokens_details};
  return 0 + ($usage->{cached}
    // $usage->{cached_tokens}
    // (ref($details) eq 'HASH' ? $details->{cached_tokens} : undef)
    // $usage->{cache_read_input_tokens}
    // 0);
}

# Prices an upstream answer: its usage block goes through metrics.normalize (Langertha::Usage +
# Langertha::Pricing), the one pricing path for every face, streamed or not (skeid #28, #41).
# $payload is the decoded upstream body, or for a stream a body holding only the usage block
# the stream carried -- the same usage, so the same cost.
sub _priced_metrics {
  my ($c, $meta, $body, $duration_ms, $payload, $tool_calls) = @_;
  my $metrics = eval {
    $c->skeid->call_function('metrics.normalize', {
      provider    => ($meta->{provider} || 'skeid'),
      engine      => ($meta->{engine} || 'openaibase'),
      model       => ($meta->{model} || ($body->{model} // '')),
      route       => ($meta->{endpoint} || ''),
      duration_ms => $duration_ms,
      response    => $payload,
      tool_calls  => ($tool_calls || []),
    });
  };
  $metrics = {} unless ref($metrics) eq 'HASH';
  # metrics.normalize reports the prompt-cache counts off Langertha::Usage, from every wire
  # spelling it knows (skeid #28). Langertha 0.503's Usage has no such counts, so there they are
  # pulled straight off the raw upstream usage and carried flat, the way input/output survive
  # as metrics->{*_tokens} (k27).
  if (!defined $metrics->{cached_tokens}) {
    my $cached = _cached_tokens($payload->{usage});
    $metrics->{cached_tokens} = $cached if $cached;
  }
  if (!defined $metrics->{cache_write_tokens}) {
    my $written = _cache_write_tokens($payload->{usage});
    $metrics->{cache_write_tokens} = $written if $written;
  }
  return $metrics;
}

# A stream's metrics: its verbatim usage priced exactly as a non-streamed body carrying it would
# be. A stream that carried no usage has nothing to price -- no token count or cost is invented.
sub _stream_metrics {
  my ($c, $meta, $body, $duration_ms, $usage) = @_;
  return {} unless ref($usage) eq 'HASH';
  return _priced_metrics($c, $meta, $body, $duration_ms, { usage => $usage });
}

# Folds one stream frame's usage block into what the stream reported so far, key by key, a later
# frame's value replacing an earlier one (nested blocks such as prompt_tokens_details likewise).
# Usage counts on a stream are running totals, never increments: OpenAI's final frame carries
# the whole request, a server that reports on every chunk repeats the growing total, and a wire
# that splits the block (input on the first frame, output on the last) is completed rather
# than lost. Summing frames would bill the same tokens twice.
sub _merge_usage {
  my ($into, $frame) = @_;
  my %merged = ref($into) eq 'HASH' ? %$into : ();
  for my $key (keys %$frame) {
    my $value = $frame->{$key};
    next unless defined $value;
    $merged{$key} = (ref($value) eq 'HASH' && ref($merged{$key}) eq 'HASH')
      ? _merge_usage($merged{$key}, $value)
      : $value;
  }
  return \%merged;
}

# The prompt-cache write count off a raw upstream usage hash, for a Langertha that cannot read it
# itself (0.503): OpenAI Chat nests it under prompt_tokens_details.cache_write_tokens, an
# Anthropic-shaped block carries cache_creation_input_tokens. Missing -> 0. A count, never priced
# here -- pricing is Langertha::Pricing's (skeid #41).
sub _cache_write_tokens {
  my ($usage) = @_;
  return 0 unless ref($usage) eq 'HASH';
  my $details = $usage->{prompt_tokens_details};
  return 0 + ((ref($details) eq 'HASH' ? $details->{cache_write_tokens} : undef)
    // $usage->{cache_write_tokens}
    // $usage->{cache_creation_input_tokens}
    // 0);
}

# The model a tier asks its nodes for. Falls back to what the client requested, which is what
# makes an aliasless deployment behave exactly as it did before tiers existed.
sub _served_model {
  my ($tier, $requested) = @_;
  return $requested unless ref($tier) eq 'HASH';
  my $model = $tier->{model};
  return (defined($model) && length($model)) ? $model : $requested;
}

sub _endpoint_url_for_node {
  my ($base, $path) = @_;
  $base //= '';
  $path //= '';
  $base =~ s{/\z}{};

  return $base . $path if $base =~ m{/v1\z} && $path =~ m{^/};
  return $base . '/v1' . $path if $path =~ m{^/};
  return $base . '/v1/' . $path;
}

sub _duration_ms {
  my ($started) = @_;
  return int((time - $started) * 1000);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Proxy - Multi-format LLM proxy (OpenAI, Anthropic, Ollama) powered by Langertha::Skeid routing

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Langertha::Skeid::Proxy;
  use Mojo::Server::Daemon;

  my $app = Langertha::Skeid::Proxy->build_app(config_file => '/etc/skeid/skeid.yaml');
  Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1:8090'])->run;

  # or simply
  skeid serve --config /etc/skeid/skeid.yaml --listen 127.0.0.1:8090

=head1 DESCRIPTION

The Mojolicious application in front of L<Langertha::Skeid>. It speaks three client formats --
OpenAI, Anthropic and Ollama -- and makes one kind of upstream call, an OpenAI-shaped C<POST> to
the node routing picked (ADR 0001); the translation lives in L<Langertha::Skeid::Protocol> and
its per-format modules. Everything else -- nodes, routing, admission, pricing, usage -- is the
control plane's, driven through L<Langertha::Skeid/call_function>, and is configured there (see
L<Langertha::Skeid/CONFIGURATION>). C<skeid serve> runs it.

The request path is asynchronous throughout (ADR 0005): waiting for capacity is a timer, key
resolution goes through L<Langertha::Skeid::KeyBroker/key_async>, and the upstream call never
blocks the loop.

=head2 Client routes

No Skeid credential is needed on these; see L</Customer identity>.

  GET  /health                     {status: ok, proxy: skeid, config_reload: {...}}
  GET  /.well-known/langertha.json provider manifest for the presented key
  GET  /v1/models                  OpenAI: node models and alias names, once each
  POST /v1/chat/completions        OpenAI chat; a stream is relayed byte for byte
  POST /v1/embeddings              OpenAI embeddings
  POST /v1/messages                Anthropic Messages, streamed or not
  POST /api/chat                   Ollama chat; streams unless "stream": false
  POST /api/generate               Ollama generate; streams unless "stream": false
  GET  /api/tags                   Ollama: the same names as /v1/models
  GET  /api/ps                     Ollama: always an empty list

C</health> stays C<ok> while a config reload is failing -- the proxy serves under the config it
kept -- and shows the reload state without its message. C</v1/models> and C</api/tags> list the
node models and the alias names, each once, so a client can discover what it may put in
C<model>. The list follows the policy of the key presented (no key: the default policy): a name
the key's C<models> do not grant, an alias with every tier denied and a model only denied nodes
serve are left out. Unhealthy nodes are included. A node without a C<model> is not listed -- it matches any
requested name, so no name reaches it in particular. The manifest route answers C<404> unless
the config enables it, C<401> without a key and C<403> for a key without a grant; see
L<Langertha::Skeid/Provider Manifest>.

=head2 Registry route

  GET  /skeid/registry/snapshot    signed capacity snapshot, for a fronting Skeid

Bearer token: the admin API key or the registry read key (C<registry.read_key_env>), and nothing
else accepts the read key. C<404> when neither is configured or the registry is not enabled,
C<401> for a wrong token, C<503> while the signing secret is missing. The body is signed in C<X-Skeid-Registry-Signature> and sent
C<Cache-Control: no-store>. See L<Langertha::Skeid/registry_enabled> and ADR 0017.

=head2 Admin routes

Bearer token: the admin API key (L<Langertha::Skeid/admin>). Without one configured every
C</skeid/*> route answers C<404>; a missing or wrong token answers C<401>.

  GET  /skeid/nodes                {nodes}
  POST /skeid/nodes                body: a node, as a config nodes entry -> {ok, nodes}, or 400
  POST /skeid/nodes/:id/health     body: {"healthy": true|false} -> {ok}
  GET  /skeid/config               {reload}: the config reload status, with its message
  GET  /skeid/metrics/nodes        {metrics}: per-node counters, never billed
  GET  /skeid/usage                ?since=&api_key_id=&model=&limit= (default 50) -> the report

Changes made here live in this process only: a changed C<nodes> section in the config replaces
them, and under C<--workers> each write reaches one worker (ADR 0010).

=head2 Customer identity

Skeid does not authenticate customers. The key a client presents (C<Authorization: Bearer>, else
C<x-api-key>) derives the customer key id (L<Langertha::Skeid/key_id_for_key>; no key is
C<anonymous>), which selects the routing policy and is recorded on the usage event. With
C<routing.trust_key_id_header> a C<x-skeid-key-id> (or C<x-api-key-id>) header names the key id
instead.

=head2 The upstream call

The node URL gets C</v1> added unless it ends in it, then C</chat/completions> or
C</embeddings>; the body carries the served model (an alias tier's C<model>), everything else as
the client sent it or as translated. The client's headers go upstream except the hop-by-hop
ones, C<Host>, C<Content-Length> and C<Accept-Encoding>. When the node has a key of its own --
C<api_key_ref> through the key broker, else C<api_key_env> -- it replaces C<Authorization> and
the client's C<Authorization> and C<x-api-key> are dropped, however the client spelled them. A
node that names neither forwards the client's own key. A node that names one and gets no key
from it -- the broker fails or is not running, the variable is unset or empty -- is not called
at all, and neither is one that left the inventory after it was selected: the request is
refused with C<503> (see L</Errors>), so the client's key never stands in for the node's. An answer that came from a node carries
C<x-skeid-node> with the node id. Rate-limit headers and C<429>s on every response feed
L<Langertha::Skeid/observe_response_headers>.

Each admitted request gets its C<request.finish> on every path and one usage event, failures
included.

=head2 A client that hangs up

A client that closes its connection before the answer is complete ends its request at that
moment. While it waits for capacity it stops waiting and takes no slot. Once a node was called,
the upstream connection is closed -- which is how the node learns to stop generating -- and is
not returned to the pool; the slot is given back with a C<request.finish> marked C<aborted> -- counted apart, not as a node
error, so the node's error counter and the registry snapshot's C<errors_in_window> stay untouched --
and the one usage event is written with C<ok = 0>, C<status_code> 499 and C<error_type>
C<client_abort>, priced from the usage the stream had reported until then (nothing, for a
request that was not streamed). A client that leaves while the node's key is still being
resolved gives its slot back too, but nothing was forwarded, so no usage event is written.
When the node had already finished and only the rest of the answer was still being written
out, the request stays what it was: finished and metered by the node's answer.

=head2 Errors

A request no node may serve for this key is C<403 permission_error>; a model no healthy node
serves is C<503 model_not_found>; eligible nodes that stay full past the wait are
C<429 rate_limit_error>; an upstream failure is its status (or C<502>) with type
C<upstream_error>; a node whose own key cannot be resolved is
C<503 upstream_key_unavailable>, logged with the key reference and recorded as a failed usage
event. The body is shaped for the face that was called: OpenAI's
C<{error: {message, type}}>, Anthropic's envelope
(L<Langertha::Skeid::Protocol::Anthropic/error_body>) on C</v1/messages>, and Ollama's
C<{error: "..."}> on C</api/*>. A stream that fails after it opened ends with the face's in-band
error event where it has one.

=head1 METHODS

=head2 build_app

  my $app = Langertha::Skeid::Proxy->build_app(%options);

Builds the L<Mojolicious> application. Options:

=over 4

=item * C<config_file> -- the config to build a L<Langertha::Skeid> from.

=item * C<skeid> -- an existing L<Langertha::Skeid> to serve instead; C<config_file> and the
OpenBao detection below are then not used.

=item * C<admin_api_key> -- the explicit admin API key (L<Langertha::Skeid/set_admin_api_key>):
it wins over the config's, on every reload. Empty leaves the key to the config and
C<SKEID_ADMIN_API_KEY>.

=item * C<worker_count> -- how many prefork workers share the nodes (L<Langertha::Skeid/worker_count>),
set before any admission or probe timer reads it.

=back

The Skeid's L<Langertha::Skeid/on_usage_lost> is set to this app's C<usage event lost> log line,
so a usage event a write-behind store could not write is logged like one whose synchronous write
failed. An embedding application that wants its own hook sets it after C<build_app>.

With both C<OPENBAO_ROLE_ID> and C<OPENBAO_SECRET_ID> set, a
L<Langertha::Skeid::KeyBroker::OpenBao> at C<OPENBAO_ADDR> (default C<http://127.0.0.1:8200>)
becomes the key broker; if its login fails the proxy warns and runs without one. A broker that
can renew its token starts renewing on a timer. The capacity probes of every node are started
and restarted whenever the probed part of the inventory changes.

Upstream connections time out after 10s to connect, and at most C<SKEID_UPSTREAM_POOL>
(default 100) are kept. An upstream request may take C<SKEID_UPSTREAM_TIMEOUT> seconds (default
300; a positive integer, anything else counts as unset) and may be silent for all of them --
the time to the first token is silence on the wire. The client's connection is given the same
time on top of the server's own inactivity timeout, on the routes that call an upstream and for
that request only: the proxy never closes a request its upstream is still working on, and is
still there to answer when the upstream timed out. Every other route stays under the server's
timeout. The client's side is read from the user agent when a request arrives, so whoever
changes C<< $app->ua->request_timeout >> afterwards changes both sides, and should set
C<< $app->ua->inactivity_timeout >> to match.

The app has a C<skeid> helper returning the control plane.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid> -- the control plane and its configuration

=item * L<skeid> -- the command that runs this app

=item * L<Langertha::Skeid::Protocol::Anthropic>, L<Langertha::Skeid::Protocol::Ollama> -- the
translated faces

=item * L<Langertha::Skeid::KeyBroker::OpenBao> -- upstream keys from OpenBao

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
