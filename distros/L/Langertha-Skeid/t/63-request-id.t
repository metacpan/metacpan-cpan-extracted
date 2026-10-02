use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Anthropic::Stream;

# One id per request, fixed when the request arrives: it is returned as x-request-id on every
# face and on every kind of answer (a refusal, an upstream error, a translator failure, a stream
# before its first byte), and it is the id of the usage event and of the "usage event lost" line.
# A client's own x-request-id is taken over as it always was; an id from the upstream never
# replaces it.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR )};

my $DIE_STREAM = 0;
{
  no warnings 'redefine';
  my $orig = Langertha::Skeid::Protocol::Anthropic::Stream->can('delta');
  *Langertha::Skeid::Protocol::Anthropic::Stream::delta = sub {
    die "translator exploded\n" if $DIE_STREAM;
    return $orig->(@_);
  };
}

my @usage;
my $store_ok = 1;
my $skeid = Langertha::Skeid->new(
  route_wait_timeout_ms => 50,
  route_wait_poll_ms    => 5,
  store_usage_event     => sub { push @usage, $_[1]; return $store_ok ? { ok => 1 } : { ok => 0, error => 'disk full' } },
);
my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
my @log;
$app->log->level('debug');
$app->log->unsubscribe('message')->on(message => sub { push @log, $_[2] });

my $frame = sub {
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"$_[0]"},"finish_reason":null}]}\n\n};
};
$app->routes->post('/__up/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body = $c->req->json || {};
  $c->res->headers->header('x-request-id' => 'from-the-upstream');
  return $c->render(status => 500, json => { error => { message => 'boom' } })
    if ($body->{model} // '') eq 'bad';
  unless ($body->{stream}) {
    return $c->render(json => {
      id => 'c1', object => 'chat.completion', model => $body->{model},
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 4, completion_tokens => 2, total_tokens => 6 },
    });
  }
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk($frame->('a'));
  $c->write_chunk($frame->('b'));
  $c->write_chunk(qq{data: [DONE]\n\n} => sub { $c->finish });
});

my $t = Test::Mojo->new($app);
my $up = $t->ua->server->nb_url->clone->path('/__up/v1');
$skeid->add_node(id => 'n1', url => "$up", model => 'm',   engine => 'openai', healthy => 1, max_conns => 2);
$skeid->add_node(id => 'n2', url => "$up", model => 'bad', engine => 'openai', healthy => 1, max_conns => 2);

my %FACE = (
  openai => { path => '/v1/chat/completions',
    body => sub { { model => $_[0], stream => $_[1] ? \1 : \0, messages => [{ role => 'user', content => 'hi' }] } } },
  anthropic => { path => '/v1/messages',
    body => sub { { model => $_[0], max_tokens => 10, stream => $_[1] ? \1 : \0,
                    messages => [{ role => 'user', content => 'hi' }] } } },
  ollama => { path => '/api/chat',
    body => sub { { model => $_[0], stream => $_[1] ? \1 : \0, messages => [{ role => 'user', content => 'hi' }] } } },
);

sub settle {
  Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
}

# Runs a request and checks the header against the usage event it produced.
sub check {
  my ($label, $tx, $code, %o) = @_;
  is $tx->res->code, $code, "$label: status";
  my $id = $tx->res->headers->header('x-request-id');
  ok defined($id) && length($id), "$label: x-request-id is returned";
  isnt $id, 'from-the-upstream', "$label: not the upstream's id";
  is $id, $o{expect}, "$label: the client's own id is kept" if $o{expect};
  settle();
  if (!$o{no_event}) {
    is scalar(@usage), 1, "$label: one usage event" or diag explain \@usage;
    is $usage[0]{request_id}, $id, "$label: the usage event carries the same id" if @usage;
  }
  return $id;
}

for my $face (qw( openai anthropic ollama )) {
  my $spec = $FACE{$face};
  my $path = $spec->{path};

  @usage = ();
  $t->post_ok($path => json => $spec->{body}->('m', 0));
  my $generated = check("$face json", $t->tx, 200);
  like $generated, qr/\Areq_/, "$face json: generated when the client sent none";

  @usage = ();
  $t->post_ok($path => { 'x-request-id' => 'client-id-1' } => json => $spec->{body}->('m', 0));
  check("$face json, client id", $t->tx, 200, expect => 'client-id-1');

  @usage = ();
  $t->post_ok($path => json => $spec->{body}->('m', 1));
  check("$face stream", $t->tx, 200);

  @usage = ();
  $t->post_ok($path => json => $spec->{body}->('bad', 0));
  check("$face upstream error", $t->tx, 500);

  @usage = ();
  $t->post_ok($path => json => $spec->{body}->('bad', 1));
  check("$face upstream error, stream", $t->tx, 500);

  # A refusal before any node is chosen: no such model, and a body that is not JSON.
  @usage = ();
  $t->post_ok($path => { 'x-request-id' => 'client-id-2' } => json => $spec->{body}->('nope', 0));
  check("$face model not found", $t->tx, 503, expect => 'client-id-2', no_event => 1);

  $t->post_ok($path => { 'Content-Type' => 'application/json' } => '{not json');
  ok length($t->tx->res->headers->header('x-request-id') // ''), "$face invalid JSON: x-request-id is returned";
}

# A translator that dies before the first byte: the response headers are cleared for the error.
$DIE_STREAM = 1;
@usage = ();
$t->post_ok($FACE{anthropic}{path} => json => $FACE{anthropic}{body}->('m', 1));
check('anthropic translator failure', $t->tx, 500);
$DIE_STREAM = 0;

# The lost-event line names the id the client was given.
@usage = (); @log = ();
$store_ok = 0;
$t->post_ok('/v1/chat/completions' => json => $FACE{openai}{body}->('m', 0));
my $rid = $t->tx->res->headers->header('x-request-id');
settle();
my ($lost) = grep { /usage event lost/ } @log;
ok defined($rid) && length($rid), 'lost event: the client got an id';
like $lost // '', qr/request_id=\Q$rid\E\b/, 'lost event: the log line names that id';
$store_ok = 1;

# Two requests, two ids.
$t->post_ok('/v1/chat/completions' => json => $FACE{openai}{body}->('m', 0));
my $first = $t->tx->res->headers->header('x-request-id');
$t->post_ok('/v1/chat/completions' => json => $FACE{openai}{body}->('m', 0));
isnt $t->tx->res->headers->header('x-request-id'), $first, 'ids differ per request';

done_testing;
