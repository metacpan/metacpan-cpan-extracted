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
    config_reload_interval => 0,   # every dispatch re-reads the loader here
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

# admin.api_key_env: the deployed stack names the variable in the config and injects the value
# as an environment variable, so the key never sits in a file that gets mounted into a
# container. Without support for it the config names a key Skeid cannot see, and the admin API
# silently disables itself -- a 404 that looks like a routing bug, not a config one.
{
  local $ENV{SKEID_ADMIN_API_KEY} = 'from-env-key';
  my $skeid = Langertha::Skeid->new(
    config_loader => sub {
      return {
        admin => { api_key_env => 'SKEID_ADMIN_API_KEY' },
        nodes => [
          { id => 'env-1', url => 'http://127.0.0.1:22002/v1', model => 'qwen2.5' },
        ],
      };
    },
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);

  my $tx1 = _request($app, 'GET', '/skeid/nodes');
  is($tx1->res->code, 401, 'api_key_env: admin API is enabled, not 404');

  my $tx2 = _request($app, 'GET', '/skeid/nodes', { Authorization => 'Bearer from-env-key' });
  is($tx2->res->code, 200, 'api_key_env: value from the environment authorizes');

  my $tx3 = _request($app, 'GET', '/skeid/nodes', { Authorization => 'Bearer SKEID_ADMIN_API_KEY' });
  is($tx3->res->code, 401, 'api_key_env: the variable name is not itself the key');
}

# skeid #50: the admin key is compared through Langertha::Skeid::Secret->equal, not ne, so its
# timing gives nothing away. Timing is not asserted here; what must not move is the verdict:
# only the exact key passes -- a prefix, a longer key, an empty or missing token and another
# scheme all stay 401.
{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my $skeid = Langertha::Skeid->new;
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid, admin_api_key => 'adminkey');

  is(_request($app, 'GET', '/skeid/nodes', { Authorization => 'Bearer adminkey' })->res->code,
    200, 'constant-time compare: the exact key passes');
  is(_request($app, 'GET', '/skeid/nodes', { Authorization => 'bearer adminkey' })->res->code,
    200, 'constant-time compare: the scheme stays case-insensitive');
  for my $case (
    [ 'Bearer adminke'    => 'a prefix of the key' ],
    [ 'Bearer adminkeyX'  => 'the key plus a character' ],
    [ 'Bearer x'          => 'a much shorter key' ],
    [ 'Bearer ' . ('a' x 200) => 'a much longer key' ],
    [ 'Bearer adminkeY'   => 'same length, last character differs' ],
    [ 'Bearer '           => 'an empty token' ],
    [ 'Basic adminkey'    => 'the right key under another scheme' ],
    [ 'adminkey'          => 'the key without a scheme' ],
  ) {
    my ($header, $what) = @$case;
    my $tx = _request($app, 'GET', '/skeid/nodes', { Authorization => $header });
    is($tx->res->code, 401, "constant-time compare: $what is rejected");
    is($tx->res->headers->header('WWW-Authenticate'), 'Bearer realm="skeid-admin"',
      "constant-time compare: $what gets the bearer challenge");
  }
}

# The helper itself: equal only for identical strings, whatever the lengths.
{
  require Langertha::Skeid::Secret;
  my $eq = sub { Langertha::Skeid::Secret->equal(@_) };
  is($eq->('adminkey', 'adminkey'), 1, 'Secret->equal: identical strings');
  is($eq->('adminkey', 'adminke'),  0, 'Secret->equal: different length');
  is($eq->('adminkey', 'adminkeY'), 0, 'Secret->equal: same length, different byte');
  is($eq->('', 'adminkey'),         0, 'Secret->equal: empty against a key');
  is($eq->(undef, 'adminkey'),      0, 'Secret->equal: undef against a key');
  is($eq->('', ''),                 1, 'Secret->equal: empty equals empty (callers reject empty keys first)');
}

done_testing;
