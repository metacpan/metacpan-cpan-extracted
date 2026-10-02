use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# /v1/models and /api/tags name what a client can ask for. A node configured without a model
# is a wildcard: routing sends it any requested name, so there is no name that reaches it in
# particular -- its id is not a routing key. It used to show up in /api/tags under the name ''
# (skeid k67), because add_node stores an absent model as '' and the id fallback never fired.
# Both lists now hold the same distinct, non-empty model names.

my $skeid = Langertha::Skeid->new(store_usage_event => sub { return { ok => 1 } });
$skeid->add_node(id => 'a1', url => 'http://127.0.0.1:9/v1', model => 'm1', engine => 'vllm');
$skeid->add_node(id => 'a2', url => 'http://127.0.0.1:9/v1', model => 'm1', engine => 'vllm');
$skeid->add_node(id => 'b1', url => 'http://127.0.0.1:9/v1', model => 'm2');
$skeid->add_node(id => 'wild', url => 'http://127.0.0.1:9/v1');

my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid));
$t->app->log->level('fatal');

$t->get_ok('/api/tags')->status_is(200);
my @tags = map { $_->{name} } @{ $t->tx->res->json->{models} };
ok !grep({ !defined || !length } @tags), '/api/tags: no entry without a name';
ok !grep({ $_ eq 'wild' } @tags), '/api/tags: a model-less node does not appear under its id';
is_deeply [sort @tags], [qw( m1 m2 )], '/api/tags: one entry per distinct model';
my ($m1) = grep { $_->{name} eq 'm1' } @{ $t->tx->res->json->{models} };
is $m1->{model}, 'm1', '/api/tags: model matches name';
is $m1->{details}{family}, 'vllm', '/api/tags: family comes from the node engine';

$t->get_ok('/v1/models')->status_is(200);
my @ids = map { $_->{id} } @{ $t->tx->res->json->{data} };
is_deeply [sort @ids], [qw( m1 m2 )], '/v1/models: one entry per distinct model';
is_deeply [sort @tags], [sort @ids], '/v1/models and /api/tags list the same names';

# Only model-less nodes: nothing to list, and an empty list rather than a nameless entry.
my $bare = Langertha::Skeid->new(store_usage_event => sub { return { ok => 1 } });
$bare->add_node(id => 'wild', url => 'http://127.0.0.1:9/v1');
my $tb = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $bare));
$tb->app->log->level('fatal');
$tb->get_ok('/api/tags')->status_is(200)->json_is('/models' => []);
$tb->get_ok('/v1/models')->status_is(200)->json_is('/data' => []);

done_testing;
