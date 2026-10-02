use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Anthropic;
use Langertha::Skeid::Protocol::Anthropic::Stream;
use Langertha::Skeid::Protocol::Ollama;
use Langertha::Skeid::Protocol::Ollama::Stream;

# A translator that dies in the middle of a request is an exit path like any other: the client
# gets an answer in its own face's error shape (an HTTP error while nothing was sent yet, an
# in-band error event once the stream is open), the slot is given back, one usage event says the
# request failed, and a stream still running upstream is cancelled. What the exception said stays
# out of the client's answer.

# The translators are made to die from outside, on the Nth call of a request.
my %DIE;
{
  no warnings "redefine"; no strict "refs";
  for my $class (qw(Langertha::Skeid::Protocol::Anthropic::Stream Langertha::Skeid::Protocol::Ollama::Stream)) {
    my $orig = $class->can('delta');
    *{$class . '::delta'} = sub {
      my ($self, @args) = @_;
      my $n = ++$self->{_test_calls};
      die "translator exploded sk-secret-123\n" if ($DIE{stream} // 0) == $n;
      return $self->$orig(@args);
    };
  }
  for my $spec (['Langertha::Skeid::Protocol::Anthropic', 'response_from_openai'],
                ['Langertha::Skeid::Protocol::Ollama', 'response_from_openai'],
                ['Langertha::Skeid::Protocol::Ollama', 'generate_response_from_openai']) {
    my ($class, $name) = @$spec;
    my $orig = $class->can($name);
    *{$class . '::' . $name} = sub {
      die "translator exploded sk-secret-123\n" if $DIE{json};
      return $orig->(@_);
    };
  }
}

my @usage;
my $skeid = Langertha::Skeid->new(
  route_wait_timeout_ms => 100,
  route_wait_poll_ms    => 5,
  store_usage_event     => sub { push @usage, $_[1]; return { ok => 1 } },
);
my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->mode('production');
my @log;
$app->log->level('debug');
$app->log->unsubscribe('message')->on(message => sub { push @log, $_[2] });

my $frame = sub {
  my ($text) = @_;
  return qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"$text"},"finish_reason":null}]}\n\n};
};
my $upstream = { frames_written => 0, hung_up => 0, finished => 0 };
$app->routes->post('/__up/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body = $c->req->json || {};
  unless ($body->{stream}) {
    return $c->render(json => {
      id => 'c1', object => 'chat.completion', model => $body->{model},
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 4, completion_tokens => 2, total_tokens => 6 },
    });
  }
  $c->render_later;
  $c->res->headers->content_type('text/event-stream');
  $c->on(finish => sub { $upstream->{hung_up} = 1 unless $upstream->{finished} });
  my $left = 8;
  my $write;
  $write = sub {
    return unless $c->tx;
    if (!$left || $upstream->{hung_up}) {
      $upstream->{finished} = 1;
      return $c->finish;
    }
    $left--;
    $upstream->{frames_written}++;
    $c->write_chunk($frame->('x') => sub { Mojo::IOLoop->timer(0.05 => $write) });
  };
  $write->();
});

my $t = Test::Mojo->new($app);
my $up = $t->ua->server->nb_url->clone->path('/__up/v1');
ok $skeid->add_node(id => 'n1', url => "$up", model => 'm', engine => 'openai', healthy => 1, max_conns => 2),
  'node added';

sub reset_state {
  %DIE = ();
  @usage = ();
  @log = ();
  $upstream = { frames_written => 0, hung_up => 0, finished => 0 };
}

sub settle {
  my ($cond) = @_;
  my $guard = Mojo::IOLoop->timer(1.5 => sub { Mojo::IOLoop->stop });
  my $poll = Mojo::IOLoop->recurring(0.01 => sub { Mojo::IOLoop->stop if $cond->() });
  Mojo::IOLoop->start unless $cond->();
  Mojo::IOLoop->remove($_) for $guard, $poll;
}

sub failed_once {
  my ($name) = @_;
  settle(sub { @usage >= 1 });
  Mojo::IOLoop->timer(0.05 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  is scalar(@usage), 1, "$name: one usage event";
  ok !$usage[0]{ok}, "$name: recorded as failed";
  is $skeid->node_metrics('n1')->{inflight}, 0, "$name: the slot is free";
  unlike join("\n", @log), qr/sk-secret-123/, "$name: the log does not carry what the exception said";
}

my %FACE = (
  anthropic => { path => '/v1/messages',
    body => sub { { model => 'm', max_tokens => 10, stream => $_[0] ? \1 : \0,
                    messages => [{ role => 'user', content => 'hi' }] } } },
  'ollama-chat' => { path => '/api/chat',
    body => sub { { model => 'm', stream => $_[0] ? \1 : \0,
                    messages => [{ role => 'user', content => 'hi' }] } } },
  'ollama-generate' => { path => '/api/generate',
    body => sub { { model => 'm', prompt => 'hi', stream => $_[0] ? \1 : \0 } } },
);

for my $face (sort keys %FACE) {
  my $spec = $FACE{$face};

  # JSON: the translator dies on a complete upstream answer.
  reset_state();
  $DIE{json} = 1;
  $t->post_ok($spec->{path} => json => $spec->{body}->(0))->status_is(500, "$face json: an HTTP 500");
  $t->content_type_like(qr{json}, "$face json: an error body, not an HTML page");
  if ($face eq 'anthropic') {
    $t->json_is('/type' => 'error', "$face json: Anthropic's error envelope");
  } else {
    $t->json_has('/error', "$face json: Ollama's error");
    is ref($t->tx->res->json->{error}), '', "$face json: as a plain string";
  }
  $t->content_unlike(qr/sk-secret-123/, "$face json: the exception stays out of the answer");
  failed_once("$face json");
  is $usage[0]{status_code}, 500, "$face json: status recorded";

  # Stream, translator dies on the first frame: nothing was written, so an HTTP error.
  reset_state();
  $DIE{stream} = 1;
  $t->post_ok($spec->{path} => json => $spec->{body}->(1))->status_is(500, "$face stream, first frame: an HTTP 500");
  $t->content_unlike(qr/sk-secret-123/, "$face stream, first frame: the exception stays out");
  if ($face eq 'anthropic') {
    $t->json_is('/type' => 'error', "$face stream, first frame: Anthropic's error envelope");
  } else {
    $t->json_has('/error', "$face stream, first frame: Ollama's error");
  }
  failed_once("$face stream, first frame");
  settle(sub { $upstream->{hung_up} });
  ok $upstream->{hung_up}, "$face stream, first frame: the upstream was cancelled";
  cmp_ok $upstream->{frames_written}, '<', 8, "$face stream, first frame: it did not run to its end";

  # Stream, translator dies on the second frame: the stream is open, so the failure is in-band.
  reset_state();
  $DIE{stream} = 2;
  $t->post_ok($spec->{path} => json => $spec->{body}->(1))->status_is(200, "$face stream, later frame: the stream had opened");
  my $body = $t->tx->res->body;
  if ($face eq 'anthropic') {
    like $body, qr/event: error/, "$face stream, later frame: an error event";
  } else {
    like $body, qr/"error"/, "$face stream, later frame: an error line";
  }
  unlike $body, qr/sk-secret-123/, "$face stream, later frame: the exception stays out";
  failed_once("$face stream, later frame");
  settle(sub { $upstream->{hung_up} });
  ok $upstream->{hung_up}, "$face stream, later frame: the upstream was cancelled";
  cmp_ok $upstream->{frames_written}, '<', 8, "$face stream, later frame: it did not run to its end";
}

done_testing;
