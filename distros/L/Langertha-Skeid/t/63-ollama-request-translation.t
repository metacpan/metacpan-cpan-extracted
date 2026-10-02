use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Ollama;

# A request the Ollama translator cannot read is the client's malformed request: it is answered
# in Ollama's own error shape before anything is routed or metered, like the Anthropic face does.
# What the exception said stays out of the answer and out of the log.

my $die = 0;
{
  no warnings 'redefine'; no strict 'refs';
  for my $name (qw(request_to_openai generate_request_to_openai)) {
    my $orig = Langertha::Skeid::Protocol::Ollama->can($name);
    *{'Langertha::Skeid::Protocol::Ollama::' . $name} = sub {
      die "translator exploded sk-secret-123\n" if $die;
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
$app->routes->post('/__up/v1/chat/completions' => sub {
  my ($c) = @_;
  $c->render(json => {
    id => 'c1', object => 'chat.completion', model => 'm',
    choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
    usage => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
  });
});

my $t = Test::Mojo->new($app);
my $up = $t->ua->server->nb_url->clone->path('/__up/v1');
$skeid->add_node(id => 'n1', url => "$up", model => 'm', engine => 'openai', healthy => 1, max_conns => 2);

my %FACE = (
  chat     => { path => '/api/chat',     body => { model => 'm', messages => [{ role => 'user', content => 'hi' }] } },
  generate => { path => '/api/generate', body => { model => 'm', prompt => 'hi' } }
);

for my $face (sort keys %FACE) {
  for my $stream (0, 1) {
    my $name = "$face stream=$stream";
    $die = 1; @usage = (); @log = ();
    $t->post_ok($FACE{$face}{path} => { 'x-request-id' => 'rid-42' } => json => { %{ $FACE{$face}{body} }, stream => $stream ? \1 : \0 })
      ->status_is(400, "$name: the client's request is refused with a 400");
    $t->content_type_like(qr{json}, "$name: an error body, not an HTML page");
    $t->json_has('/error', "$name: Ollama's error");
    is ref($t->tx->res->json->{error}), '', "$name: as a plain string";
    $t->content_unlike(qr/sk-secret-123/, "$name: the exception stays out of the answer");
    $t->header_is('x-request-id' => 'rid-42', "$name: the request id is on the answer");
    unlike join("\n", @log), qr/sk-secret-123/, "$name: the log does not carry what the exception said";
    is scalar(@usage), 0, "$name: nothing was routed or metered";
    is $skeid->node_metrics('n1')->{inflight} // 0, 0, "$name: no slot is held";
    $die = 0;
  }
  $t->post_ok($FACE{$face}{path} => json => { %{ $FACE{$face}{body} }, stream => \0 })
    ->status_is(200, "$face: a good request still goes through");
}

done_testing;
