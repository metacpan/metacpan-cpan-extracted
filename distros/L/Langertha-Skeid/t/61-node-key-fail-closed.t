use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::JSON qw( true false );
use Langertha::Skeid;
use Langertha::Skeid::KeyBroker;
use Langertha::Skeid::Proxy;

# A node that names a key of its own (api_key_ref, api_key_env) and cannot produce it must not
# be called at all. Falling through to the pass-through of a keyless node would hand the
# customer's Skeid key to the upstream provider as its bearer token -- a secret reaching a party
# that must never see it (ADR 0003). Only a node with no key source forwards the client's header.

# build_app wires an OpenBao broker off the environment; this test is offline by construction.
delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR )};

my $CLIENT_KEY = 'sk-customer-key-that-must-stay-here';
my $NODE_KEY   = 'gsk-node-key-from-the-broker';
my $ENV_KEY    = 'gsk-node-key-from-the-environment';
my $KEY_REF    = 'secret/skeid/remote/failclosed';
my $ENV_NAME   = 'TEST_SKEID_FAIL_CLOSED_KEY';
my $MODEL      = 'fail-closed-model';

{
  # Takes the selected node out of the inventory between admission and the upstream call, which
  # is what a config reload landing in that gap does.
  package Local::FailClosed::VanishingSkeid;
  use parent 'Langertha::Skeid';

  sub call_function {
    my ( $self, $name, $args ) = @_;
    my $result = $self->SUPER::call_function($name, $args);
    $self->remove_node($args->{id}) if $name eq 'request.start' && $self->{_vanish};
    return $result;
  }
}

{
  package Local::FailClosed::Broker;
  use Moo;
  extends 'Langertha::Skeid::KeyBroker';
  has keys => (is => 'ro', default => sub { {} });
  sub resolve_key {
    my ( $self, $ref ) = @_;
    return $self->keys->{$ref} // die "vault said no for $ref\n";
  }
}

my @stream_frames = (
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"ok"},"finish_reason":null}]}\n\n},
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":2,"completion_tokens":1,"total_tokens":3}}\n\n},
  qq{data: [DONE]\n\n},
);

