use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use Mojo::Transaction::HTTP;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

sub _request {
  my ($app, $method, $path, $headers) = @_;
  $headers ||= {};
  my $tx = Mojo::Transaction::HTTP->new;
  $tx->req->method($method);
  $tx->req->url->parse($path);
  for my $name (keys %$headers) {
    $tx->req->headers->header($name => $headers->{$name});
  }
  $app->handler($tx);
  return $tx;
}

{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my $skeid = Langertha::Skeid->new;
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);

  my $tx = _request($app, 'GET', '/skeid/nodes');
  is($tx->res->code, 404, 'admin routes return 404 when admin key is unset');
}

{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(
    id    => 'n1',
    url   => 'http://127.0.0.1:21001/v1',
    model => 'qwen2.5',
  );
  my $app = Langertha::Skeid::Proxy->build_app(
    skeid         => $skeid,
    admin_api_key => 'adminkey',
  );

  my $tx_no_auth = _request($app, 'GET', '/skeid/nodes');
  is($tx_no_auth->res->code, 401, 'admin route requires bearer token');

  my $tx_bad = _request($app, 'GET', '/skeid/nodes', { Authorization => 'Bearer wrong' });
  is($tx_bad->res->code, 401, 'wrong bearer token returns 401');

  my $tx_ok = _request($app, 'GET', '/skeid/nodes', { Authorization => 'Bearer adminkey' });
  is($tx_ok->res->code, 200, 'correct bearer token returns 200');
  if (($tx_ok->res->code // 0) == 200) {
    my $json = decode_json($tx_ok->res->body // '{}');
    is($json->{nodes}[0]{id}, 'n1', 'admin route returns nodes payload');
  }
}

{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my $admin_key = '';
  my $skeid = Langertha::Skeid->new(
    config_loader => sub {
      return {
        admin => { api_key => $admin_key },
        nodes => [
          { id => 'dyn-1', url => 'http://127.0.0.1:22001/v1', model => 'qwen2.5' },
        ],
      };
    },
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);

  my $tx1 = _request($app, 'GET', '/skeid/nodes');
  is($tx1->res->code, 404, 'dynamic config: no key means 404');

  $admin_key = 'rotate-1';
  my $tx2 = _request($app, 'GET', '/skeid/nodes');
  is($tx2->res->code, 401, 'dynamic config: key enabled means auth required');

  my $tx3 = _request($app, 'GET', '/skeid/nodes', { Authorization => 'Bearer rotate-1' });
  is($tx3->res->code, 200, 'dynamic config: matching bearer works');

  $admin_key = '';
  my $tx4 = _request($app, 'GET', '/skeid/nodes', { Authorization => 'Bearer rotate-1' });
  is($tx4->res->code, 404, 'dynamic config: removing key disables routes again');
}

done_testing;
