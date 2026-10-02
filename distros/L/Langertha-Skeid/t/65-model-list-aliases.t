use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# /v1/models and /api/tags list what a caller can put in "model" (skeid k66): the node models
# and the alias names, once each, narrowed by the policy of the key that asks -- a key is not
# shown a name its policy would refuse. No key means the default policy; the route stays open.

my $skeid = Langertha::Skeid->new(store_usage_event => sub { return { ok => 1 } });
$skeid->add_node(id => 'l1', url => 'http://127.0.0.1:9/v1', model => 'qwen', tags => ['local']);
$skeid->add_node(id => 'c1', url => 'http://127.0.0.1:9/v1', model => 'llama', tags => ['cloud']);
$skeid->add_node(id => 'wild', url => 'http://127.0.0.1:9/v1');
$skeid->set_model_alias('house-model', { tiers => [{ tags => ['local'], model => 'qwen' }] });
$skeid->set_model_alias('qwen', { tiers => [{ tags => ['local'], model => 'qwen' }] });
$skeid->set_model_alias('cloud-product', { tiers => [{ tags => ['cloud'], model => 'llama' }] });
$skeid->set_policy('local-only', { deny_tags => ['cloud'] });
$skeid->set_policy('one-product', { models => ['house-model'] });
$skeid->key_policies({
  $skeid->key_id_for_key('sk-local') => $skeid->policies->{'local-only'},
  $skeid->key_id_for_key('sk-one')   => $skeid->policies->{'one-product'}
});

my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid));
$t->app->log->level('fatal');

sub names {
  my ($path, $key) = @_;
  $t->get_ok($path, $key ? { Authorization => 'Bearer '.$key } : {})->status_is(200);
  my $j = $t->tx->res->json;
  return [sort map { $_->{id} // $_->{name} } @{ $j->{data} // $j->{models} }];
}

for my $path ('/v1/models', '/api/tags') {
  is_deeply names($path), [qw( cloud-product house-model llama qwen )],
    $path.': aliases join the node models, a name that is both appears once';
  is_deeply names($path, 'sk-local'), [qw( house-model qwen )],
    $path.': a key denied cloud is shown neither the cloud model nor the cloud-only alias';
  is_deeply names($path, 'sk-one'), ['house-model'],
    $path.': a key restricted to one product sees that product only';
}

done_testing;