# One app per scenario: the broker belongs to the Skeid, and a scenario is "this Skeid, this node".
sub build_stack {
  my ( %arg ) = @_;
  my $stack = { events => [], hits => [], log => [] };

  my $skeid = ($arg{skeid_class} || 'Langertha::Skeid')->new(
    ($arg{broker} ? ( key_broker => $arg{broker} ) : ()),
    store_usage_event => sub { push @{$stack->{events}}, $_[1]; return { ok => 1 } },
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->mode('production');
  $app->log->level('warn');
  $app->log->unsubscribe('message');
  $app->log->on(message => sub {
    my ( $log, $level, @lines ) = @_;
    push @{$stack->{log}}, join(' ', $level, @lines);
  });

  my $hit = sub {
    my ( $c ) = @_;
    push @{$stack->{hits}}, {
      path          => $c->req->url->path->to_string,
      authorization => $c->req->headers->authorization,
      x_api_key     => $c->req->headers->header('x-api-key'),
      headers       => $c->req->headers->to_string,
    };
  };

  $app->routes->post('/__fake_upstream/v1/chat/completions' => sub {
    my ( $c ) = @_;
    $hit->($c);
    my $body = $c->req->json || {};
    if ($body->{stream}) {
      $c->res->headers->content_type('text/event-stream; charset=utf-8');
      $c->render(status => 200, data => join('', @stream_frames));
      return;
    }
    $c->render(json => {
      id      => 'chatcmpl-failclosed',
      object  => 'chat.completion',
      model   => ($body->{model} // ''),
      choices => [{
        index         => 0,
        message       => { role => 'assistant', content => 'ok' },
        finish_reason => 'stop',
      }],
      usage => { prompt_tokens => 2, completion_tokens => 1, total_tokens => 3 },
    });
  });

  $app->routes->post('/__fake_upstream/v1/embeddings' => sub {
    my ( $c ) = @_;
    $hit->($c);
    $c->render(json => {
      object => 'list',
      data   => [{ object => 'embedding', index => 0, embedding => [ 0.1, 0.2 ] }],
      usage  => { prompt_tokens => 2, total_tokens => 2 },
    });
  });

  my $t = Test::Mojo->new($app);
  my $upstream = $t->ua->server->nb_url->clone;
  $upstream->path('/__fake_upstream/v1');

  $skeid->add_node(
    id        => 'the-node',
    url       => "$upstream",
    model     => $MODEL,
    engine    => 'openai',
    healthy   => 1,
    max_conns => 4,
    %{$arg{node} || {}},
  );

  @{$stack}{qw( skeid t )} = ( $skeid, $t );
  return $stack;
}

my @chat = ( messages => [{ role => 'user', content => 'hi' }] );
my %bearer    = ( Authorization => 'Bearer '.$CLIENT_KEY );
my %anthropic = ( 'x-api-key' => $CLIENT_KEY, 'anthropic-version' => '2023-06-01' );

# Every route that reaches _inject_node_auth_async, streamed and not.
my @faces = (
  { name => 'openai chat',          shape => 'openai',    path => '/v1/chat/completions',
    headers => \%bearer,    body => { model => $MODEL, @chat } },
  { name => 'openai chat stream',   shape => 'openai',    path => '/v1/chat/completions',
    headers => \%bearer,    body => { model => $MODEL, @chat, stream => true } },
  { name => 'openai embeddings',    shape => 'openai',    path => '/v1/embeddings',
    headers => \%bearer,    body => { model => $MODEL, input => 'hi' } },
  { name => 'anthropic messages',   shape => 'anthropic', path => '/v1/messages',
    headers => \%anthropic, body => { model => $MODEL, max_tokens => 16, @chat } },
  { name => 'anthropic stream',     shape => 'anthropic', path => '/v1/messages',
    headers => \%anthropic, body => { model => $MODEL, max_tokens => 16, @chat, stream => true } },
  { name => 'ollama chat',          shape => 'ollama',    path => '/api/chat',
    headers => \%bearer,    body => { model => $MODEL, @chat, stream => false } },
  { name => 'ollama chat stream',   shape => 'ollama',    path => '/api/chat',
    headers => \%bearer,    body => { model => $MODEL, @chat } },
  { name => 'ollama generate',      shape => 'ollama',    path => '/api/generate',
    headers => \%bearer,    body => { model => $MODEL, prompt => 'hi', stream => false } },
  { name => 'ollama generate stream', shape => 'ollama',  path => '/api/generate',
    headers => \%bearer,    body => { model => $MODEL, prompt => 'hi' } },
);

sub request {
  my ( $stack, $face ) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, join('', @_) };
  $stack->{t}->post_ok($face->{path} => { %{$face->{headers}} } => json => $face->{body});
  push @{$stack->{log}}, map { 'warn '.$_ } @warnings;
  return $stack->{t};
}

# --- a configured key source that yields nothing: fail closed ---

my @refused = (
  {
    name  => 'api_key_ref without a key broker',
    node  => { api_key_ref => $KEY_REF },
    names => [ $KEY_REF ],
  },
  {
    name   => 'api_key_ref the broker cannot resolve',
    broker => sub { Local::FailClosed::Broker->new },
    node   => { api_key_ref => $KEY_REF },
    names  => [ $KEY_REF ],
  },
  {
    name  => 'api_key_env naming an unset variable',
    node  => { api_key_env => $ENV_NAME },
    names => [ $ENV_NAME ],
  },
  {
    name  => 'api_key_env naming an empty variable',
    env   => '',
    node  => { api_key_env => $ENV_NAME },
    names => [ $ENV_NAME ],
  },
  {
    name   => 'api_key_ref and api_key_env that both yield nothing',
    broker => sub { Local::FailClosed::Broker->new },
    node   => { api_key_ref => $KEY_REF, api_key_env => $ENV_NAME },
    names  => [ $KEY_REF, $ENV_NAME ],
  },
);

for my $case (@refused) {
  for my $face (@faces) {
    my $name = $case->{name}.', '.$face->{name};
    subtest $name => sub {
      local $ENV{$ENV_NAME} = $case->{env} if defined $case->{env};
      delete local $ENV{$ENV_NAME} unless defined $case->{env};

      my $stack = build_stack(
        node => $case->{node},
        ($case->{broker} ? ( broker => $case->{broker}->() ) : ()),
      );
      my $t = request($stack, $face);

      is scalar(@{$stack->{hits}}), 0, 'the upstream is never called'
        or diag explain $stack->{hits};

      $t->status_is(503);
      $t->header_like('content-type' => qr{\Aapplication/json}, 'answered as a plain JSON error');
      if ($face->{shape} eq 'anthropic') {
        $t->json_is('/type' => 'error', 'in the Anthropic envelope')
          ->json_is('/error/type' => 'api_error')
          ->json_like('/error/message' => qr/key/i);
      } elsif ($face->{shape} eq 'ollama') {
        my $error = $t->tx->res->json('/error');
        ok defined($error) && !ref($error) && $error =~ /key/i, 'in the Ollama error shape';
      } else {
        $t->json_is('/error/type' => 'upstream_key_unavailable', 'in the OpenAI error shape')
          ->json_like('/error/message' => qr/key/i);
      }

      my $answer = $t->tx->res->body;
      unlike $answer, qr/\Q$CLIENT_KEY\E/, 'the answer does not echo the client key';
      unlike $answer, qr/\Q$_\E/, 'the answer does not name the key source '.$_ for @{$case->{names}};

      my $metrics = $stack->{skeid}->node_metrics('the-node');
      is $metrics->{started}, 1, 'the request was admitted';
      is $metrics->{inflight}, 0, 'and released: request.finish ran';
      is $metrics->{error}, 1, 'as a failure';
      is $metrics->{ok}, 0, 'not as a success';

      is scalar(@{$stack->{events}}), 1, 'exactly one usage event'
        or diag explain $stack->{events};
      my $event = $stack->{events}[0] || {};
      is $event->{ok}, 0, 'recorded as failed';
      is $event->{status_code}, 503, 'with the status the client got';
      is $event->{error_type}, 'upstream_key_unavailable', 'and what went wrong';
      is $event->{node_id}, 'the-node', 'on the node that was selected';
      is $event->{api_format}, $face->{shape}, 'for the face that was called';

      my $log = join("\n", @{$stack->{log}});
      like $log, qr/\Q$_\E/, 'the log names the key source '.$_ for @{$case->{names}};
      like $log, qr/the-node/, 'and the node';
      unlike $log, qr/\Q$CLIENT_KEY\E/, 'and never the client key';
    };
  }
}

# --- everything else keeps its behaviour ---

for my $face (@faces) {
  subtest 'a node with no key source passes the client header through, '.$face->{name} => sub {
    my $stack = build_stack;
    my $t = request($stack, $face);
    $t->status_is(200);

    is scalar(@{$stack->{hits}}), 1, 'the upstream is called once';
    my $hit = $stack->{hits}[0] || {};
    if ($face->{shape} eq 'anthropic') {
      is $hit->{x_api_key}, $CLIENT_KEY, 'with the client x-api-key';
    } else {
      is $hit->{authorization}, 'Bearer '.$CLIENT_KEY, 'with the client Authorization';
    }

    is scalar(@{$stack->{events}}), 1, 'exactly one usage event';
    is $stack->{events}[0]{ok}, 1, 'recorded as ok';
    is $stack->{skeid}->node_metrics('the-node')->{inflight}, 0, 'and nothing left in flight';
  };

  subtest 'a resolved api_key_ref replaces the client key, '.$face->{name} => sub {
    my $stack = build_stack(
      broker => Local::FailClosed::Broker->new(keys => { $KEY_REF => $NODE_KEY }),
      node   => { api_key_ref => $KEY_REF },
    );
    my $t = request($stack, $face);
    $t->status_is(200);

    is scalar(@{$stack->{hits}}), 1, 'the upstream is called once';
    my $hit = $stack->{hits}[0] || {};
    is $hit->{authorization}, 'Bearer '.$NODE_KEY, 'with the node key';
    is $hit->{x_api_key}, undef, 'and without the client x-api-key';
    unlike join("\n", @{$stack->{log}}), qr/\Q$NODE_KEY\E/, 'the node key is not logged';
  };

  subtest 'api_key_env still covers a broker that fails, '.$face->{name} => sub {
    local $ENV{$ENV_NAME} = $ENV_KEY;
    my $stack = build_stack(
      broker => Local::FailClosed::Broker->new,
      node   => { api_key_ref => $KEY_REF, api_key_env => $ENV_NAME },
    );
    my $t = request($stack, $face);
    $t->status_is(200);

    is scalar(@{$stack->{hits}}), 1, 'the upstream is called once';
    my $hit = $stack->{hits}[0] || {};
    is $hit->{authorization}, 'Bearer '.$ENV_KEY, 'with the key from the environment';
    is $hit->{x_api_key}, undef, 'and without the client x-api-key';
  };
}

# --- a resolved key leaves none of the client's credentials beside it ---

for my $spelling ('x-api-key', 'X-Api-Key', 'X-API-KEY') {
  for my $source (
    { name => 'api_key_ref', key => $NODE_KEY, node => { api_key_ref => $KEY_REF },
      broker => sub { Local::FailClosed::Broker->new(keys => { $KEY_REF => $NODE_KEY }) } },
    { name => 'api_key_env', key => $ENV_KEY, node => { api_key_env => $ENV_NAME } },
  ) {
    for my $face (@faces) {
      subtest "a client $spelling does not travel beside a resolved $source->{name}, $face->{name}" => sub {
        local $ENV{$ENV_NAME} = $ENV_KEY;
        my $stack = build_stack(
          node => $source->{node},
          ($source->{broker} ? ( broker => $source->{broker}->() ) : ()),
        );
        my $t = request($stack, {
          %$face,
          headers => { Authorization => 'Bearer '.$CLIENT_KEY, $spelling => $CLIENT_KEY },
        });
        $t->status_is(200);

        is scalar(@{$stack->{hits}}), 1, 'the upstream is called once';
        my $hit = $stack->{hits}[0] || {};
        is $hit->{authorization}, 'Bearer '.$source->{key}, 'with the node key';
        is $hit->{x_api_key}, undef, 'without an x-api-key';
        unlike $hit->{headers} // '', qr/\Q$CLIENT_KEY\E/, 'and without the client key under any name';
      };
    }
  }
}

# --- a node that left the inventory after it was selected ---

for my $face (@faces) {
  subtest 'a node that is gone by the time its key is needed is not called, '.$face->{name} => sub {
    my $stack = build_stack(skeid_class => 'Local::FailClosed::VanishingSkeid');
    $stack->{skeid}{_vanish} = 1;
    my $t = request($stack, $face);

    is scalar(@{$stack->{hits}}), 0, 'the upstream is never called'
      or diag explain $stack->{hits};
    $t->status_is(503);
    unlike $t->tx->res->body, qr/\Q$CLIENT_KEY\E/, 'the answer does not echo the client key';

    my $metrics = $stack->{skeid}->node_metrics('the-node');
    is $metrics->{started}, 1, 'the request was admitted';
    is $metrics->{inflight}, 0, 'and released: request.finish ran';
    is $metrics->{error}, 1, 'as a failure';

    is scalar(@{$stack->{events}}), 1, 'exactly one usage event'
      or diag explain $stack->{events};
    my $event = $stack->{events}[0] || {};
    is $event->{ok}, 0, 'recorded as failed';
    is $event->{status_code}, 503, 'with the status the client got';
    is $event->{error_type}, 'upstream_key_unavailable', 'and what went wrong';

    my $log = join("\n", @{$stack->{log}});
    like $log, qr/the-node/, 'the log names the node';
    unlike $log, qr/\Q$CLIENT_KEY\E/, 'and never the client key';
  };
}

done_testing;
