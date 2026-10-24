use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A request the client's own fault ended (400, 404, 413, 422) is a fourth outcome of
# request.finish, `rejected`, counted apart from the node's errors (k99, ADR 0024). 401, 403 and
# 429 say something about the node's key or capacity and stay errors. Without this a client that
# sends bad requests makes a healthy node look failing to a fronting Skeid.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB )};

my $STATUS = 200;
my @USAGE;
my $skeid = Langertha::Skeid->new(
  route_wait_timeout_ms => 50,
  route_wait_poll_ms    => 5,
  store_usage_event     => sub { push @USAGE, $_[1]; return { ok => 1 } },
);
my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->log->level('fatal');
$app->routes->post('/__up/v1/chat/completions' => sub {
  my $c = shift;
  return $c->render(status => $STATUS, json => { error => { message => 'no', type => 'x' } })
    if $STATUS != 200;
  $c->render(json => { id => 'x', object => 'chat.completion', model => 'm',
    choices => [{ index => 0, message => { role => 'assistant', content => 'hi' }, finish_reason => 'stop' }],
    usage => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 } });
});
my $t = Test::Mojo->new($app);
$skeid->add_node(id => 'n1', url => $t->ua->server->nb_url->clone->path('/__up/v1')->to_string,
  model => 'm', engine => 'openaibase', max_conns => 4);

sub row { return (grep { $_->{id} eq 'n1' } @{ $skeid->registry_snapshot->{nodes} })[0] }

sub one {
  my ($status, $stream) = @_;
  $STATUS = $status;
  $t->post_ok('/v1/chat/completions' => json => { model => 'm', stream => ($stream ? \1 : \0),
    messages => [{ role => 'user', content => 'x' }] })->status_is($status);
}

for my $stream (0, 1) {
  my $label = $stream ? 'stream' : 'json';
  my $before = $skeid->node_metrics('n1');
  my $row0 = { %{ row() } };
  one($_, $stream) for 400, 404, 413, 422;
  my $m = $skeid->node_metrics('n1');
  is $m->{rejected} - $before->{rejected}, 4, "$label: four rejected";
  is $m->{error} - $before->{error}, 0, "$label: none counted as a node error";
  is row()->{errors_in_window}, $row0->{errors_in_window}, "$label: errors_in_window untouched";
  is row()->{last_failure_at}, $row0->{last_failure_at}, "$label: last_failure_at untouched";
  is row()->{rejected_in_window} - ($row0->{rejected_in_window} // 0), 4,
    "$label: rejected_in_window counts them";

  one($_, $stream) for 401, 403, 500;
  $m = $skeid->node_metrics('n1');
  is $m->{error} - $before->{error}, 3, "$label: 401, 403, 500 stay node errors";
  is row()->{errors_in_window} - $row0->{errors_in_window}, 3, "$label: and show in errors_in_window";
  is $m->{inflight}, 0, "$label: nothing in flight";
  is $m->{ok} + $m->{error} + $m->{aborted} + $m->{rejected}, $m->{started},
    "$label: every request.start has its request.finish";
}

# 429 last: it sets a capacity backoff that would answer the next request itself.
{
  my $e = $skeid->node_metrics('n1')->{error};
  one(429, 0);
  is $skeid->node_metrics('n1')->{error} - $e, 1, '429 stays a node error';
}

ok !(grep { $_->{ok} } grep { ($_->{status_code} // 0) == 422 } @USAGE),
  'the usage event of a rejected request is still ok = 0';

done_testing;
