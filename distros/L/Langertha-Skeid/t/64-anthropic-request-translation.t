use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Anthropic;

# A request the Anthropic translator dies on for a reason of its own -- not one of its deliberate,
# worded refusals -- is answered with a fixed 400 in Anthropic's error shape. What the exception
# said can quote the request, so it is neither sent nor logged (k75, k82).

my $die = 0;
{
  no warnings 'redefine';
  my $orig = \&Langertha::Skeid::Protocol::Anthropic::request_to_openai;
  *Langertha::Skeid::Protocol::Anthropic::request_to_openai = sub {
    die "translator exploded sk-secret-123 at /x/Anthropic.pm line 9.\n" if $die;
    return $orig->(@_);
  };
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

my $body = { model => 'm', max_tokens => 16, messages => [{ role => 'user', content => 'hi' }] };

for my $stream (0, 1) {
  my $name = "stream=$stream";
  $die = 1; @usage = (); @log = ();
  $t->post_ok('/v1/messages' => { 'x-request-id' => 'rid-42' } => json => { %$body, stream => $stream ? \1 : \0 })
    ->status_is(400, "$name: the client's request is refused with a 400");
  $t->json_is('/type' => 'error', "$name: typed as an Anthropic error")
    ->json_is('/error/type' => 'invalid_request_error', "$name: a client error");
  is $t->tx->res->json->{error}{message}, 'Invalid request', "$name: fixed text";
  $t->content_unlike(qr/sk-secret-123|exploded/, "$name: the exception stays out of the answer");
  $t->header_is('x-request-id' => 'rid-42', "$name: the request id is on the answer");
  unlike join("\n", @log), qr/sk-secret-123|exploded/, "$name: the log does not carry what the exception said";
  is scalar(@usage), 0, "$name: nothing was routed or metered";
  is $skeid->node_metrics('n1')->{inflight} // 0, 0, "$name: no slot is held";
  $die = 0;
}

# A deliberate refusal keeps its worded message: the client can act on it.
$t->post_ok('/v1/messages' => json => { %$body, messages => [{ role => 'user', content => [{
    type => 'image', source => { type => 'file', file_id => 'file_1' } }] }] })
  ->status_is(400, 'an unsupported image source is a 400')
  ->json_like('/error/message' => qr/image source type 'file' is not supported/,
    'a deliberate refusal keeps its message');

$t->post_ok('/v1/messages' => json => $body)->status_is(200, 'a good request still goes through');

done_testing;
