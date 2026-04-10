package Langertha::Skeid::Proxy;
our $VERSION = '0.002';
# ABSTRACT: Multi-format LLM proxy (OpenAI, Anthropic, Ollama) powered by Langertha::Skeid routing
use strict;
use warnings;
use Mojolicious;
use Mojo::IOLoop;
use Time::HiRes qw(time usleep);
use POSIX qw(strftime);
use JSON::MaybeXS qw(encode_json decode_json);
use Digest::SHA qw(sha1_hex);
use Langertha::Skeid;
use Langertha::Tool;
use Langertha::ToolCall;
use Langertha::ToolChoice;

sub build_app {
  my ($class, %opts) = @_;
  my $skeid = $opts{skeid} || Langertha::Skeid->new(
    ($opts{config_file} ? (config_file => $opts{config_file}) : ()),
  );
  if (exists $opts{admin_api_key}) {
    $skeid->admin_api_key(defined($opts{admin_api_key}) ? $opts{admin_api_key} : '');
  }

  my $app = Mojolicious->new;
  $app->secrets(['skeid-proxy']);
  $app->ua->connect_timeout(10);
  $app->ua->request_timeout(300);
  $app->helper(skeid => sub { $skeid });

  my $r = $app->routes;

  $r->get('/health' => sub {
    my ($c) = @_;
    $c->render(json => { status => 'ok', proxy => 'skeid' });
  });

  # OpenAI format
  $r->get('/v1/models' => sub {
    my ($c) = @_;
    my %seen;
    my @data;
    for my $n (@{$c->skeid->list_nodes}) {
      my $id = $n->{model};
      next unless defined $id && length $id;
      next if $seen{$id}++;
      push @data, {
        id       => $id,
        object   => 'model',
        created  => int(time),
        owned_by => 'skeid',
      };
    }
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
    _handle_anthropic_messages($c);
  });

  # Ollama format
  $r->post('/api/chat' => sub {
    my ($c) = @_;
    _handle_ollama_chat($c);
  });

  $r->get('/api/tags' => sub {
    my ($c) = @_;
    my @models = map {
      +{
        name       => ($_->{model} // $_->{id}),
        model      => ($_->{model} // $_->{id}),
        modified_at => _iso8601_now(),
        size       => 0,
        digest     => '',
        details    => {
          family             => ($_->{engine} || 'openaibase'),
          parameter_size     => 'unknown',
          quantization_level => 'unknown',
        },
      }
    } @{$c->skeid->list_nodes};

    $c->render(json => { models => \@models });
  });

  $r->get('/api/ps' => sub {
    my ($c) = @_;
    $c->render(json => { models => [] });
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
  if (!defined($scheme) || lc($scheme) ne 'bearer' || !defined($token) || $token ne $admin_api_key) {
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

sub _handle_openai_chat {
  my ($c) = @_;
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    $c->render(json => { error => { message => 'Invalid JSON body', type => 'invalid_request_error' } }, status => 400);
    return;
  }

  my $model = $body->{model} // '';
  my $api_key_id = _request_api_key_id($c);
  _begin_route_async($c, $model, sub {
    my ($route, $node_id, $started) = @_;
    return unless $route;

    my $url = _endpoint_url_for_node($route->{url}, '/chat/completions');
    my $meta = {
      api_format => 'openai',
      endpoint   => '/v1/chat/completions',
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model      => $model,
      route_url  => ($route->{url} // ''),
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
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    $c->render(json => { error => { message => 'Invalid JSON body', type => 'invalid_request_error' } }, status => 400);
    return;
  }

  my $model = $body->{model} // '';
  my $api_key_id = _request_api_key_id($c);
  _begin_route_async($c, $model, sub {
    my ($route, $node_id, $started) = @_;
    return unless $route;

    my $url = _endpoint_url_for_node($route->{url}, '/embeddings');
    my $meta = {
      api_format => 'openai',
      endpoint   => '/v1/embeddings',
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model      => $model,
      route_url  => ($route->{url} // ''),
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
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    $c->render(json => { error => { message => 'Invalid JSON body', type => 'invalid_request_error' } }, status => 400);
    return;
  }

  if ($body->{stream}) {
    $c->render(json => {
      error => {
        message => 'Anthropic streaming is not implemented in Skeid proxy yet',
        type    => 'not_supported_error',
      }
    }, status => 501);
    return;
  }

  my $openai_body = _anthropic_request_to_openai($body);
  my $model = $openai_body->{model} // '';
  my $api_key_id = _request_api_key_id($c);

  _begin_route_async($c, $model, sub {
    my ($route, $node_id, $started) = @_;
    return unless $route;

    my $url = _endpoint_url_for_node($route->{url}, '/chat/completions');
    my $meta = {
      api_format => 'anthropic',
      endpoint   => '/v1/messages',
      api_key_id => $api_key_id,
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model      => $model,
      route_url  => ($route->{url} // ''),
    };
    $c->render_later;
    _proxy_openai_json_async($c, $url, $openai_body, $node_id, $started, $meta, sub {
      my ($res, $err, $status) = @_;
      return if $err;

      my $payload = _openai_response_to_anthropic($res, $model);
      $c->res->code($status || 200);
      $c->res->headers->header('x-skeid-node' => $node_id);
      $c->render(json => $payload);
    });
  });
}

sub _handle_ollama_chat {
  my ($c) = @_;
  my $body = $c->req->json;
  unless (ref($body) eq 'HASH') {
    $c->render(json => { error => 'Invalid JSON body' }, status => 400);
    return;
  }

  if ($body->{stream}) {
    $c->render(json => { error => 'Ollama streaming is not implemented in Skeid proxy yet' }, status => 501);
    return;
  }

  my $openai_body = {
    model => ($body->{model} // ''),
    messages => ($body->{messages} || []),
    (defined($body->{options}{temperature}) ? (temperature => 0 + $body->{options}{temperature}) : ()),
    (defined($body->{options}{num_predict})  ? (max_tokens  => 0 + $body->{options}{num_predict})  : ()),
    (defined($body->{tools}) ? (tools => $body->{tools}) : ()),
    (defined($body->{tool_choice}) ? (tool_choice => $body->{tool_choice}) : ()),
  };

  _begin_route_async($c, $openai_body->{model}, sub {
    my ($route, $node_id, $started) = @_;
    return unless $route;

    my $url = _endpoint_url_for_node($route->{url}, '/chat/completions');
    my $meta = {
      api_format => 'ollama',
      endpoint   => '/api/chat',
      api_key_id => _request_api_key_id($c),
      provider   => 'skeid',
      engine     => ($route->{engine} // 'openaibase'),
      model      => ($openai_body->{model} // ''),
      route_url  => ($route->{url} // ''),
    };
    $c->render_later;
    _proxy_openai_json_async($c, $url, $openai_body, $node_id, $started, $meta, sub {
      my ($res, $err, $status) = @_;
      return if $err;

      my $payload = _openai_response_to_ollama_chat($res);
      $c->res->code($status || 200);
      $c->res->headers->header('x-skeid-node' => $node_id);
      $c->render(json => $payload);
    });
  });
}

sub _begin_route {
  my ($c, $model) = @_;
  my $wait_timeout_ms = 0 + ($c->skeid->route_wait_timeout_ms // 0);
  my $wait_poll_ms = 0 + ($c->skeid->route_wait_poll_ms // 25);
  $wait_poll_ms = 1 if $wait_poll_ms < 1;
  $wait_timeout_ms = 0 if $wait_timeout_ms < 0;

  my $started = time;
  my $deadline = $started + ($wait_timeout_ms / 1000);
  my $last_state;
  my $last_node_id = '';

  while (1) {
    my $state = $c->skeid->call_function('route.state', { model => ($model // '') });
    $last_state = $state if ref($state) eq 'HASH';

    # Wrong model / no healthy nodes for this model: fail fast.
    if (!$last_state || !$last_state->{has_eligible}) {
      $c->render(json => {
        error => {
          message => "No healthy node available for model '$model'",
          type    => 'model_not_found',
        }
      }, status => 503);
      return;
    }

    my $route = $c->skeid->call_function('route.next', { model => ($model // '') })->{node};
    if ($route && ref($route) eq 'HASH') {
      my $node_id = $route->{id};
      $last_node_id = $node_id if defined $node_id;
      my $started_ok = $c->skeid->call_function('request.start', { id => $node_id })->{ok};
      return ($route, $node_id, $started) if $started_ok;
    }

    my $now = time;
    last if $now >= $deadline;
    usleep($wait_poll_ms * 1000);
  }

  my $waited_ms = int((time - $started) * 1000);
  $waited_ms = $wait_timeout_ms if $waited_ms < $wait_timeout_ms && $wait_timeout_ms > 0;
  my $msg = length($last_node_id)
    ? "Timed out waiting for free capacity on node '$last_node_id' (waited ${waited_ms}ms)"
    : "Timed out waiting for free capacity for model '$model' (waited ${waited_ms}ms)";
  $c->render(json => {
    error => {
      message => $msg,
      type    => 'rate_limit_error',
    }
  }, status => 429);
  return;
}

sub _begin_route_async {
  my ($c, $model, $cb) = @_;
  $cb ||= sub { };
  my $wait_timeout_ms = 0 + ($c->skeid->route_wait_timeout_ms // 0);
  my $wait_poll_ms = 0 + ($c->skeid->route_wait_poll_ms // 25);
  $wait_poll_ms = 1 if $wait_poll_ms < 1;
  $wait_timeout_ms = 0 if $wait_timeout_ms < 0;

  my $started = time;
  my $deadline = $started + ($wait_timeout_ms / 1000);
  my $last_state;
  my $last_node_id = '';

  my $tick;
  $tick = sub {
    my $state = $c->skeid->call_function('route.state', { model => ($model // '') });
    $last_state = $state if ref($state) eq 'HASH';

    # Wrong model / no healthy nodes for this model: fail fast.
    if (!$last_state || !$last_state->{has_eligible}) {
      $c->render(json => {
        error => {
          message => "No healthy node available for model '$model'",
          type    => 'model_not_found',
        }
      }, status => 503);
      $cb->();
      return;
    }

    my $route = $c->skeid->call_function('route.next', { model => ($model // '') })->{node};
    if ($route && ref($route) eq 'HASH') {
      my $node_id = $route->{id};
      $last_node_id = $node_id if defined $node_id;
      my $started_ok = $c->skeid->call_function('request.start', { id => $node_id })->{ok};
      if ($started_ok) {
        $cb->($route, $node_id, $started);
        return;
      }
    }

    my $now = time;
    if ($now >= $deadline) {
      my $waited_ms = int((time - $started) * 1000);
      $waited_ms = $wait_timeout_ms if $waited_ms < $wait_timeout_ms && $wait_timeout_ms > 0;
      my $msg = length($last_node_id)
        ? "Timed out waiting for free capacity on node '$last_node_id' (waited ${waited_ms}ms)"
        : "Timed out waiting for free capacity for model '$model' (waited ${waited_ms}ms)";
      $c->render(json => {
        error => {
          message => $msg,
          type    => 'rate_limit_error',
        }
      }, status => 429);
      $cb->();
      return;
    }

    Mojo::IOLoop->timer($wait_poll_ms / 1000, $tick);
  };

  $tick->();
  return;
}

sub _proxy_openai_json {
  my ($c, $url, $body, $node_id, $started, $meta) = @_;
  $meta ||= {};

  my %fwd_headers = _forward_headers($c);
  _inject_node_auth(\%fwd_headers, $c->skeid, $node_id);
  my $tx = $c->app->ua->build_tx(POST => $url, \%fwd_headers, json => $body);
  my $done = $c->app->ua->start($tx);
  my $duration_ms = _duration_ms($started);

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
    $c->render(json => {
      error => {
        message => 'Upstream error: ' . ($err->{message} // 'unknown'),
        type    => 'upstream_error',
      }
    }, status => ($err->{code} || 502));
    return (undef, 1, ($err->{code} || 502));
  }

  my $res = $done->res;
  my $status = $res->code // 200;

  $c->skeid->call_function('request.finish', {
    id => $node_id,
    ok => ($status < 500) ? 1 : 0,
    duration_ms => $duration_ms,
  });

  my $payload = eval { $res->json };
  my $metrics = {};
  if (ref($payload) eq 'HASH') {
    my $tool_calls = eval { [ map { $_->to_hash } Langertha::ToolCall->extract($payload) ] } || [];
    $metrics = eval {
      $c->skeid->call_function('metrics.normalize', {
        provider    => ($meta->{provider} || 'skeid'),
        engine      => ($meta->{engine} || 'openaibase'),
        model       => ($meta->{model} || ($body->{model} // '')),
        route       => ($meta->{endpoint} || ''),
        duration_ms => $duration_ms,
        response    => $payload,
        tool_calls  => $tool_calls,
      });
    } || {};
  }

  _record_usage_event($c, {
    %$meta,
    node_id      => $node_id,
    status_code  => $status,
    ok           => ($status < 500) ? 1 : 0,
    duration_ms  => $duration_ms,
    metrics      => (ref($metrics) eq 'HASH' ? $metrics : {}),
  });

  return ($res, 0, $status);
}

sub _proxy_openai_json_async {
  my ($c, $url, $body, $node_id, $started, $meta, $cb) = @_;
  $meta ||= {};
  $cb ||= sub { };

  my %fwd_headers = _forward_headers($c);
  _inject_node_auth(\%fwd_headers, $c->skeid, $node_id);
  my $tx = $c->app->ua->build_tx(POST => $url, \%fwd_headers, json => $body);
  $c->app->ua->start($tx => sub {
    my ($ua, $done) = @_;
    my $duration_ms = _duration_ms($started);

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
      $c->render(json => {
        error => {
          message => 'Upstream error: ' . ($err->{message} // 'unknown'),
          type    => 'upstream_error',
        }
      }, status => ($err->{code} || 502));
      $cb->(undef, 1, ($err->{code} || 502));
      return;
    }

    my $res = $done->res;
    my $status = $res->code // 200;

    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => ($status < 500) ? 1 : 0,
      duration_ms => $duration_ms,
    });

    my $payload = eval { $res->json };
    my $metrics = {};
    if (ref($payload) eq 'HASH') {
      my $tool_calls = eval { [ map { $_->to_hash } Langertha::ToolCall->extract($payload) ] } || [];
      $metrics = eval {
        $c->skeid->call_function('metrics.normalize', {
          provider    => ($meta->{provider} || 'skeid'),
          engine      => ($meta->{engine} || 'openaibase'),
          model       => ($meta->{model} || ($body->{model} // '')),
          route       => ($meta->{endpoint} || ''),
          duration_ms => $duration_ms,
          response    => $payload,
          tool_calls  => $tool_calls,
        });
      } || {};
    }

    _record_usage_event($c, {
      %$meta,
      node_id      => $node_id,
      status_code  => $status,
      ok           => ($status < 500) ? 1 : 0,
      duration_ms  => $duration_ms,
      metrics      => (ref($metrics) eq 'HASH' ? $metrics : {}),
    });

    $cb->($res, 0, $status);
  });

  return;
}

sub _proxy_openai_stream {
  my ($c, $url, $body, $node_id, $started, $meta) = @_;
  $meta ||= {};

  my %fwd_headers = _forward_headers($c);
  _inject_node_auth(\%fwd_headers, $c->skeid, $node_id);
  my $tx = $c->app->ua->build_tx(POST => $url, \%fwd_headers, json => $body);

  $c->render_later;
  my $headers_sent = 0;
  my $had_error = 0;
  my $status = 200;

  $tx->res->content->unsubscribe('read')->on(read => sub {
    my ($content, $bytes) = @_;
    unless ($headers_sent) {
      $status = $tx->res->code // 200;
      $c->res->code($status);
      for my $name (@{$tx->res->headers->names}) {
        my $lc = lc($name);
        next if $lc eq 'content-length' || $lc eq 'transfer-encoding' || $lc eq 'content-encoding';
        $c->res->headers->header($name => $tx->res->headers->header($name));
      }
      $c->res->headers->header('x-skeid-node' => $node_id);
      $headers_sent = 1;
    }
    $c->write($bytes);
  });

  $c->app->ua->start($tx => sub {
    my ($ua, $tx_done) = @_;

    if (my $err = $tx_done->error) {
      $had_error = 1;
      unless ($headers_sent) {
        my $duration_ms = _duration_ms($started);
        $c->skeid->call_function('request.finish', {
          id => $node_id,
          ok => 0,
          duration_ms => $duration_ms,
        });
        _record_usage_event($c, {
          %$meta,
          node_id       => $node_id,
          status_code   => 502,
          ok            => 0,
          duration_ms   => $duration_ms,
          error_type    => 'upstream_error',
          error_message => ($err->{message} // 'unknown'),
          metrics       => {},
        });
        $c->render(json => {
          error => {
            message => 'Upstream error: ' . ($err->{message} // 'unknown'),
            type    => 'upstream_error',
          }
        }, status => 502);
        return;
      }
    }

    my $duration_ms = _duration_ms($started);
    $c->skeid->call_function('request.finish', {
      id => $node_id,
      ok => ($had_error || $status >= 500) ? 0 : 1,
      duration_ms => $duration_ms,
    });
    _record_usage_event($c, {
      %$meta,
      node_id      => $node_id,
      status_code  => $status,
      ok           => ($had_error || $status >= 500) ? 0 : 1,
      duration_ms  => $duration_ms,
      metrics      => {},
    });

    $c->finish;
  });
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
  $c->res->body($res->body);
  $c->rendered;
}

sub _forward_headers {
  my ($c) = @_;
  my %fwd_headers;
  for my $name (@{$c->req->headers->names}) {
    my $lc = lc($name);
    next if $lc eq 'host' || $lc eq 'content-length' || $lc eq 'transfer-encoding' || $lc eq 'accept-encoding';
    $fwd_headers{$name} = $c->req->headers->header($name);
  }
  return %fwd_headers;
}

# If the selected node has api_key_env set, inject the key from the
# environment as an Authorization: Bearer header, overriding whatever
# the client sent. Used for per-agent Skeid deployments where the
# provider API key is injected via a K8s Secret env var rather than
# being passed by the caller.
sub _inject_node_auth {
  my ($headers_ref, $skeid, $node_id) = @_;
  my ($node) = grep { ($_->{id} // '') eq $node_id } @{$skeid->nodes};
  return unless $node;

  my $key;

  # 1. KeyBroker with api_key_ref — dynamic resolution
  if ($skeid->has_key_broker && defined(my $ref = $node->{api_key_ref})) {
    my $broker = $skeid->key_broker;
    $broker->refresh if $broker->needs_refresh;
    $key = eval { $broker->resolve_key($ref) };
    warn "KeyBroker resolve failed for '$ref': $@" if $@ && !defined $key;
  }

  # 2. Fallback: env var (existing behavior)
  if (!defined($key) || !length($key)) {
    if (defined(my $env_name = $node->{api_key_env})) {
      $key = $ENV{$env_name} // '';
    }
  }

  return unless defined($key) && length($key);
  $headers_ref->{Authorization} = "Bearer $key";
  delete $headers_ref->{'x-api-key'};
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

sub _request_api_key_id {
  my ($c) = @_;
  my $forced = $c->req->headers->header('x-skeid-key-id')
    // $c->req->headers->header('x-api-key-id');
  return $forced if defined($forced) && length($forced);

  my (undef, $api_key) = _extract_request_api_key($c);
  return 'anonymous' unless defined($api_key) && length($api_key);
  return 'k_' . substr(sha1_hex($api_key), 0, 12);
}

sub _request_id {
  my ($c) = @_;
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
    },
  };

  my $recorded = eval {
    $c->skeid->call_function('usage.record', {
      created_at    => _iso8601_now(),
      request_id    => _request_id($c),
      api_format    => ($args->{api_format} // ''),
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
      metrics       => $safe_metrics,
    });
  };
  if ($@) {
    my $err = "$@";
    $err =~ s/\s+$//;
    $c->app->log->debug("usage.record failed: $err");
    return { ok => 0, error => $err };
  }

  return $recorded;
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

sub _anthropic_request_to_openai {
  my ($body) = @_;
  my @messages;

  if (defined $body->{system}) {
    if (ref($body->{system}) eq 'ARRAY') {
      my $txt = join('', map { ref($_) eq 'HASH' ? ($_->{text} // '') : "$_" } @{$body->{system}});
      push @messages, { role => 'system', content => $txt } if length $txt;
    } else {
      push @messages, { role => 'system', content => "$body->{system}" };
    }
  }

  for my $m (@{$body->{messages} || []}) {
    next unless ref($m) eq 'HASH';
    my $role = $m->{role} // 'user';
    my $content = $m->{content};

    if (!ref($content)) {
      push @messages, { role => $role, content => (defined($content) ? "$content" : '') };
      next;
    }

    if (ref($content) eq 'ARRAY') {
      my @text;
      my @tool_calls;

      for my $block (@$content) {
        next unless ref($block) eq 'HASH';
        my $type = $block->{type} // '';

        if ($type eq 'text') {
          push @text, ($block->{text} // '');
          next;
        }

        if ($type eq 'tool_use') {
          my $id = $block->{id} // ('toolu_' . int(rand(1_000_000)));
          my $name = $block->{name} // 'tool';
          my $args = _encode_json_safe($block->{input} || {});
          push @tool_calls, {
            id => $id,
            type => 'function',
            function => {
              name => $name,
              arguments => $args,
            },
          };
          next;
        }

        if ($type eq 'tool_result') {
          my $tcid = $block->{tool_use_id} // $block->{id} // '';
          my $val = $block->{content};
          my $txt = ref($val) ? _encode_json_safe($val) : (defined($val) ? "$val" : '');
          push @messages, {
            role => 'tool',
            tool_call_id => $tcid,
            content => $txt,
          };
          next;
        }
      }

      my $text = join('', @text);
      if ($role eq 'assistant') {
        my %msg = (role => 'assistant');
        $msg{content} = $text if length $text;
        $msg{tool_calls} = \@tool_calls if @tool_calls;
        $msg{content} = '' if !exists($msg{content}) && !exists($msg{tool_calls});
        push @messages, \%msg;
      } elsif (length $text) {
        push @messages, { role => $role, content => $text };
      }
    }
  }

  my %out = (
    model    => ($body->{model} // ''),
    messages => \@messages,
    (defined($body->{max_tokens}) ? (max_tokens => 0 + $body->{max_tokens}) : ()),
    (defined($body->{temperature}) ? (temperature => 0 + $body->{temperature}) : ()),
    (defined($body->{top_p}) ? (top_p => 0 + $body->{top_p}) : ()),
  );

  if (ref($body->{tools}) eq 'ARRAY') {
    my $tools = Langertha::Tool->from_list($body->{tools});
    $out{tools} = [ map { $_->to_openai } @$tools ];
  }

  if (defined $body->{tool_choice}) {
    my $tc = Langertha::ToolChoice->from_hash($body->{tool_choice});
    if ($tc) {
      my $oai_tc = $tc->to_openai;
      $out{tool_choice} = $oai_tc if defined $oai_tc;
    }
  }

  return \%out;
}

sub _openai_response_to_anthropic {
  my ($res, $default_model) = @_;

  my $choice = (ref($res->{choices}) eq 'ARRAY' ? $res->{choices}[0] : {}) || {};
  my $msg = $choice->{message} || {};
  my $text = $msg->{content} // '';
  my @calls = Langertha::ToolCall->extract($res || {});

  if (!@calls && length($text)) {
    my ($clean, $extracted) = Langertha::ToolCall->extract_hermes_from_text($text);
    $text = $clean;
    @calls = @$extracted;
  }

  my @content;
  push @content, { type => 'text', text => $text } if length $text;
  my $i = 0;
  for my $call (@calls) {
    $i++;
    push @content, $call->to_anthropic_block( fallback_id => "toolu_skeid_$i" );
  }

  my $fr = $choice->{finish_reason} // 'stop';
  my $stop_reason = $fr eq 'tool_calls' ? 'tool_use'
                  : $fr eq 'length'     ? 'max_tokens'
                  : 'end_turn';

  return {
    id           => ($res->{id} ? ('msg_' . $res->{id}) : ('msg_' . int(time * 1000))),
    type         => 'message',
    role         => 'assistant',
    model        => ($res->{model} // $default_model),
    content      => \@content,
    stop_reason  => $stop_reason,
    stop_sequence => undef,
    usage => {
      input_tokens  => 0 + (($res->{usage} || {})->{prompt_tokens} // 0),
      output_tokens => 0 + (($res->{usage} || {})->{completion_tokens} // 0),
    },
  };
}

sub _openai_response_to_ollama_chat {
  my ($res) = @_;
  my $choice = (ref($res->{choices}) eq 'ARRAY' ? $res->{choices}[0] : {}) || {};
  my $msg = $choice->{message} || {};
  my $text = ($msg->{content} // '');
  my $tool_calls = [];

  if (ref($msg->{tool_calls}) eq 'ARRAY') {
    my @calls = Langertha::ToolCall->extract($res || {});
    $tool_calls = [ map { $_->to_ollama } @calls ];
  } elsif (length($text)) {
    my ($clean, $calls) = Langertha::ToolCall->extract_hermes_from_text($text);
    if (@$calls) {
      $text = $clean;
      $tool_calls = [ map { $_->to_ollama } @$calls ];
    }
  }

  return {
    model      => ($res->{model} // ''),
    created_at => _iso8601_now(),
    message    => {
      role    => ($msg->{role} // 'assistant'),
      content => $text,
      (@$tool_calls ? (tool_calls => $tool_calls) : ()),
    },
    done       => 1,
    done_reason => ($choice->{finish_reason} // 'stop'),
    prompt_eval_count => 0 + (($res->{usage} || {})->{prompt_tokens} // 0),
    eval_count        => 0 + (($res->{usage} || {})->{completion_tokens} // 0),
  };
}

sub _parse_hermes_tool_calls {
  my ($text) = @_;
  my @calls;
  return \@calls unless defined $text;

  while ($text =~ m{<tool_call>\s*(\{.*?\})\s*</tool_call>}sg) {
    my $json = $1;
    my $obj = _decode_json_safe($json);
    next unless ref($obj) eq 'HASH';
    push @calls, {
      id => ('tool_' . int(rand(1_000_000))),
      type => 'function',
      function => {
        name => ($obj->{name} // 'tool'),
        arguments => _encode_json_safe($obj->{arguments} || {}),
      },
    };
  }

  return \@calls;
}

sub _decode_json_safe {
  my ($value) = @_;
  return $value if ref($value);
  return undef unless defined $value && length $value;
  my $decoded = eval { decode_json($value) };
  return $@ ? undef : $decoded;
}

sub _encode_json_safe {
  my ($value) = @_;
  return '{}' unless defined $value;
  return eval { encode_json($value) } || '{}';
}

sub _duration_ms {
  my ($started) = @_;
  return int((time - $started) * 1000);
}

sub _iso8601_now {
  return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Proxy - Multi-format LLM proxy (OpenAI, Anthropic, Ollama) powered by Langertha::Skeid routing

=head1 VERSION

version 0.002

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
