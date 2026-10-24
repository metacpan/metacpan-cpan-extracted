package Langertha::Skeid::Proxy;
our $VERSION = '0.004';
# ABSTRACT: Multi-format LLM proxy (OpenAI, Anthropic, Ollama) powered by Langertha::Skeid routing
use strict;
use warnings;
use Carp qw(croak);
use Mojolicious;
use Mojo::IOLoop;
use Time::HiRes qw(time);
use JSON::MaybeXS qw(decode_json);
use Scalar::Util qw(blessed weaken);
use Mojo::Util qw(decode encode);
use Langertha::Skeid;
use Langertha::Skeid::CapacityProbe;
use Langertha::Skeid::OpenAPI;
use Langertha::Skeid::Registry;
use Langertha::Skeid::SwaggerUI;
use Langertha::Skeid::Secret;
use Langertha::Skeid::Proxy::Realtime;
use Langertha::Skeid::Proxy::RelayContent;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Anthropic;
use Langertha::Skeid::Protocol::Anthropic::Stream;
use Langertha::Skeid::Protocol::Audio;
use Langertha::Skeid::Protocol::Documents;
use Langertha::Skeid::Protocol::MCP;
use Langertha::Skeid::Protocol::Ollama;
use Langertha::Skeid::Protocol::Ollama::Stream;
use Langertha::Skeid::Protocol::RawBody;
use Langertha::Skeid::Protocol::Realtime;
use Langertha::Skeid::Protocol::Rerank;
use Langertha::ToolCall;


# What the request limit of an upload route allows on top of uploads.max_bytes (skeid k91): the
# request's head, which the server counts into its message size and caps well below this itself
# (100 lines of 8 KiB). The body alone is checked exactly when the route runs.
my $UPLOAD_HEAD_ALLOWANCE = 1048576;

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

  # The customer source's fetcher (ADR 0026): on the loop, never on the request path. Its
  # connections open with the first fetch, in the process that runs the loop.
  $skeid->start_customer_source;

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
  # The open realtime sessions of this app (skeid k95, ADR 0029): what a graceful stop closes.
  my $realtime = Langertha::Skeid::Proxy::Realtime->new(skeid => $skeid, log => $app->log);
  $app->helper(realtime => sub { $realtime });

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

  # The upload routes get their own request limit (uploads.max_bytes, skeid k91), set the moment
  # the request's head is parsed and before any of its body is: see _limit_upload. The
  # transaction is held weakly -- the listener sits on its own request content, and a connection
  # that closes before the head is complete would otherwise keep both alive.
  $app->hook(after_build_tx => sub {
    my ($tx, $app) = @_;
    weaken $tx;
    $tx->req->content->once(body => sub { _limit_upload($app, $tx) if $tx });
  });

  # Swagger UI assets: fetched on the first request for the UI, only when the config switches
  # it on (skeid k105, ADR 0025). Nothing is fetched at build. The object is injectable (the
  # swagger_ui option of build_app) so a test never reaches the network.
  my $swagger_ui = $opts{swagger_ui} || Langertha::Skeid::SwaggerUI->new;
  $app->helper(swagger_ui => sub { $swagger_ui });

  # Every route is registered from route_table, and the OpenAPI documents are built from the
  # same entries: a route without an entry cannot exist, which t/78-route-table.t proves by
  # walking the router. A group names the bridge the entry sits behind. Bridges are made when
  # the first entry of their group comes, so the order of the table is the order of matching.
  #
  # Client routes sit behind _authorize_client (skeid k90): a bridge, so only these routes are
  # gated and an unknown path stays a 404. Each face's bridge sets what its 401 needs before the
  # gate can render it -- the error dialect, the manifest's cache headers.
  my $r = $app->routes;
  my %make_bridge = (
    root     => sub { $r },
    manifest => sub {
      $r->under(sub {
        my ($c) = @_;
        _manifest_cache_headers($c);
        return _authorize_client($c);
      });
    },
    openai => sub {
      $r->under(sub { _authorize_client($_[0]) });
    },
    # Every error this request produces, wherever it is rendered -- the gate's 401 included --
    # has to be Anthropic-shaped (core karr #224). _render_error reads this.
    anthropic => sub {
      $r->under(sub {
        my ($c) = @_;
        $c->stash('skeid.error_format' => 'anthropic');
        return _authorize_client($c);
      });
    },
    # Every error on these routes has to be Ollama-shaped, {"error": "<string>"}: an Ollama
    # client decodes the error as a string and fails on the OpenAI object (skeid #47).
    ollama => sub {
      $r->under(sub {
        my ($c) = @_;
        $c->stash('skeid.error_format' => 'ollama');
        return _authorize_client($c);
      });
    },
    # The MCP bridge answers as an unknown path while the config has no mcp: section, before
    # the client gate can turn that 404 into a 401.
    mcp => sub {
      $r->under(sub { _authorize_mcp_client($_[0]) });
    },
    admin => sub {
      $r->under(sub { _authorize_admin($_[0]) });
    },
  );
  my %bridge;
  for my $entry ($class->route_table) {
    my $make = $make_bridge{$entry->{group}}
      or croak "route table: unknown group '$entry->{group}' of $entry->{id}";
    my $parent = $bridge{$entry->{group}} //= $make->();
    # A WebSocket route matches only an upgrade request (ADR 0029); everything else is as for
    # any route: behind its group's bridge, so the client gate answers before an upgrade.
    if ($entry->{websocket}) { $parent->websocket($_ => $entry->{handler}) for @{$entry->{paths}} }
    else { $parent->any($entry->{methods} => $_ => $entry->{handler}) for @{$entry->{paths}} }
  }

  return $app;
}


my @ROUTE_TABLE;

sub route_table {
  my ($class) = @_;
  @ROUTE_TABLE = $class->_build_route_table unless @ROUTE_TABLE;
  return @ROUTE_TABLE;
}

sub _build_route_table {
  my ($class) = @_;
  my @t;
  my $add = sub { push @t, { methods => ['GET'], document => 'client', @_ } };

  # Still 'ok' while a config reload is failing: the proxy serves under the config it kept, so
  # it is not unhealthy, and a probe that restarted it would lose that config. The reload
  # state is shown without its message, which can name customers; that is on /skeid/config.
  $add->(id => 'health', group => 'root', paths => ['/health'], tag => 'Service', public => 1,
    summary => 'Liveness and config reload state',
    handler => sub {
      my ($c) = @_;
      my $reload = $c->skeid->reload_status;
      delete $reload->{error};
      # The customer source likewise: whether it fetches, never why not (ADR 0026).
      my $source = $c->skeid->customer_source_status;
      $source &&= {
        ok => $source->{ok},
        ($source->{failures} ? (failed_at => $source->{failed_at}, failures => $source->{failures}) : ()),
      };
      $c->render(json => { status => 'ok', proxy => 'skeid', config_reload => $reload,
        ($source ? (customer_source => $source) : ()) });
    });

  # Provider manifest (skeid #29, ADR 0015): per customer key, never the whole catalog.
  $add->(id => 'manifest', group => 'manifest', paths => ['/.well-known/langertha.json'],
    tag => 'Manifest', requires => 'manifest',
    summary => 'Provider manifest for the presented key',
    handler => sub { _handle_manifest($_[0]) });

  # OpenAI format
  $add->(id => 'models', group => 'openai', paths => ['/v1/models'], tag => 'OpenAI',
    summary => 'List the models this key may use', response => 'ModelList',
    handler => sub {
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

  $add->(id => 'chat_completions', group => 'openai', methods => ['POST'],
    paths => ['/v1/chat/completions'], tag => 'OpenAI', request => 'ChatCompletionRequest',
    stream => 1, summary => 'Chat completion',
    handler => sub { _handle_openai_chat($_[0]) });

  $add->(id => 'embeddings', group => 'openai', methods => ['POST'], paths => ['/v1/embeddings'],
    tag => 'OpenAI', request => 'EmbeddingsRequest', summary => 'Embeddings',
    handler => sub { _handle_openai_embeddings($_[0]) });

  # Audio (skeid k91): relayed in the upstream's own shape, not translated (ADR 0021).
  for my $endpoint (Langertha::Skeid::Protocol::Audio->routes) {
    (my $id = $endpoint) =~ s{[^A-Za-z0-9]+}{_}g;
    $add->(id => 'audio' . $id, group => 'openai', methods => ['POST'], paths => [$endpoint],
      tag => 'OpenAI', request => 'AudioRequest', request_type => 'multipart', stream => 1,
      summary => 'Audio ' . ($endpoint =~ /translations/ ? 'translation' : 'transcription'),
      description => 'Relayed to the node as the multipart form was sent; the answer is the node\'s own.',
      handler => sub { _handle_openai_audio($_[0], $endpoint) });
  }

  # Rerank (skeid k92): /v1/rerank and its alias /rerank, one route. Relayed like audio, except
  # to a node whose rerank_format names another upstream dialect.
  for my $endpoint (Langertha::Skeid::Protocol::Rerank->routes) {
    (my $id = $endpoint) =~ s{[^A-Za-z0-9]+}{_}g;
    $add->(id => 'rerank' . $id, group => 'openai', methods => ['POST'], paths => [$endpoint],
      tag => 'OpenAI', request => 'RerankRequest', summary => 'Rerank documents',
      handler => sub { _handle_openai_rerank($_[0]) });
  }

  # Documents (skeid k94, ADR 0028): docling-serve's synchronous conversion, under its own paths.
  # Relayed like audio; planned over the nodes of kind `documents`, not by a model name.
  for my $endpoint (Langertha::Skeid::Protocol::Documents->routes) {
    my $file = $endpoint =~ /file\z/;
    (my $id = $endpoint) =~ s{[^A-Za-z0-9]+}{_}g;
    $add->(id => 'documents' . $id, group => 'openai', methods => ['POST'], paths => [$endpoint],
      tag => 'Documents', summary => 'Convert ' . ($file ? 'uploaded files' : 'sources') . ' to a document',
      request => ($file ? 'DocumentsFileRequest' : 'DocumentsSourceRequest'),
      ($file ? (request_type => 'multipart') : ()),
      description => 'docling-serve\'s own call, relayed to a node of kind documents; the answer '
        . '(JSON, or a zip) is the node\'s. Authorised under the model name documents.',
      handler => sub { _handle_documents($_[0], $endpoint) });
  }

  # Realtime transcription (skeid k95, ADR 0029): a WebSocket, relayed as a session. Not a
  # request/answer route, so it has its own handler and not a $relay of the proxy functions.
  $add->(id => 'realtime', group => 'openai', paths => [Langertha::Skeid::Protocol::Realtime->route],
    tag => 'OpenAI', websocket => 1,
    query => [
      { name => 'model', required => 1, description => 'The model of the session; the key\'s policy applies to it.' },
      { name => 'intent', description => 'Passed to the node, as sent (transcription).' },
    ],
    summary => 'Realtime transcription (WebSocket)',
    description => 'Upgrades to a WebSocket relayed to the node\'s realtime endpoint; the events of '
      . 'both directions are the node\'s own, nothing is translated. A key can also be sent in the '
      . '"openai-insecure-api-key.<key>" subprotocol, beside "realtime". One session holds one slot '
      . 'of its node until it closes, and is recorded as one usage event.',
    handler => sub { _handle_openai_realtime($_[0]) });

  # The description of the client routes themselves. Behind the client gate like /v1/models:
  # the examples carry model names, and those are per key.
  $add->(id => 'openapi', group => 'openai', paths => ['/openapi.json'], tag => 'Service',
    summary => 'This OpenAPI 3.1 document',
    handler => sub { _handle_openapi($_[0], 'client') });

  # Anthropic format.
  $add->(id => 'messages', group => 'anthropic', methods => ['POST'], paths => ['/v1/messages'],
    tag => 'Anthropic', request => 'AnthropicMessagesRequest', stream => 1,
    summary => 'Anthropic Messages',
    handler => sub { _handle_anthropic_messages($_[0]) });

  # Ollama format.
  $add->(id => 'ollama_chat', group => 'ollama', methods => ['POST'], paths => ['/api/chat'],
    tag => 'Ollama', request => 'OllamaChatRequest', stream => 1, summary => 'Ollama chat',
    handler => sub { _handle_ollama($_[0], 'chat') });

  $add->(id => 'ollama_generate', group => 'ollama', methods => ['POST'], paths => ['/api/generate'],
    tag => 'Ollama', request => 'OllamaGenerateRequest', stream => 1, summary => 'Ollama generate',
    handler => sub { _handle_ollama($_[0], 'generate') });

  $add->(id => 'ollama_tags', group => 'ollama', paths => ['/api/tags'], tag => 'Ollama',
    summary => 'The models this key may use, Ollama shaped',
    handler => sub {
      my ($c) = @_;
      $c->render(json => Langertha::Skeid::Protocol::Ollama->tags_from_models(
        $c->skeid->list_models(api_key_id => _request_api_key_id($c))));
    });

  $add->(id => 'ollama_ps', group => 'ollama', paths => ['/api/ps'], tag => 'Ollama',
    summary => 'Always an empty list',
    handler => sub { $_[0]->render(json => { models => [] }) });

  # MCP gateway (skeid k103, ADR 0022): the MCP servers assigned to the presented key, listed
  # and relayed. The relaxed placeholder takes a name with a dot in it; what follows the name
  # is the sub-path, for an upstream with more than one endpoint.
  $add->(id => 'mcp_servers', group => 'mcp', paths => [Langertha::Skeid::Protocol::MCP->listing_path],
    tag => 'MCP', requires => 'mcp', summary => 'The MCP servers assigned to this key',
    handler => sub { _handle_mcp_servers($_[0]) });

  $add->(id => 'mcp_relay', group => 'mcp', methods => [qw( GET POST DELETE )],
    paths => ['/mcp/#mcp_server', '/mcp/#mcp_server/*mcp_path'], tag => 'MCP', requires => 'mcp',
    summary => 'Relay MCP Streamable HTTP to an assigned MCP server', stream => 1,
    handler => sub { _handle_mcp($_[0]) });

  # Skeid-to-Skeid registry (skeid #18, ADR 0017). Registered before the /skeid admin block so
  # it is not behind _authorize_admin: it also takes the registry read key (skeid #49), which
  # that block must never accept.
  $add->(id => 'registry_snapshot', group => 'root', paths => ['/skeid/registry/snapshot'],
    document => 'admin', requires => 'registry', tag => 'Registry',
    summary => 'Signed capacity snapshot, for a fronting Skeid',
    description => 'Takes the admin key or the registry read key. The body is signed in '
      . 'X-Skeid-Registry-Signature.',
    handler => sub { _handle_registry_snapshot($_[0]) });

  # Lightweight admin API for live control-plane updates.
  $add->(id => 'admin_nodes', group => 'admin', paths => ['/skeid/nodes'], document => 'admin',
    tag => 'Admin', summary => 'List nodes', response => 'NodeList',
    handler => sub {
      my ($c) = @_;
      $c->render(json => { nodes => $c->skeid->list_nodes });
    });

  $add->(id => 'admin_nodes_add', group => 'admin', methods => ['POST'], paths => ['/skeid/nodes'],
    document => 'admin', tag => 'Admin', summary => 'Add or replace a node',
    handler => sub {
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

  $add->(id => 'admin_node_health', group => 'admin', methods => ['POST'],
    paths => ['/skeid/nodes/:id/health'], document => 'admin', tag => 'Admin',
    summary => 'Set a node healthy or unhealthy',
    handler => sub {
      my ($c) = @_;
      my $body = $c->req->json || {};
      my $id = $c->param('id');
      my $ok = $c->skeid->call_function('nodes.set_health', {
        id      => $id,
        healthy => ($body->{healthy} ? 1 : 0),
      })->{ok};
      $c->render(json => { ok => $ok ? 1 : 0 });
    });

  $add->(id => 'admin_config', group => 'admin', paths => ['/skeid/config'], document => 'admin',
    tag => 'Admin', summary => 'Config reload status',
    handler => sub {
      my ($c) = @_;
      my $reload = $c->skeid->call_function('config.status', {});
      my $source = $c->skeid->customer_source_status;
      $c->render(json => {
        reload => $reload,
        ($source ? (
          customer_source => $source,
          customer_names  => $c->skeid->customer_names,
          customer_report => $c->skeid->customer_report,
        ) : ()),
      });
    });

  $add->(id => 'admin_metrics_nodes', group => 'admin', paths => ['/skeid/metrics/nodes'],
    document => 'admin', tag => 'Admin', summary => 'Per-node counters',
    handler => sub {
      my ($c) = @_;
      $c->render(json => { metrics => $c->skeid->node_metrics });
    });

  $add->(id => 'admin_usage', group => 'admin', paths => ['/skeid/usage'], document => 'admin',
    tag => 'Admin', summary => 'Usage report',
    handler => sub {
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

  $add->(id => 'admin_openapi', group => 'admin', paths => ['/skeid/openapi.json'],
    document => 'admin', tag => 'Admin', summary => 'The OpenAPI 3.1 document of the admin routes',
    handler => sub { _handle_openapi($_[0], 'admin') });

  # The Swagger UI (skeid k105): off unless openapi.swagger_ui, an unknown path then. No
  # document lists it; it carries no data, so it is outside the client gate -- the browser
  # that loads it has no key yet. The description it shows is behind the gate.
  $add->(id => 'docs', group => 'root', paths => ['/docs'], document => undef,
    handler => sub { _handle_docs($_[0]) });
  $add->(id => 'docs_file', group => 'root', paths => ['/docs/#file'], document => undef,
    handler => sub { _handle_docs($_[0]) });

  return @t;
}

# Whether the config has the section an entry's route needs.
sub _route_enabled {
  my ($skeid, $entry) = @_;
  my $need = $entry->{requires};
  return 1 unless defined $need;
  return $skeid->manifest_enabled && $skeid->manifest_available ? 1 : 0 if $need eq 'manifest';
  return $skeid->mcp_enabled ? 1 : 0 if $need eq 'mcp';
  return $skeid->registry_enabled ? 1 : 0 if $need eq 'registry';
  return 0;
}

# GET /openapi.json and GET /skeid/openapi.json: the document of the routes the config enables
# (ADR 0025). The model names in the examples are the ones /v1/models lists for this caller.
sub _handle_openapi {
  my ($c, $kind) = @_;
  my $skeid = $c->skeid;
  my @entries = grep { ($_->{document} // '') eq $kind && _route_enabled($skeid, $_) }
    Langertha::Skeid::Proxy->route_table;
  my @models = $kind eq 'client'
    ? map { $_->{model} } @{$skeid->list_models(api_key_id => _request_api_key_id($c))}
    : ();
  _manifest_cache_headers($c) if $kind eq 'client';
  $c->res->headers->header('Cache-Control' => 'no-store') if $kind eq 'admin';
  $c->render(json => Langertha::Skeid::OpenAPI->document(
    kind        => $kind,
    entries     => \@entries,
    models      => \@models,
    client_auth => $skeid->client_auth_enabled,
    version     => $Langertha::Skeid::Proxy::VERSION,
  ));
}

# /docs and /docs/<file>: the Swagger UI, from the cache directory (skeid k105). Unknown path
# unless the config switches it on; the assets are fetched on the first request that needs them,
# without blocking the loop. A fetch that fails answers 502, and 503 while the failure is
# remembered -- the client is told, never left waiting, and no request starts a second download
# within the window.
sub _handle_docs {
  my ($c) = @_;
  my $skeid = $c->skeid;
  $skeid->maybe_reload_config;
  return $c->render(status => 404, text => 'Not Found') unless $skeid->openapi_swagger_ui;

  my $ui   = $c->app->swagger_ui;
  my $file = $c->stash('file');
  if (defined $file && $file eq 'init.js') {
    $c->res->headers->content_type('application/javascript; charset=utf-8');
    return $c->render(data => $ui->init_js);
  }
  return $c->render(status => 404, text => 'Not Found') if defined($file) && !$ui->is_asset($file);

  my $dir = $skeid->openapi_cache_dir // $ui->default_cache_dir;
  $c->render_later;
  $ui->ensure($dir, sub {
    my ($ok, $kind, $message) = @_;
    unless ($ok) {
      # The message names the pinned URL and the check that failed, nothing of a response.
      $c->app->log->error('swagger ui: ' . $message) if $kind eq 'fetch';
      $c->res->headers->header('Retry-After' => $ui->retry_after) if $kind eq 'backoff';
      return _render_error($c, ($kind eq 'backoff' ? 503 : 502),
        'The Swagger UI assets could not be fetched', 'upstream_error', 'swagger_ui_unavailable');
    }
    unless (defined $file) {
      $c->res->headers->content_type('text/html; charset=utf-8');
      return $c->render(data => $ui->index_html);
    }
    $c->res->headers->cache_control('public, max-age=3600');
    $c->reply->file($ui->asset_path($dir, $file));
  });
  return;
}

# GET /skeid/registry/snapshot (skeid #18, ADR 0017): a fronting tier's CapacityProbe::Registry
# pulls this. 404 unless registry.enabled, and never unsigned. No store may keep it: a cached
# snapshot is a stale one.
sub _handle_registry_snapshot {
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

# The client routes' gate (skeid k90), run by their bridges before anything else of the request:
# before the body is parsed, a node is admitted (request.start), a key resolved, an upstream
# called or a usage event written -- a refused request has nothing to give back. It reloads the
# config first, so switching client authentication on or off or rotating an id holds from the
# next request on every client route, a GET included. That is what the reload throttle
# (config_reload_interval) and the no-op on an unchanged config are for: an anonymous GET does
# not rerun the loader, nor restart the node probes, per request. Off without client_auth.
# The identity is the one routing uses, so with routing.trust_key_id_header the header's id is
# what must be on the list. A refusal is not logged -- the routes are public, and a line per
# rejected request would be anybody's to flood -- and its body names neither the key nor its id.
sub _authorize_client {
  my ($c) = @_;
  my $skeid = $c->skeid;
  $skeid->maybe_reload_config;
  return 1 unless $skeid->client_auth_enabled;

  my $api_key_id = _request_api_key_id($c);
  return 1 if $skeid->client_key_allowed($api_key_id);

  my $missing = !defined($api_key_id) || $api_key_id eq 'anonymous';
  $c->res->headers->header('WWW-Authenticate' => 'Bearer realm="skeid"');
  _render_error($c, 401, ($missing ? 'Missing API key' : 'Invalid API key'),
    'invalid_request_error', 'invalid_api_key');
  return undef;
}

# What a key is shown depends on who presents it, so no cache may hand one key's answer to
# another: every answer -- the client gate's 401 included -- is private, not stored, and varies on
# each header that can carry the identity. Set by the route's bridge, before the gate.
sub _manifest_cache_headers {
  my ($c) = @_;
  my $headers = $c->res->headers;
  $headers->header('Cache-Control' => 'private, no-store');
  $headers->header(Vary => 'Authorization, X-Api-Key, X-Skeid-Key-Id, X-Api-Key-Id');
  return;
}

# The config is reloaded by the client gate before this runs (see _authorize_client), throttled
# by config_reload_interval and a no-op when nothing changed. 404 when nothing is published
# (disabled, or a Langertha without Langertha::Manifest), 401 without a key (ADR 0015: no
# anonymous manifest, not even a minimal one), 403 for a key without a manifest: grant, else the
# manifest built for that key id.
sub _handle_manifest {
  my ($c) = @_;
  my $skeid = $c->skeid;

  my $headers = $c->res->headers;

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

    my $relay = _verbatim_relay($c, $served_model);

    if ($body->{stream}) {
      _proxy_openai_stream($c, $url, $body, $node_id, $started, $meta, undef, $relay);
      return;
    }

    $c->render_later;
    _proxy_openai_json_async($c, $url, $body, $node_id, $started, $meta, sub {
      my ($res, $err, $status) = @_;
      return if $err;
      _render_upstream_response($c, $res, $node_id);
    }, undef, $relay);
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
    }, undef, _verbatim_relay($c, $served_model));
  });
}

# Runs once per request, when its head is parsed and its body is still on the wire (the request
# content's `body` event). An upload route gets its own limit there, because afterwards is too
# late for either thing it is for (skeid k91):
#
# - uploads.max_bytes replaces the server's request limit, which is 16 MiB and so below the
#   default upload limit. A request that declares a larger body is cut off at once: the limit is
#   set below what was already read, the parser stops, and the route answers 413 without the body
#   having been received. A body of undeclared length (chunked) is cut off when it passes the
#   limit plus the head allowance, so it is never buffered whole either.
# - A caller the client gate is going to refuse is cut off the same way, so its 401 does not
#   cost an upload spooled to disk first. The gate itself still runs and renders the 401.
#
# Which limit a route has is the route table below: the audio routes the uploads.max_bytes, the
# documents routes (a form, and base64 in JSON for /v1/convert/source) uploads.documents_max_bytes.
# A new upload route is an entry there, or it runs under the server's 16 MiB.
#
# The limit is read off the Skeid here, after picking up a changed config, so a reload holds
# from the next upload. Every other route keeps the server's own limit: nothing is set for it.
# A failure here leaves the server's limit in force and the route's own checks to decide.
my %UPLOAD_ROUTE = (
  (map { $_ => 'upload_max_bytes' }    Langertha::Skeid::Protocol::Audio->routes),
  (map { $_ => 'documents_max_bytes' } Langertha::Skeid::Protocol::Documents->routes),
);

sub _limit_upload {
  my ($app, $tx) = @_;
  my $req = $tx->req;
  (my $path = $req->url->path->to_route) =~ s{/\z}{};
  return _limit_mcp_request($app, $tx) if $path =~ m{\A/mcp/};
  return unless uc($req->method // '') eq 'POST';
  my $limit = $UPLOAD_ROUTE{$path} or return;

  my $done = eval {
    my $c = $app->build_controller($tx);
    my $skeid = $c->skeid;
    $skeid->maybe_reload_config;

    if ($skeid->client_auth_enabled && !$skeid->client_key_allowed(_request_api_key_id($c))) {
      $req->max_message_size(1);
      return 1;
    }

    my $max = $skeid->$limit;
    my $declared = $req->headers->content_length;
    if (!$req->content->is_chunked && defined($declared) && $declared =~ /\A[0-9]+\z/ && $declared > $max) {
      $req->max_message_size(1);
      return 1;
    }
    $req->max_message_size($max + $UPLOAD_HEAD_ALLOWANCE);
    1;
  };
  $app->log->error('Setting the upload limit failed: ' . ($@ || 'unknown error')) unless $done;
  return;
}

# The body limit of the MCP routes: mcp.max_request_bytes, not the server's own. Set on the
# request as its body begins, like the upload limit. A body over it is cut off and _handle_mcp
# answers 413. A failure here leaves the server's limit in force.
sub _limit_mcp_request {
  my ($app, $tx) = @_;
  my $done = eval {
    my $skeid = $app->build_controller($tx)->skeid;
    $skeid->maybe_reload_config;
    $tx->req->max_message_size($skeid->mcp_max_request_bytes);
    1;
  };
  $app->log->error('Setting the MCP request limit failed: ' . ($@ || 'unknown error')) unless $done;
  return;
}

# POST /v1/audio/transcriptions and /v1/audio/translations (skeid k91). The request is a
# multipart form and the answer is whatever the node's transcription endpoint says -- JSON, plain
# text, subtitles or an event stream. Neither is translated (ADR 0021): the form goes upstream
# part for part as the client sent it, the answer comes back byte for byte. Skeid reads two
# fields of the form, `model` to route by and `stream` to pick the relay, and writes one, `model`
# again, when an alias tier serves another model than the one asked for (ADR 0008). What the
# form and the answers look like on the wire is Langertha::Skeid::Protocol::Audio's to know.
sub _handle_openai_audio {
  my ($c, $endpoint) = @_;
  my $audio = 'Langertha::Skeid::Protocol::Audio';
  _extend_client_timeout($c);
  my $req = $c->req;

  # Before anything is read off the body: a request cut off by _limit_upload has no complete
  # form. The body size is checked again, exactly, for what the limit set there lets through.
  my $max = $c->skeid->upload_max_bytes;
  if ($req->is_limit_exceeded || ($req->body_size // 0) > $max) {
    _render_error($c, 413, "Maximum content size limit ($max bytes) exceeded", 'invalid_request_error');
    return;
  }

  my $content = $req->content;
  unless ($content->is_multipart) {
    _render_error($c, 400, 'Expected a multipart/form-data body', 'invalid_request_error');
    return;
  }

  # One `model` field, no more: with two, Skeid would route -- and apply the key's policy -- by
  # one while the node may well serve the other.
  my ($field, $problem) = $audio->form_fields($content);
  my @models = @{$field->{model} || []};
  my $model = @models == 1 ? $models[0]{value} : undef;
  $model = decode('UTF-8', $model) // $model if defined $model;
  $problem //= !@models                           ? "The 'model' form field is required"
             : @models > 1                        ? "The 'model' form field may be given only once"
             : !(defined($model) && length($model)) ? "The 'model' form field is empty or too long"
             :                                      undef;
  if (defined $problem) {
    _render_error($c, 400, $problem, 'invalid_request_error');
    return;
  }

  # The last `stream` field decides, as it does for the node that parses the same form.
  my $streamed = @{$field->{stream} || []} ? $audio->is_true($field->{stream}[-1]{value}) : 0;

  my $api_key_id = _request_api_key_id($c);
  _begin_route_async($c, $model, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    # Requested and served model are two strings once an alias is in play (ADR 0008): the form
    # that goes upstream carries the served one, the usage event carries both.
    my $served_model = _served_model($tier, $model);
    my %replace = $served_model eq $model ? () : ($models[0]{index} => encode('UTF-8', $served_model));

    my $url = _endpoint_url_for_node($route->{url}, $audio->upstream_path($endpoint));
    my $meta = {
      api_format => 'openai',
      endpoint   => $endpoint,
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model            => $served_model,
      requested_model  => $model,
      route_url        => ($route->{url} // ''),
    };
    my $relay = {
      # The upstream form is built from the parts the server already parsed: a part is its
      # headers and an asset, and an upload above 256 KiB is an asset on disk, so the file is
      # streamed from there and never copied into memory. The client's Content-Type travels in
      # the forwarded headers and its boundary is the one the body is written with.
      request => sub {
        my ($ua, $url, $headers) = @_;
        return $ua->build_tx(POST => $url, $headers,
          multipart => $audio->upstream_parts($content, \%replace));
      },
      units      => sub { $audio->usage_units(@_) },
      delta_text => sub { $audio->delta_text(@_) },
    };
    my $body = { model => $served_model };

    if ($streamed) {
      _proxy_openai_stream($c, $url, $body, $node_id, $started, $meta, undef, $relay);
      return;
    }

    $c->render_later;
    _proxy_openai_json_async($c, $url, $body, $node_id, $started, $meta, sub {
      my ($res, $err, $status) = @_;
      return if $err;
      _render_upstream_response($c, $res, $node_id);
    }, undef, $relay);
  });
}

# POST /v1/convert/file and POST /v1/convert/source (skeid k94, ADR 0028): docling-serve's
# synchronous conversion under its own paths, relayed in its own shape like the audio routes
# (ADR 0021) -- a form goes upstream part for part, a source body is decoded once and written
# again so the node reads exactly what Skeid did, and the answer (JSON, or a zip) comes back byte
# for byte. There is no `model` field: the route is planned over the nodes of kind `documents`
# under the routing key `documents`, which is what a key's policy grants. Skeid refuses what makes
# the node fetch from an address the client names, unless documents.allow_remote_sources: that
# is a server-side request from inside the cluster network. The wire is
# Langertha::Skeid::Protocol::Documents's to know.
sub _handle_documents {
  my ($c, $endpoint) = @_;
  my $docs = 'Langertha::Skeid::Protocol::Documents';
  _extend_client_timeout($c);
  my $req   = $c->req;
  my $skeid = $c->skeid;

  # A request cut off by _limit_upload has no complete body. The size is checked again,
  # exactly, for what the limit set there lets through.
  my $max = $skeid->documents_max_bytes;
  if ($req->is_limit_exceeded || ($req->body_size // 0) > $max) {
    _render_error($c, 413, "Maximum content size limit ($max bytes) exceeded", 'invalid_request_error');
    return;
  }

  my ($remote, $count, $body, $content);
  if ($endpoint =~ /file\z/) {
    $content = $req->content;
    unless ($content->is_multipart) {
      _render_error($c, 400, 'Expected a multipart/form-data body', 'invalid_request_error');
      return;
    }
    my ($names, $problem) = $docs->form_remote_fields($content);
    if (defined $problem) {
      _render_error($c, 400, $problem, 'invalid_request_error');
      return;
    }
    $remote = $names;
    $count  = $docs->document_count($content);
  }
  else {
    $body = $req->json;
    unless (ref($body) eq 'HASH') {
      _render_error($c, 400, 'Expected a JSON object', 'invalid_request_error');
      return;
    }
    $remote = $docs->json_remote_fields($body, $req->body);
    $count  = $docs->document_count($body);
  }

  # Before admission, so it costs no slot and no event. The message names the field and never
  # what it holds: the value is an address the caller chose.
  if (@$remote && !$skeid->documents_allow_remote_sources) {
    _render_error($c, 400,
      "The '$remote->[0]' field is not accepted: requests that make the node fetch from or call "
      . 'an address are disabled (documents.allow_remote_sources)', 'invalid_request_error');
    return;
  }

  my $routing_key = $docs->routing_key;
  my $api_key_id  = _request_api_key_id($c);
  _begin_route_async($c, $routing_key, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    my $url = _endpoint_url_for_node($route->{url}, $docs->upstream_path($endpoint));
    my $meta = {
      api_format => $docs->api_format,
      endpoint   => $endpoint,
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model            => $routing_key,
      requested_model  => $routing_key,
      route_url        => ($route->{url} // ''),
    };
    my $relay = {
      # The form is built from the parts the server parsed: a part is its headers and an asset,
      # and a file above 256 KiB is an asset on disk, sent from there and never copied. The
      # client's Content-Type, boundary included, travels in the forwarded headers.
      ($content ? (request => sub {
        my ($ua, $url, $headers) = @_;
        return $ua->build_tx(POST => $url, $headers,
          multipart => Langertha::Skeid::Protocol::Audio->upstream_parts($content, {}));
      }) : ()),
      # Not decoded past what is worth the CPU of the event loop; and no tokens to read.
      max_parse_bytes => $docs->max_parse_bytes,
      usage => sub { return },
      units => sub {
        my ($payload, $res) = @_;
        return unless $res->is_success;
        my $pages = $docs->pages($payload, $res);
        return (documents => $count, (defined $pages ? (pages => $pages) : ()));
      },
    };

    $c->render_later;
    _proxy_openai_json_async($c, $url, ($body // {}), $node_id, $started, $meta, sub {
      my ($res, $err, $status) = @_;
      return if $err;
      _render_upstream_response($c, $res, $node_id);
    }, undef, $relay);
  }, kind => 'documents');
}

# GET /v1/realtime (skeid k95, ADR 0029): live transcription over the OpenAI realtime protocol.
# The handshake is an ordinary request that has a slot and a node to get -- the client gate has
# run already (a bridge, so a refused key is a plain 401 and no socket), the model comes from the
# query, the key's policy, tiers and admission apply, and route_wait happens before the upgrade.
# The node is opened FIRST: only a node that took the WebSocket handshake gets a client that is
# upgraded, so a node that refuses is an HTTP 502 and not an accepted-then-closed socket. From the
# upgrade on the session is Langertha::Skeid::Proxy::Realtime's; this function ends with handing
# it both transactions, and its finish callback is the only place request.finish and the usage
# event happen for a session that got that far (once, on whichever path the session ends).
sub _handle_openai_realtime {
  my ($c) = @_;
  my $protocol = 'Langertha::Skeid::Protocol::Realtime';
  _extend_client_timeout($c);
  $c->render_later;

  my ($model, $problem) = $protocol->query_model($c->req->url->query);
  if (defined $problem) {
    _render_error($c, 400, $problem, 'invalid_request_error');
    return;
  }

  my $api_key_id = _request_api_key_id($c);
  _begin_route_async($c, $model, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    my $served_model = _served_model($tier, $model);
    my $meta = {
      api_format      => 'openai',
      endpoint        => $protocol->route,
      api_key_id      => $api_key_id,
      provider        => 'skeid',
      engine          => ($route->{engine} // 'openaibase'),
      model           => $served_model,
      requested_model => $model,
      route_url       => ($route->{url} // ''),
    };
    my $url = $protocol->upstream_url(
      _endpoint_url_for_node($route->{url}, $protocol->upstream_path), $served_model,
      $c->req->url->query);

    # What the client sent for the handshake of its own connection is not the node's: its
    # Sec-WebSocket-* headers (the subprotocol list may carry the browser's key -- never passed
    # on, ADR 0003), its Origin and its cookies stay here. The user agent makes the node's own.
    my %fwd_headers = _forward_headers($c);
    delete @fwd_headers{ grep { /\A(?:sec-websocket-|origin\z|cookie\z)/i } keys %fwd_headers };

    _inject_node_auth_async(\%fwd_headers, $c->skeid, $node_id, sub {
      my ($no_key) = @_;

      # The client left while the node's key was being resolved: nothing went upstream, the
      # slot goes back and nothing is metered, as for a request that was not forwarded.
      if (_client_gone($c)) {
        $c->skeid->call_function('request.finish', {
          id => $node_id, ok => 0, aborted => 1, duration_ms => _duration_ms($started),
        });
        return;
      }
      if (defined $no_key) {
        _refuse_unkeyed_node($c, $node_id, $started, $meta, $no_key);
        return;
      }

      my $client   = $c->tx;
      my $up_tx    = $c->app->ua->build_websocket_tx($url => \%fwd_headers);
      my $settled  = 0;   # set by whichever comes first: the node's answer or the client leaving
      my $handshake = $client->can('handshake') ? $client->handshake : $client;

      # The client hangs up while the node is being opened. Its upgrade request is the
      # transaction that closes (the WebSocket one does not exist yet), and the node's is
      # cancelled -- a node that sees the handshake finish would otherwise hold a session
      # for nobody. The slot is given back and the request recorded, as for a plain request.
      $handshake->once(finish => sub {
        return if $settled;
        $settled = 1;
        my $duration_ms = _duration_ms($started);
        $c->skeid->call_function('request.finish', {
          id => $node_id, ok => 0, aborted => 1, duration_ms => $duration_ms,
        });
        _record_usage_event($c, {
          %$meta, _client_abort_event(), node_id => $node_id, duration_ms => $duration_ms,
          metrics => {},
        });
        _cancel_upstream($up_tx);
      });

      $c->app->ua->start($up_tx => sub {
        my ($ua, $tx) = @_;
        return if $settled;
        $settled = 1;
        my $duration_ms = _duration_ms($started);
        _observe_capacity($c, $node_id, $tx->res);

        # The node did not take the handshake: HTTP 502 in the client's shape, no socket. A
        # 4xx of the node (its key, its capacity) is Skeid's problem to the client, not theirs.
        unless ($tx->is_websocket) {
          my $err = $tx->error || {};
          $c->skeid->call_function('request.finish', {
            id => $node_id, ok => 0, duration_ms => $duration_ms,
          });
          _record_usage_event($c, {
            %$meta,
            node_id       => $node_id,
            status_code   => 502,
            ok            => 0,
            duration_ms   => $duration_ms,
            error_type    => 'upstream_error',
            error_message => 'The node refused the realtime handshake: '
              . ($err->{code} ? $err->{code} . ' ' : '') . ($err->{message} // 'no WebSocket'),
            metrics       => {},
          });
          _render_error($c, 502, 'The node did not accept the realtime connection', 'upstream_error');
          return;
        }

        # Upgrade the client now, choosing the one subprotocol Skeid ever answers with -- never
        # the entry that carries a key. From here the session owns both ends.
        $client->with_protocols($protocol->subprotocol);
        $c->res->headers->header('x-skeid-node' => $node_id);
        $c->rendered(101);

        my $skeid = $c->skeid;
        $c->app->realtime->start_session(
          client          => $client,
          upstream        => $tx,
          requested_model => $model,
          served_model    => $served_model,
          started         => $started,
          limits          => {
            idle_timeout        => $skeid->realtime_idle_timeout,
            max_session_seconds => $skeid->realtime_max_session_seconds,
            max_message_bytes   => $skeid->realtime_max_message_bytes,
            max_queued_bytes    => $skeid->realtime_max_queued_bytes,
          },
          finish          => sub {
            my ($result) = @_;
            $skeid->call_function('request.finish', {
              id          => $node_id,
              ok          => $result->{ok},
              ($result->{aborted}  ? (aborted  => 1) : ()),
              ($result->{rejected} ? (rejected => 1) : ()),
              duration_ms => $result->{duration_ms},
            });
            # One event for the whole session (ADR 0029): the usage blocks of its completed
            # transcriptions summed, priced like any other answer's, and the duration.
            my $metrics = ref($result->{usage}) eq 'HASH'
              ? _stream_metrics($c, $meta, { model => $served_model }, $result->{duration_ms},
                  $result->{usage})
              : {};
            _record_usage_event($c, {
              %$meta,
              node_id       => $node_id,
              status_code   => $result->{status_code},
              ok            => $result->{ok},
              duration_ms   => $result->{duration_ms},
              error_type    => $result->{error_type},
              error_message => $result->{error_message},
              metrics       => $metrics,
              (defined $result->{audio_seconds} ? (audio_seconds => $result->{audio_seconds}) : ()),
              (defined $result->{content_bytes} ? (content_bytes => $result->{content_bytes}) : ()),
            });
          },
        );
      });
    });
  });
  return;
}

# POST /v1/rerank and POST /rerank (skeid k92). A JSON body in the shape Cohere, vLLM, Jina and
# infinity share, routed by its `model` like a chat request. To a node that speaks that shape
# the body is relayed with only `model` replaced, and the answer comes back byte for byte (ADR
# 0021). A node marked `rerank_format` speaks another dialect and is translated in both
# directions -- on the upstream side, the one place Skeid does that. Either way the wire's names
# are Langertha::Skeid::Protocol::Rerank's to know.
sub _handle_openai_rerank {
  my ($c) = @_;
  my $rerank = 'Langertha::Skeid::Protocol::Rerank';
  _extend_client_timeout($c);
  my $body = $c->req->json;
  if (defined(my $problem = $rerank->request_problem($body))) {
    _render_error($c, 400, $problem, 'invalid_request_error');
    return;
  }

  my $model = $body->{model};
  my $documents = $rerank->document_count($body);
  my $api_key_id = _request_api_key_id($c);
  _begin_route_async($c, $model, $api_key_id, sub {
    my ($route, $node_id, $started, $tier) = @_;
    return unless $route;

    # Requested and served model are two strings once an alias is in play (ADR 0008): the body
    # that goes upstream carries the served one, the usage event carries both.
    my $served_model = _served_model($tier, $model);
    my $format = $route->{rerank_format} // '';
    my $meta = {
      api_format => 'openai',
      endpoint   => $rerank->endpoint,
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model            => $served_model,
      requested_model  => $model,
      route_url        => ($route->{url} // ''),
    };

    # Which dialect the request has to be put in is known only now, with the node. A request
    # this node's dialect cannot carry -- a document that is not text, for a node that takes
    # texts -- is the client's to fix, but it holds a slot already.
    my $upstream_body = eval { $rerank->request_to_upstream($body, $served_model, $format) };
    unless (ref($upstream_body) eq 'HASH') {
      my $err = $@;
      my $message = blessed($err) && $err->isa('Langertha::Skeid::Protocol::Refusal')
        ? $err->message : 'Invalid request';
      _refuse_unsendable_request($c, $node_id, $started, $meta, $message);
      return;
    }

    my $url = $rerank->at_server_root($format)
      ? _root_url_for_node($route->{url}, $rerank->upstream_path)
      : _endpoint_url_for_node($route->{url}, $rerank->upstream_path);
    my $relay = {
      # Tokens are reported in three places, none of them where a chat answer has them.
      usage => sub {
        my ($payload, $res) = @_;
        return $rerank->usage($payload, $res->headers, $format);
      },
      # Counted off the request, so it needs nothing from the node but its answer.
      units => sub {
        my ($payload, $res) = @_;
        return $res->is_success ? (documents => $documents) : ();
      },
      (length($format) ? (answer => sub {
        my ($payload, $res) = @_;
        return $rerank->response_from_upstream($payload, $res->headers, $body, $served_model, $format);
      }) : ()),
    };

    $c->render_later;
    _proxy_openai_json_async($c, $url, $upstream_body, $node_id, $started, $meta, sub {
      my ($res, $err, $status, $upstream, $payload) = @_;
      return if $err;
      return _render_upstream_response($c, $res, $node_id) unless length $format;
      $c->res->code($status || 200);
      $c->res->headers->header('x-skeid-node' => $node_id);
      $c->render(json => $payload);
    }, undef, $relay);
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
        Langertha::Skeid::Protocol::Anthropic::Stream->new(model => $model),
        _schema_relay($c, $openai_body, 'input_schema'));
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
    }, _schema_relay($c, $openai_body, 'input_schema'));
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
        Langertha::Skeid::Protocol::Ollama::Stream->new(model => $model, shape => $face->{shape}),
        _schema_relay($c, $openai_body, 'function', 'parameters'));
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
    }, _schema_relay($c, $openai_body, 'function', 'parameters'));
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
  my ($c, $model, $api_key_id, $cb, %route) = @_;
  $cb ||= sub { };
  # What the route is over besides a model name: `documents` plans over the nodes of that kind
  # (ADR 0028). Chat routes pass nothing.
  my @kind = length($route{kind} // '') ? (kind => $route{kind}) : ();
  my $wait_poll_ms = 0 + ($c->skeid->route_wait_poll_ms // 25);
  $wait_poll_ms = 1 if $wait_poll_ms < 1;

  my $decision = $c->skeid->call_function('route.plan', {
    model      => ($model // ''),
    api_key_id => $api_key_id,
    @kind,
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
          @kind,
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
      @kind,
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
  # On a WebSocket route that has not been upgraded the transaction that closes when the client
  # leaves is the handshake's, not the WebSocket one the controller holds (skeid k95).
  if ($c->can('tx') && $c->tx) {
    my $tx = $c->tx;
    $tx = $tx->handshake if $tx->is_websocket && !$tx->established && $tx->can('handshake');
    $tx->on(finish => sub {
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

# A status that says the request, not the node, was at fault (k99, ADR 0024). 401, 403 and 429
# are not here: they speak of the node's key or capacity and stay node errors.
sub _client_fault {
  my ($status) = @_;
  return (defined $status && $status =~ /\A(?:400|404|413|422)\z/) ? 1 : 0;
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
#
# $relay is what a route relayed in the upstream's own shape brings (ADR 0021), all optional:
# `request`, a code ref called with the user agent, the URL and the upstream headers that builds
# the upstream transaction instead of the JSON one made from $body; `units`, a code ref that
# reads the route's own usage units off the decoded answer and returns them as event fields;
# and, for a stream, `delta_text`, which returns the text of a frame in the route's own dialect.
# Two more for an answer that is not chat-shaped (rerank, skeid k92), both called with the
# decoded answer -- whatever JSON it is -- and the upstream response: `usage` returns the usage
# block to meter, or nothing, where the answer reports its tokens somewhere else than a chat
# answer does; `answer` is $translate for a node whose own dialect is not the client's, and
# fails the same way.
sub _proxy_openai_json_async {
  my ($c, $url, $body, $node_id, $started, $meta, $cb, $translate, $relay) = @_;
  $meta ||= {};
  $cb ||= sub { };
  $relay ||= {};

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
  my $tx = _upstream_tx($c, $url, \%fwd_headers, $body, $relay);

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
        _client_fault($err->{code}) ? (rejected => 1) : (),
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
    # A route that names a bound leaves a larger answer undecoded (a converted document is
    # megabytes, and decoding it is CPU on the loop); its units then say nothing.
    my $payload = (defined($relay->{max_parse_bytes}) && ($res->body_size // 0) > $relay->{max_parse_bytes})
      ? undef : eval { $res->json };

    my $translated;
    if ($translate || $relay->{answer}) {
      $translated = eval {
        $relay->{answer}
          ? $relay->{answer}->($payload, $res)
          : $translate->(ref($payload) eq 'HASH' ? $payload : {});
      };
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
    if ($relay->{usage}) {
      my $usage = $relay->{usage}->($payload, $res);
      $metrics = _priced_metrics($c, $meta, $body, $duration_ms, { usage => $usage })
        if ref($usage) eq 'HASH';
    } elsif (ref($payload) eq 'HASH') {
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
      ($relay->{units} ? $relay->{units}->($payload, $res) : ()),
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
# $relay is as for _proxy_openai_json_async.
sub _proxy_openai_stream {
  my ($c, $url, $body, $node_id, $started, $meta, $stream, $relay) = @_;
  $meta ||= {};
  $relay ||= {};

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
  my $tx = _upstream_tx($c, $url, \%fwd_headers, $body, $relay);
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
  # The route's own usage units (ADR 0021), read off the usage the stream carried so far -- the
  # same block a non-streamed answer would have carried. Nothing until a frame had one.
  my $units = sub {
    return () unless $relay->{units} && ref($upstream_usage) eq 'HASH';
    return $relay->{units}->({ usage => $upstream_usage });
  };

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
      $units->(),
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
        next if _skip_response_header($lc);
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
      # SSE makes the space after the colon optional: `data:{...}` is as valid as `data: {...}`.
      next unless $line =~ /^data:\s?(.*?)\s*$/;
      my $payload = $1;
      next unless length $payload;

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
      if ($relay->{delta_text}) {
        my $text = $relay->{delta_text}->($json);
        $accumulated_content_bytes += Langertha::Skeid::Protocol::utf8_length($text)
          if defined($text) && length($text);
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
      $units->(),
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
          _client_fault($err_status) ? (rejected => 1) : (),
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
          $units->(),
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
      # An upstream 4xx relayed after the headers went out is still the client's to fix.
      ($had_error && _client_fault($status)) ? (rejected => 1) : (),
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
      $units->(),
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

# The request of a route on the OpenAI face, whose node speaks the wire the client spoke: the
# client's own bytes with only `model` replaced (Langertha::Skeid::Protocol::RawBody), never the
# decoded body encoded again. Re-encoding sorts the keys of every object, and a node renders
# tool definitions into the prompt in the order they arrive -- so it would hand the model a
# prompt the client did not write, and its prompt cache a prefix it has not seen.
#
# undef, and with it the encoded body, only for bytes the scanner cannot follow.
sub _verbatim_relay {
  my ($c, $served_model) = @_;
  my $bytes = Langertha::Skeid::Protocol::RawBody::with_top_level($c->req->body, model => $served_model);
  return undef unless defined $bytes;
  return { request => sub {
    my ($ua, $url, $headers) = @_;
    return $ua->build_tx(POST => $url, $headers, $bytes);
  } };
}

# The request of a translated route (the Anthropic and Ollama faces): the translated body, with
# each tool's JSON schema written as the client spelled it and the tool definition around it in
# the order the function-calling wire spells it. The body is new, so it cannot go up as the
# client's bytes -- but the tool definitions are what a node renders into the prompt verbatim,
# and those are kept (Langertha::Skeid::Protocol::RawBody). @path is where a tool carries its
# schema on the client's wire.
#
# The body is encoded when the request is built, after the caller has set `model` and `stream`
# on it. undef for a request without tools; a body whose tools no longer line up with the
# client's goes up encoded as before.
sub _schema_relay {
  my ($c, $openai_body, @path) = @_;
  my $texts = Langertha::Skeid::Protocol::RawBody::tool_schemas($c->req->body, @path) or return undef;
  return { request => sub {
    my ($ua, $url, $headers) = @_;
    my $bytes = Langertha::Skeid::Protocol::RawBody::encode_with_schemas($openai_body, $texts);
    return $ua->build_tx(POST => $url, $headers, json => $openai_body) unless defined $bytes;
    delete @{$headers}{ grep { lc($_) eq 'content-type' } keys %$headers };
    return $ua->build_tx(POST => $url, { %$headers, 'Content-Type' => 'application/json' }, $bytes);
  } };
}

# The upstream request of an admitted call: the one JSON POST every translated route makes (ADR
# 0001), or what a relayed route's own `request` builder returns (ADR 0021).
sub _upstream_tx {
  my ($c, $url, $headers, $body, $relay) = @_;
  my $ua = $c->app->ua;
  return $relay->{request}->($ua, $url, $headers) if $relay && $relay->{request};
  return $ua->build_tx(POST => $url, $headers, json => $body);
}

# Renders an error in the shape of the face the client called. The Anthropic Messages face
# gets Anthropic's envelope, {type: "error", error: {type, message}}, with the type taken from
# the HTTP status, because that is what an Anthropic SDK parses and raises on (core karr #224).
# The Ollama face gets Ollama's {error: "<message>"}, a plain string, because that is what the
# Ollama clients decode (skeid #47). Every other face keeps the OpenAI shape it always had, with
# $openai_type as its type and $openai_code, when given, as its code (OpenAI's own 401 carries
# invalid_api_key). The face is read off the stash, which the /v1/messages and /api/* bridges
# set; a controller without one (a unit test's stand-in) is an OpenAI face.
sub _render_error {
  my ($c, $status, $message, $openai_type, $openai_code) = @_;
  # A refused WebSocket handshake is a plain HTTP answer: the upgrade headers the server
  # prepared for a 101 do not belong on it (skeid k95).
  my $handshake = $c->can('tx') ? $c->tx : undef;
  if ($handshake && $handshake->is_websocket && !$handshake->established) {
    $c->res->headers->remove($_) for qw( Upgrade Connection Sec-WebSocket-Accept );
  }
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
  $c->render(json => { error => {
    message => $message,
    type    => $openai_type,
    defined($openai_code) ? ( code => $openai_code ) : (),
  } }, status => $status);
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
    next if _skip_response_header($lc);
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

# An upstream response header Skeid does not relay to the client: hop-by-hop headers describe
# the node's connection to Skeid, not the client's (a relayed `Connection: close` makes Skeid
# drop the customer's keep-alive connection), and the body is re-framed and never re-encoded
# here. One filter for the JSON, stream and MCP relays (skeid k107). `$lc` is the lowercased name.
sub _skip_response_header {
  my ($lc) = @_;
  return $HOP_BY_HOP{$lc} || $lc eq 'content-length' || $lc eq 'content-encoding' ? 1 : 0;
}

sub _forward_headers {
  my ($c) = @_;
  my %fwd_headers;
  for my $name (@{$c->req->headers->names}) {
    my $lc = lc($name);
    next if $HOP_BY_HOP{$lc};
    next if $lc eq 'host' || $lc eq 'content-length' || $lc eq 'accept-encoding';
    # The body is in hand, so nothing is expected of the node. A node that answered `Expect:
    # 100-continue` with its `100 Continue` would have the user agent start a fresh response
    # object, one the stream relay is not listening on (skeid k96).
    next if $lc eq 'expect';
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

  _upstream_key_async($skeid, $node, sub {
    my ($key, $reason) = @_;

    if (defined $key) {
      _drop_client_credentials($headers_ref);
      # The header the node names carries the raw key; without one it is a Bearer token.
      my $header = $node->{api_key_header};
      if (defined($header) && length($header)) { $headers_ref->{$header} = $key }
      else                                     { $headers_ref->{Authorization} = "Bearer $key" }
      return $cb->();
    }

    # A node with no key of its own: the documented pass-through.
    return $cb->() unless defined $reason;

    # A key source was named and produced nothing. Take the client's credentials out of what
    # would go upstream as well, so a caller that ignored the reason still could not leak them.
    _drop_client_credentials($headers_ref);
    $cb->($reason);
  });
  return;
}

# Resolves the upstream key of $source -- a node, or an MCP server (skeid k103): whatever names
# its key by api_key_ref and api_key_env. The broker is asked first, the variable stands in when
# the reference resolves nothing. The callback runs exactly once, and always: with the key; with
# nothing when $source names no key source; with undef and a reason when it names one and none
# produced a key. The reason names the key reference and the variable, never a key, and is for
# the log and the usage event (ADR 0003).
sub _upstream_key_async {
  my ($skeid, $source, $cb) = @_;

  my $ref = $source->{api_key_ref};
  $ref = undef unless defined($ref) && length($ref);
  my $env_name = $source->{api_key_env};
  $env_name = undef unless defined($env_name) && length($env_name);

  my $apply = sub {
    my ($key, $ref_failure) = @_;

    # Fallback: env var
    if (!defined($key) || !length($key)) {
      if (defined $env_name) {
        $key = $ENV{$env_name} // '';
      }
    }

    return $cb->($key) if defined($key) && length($key);
    return $cb->() unless defined($ref) || defined($env_name);

    $cb->(undef, join('; ',
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

# The answer to a request that holds a slot on a node and cannot be put to it: the body is in a
# shape the node's dialect has no place for, which only shows once the node is known (rerank to a
# `rerank_format` node, skeid k92). As for an unkeyed node, no upstream call and everything an
# admitted request is owed -- its request.finish, one usage event, an error in the face's shape
# -- but 400: the request is the client's to change, and no retry will get it through.
# $message is written for the client and quotes nothing of the request.
sub _refuse_unsendable_request {
  my ($c, $node_id, $started, $meta, $message) = @_;
  my $duration_ms = _duration_ms($started);
  $c->skeid->call_function('request.finish', {
    id => $node_id,
    ok => 0,
    rejected => 1,
    duration_ms => $duration_ms,
  });
  _record_usage_event($c, {
    %$meta,
    node_id       => $node_id,
    status_code   => 400,
    ok            => 0,
    duration_ms   => $duration_ms,
    error_type    => 'invalid_request_error',
    error_message => $message,
    metrics       => {},
  });
  _render_error($c, 400, $message, 'invalid_request_error');
  return;
}

# The bridge of the MCP routes (skeid k103, ADR 0022). Three answers before a handler runs, in
# this order. Without an mcp: section the routes do not exist: the answer is the one an unknown
# path gets, and it comes before the client gate, so a Skeid that has no MCP servers does not
# start answering 401 where it answered 404. Then the client gate, as on every client route.
# Then a key at all, also while client authentication is off: an MCP server is assigned to a
# customer key id, `anonymous` can hold none, and a caller that forgot its key is better told
# so than shown an empty list.
sub _authorize_mcp_client {
  my ($c) = @_;
  my $skeid = $c->skeid;
  $skeid->maybe_reload_config;
  unless ($skeid->mcp_enabled) {
    $c->reply->not_found;
    return undef;
  }
  return undef unless _authorize_client($c);

  my $api_key_id = _request_api_key_id($c);
  return 1 if defined($api_key_id) && $api_key_id ne 'anonymous';

  $c->res->headers->header('WWW-Authenticate' => 'Bearer realm="skeid"');
  _render_error($c, 401, 'Missing API key', 'invalid_request_error', 'invalid_api_key');
  return undef;
}

# GET /v1/mcp/servers: the servers assigned to the presented key, and only what a client needs
# to connect -- the public URL of a relayed server, the command of a stdio one. Whose answer it
# is depends on the key, so it carries the manifest's cache headers. The public URL is the
# config's, else the one this request came in on.
sub _handle_mcp_servers {
  my ($c) = @_;
  my $mcp = 'Langertha::Skeid::Protocol::MCP';
  my $skeid = $c->skeid;
  _manifest_cache_headers($c);

  my $base = $skeid->mcp_public_url;
  unless (defined $base) {
    my $abs = $c->req->url->to_abs;
    $base = $abs->scheme . '://' . $abs->host_port;
  }
  $c->render(json => {
    object => 'list',
    data   => [ map { $mcp->listing_entry($_, $base) } @{$skeid->mcp_servers_for_key(_request_api_key_id($c))} ],
  });
  return;
}

# POST|GET|DELETE /mcp/<name>[/<path>] (skeid k103): relayed to the MCP server of that name, if
# it is assigned to the presented key. Everything that is not such a server is one 404 -- an
# unknown name, another key's server, a stdio entry, a sub-path that climbs -- so a key cannot
# learn which names exist. Skeid reads nothing of the request (ADR 0022): the body goes up as
# the bytes it came in, with the headers Protocol::MCP lets through, the server's static
# headers and the server's own key. The client's credentials are never among them.
sub _handle_mcp {
  my ($c) = @_;
  my $mcp = 'Langertha::Skeid::Protocol::MCP';
  my $skeid = $c->skeid;
  my $req = $c->req;

  my $api_key_id = _request_api_key_id($c);
  my $server = $skeid->mcp_server_for_key($c->stash('mcp_server'), $api_key_id);
  my $url = ($server && $mcp->is_relayed($server->{transport}))
    ? $mcp->upstream_url($server->{url}, $c->stash('mcp_path'), $req->url->query)
    : undef;
  unless ($url) {
    _render_error($c, 404, 'No MCP server of this name is available for this key', 'not_found');
    return;
  }

  # A body cut off at the server's request limit is not the body the client sent.
  if ($req->is_limit_exceeded) {
    _render_error($c, 413, 'Maximum message size exceeded', 'invalid_request_error');
    return;
  }

  _extend_client_timeout($c);
  # Before the key resolution: a cold broker cache answers on a later tick.
  $c->render_later;
  my $started = time;
  my $meta = {
    api_format => 'mcp',
    endpoint   => $mcp->endpoint($server->{name}),
    api_key_id => $api_key_id,
    provider   => 'skeid',
    route_url  => $server->{url},
  };
  my %headers = ($mcp->request_headers($req->headers), %{$server->{headers} || {}});

  _upstream_key_async($skeid, $server, sub {
    my ($key, $no_key) = @_;

    # The client hung up while the key was being resolved: nothing went upstream, nothing is
    # metered, as on every other route.
    return if _client_gone($c);

    # A key source was named and produced no key: the server is not called without it.
    if (defined $no_key) {
      $c->app->log->error("No upstream key for MCP server '$server->{name}', request refused: $no_key");
      _record_usage_event($c, {
        %$meta,
        status_code   => 503,
        ok            => 0,
        duration_ms   => _duration_ms($started),
        error_type    => 'upstream_key_unavailable',
        error_message => $no_key,
        metrics       => {},
      });
      _render_error($c, 503, 'The upstream key for this MCP server is not available',
        'upstream_key_unavailable');
      return;
    }

    $headers{Authorization} = "Bearer $key" if defined $key;
    _relay_mcp($c, $server, $url, \%headers, $meta, $started);
  });
  return;
}

# The relay of one MCP request. Its own function, not _proxy_openai_stream: there is no node --
# no slot to give back, no capacity headers, no usage frame to read along -- and an answer's
# shape is not known before it arrives: one JSON body, an event stream, or nothing (202).
# So every answer is relayed the same way, as it arrives. The response is opened -- status and
# headers written out -- the moment the upstream's headers are parsed, before any body byte: a
# standing GET stream is open for the client before its first event. Every chunk is then written
# as it was read. Mojolicious buffers what the client has not taken yet and keeps the order.
#
# Two answers are not relayed, because they are about this gateway and not for its client. An
# upstream 401: towards the client 401 says "your Skeid key is not let in", and an MCP client
# acts on it; the upstream's 401 is about the key Skeid presented. And a redirect: its Location
# is an upstream URL, which a customer is never shown, and Skeid follows none -- the server's
# key would travel along. Both are the operator's to fix: logged, answered 502.
#
# One usage event per request, written when it ends. An event stream has no end that could be
# checked without reading MCP, so however it ends -- the client leaves, the upstream closes it,
# the time limit cuts it -- it is recorded under the status it was opened with. Any other answer
# is held to its framing, and a client that leaves before it is complete is a 499.
sub _relay_mcp {
  my ($c, $server, $url, $headers, $meta, $started) = @_;
  my $mcp = 'Langertha::Skeid::Protocol::MCP';

  my $body = $c->req->body;
  my $tx = $c->app->ua->build_tx($c->req->method => $url => $headers => (length($body) ? ($body) : ()));
  # As for every relayed stream: the bytes, not Mojolicious' own SSE events (skeid karr #30).
  $tx->res->content(Langertha::Skeid::Proxy::RelayContent->new);
  # A standing stream has no size: the user agent's response limit (2 GiB by default) would cut
  # it at its sum, however long it lived. The time limits bound it, not its length.
  $tx->res->max_message_size(0);

  # Taken now: the request may be past its transaction when the answer opens.
  my $request_id = _request_id($c);
  my ($opened, $event_stream, $status) = (0, 0, 0);
  # Why the upstream's answer is not relayed, once its status says so: see above.
  my $unrelayed = sub {
    my ($code) = @_;
    return undef unless defined $code;
    return 'unauthorized' if $code == 401;
    return 'redirect' if $code >= 300 && $code < 400;
    return undef;
  };
  my $refused;
  # Set by whichever comes first, the upstream's completion or the client hanging up, so that
  # the usage event is written once.
  my $closed = 0;

  my $record = sub {
    my (%event) = @_;
    _record_usage_event($c, { %$meta, duration_ms => _duration_ms($started), metrics => {}, %event });
  };
  my $open = sub {
    my ($res) = @_;
    $status = $res->code;
    $c->res->code($status);
    for my $name (@{$res->headers->names}) {
      next unless $mcp->response_header_allowed($name);
      $c->res->headers->header($name => $res->headers->header($name));
    }
    $c->res->headers->header('x-request-id' => $request_id);
    $opened = 1;
  };

  $tx->res->content->unsubscribe('read')->on(read => sub {
    my ($content, $bytes) = @_;
    return if $closed || $refused;
    unless ($opened) {
      # The first read comes with the upstream's headers, with or without a first chunk.
      return if defined($refused = $unrelayed->($tx->res->code));
      $open->($tx->res);
      $event_stream = $mcp->is_event_stream($tx->res->headers->content_type);
      $c->write_chunk;
    }
    $c->write_chunk($bytes) if length $bytes;
  });

  $c->tx->on(finish => sub {
    # Also emitted when the answer is complete, and then there is nothing left to do here.
    return if $closed;
    $closed = 1;
    $tx->res->content->unsubscribe('read');
    $record->(($opened && $event_stream)
      ? (status_code => $status, ok => ($status < 500 ? 1 : 0))
      : _client_abort_event());
    _cancel_upstream($tx);
  });

  $c->app->ua->start($tx => sub {
    my ($ua, $done) = @_;
    # The read listener closes over the upstream transaction and the client controller: remove
    # it on every path, or the completed transaction owns the listener that owns it.
    $done->res->content->unsubscribe('read');

    # The client hung up and its request was closed then; this is the cancelled transaction.
    return if $closed;
    $closed = 1;

    my $res  = $done->res;
    my $err  = $done->error;
    my $code = $res->code;
    # Mojo reports an HTTP 4xx/5xx as an error with a code; one without is the connection's.
    my $broken = ($err && !$err->{code}) ? ($err->{message} // 'unknown') : undef;

    $refused //= $unrelayed->($code) unless $opened;
    if (defined($refused) && $refused eq 'unauthorized') {
      $c->app->log->error("MCP server '$server->{name}' answered 401 to the key Skeid presented ("
        . (join(', ', map { "$_ '$server->{$_}'" } grep { defined $server->{$_} } qw( api_key_ref api_key_env ))
          || 'it names no key source') . ')');
      $record->(status_code => 502, ok => 0, error_type => 'upstream_unauthorized',
        error_message => 'The MCP server answered 401 to the upstream key');
      _render_error($c, 502, 'Upstream error: the MCP server did not accept the gateway\'s credential',
        'upstream_error');
      return;
    }
    if (defined $refused) {
      my $location = $res->headers->location // '';
      $c->app->log->error("MCP server '$server->{name}' answered $code with a redirect to '$location': "
        . 'no redirect is followed, configure the URL it leads to');
      $record->(status_code => 502, ok => 0, error_type => 'upstream_redirect',
        error_message => "The MCP server answered $code with a redirect");
      _render_error($c, 502, 'Upstream error: the MCP server answered with a redirect', 'upstream_error');
      return;
    }

    unless ($opened) {
      # No answer, or one whose connection broke before its body began.
      if (!defined($code) || defined($broken)) {
        my $message = $broken // 'unknown';
        $record->(status_code => 502, ok => 0, error_type => 'upstream_error', error_message => $message);
        _render_error($c, 502, "Upstream error: $message", 'upstream_error');
        return;
      }
      # An answer without a body (202, 204): no read ever came.
      $open->($res);
      $record->(status_code => $status, ok => ($status < 500 ? 1 : 0));
      $c->rendered;
      return;
    }

    # The answer is open, so its status is sent. An event stream ends however it ends. Anything
    # else is held to its framing: Mojo::UserAgent reports an upstream that hangs up mid-body as
    # no error at all once the status line has arrived.
    my $cut;
    unless ($event_stream) {
      my $content = $res->content;
      my $framed = $content->is_chunked || length($content->headers->content_length // '');
      $cut = $broken // (($framed && !$content->is_finished) ? 'Premature connection close' : undef);
    }
    # An event stream has no framing to check, but a time limit cutting it is told by the user
    # agent: that one is not a clean end, whatever status it was opened with.
    my $timeout = ($event_stream && defined($broken) && $broken =~ /timeout/i) ? $broken : undef;
    $record->(
      status_code => $status,
      ok          => (!defined($cut) && !defined($timeout) && $status < 500) ? 1 : 0,
      (defined($cut) ? (error_type => 'upstream_error', error_message => $cut) : ()),
      (defined($timeout) ? (error_type => 'upstream_timeout', error_message => $timeout) : ()),
    );
    $c->finish;
  });
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
  # A browser cannot set a header on a WebSocket: the realtime route takes its key from the
  # subprotocol list as a last resort (skeid k95), only ever for the one route, and never
  # before a header. It is read here and answered nowhere.
  if (!length($raw) && $c->req->url->path->to_route =~ m{\A/v1/realtime/?\z}) {
    my $key = Langertha::Skeid::Protocol::Realtime->subprotocol_key(
      $c->req->headers->sec_websocket_protocol);
    return ($key, $key) if defined $key;
  }
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
      # Audio routes only, and only when the node reported it (skeid k91, ADR 0021).
      (defined($args->{audio_seconds}) ? (audio_seconds => 0 + $args->{audio_seconds}) : ()),
      # The rerank route only, and only for a request the node answered (skeid k92).
      (defined($args->{documents}) ? (documents => 0 + $args->{documents}) : ()),
      # The documents routes, when the answer carried a page count (skeid k94, ADR 0028).
      (defined($args->{pages}) ? (pages => 0 + $args->{pages}) : ()),
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

# The URL of a route a node serves at its server root rather than below /v1 (a TEI node's
# /rerank): a node URL is a base, and one written with a trailing /v1 names the same server.
sub _root_url_for_node {
  my ($base, $path) = @_;
  $base //= '';
  $base =~ s{/\z}{};
  $base =~ s{/v1\z}{};
  return $base . $path;
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

version 0.004

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

No Skeid credential is needed on these unless the config has a C<client_auth> section; then
every one but C</health> answers C<401> to a key not on its list. See L</Customer identity>.
The MCP routes exist only with an C<mcp> section and always need a key; see L</MCP routes>.

  GET  /health                     {status: ok, proxy: skeid, config_reload: {...},
                                    customer_source: {...} with a customer_source}
  GET  /.well-known/langertha.json provider manifest for the presented key
  GET  /v1/models                  OpenAI: node models and alias names, once each
  POST /v1/chat/completions        OpenAI chat; a stream is relayed byte for byte
  POST /v1/embeddings              OpenAI embeddings
  POST /v1/audio/transcriptions    OpenAI audio: multipart upload, relayed as the node answers
  POST /v1/audio/translations      the same, to the node's translations endpoint
  POST /v1/rerank                  rerank: relayed as the node answers, translated for a TEI node
  GET  /v1/realtime                realtime transcription: a WebSocket relayed as a session
  POST /rerank                     the same route under its other name
  POST /v1/messages                Anthropic Messages, streamed or not
  POST /api/chat                   Ollama chat; streams unless "stream": false
  POST /api/generate               Ollama generate; streams unless "stream": false
  GET  /api/tags                   Ollama: the same names as /v1/models
  GET  /api/ps                     Ollama: always an empty list
  GET  /openapi.json               OpenAPI 3.1 description of the routes this config enables
  GET  /docs                       Swagger UI; only with openapi.swagger_ui, else 404
  GET  /v1/mcp/servers             the MCP servers assigned to the presented key
  ANY  /mcp/:name                  POST, GET, DELETE: relayed to that MCP server
  ANY  /mcp/:name/*path            the same, to a sub-path of it

C</health> stays C<ok> while a config reload is failing -- the proxy serves under the config it
kept -- and shows the reload state without its message. Likewise a failing customer source
(L<Langertha::Skeid/customer_source>): C<customer_source> carries C<ok>, and C<failed_at> and
C<failures> while it fails, never the message. C</v1/models> and C</api/tags> list the
node models and the alias names, each once, so a client can discover what it may put in
C<model>. The list follows the policy of the key presented (no key: the default policy): a name
the key's C<models> do not grant, an alias with every tier denied and a model only denied nodes
serve are left out. Unhealthy nodes are included. A node without a C<model> is not listed -- it matches any
requested name, so no name reaches it in particular. The manifest route answers C<404> unless
the config enables it, C<401> without a key and C<403> for a key without a grant; see
L<Langertha::Skeid/Provider Manifest>.

=head2 Audio routes

C</v1/audio/transcriptions> and C</v1/audio/translations> take OpenAI's C<multipart/form-data>
upload -- C<file>, C<model> and whatever else the client sends -- and relay it to
C<{node url}/audio/transcriptions> or C</audio/translations>, the endpoint vLLM (Whisper) and
speaches both serve. Nothing is translated in either direction (ADR 0021): there is one dialect
for the request, and the answer is the node's own. What Skeid knows of that wire is in
L<Langertha::Skeid::Protocol::Audio>.

The request is routed like a chat request -- by the form's C<model> field, through aliases,
tiers, the key's policy, eligibility and admission -- and the form goes upstream part for part:
each part with its own headers and content, in the client's order, under the client's boundary.
Fields Skeid does not know and fields that repeat (C<timestamp_granularities[]>) pass through.
One part is rewritten: C<model>, when an alias tier serves another model than the one asked
for. The upload itself is never copied: the server spools a part above 256 KiB to a temporary
file, and the upstream request is sent from that file. The client's C<Expect> header is not
passed on.

Skeid reads two fields. C<model> has to be there exactly once, as a non-empty value of at most
1024 bytes; anything else is a C<400> before a node is touched -- with two, Skeid would route by
one while the node may serve the other. C<stream> picks the relay: the last one in the form
decides, and it is on for C<true>, C<1>, C<on>, C<yes>, C<t> and C<y> in any case, which is what
the nodes read as true. A part's name is taken from its C<Content-Disposition> however it is
written (quoted or bare, any case); a name in the extended C<name*> notation is refused.

The answer comes back as the node gave it -- its status, its headers but for the framing ones,
its body untouched: JSON, C<verbose_json>, plain C<text>, C<srt>, C<vtt>. A stream is relayed byte for byte like a chat stream, in whichever
event dialect the node speaks -- OpenAI's and speaches' C<transcript.text.delta> /
C<transcript.text.done>, or vLLM's C<transcription.chunk> frames ending in C<[DONE]> -- and
nothing is added to the form to make the node report usage: a vLLM node sends its usage frame
when the client's form carries C<stream_include_usage=true>.

The usage event has C<api_format> C<openai> and the route as its C<endpoint>. Tokens are
recorded when the node reports them (OpenAI's C<usage.type: tokens>, vLLM's stream usage
frame); C<audio_seconds> when it reports a duration -- C<usage.seconds> of a C<usage.type:
duration> block, else the top-level C<duration> of a C<verbose_json> answer; a streamed request
also has C<content_bytes>, the UTF-8 bytes of the text relayed. A node that reports neither
count leaves an event with a status and a duration and no C<audio_seconds> key: not measured,
which is not zero. See L<Langertha::Skeid/Pluggable Usage Storage>.

=head2 Realtime route

C<GET /v1/realtime?model=E<lt>nameE<gt>> upgraded to a WebSocket is live transcription over
OpenAI's realtime protocol: the client sends C<input_audio_buffer.append> frames and gets
C<conversation.item.input_audio_transcription.delta> and C<.completed> events. Skeid relays the
frames to C<{node url}/realtime> and back in the node's own events (ADR 0029, ADR 0021): nothing is
translated, so the beta C<transcription_session.update> and the GA C<session.update> both go
through as the client speaks them. What Skeid knows of that wire is in
L<Langertha::Skeid::Protocol::Realtime>; the session itself is
L<Langertha::Skeid::Proxy::Realtime>.

B<The handshake is a request.> Everything that can refuse a session answers as plain HTTP before
a socket exists: C<401> from C<client_auth>, C<400> without exactly one C<model> in the query
(C<intent=transcription> alone names none), C<403> from the key's policy, C<503> for a model no
node serves, C<429> after the route wait. Then Skeid resolves the node's key and opens the node's
WebSocket B<first>; the client is upgraded only when the node accepted, so a node that refuses is
a C<502> (and its slot is given back), never a socket that was accepted and closed. A client
that leaves meanwhile gives its slot back as well. The node is called with its own key and with
none of the client's C<Sec-WebSocket-*> headers, C<Origin> or cookies.

B<A key from a browser.> A page cannot set C<Authorization> on a WebSocket. On this route, and
only when neither C<Authorization> nor C<x-api-key> is present, the key is read from the
C<Sec-WebSocket-Protocol> entry C<openai-insecure-api-key.E<lt>keyE<gt>> and goes through the same
client gate, so a key that is not allowed is a C<401> before the upgrade. It is never answered:
the subprotocol Skeid selects is C<realtime> (or none), and it is neither logged nor forwarded.

B<The model of a session is the handshake's.> Every client text frame is JSON-decoded -- never
tested by substring, since the node decodes it again and JSON spells one text many ways. Each
string C<model> in it is compared with the session's: the same one is rewritten to the served
model (an alias tier), any other is B<not forwarded> -- the client gets an C<error> event and the
session goes on, on the model it started with. What goes to the node is the decoded document,
encoded again. A frame that is not a JSON object, and any binary frame, closes the session
C<1003>.

B<A session is one slot and one usage event.> The slot is taken at the handshake and given back
exactly once when the session ends -- from either side, from a limit or from a graceful stop --
so C<max_conns> of a realtime node counts concurrent sessions; give it a node of its own, with
C<max_conns> at least the worker count, since every prefork worker admits its share and keeps the
sessions it accepted (ADR 0010). One usage event is written when the session closes: C<endpoint>
C</v1/realtime>, C<duration_ms> the session's length, the C<usage> blocks of its completed
transcriptions summed and priced, C<audio_seconds> where a block is a duration, C<content_bytes>
the text relayed, and a status: C<200> for a close from either side (any code), C<499> for a
client that vanished without a close frame, C<502> for a node that closed with an error or died,
C<413> for a message above C<realtime.max_message_bytes>, C<400> for a frame a session cannot
carry. A count the node never reported is absent, not zero.

B<Bounds.> The C<realtime> section of the config (L<Langertha::Skeid/realtime>): a message above
C<max_message_bytes> closes C<1009>, bytes a peer does not read past C<max_queued_bytes> close
C<1013>, silence for C<idle_timeout> seconds and C<max_session_seconds> of age close C<1000> with
a reason. On a graceful stop (C<SIGQUIT>, the event loop's C<finish>) every open session is closed
C<1001> and its event written before the process exits.

=head2 Rerank route

C</v1/rerank> and C</rerank> are one route. It takes the request shape Cohere set and vLLM, Jina
and infinity took over -- C<model>, C<query>, C<documents>, optionally C<top_n>,
C<return_documents> and whatever else the node understands -- and answers with the node's
C<results>. It is not a streamed route.

Four things are checked before a node is picked, each a C<400> that costs no slot and no usage
event: the body is a JSON object, C<model> is a non-empty string, C<query> is a string,
C<documents> is a non-empty array. What a document may be is left to the node. The request is
then routed like a chat request -- by C<model>, through aliases, tiers, the key's policy,
eligibility and admission.

By default the request is B<relayed> (ADR 0021): it goes to C<{node url}/rerank> with every
field as the client sent it and C<model> replaced by the served model, and the node's answer
comes back as it is -- status, headers but for the framing ones, body byte for byte. That
covers vLLM, infinity started with C<--url-prefix /v1>, Jina and Cohere, and Skeid does not
even out what differs between them: C<document> is C<{ "text": ... }> on vLLM and Cohere and a
plain string on infinity, and vLLM returns the documents whether C<return_documents> asked for
them or not. The body is decoded and written again on the way, so the node sees exactly one
C<model> -- the one Skeid routed by.

A node with C<rerank_format: tei> (L<Langertha::Skeid/nodes>) is Hugging Face
text-embeddings-inference, which speaks another dialect, and is B<translated> in both
directions. The request goes to C</rerank> at the server root -- the node's URL with or without
a trailing C</v1> -- as C<query>, C<texts> (each document a string, or an object's string
C<text>), C<return_text> for C<return_documents> and C<truncate> when the client sent them, and
nothing else. TEI's bare array becomes C<< { model, results, usage } >>: C<model> the served
model, C<results> sorted by score with C<relevance_score> and, when C<return_documents> asked
for it, C<< document => { text } >>, cut to C<top_n>; C<usage.total_tokens> from TEI's
C<x-compute-tokens> header when it sent one. A request such a node cannot take -- a document
that is not text, a C<top_n> that is not a whole number of at least zero -- is a C<400> as
well, but one known only after the node was admitted: the slot is given back, and one failed
usage event is written. An answer that is not TEI's array is a C<500> C<api_error>, as for
any translation that fails. The wire of both dialects is L<Langertha::Skeid::Protocol::Rerank>'s.

The usage event has C<api_format> C<openai> and C<endpoint> C</v1/rerank> for both spellings.
C<documents> is the number of documents the request carried, on the event of a request the
node answered and on no other. The node's tokens are recorded as B<input> tokens and as the
total, so the model's C<input_per_million> prices them, from wherever that node reports them:
C<usage.prompt_tokens>, else C<usage.total_tokens>, else Cohere's C<meta.tokens.input_tokens>,
or a TEI node's C<x-compute-tokens>. A node that reports none leaves an event without tokens.
infinity counts characters unless it runs with C<lengths_via_tokenize>; Skeid records what the
node says. See L<Langertha::Skeid/Pluggable Usage Storage>.

=head2 Documents routes

C<POST /v1/convert/file> and C<POST /v1/convert/source> are the synchronous calls of docling-serve
under its own paths (skeid k94, ADR 0028), so a docling client only changes its base URL. They
are relayed like the audio routes: the multipart form goes upstream part for part, a source body
(JSON, files as base64) is decoded once and written again, and the node's answer -- JSON, or a
zip when several documents or outputs come back -- is relayed byte for byte, whatever its
status. The asynchronous calls are not offered.

The request has no C<model>. It is planned over the nodes of C<kind: documents>
(L<Langertha::Skeid/nodes>) under the routing key C<documents>: a key whose policy lists C<models>
must list C<documents> or is answered C<403>; an alias named C<documents> tiers the nodes by
tags; chat requests never reach these nodes and these never reach chat nodes, and C</v1/models>
lists none of it. Before a node is chosen, a request that makes the node fetch from or call an
address the client names -- C<http_sources>, C<callbacks>, a C<target> that is not C<inbody> or
C<zip>, a C<sources> entry that is not a file, in any spelling, named twice or not -- is a C<400>
that names the field and costs no slot and no event, unless C<documents.allow_remote_sources>.

The body limit is C<uploads.documents_max_bytes> (default 100 MiB), applied as for audio before
the body is read: C<413>, or C<401> for a caller C<client_auth> refuses. A form is spooled to disk
and sent from there; a source body is decoded in memory, once, which is CPU on the event loop
proportional to its size -- big files belong to C</v1/convert/file>. The node's key goes in the
header its C<api_key_header> names (C<X-Api-Key> for docling-serve), the client's credentials are
dropped. The wait for a conversion is the upstream timeout, unchanged.

The event has C<api_format> C<docling>, C<model> C<documents>, C<documents> (files or sources the
request held, on a request the node answered) and C<pages>, read off
C<document.json_content.pages> of a JSON answer up to 8 MiB -- nothing is decoded beyond that, a
zip is not decoded at all, and an answer without a page count leaves C<pages> out. No tokens,
nothing priced. See L<Langertha::Skeid::Protocol::Documents>.

=head2 MCP routes

The MCP gateway (skeid k103, ADR 0022): a customer reaches the MCP servers the config assigned
to its key (L<Langertha::Skeid/mcp>) with that key, one route per server. Skeid relays MCP's
Streamable HTTP transport and reads none of it -- no JSON-RPC, no tool list, no session. What it
knows of the wire is in L<Langertha::Skeid::Protocol::MCP>.

Both routes sit behind one check, in this order. Without an C<mcp> section they are unknown
paths and answer as one, C<404>, whatever the caller presents. Then client authentication, as
on every client route (L</Customer identity>). Then a key at all: no key is C<401> C<Missing
API key> also while C<client_auth> is off, because a server is assigned to a key id and no key
has none. The identity is the one every route uses, C<routing.trust_key_id_header> included.

C<GET /v1/mcp/servers> lists the servers assigned to the presented key, sorted by name:

  { "object": "list", "data": [
    { "name": "bookrag", "transport": "streamable-http",
      "url": "https://llm.example.com/mcp/bookrag", "description": "..." },
    { "name": "files", "transport": "stdio", "command": "mcp-files",
      "args": ["--root", "/srv/data"], "env": {}, "description": "..." } ] }

C<url> is C<mcp.public_url> (else the scheme and host of this request) plus C</mcp/E<lt>nameE<gt>>.
A C<stdio> entry is a hint for a server on the customer's own machine. The upstream URL, the
key reference, the variable name and the static headers are never in it. A key with no
assignment gets an empty list. The answer is C<Cache-Control: private, no-store>.

C<POST>, C<GET> and C<DELETE> on C</mcp/E<lt>nameE<gt>> are relayed to the server's C<url>; a
path after the name is appended to it segment by segment, and the client's query to its query.
Everything that is not a relayed server of the presented key is the same C<404> C<not_found>: an
unknown name, a server assigned to another key, a C<stdio> entry, a sub-path with a C<.> or
C<..> segment or a backslash. A key cannot tell which names exist.

Upstream go the method, the body as the bytes it came in, and of the client's headers
C<Content-Type>, C<Accept>, C<Last-Event-ID> and every C<Mcp-*> header (C<Mcp-Session-Id>,
C<Mcp-Protocol-Version>) -- nothing else, so never the client's C<Authorization>, C<X-Api-Key> or
cookies. Then the server's static C<headers>, and C<Authorization: Bearer> with the server's
own key when it names a key source. A server that names one which yields no key is not called:
C<503> C<upstream_key_unavailable>, logged with the key reference.

The answer comes back as the server gave it: its status, its headers but for the hop-by-hop
ones, C<Content-Length> and C<Content-Encoding>, and its body. The response is opened when the
upstream's headers arrive, before any body byte, and every chunk is written as it is read, so
an event stream (C<text/event-stream>) is not buffered and a standing C<GET> stream is open for
the client before its first event. An answer without a body (C<202>, C<204>) is relayed as one.
The upstream's own C<4xx> and C<5xx> are relayed too -- a C<404> for an expired session has to
reach the client -- with two exceptions, both answered C<502> C<upstream_error> and logged. An
upstream C<401>, because towards the client C<401> means its Skeid key was not let in, while the
upstream's is about the key Skeid presented. And a redirect (C<3xx>): its C<Location> is an
upstream URL, and Skeid follows none -- configure the URL it leads to, a trailing slash
included. A server that cannot be reached is C<502>
C<upstream_error>; a request body over the server's request limit is C<413>.

The upstream call runs under the upstream timeout of L</build_app> (C<SKEID_UPSTREAM_TIMEOUT>),
and the client's connection is given the same time: a standing stream is cut after it, and an
MCP client reconnects with C<Last-Event-ID>. A client that hangs up closes the upstream
connection. There is no routing and no admission -- an MCP server is not a node: no
C<max_conns>, no health, no capacity probe.

Each relayed request writes one usage event with C<api_format> C<mcp>, C</mcp/E<lt>nameE<gt>> as
its C<endpoint> (without the sub-path), the customer key id, the server's C<url> as
C<route_url>, the status and the duration; no model, node, tokens or cost. C<ok> is the status
below 500. A refusal for want of an upstream key is a C<503> event, an upstream C<401> a C<502>
event with C<error_type> C<upstream_unauthorized>, a redirect one with C<upstream_redirect>, an
unreachable server a C<502> event. A
client that leaves before a plain answer is complete is the C<499> C<client_abort> of every
route; an event stream that was opened is recorded under its status however it ends, since
closing it is how such a stream ends. C<401> and C<404> write nothing.

=head2 Uploads

The audio routes are the upload routes: their request limit is the config's
C<uploads.max_bytes> (L<Langertha::Skeid/uploads>, default 26214400), not the server's own
(Mojolicious' 16 MiB, which every other route keeps). A larger body is answered C<413> in the
OpenAI error shape, with no node touched and no usage event.

The limit is applied when the request's head has arrived, before its body is read. A request
that declares a larger C<Content-Length> is answered at once and its connection closed; a body
of undeclared length (chunked) is cut off once it is 1 MiB past the limit, and measured exactly
if it ends before that. With C<client_auth>, a caller the list does not let in is cut off the
same way -- its C<401> does not wait for, or store, the upload. The limit is read per request,
so a changed C<uploads.max_bytes> holds from the next one.

A client that sends C<Expect: 100-continue> (curl does, above 1 MiB) gets no C<100 Continue>:
the server underneath does not send one. It gets a C<401> or C<413> right away, and otherwise
sends the body after its own timeout.

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
  GET  /skeid/config               {reload}: the config reload status, with its message;
                                   {customer_source}: the customer source status, with its message;
                                   {customer_names}: customer key id => name of the source's rows;
                                   {customer_report}: rows accepted, rejected, shadowed (labels, reasons)
  GET  /skeid/metrics/nodes        {metrics}: per-node counters, never billed
  GET  /skeid/usage                ?since=&api_key_id=&model=&limit= (default 50) -> the report
  GET  /skeid/openapi.json         OpenAPI 3.1 description of the admin routes

Changes made here live in this process only: a changed C<nodes> section in the config replaces
them, and under C<--workers> each write reaches one worker (ADR 0010).

=head2 Customer identity

Skeid does not authenticate customers unless the config has a C<client_auth> section
(L<Langertha::Skeid/client_auth>). The key a client presents (C<Authorization: Bearer>, else
C<x-api-key>) derives the customer key id (L<Langertha::Skeid/key_id_for_key>; no key is
C<anonymous>), which selects the routing policy and is recorded on the usage event. With
C<routing.trust_key_id_header> a C<x-skeid-key-id> (or C<x-api-key-id>) header names the key id
instead.

With C<client_auth>, that key id has to be on the section's list. Every client route checks it
first -- C</v1/models>, C</v1/chat/completions>, C</v1/embeddings>, the C</v1/audio/*> routes,
C</v1/rerank> and C</rerank>, C</v1/messages>, every C</api/*> route, C</.well-known/langertha.json> and,
with an C<mcp> section, the MCP routes -- after picking up a
changed config
(L<Langertha::Skeid/maybe_reload_config>), so a list change holds from the next request.
No key is C<401> C<Missing API key>, a key whose id is not listed C<401> C<Invalid API key>,
both with C<WWW-Authenticate: Bearer realm="skeid">, and nothing else happens for that request:
the body is not parsed, no node is admitted or called, no usage event is written, and Skeid logs
nothing about it. The answer names neither the key nor its id. C</health> and the C</skeid/*> routes are not checked;
they have their own rules. Being let in widens nothing: the key's routing policy still applies.

=head2 The upstream call

The node URL gets C</v1> added unless it ends in it, then C</chat/completions> or
C</embeddings> (an audio route: C</audio/transcriptions> or C</audio/translations>, see
L</Audio routes>; rerank: C</rerank>, for a TEI node without the C</v1>, see L</Rerank route>);
the body carries the served model (an alias tier's C<model>), everything else
as the client sent it or as translated. The client's headers go upstream except the hop-by-hop
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
error (and a request the node refused as the client's own fault, 400, 404, 413 or 422, is marked C<rejected>
and counted apart the same way, ADR 0024), so the node's error counter and the registry snapshot's C<errors_in_window> stay untouched --
and the one usage event is written with C<ok = 0>, C<status_code> 499 and C<error_type>
C<client_abort>, priced from the usage the stream had reported until then (nothing, for a
request that was not streamed). A client that leaves while the node's key is still being
resolved gives its slot back too, but nothing was forwarded, so no usage event is written.
When the node had already finished and only the rest of the answer was still being written
out, the request stays what it was: finished and metered by the node's answer.

=head2 Errors

A key the C<client_auth> list does not let in is C<401> (OpenAI: type C<invalid_request_error>,
code C<invalid_api_key>; Anthropic: C<authentication_error>; see L</Customer identity>). An
upload over C<uploads.max_bytes> is C<413 invalid_request_error>; an audio request that is not a
multipart form, or whose form has no usable C<model> field, is C<400 invalid_request_error>, as
is a rerank request without a C<model>, a string C<query> or C<documents>. A
request no node may serve for this key is C<403 permission_error>; a model no healthy node
serves is C<503 model_not_found>; eligible nodes that stay full past the wait are
C<429 rate_limit_error>; an upstream failure is its status (or C<502>) with type
C<upstream_error>; a node whose own key cannot be resolved is
C<503 upstream_key_unavailable>, logged with the key reference and recorded as a failed usage
event. The body is shaped for the face that was called: OpenAI's
C<{error: {message, type}}>, Anthropic's envelope
(L<Langertha::Skeid::Protocol::Anthropic/error_body>) on C</v1/messages>, and Ollama's
C<{error: "..."}> on C</api/*>. A stream that fails after it opened ends with the face's in-band
error event where it has one.

The MCP routes answer their own errors in the OpenAI shape: C<401> without a key, C<404>
C<not_found> for whatever is not a relayed server of the presented key, C<413> for a body over
the request limit, C<502> C<upstream_error> for a server that is unreachable, answers C<401> or
redirects, C<503> C<upstream_key_unavailable> for one whose key is missing. Every other status
on C</mcp/E<lt>nameE<gt>> is the MCP server's own, body included; see L</MCP routes>.

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

=item * C<swagger_ui> -- a L<Langertha::Skeid::SwaggerUI> object to serve C</docs> from; a
test passes one with an injected fetcher so nothing reaches the network. Default: one that
fetches the pinned release.

=back

The Skeid's L<Langertha::Skeid/on_usage_lost> is set to this app's C<usage event lost> log line,
so a usage event a write-behind store could not write is logged like one whose synchronous write
failed. An embedding application that wants its own hook sets it after C<build_app>.

With both C<OPENBAO_ROLE_ID> and C<OPENBAO_SECRET_ID> set, a
L<Langertha::Skeid::KeyBroker::OpenBao> at C<OPENBAO_ADDR> (default C<http://127.0.0.1:8200>)
becomes the key broker; if its login fails the proxy warns and runs without one. A broker that
can renew its token starts renewing on a timer. The capacity probes of every node are started
and restarted whenever the probed part of the inventory changes, and the customer source of the
config, if it has one, starts fetching (L<Langertha::Skeid/start_customer_source>).

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

=head2 route_table

  my @entries = Langertha::Skeid::Proxy->route_table;

Every route the app registers, as one entry each -- the single source of the router and of the
OpenAPI documents (ADR 0025). An entry is a hashref:

=over 4

=item * C<id>, C<group> (the bridge it sits behind), C<methods>, C<paths> (Mojolicious
patterns), C<handler> (a coderef taking the controller)

=item * C<document>: C<client> or C<admin> for the OpenAPI document that lists it, absent for a
route no document lists (the UI)

=item * C<requires>: C<manifest>, C<mcp> or C<registry> -- the config section that has to be on
for the route to be listed

=item * C<websocket>: the route is registered as a WebSocket route (only an upgrade request
reaches it) and documented with a C<101>; C<query> lists the query parameters the document names
(C<name>, C<required>, C<description>)

=item * C<tag>, C<summary>, C<description>, C<request>, C<request_type>, C<response>,
C<stream>, C<public>: what the document says about it

=back

A route added to the app any other way has no entry; the test suite fails on it.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid> -- the control plane and its configuration

=item * L<skeid> -- the command that runs this app

=item * L<Langertha::Skeid::Protocol::Anthropic>, L<Langertha::Skeid::Protocol::Ollama> -- the
translated faces

=item * L<Langertha::Skeid::Protocol::Audio> -- the wire of the relayed audio routes

=item * L<Langertha::Skeid::Protocol::Rerank> -- the wire of the rerank route, and its TEI dialect

=item * L<Langertha::Skeid::Protocol::Realtime>, L<Langertha::Skeid::Proxy::Realtime> -- the wire
and the session of the realtime route

=item * L<Langertha::Skeid::Protocol::MCP> -- the wire of the MCP gateway

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
