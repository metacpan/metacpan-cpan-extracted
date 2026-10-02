use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Mojo::Transaction::HTTP;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# skeid k64: where the admin API key comes from, and that a reload keeps that order. First an
# explicit key (skeid serve --admin-api-key, build_app(admin_api_key => ...), or new()), then
# the config (admin_api_key, admin_api_key_env, admin.api_key, admin.api_key_env), then
# SKEID_ADMIN_API_KEY, then nothing -- admin API off. A reload re-applies the same order: it
# used to overwrite the explicit key with the file's value, or with nothing.

sub _request {
  my ($app, $path, $token) = @_;
  my $tx = Mojo::Transaction::HTTP->new;
  $tx->req->method('GET');
  $tx->req->url->parse($path);
  $tx->req->headers->header(Authorization => 'Bearer ' . $token) if defined $token;
  $app->handler($tx);
  return $tx->res->code;
}

sub _loader_skeid {
  my ($cfg_ref, %args) = @_;
  return Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader          => sub { return { %{ $$cfg_ref } } },
    %args,
  );
}

my @nodes = ({ id => 'n1', url => 'http://127.0.0.1:1/v1', model => 'm' });

# --- the explicit key from build_app survives a changed config ---
{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my $cfg = { nodes => [@nodes] };
  my $skeid = _loader_skeid(\$cfg);
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid, admin_api_key => 'cli-key');
  is _request($app, '/skeid/nodes', 'cli-key'), 200, 'build_app admin_api_key: in force';

  $cfg = { nodes => [@nodes, { id => 'n2', url => 'http://127.0.0.1:2/v1', model => 'm' }] };
  is _request($app, '/skeid/nodes', 'cli-key'), 200,
    'a changed config without an admin key keeps the explicit key';
  is scalar @{ $skeid->list_nodes }, 2, 'and the changed config was applied';

  $cfg = { nodes => [@nodes], admin => { api_key => 'file-key' } };
  is _request($app, '/skeid/nodes', 'cli-key'), 200, 'the explicit key wins over the config';
  is _request($app, '/skeid/nodes', 'file-key'), 401, 'the config key is not accepted beside it';

  $skeid->set_admin_api_key('');
  is _request($app, '/skeid/nodes', 'file-key'), 200,
    'clearing the explicit key falls back to the config at once';
}

# --- the explicit key from new(), with a config file ---
{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my $cfg = { nodes => [@nodes], admin_api_key => 'file-key' };
  my $skeid = _loader_skeid(\$cfg, admin_api_key => 'ctor-key');
  is $skeid->admin_api_key, 'ctor-key', 'new(admin_api_key): wins over the config at construction';
  $cfg = { nodes => [@nodes] };
  $skeid->call_function('nodes.list', {});
  is $skeid->admin_api_key, 'ctor-key', 'and over the next changed config';
}

# --- skeid serve --admin-api-key: build_app with a config_file ---
{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my ($fh, $path) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print {$fh} "nodes:\n  - id: f1\n    url: http://127.0.0.1:3/v1\n";
  close $fh;
  my $app = Langertha::Skeid::Proxy->build_app(config_file => $path, admin_api_key => 'serve-key');
  is _request($app, '/skeid/nodes', 'serve-key'), 200, 'serve --admin-api-key: in force';

  open $fh, '>', $path or die "open $path: $!";
  print {$fh} "nodes:\n  - id: f2\n    url: http://127.0.0.1:4/v1\n";
  close $fh;
  my $mtime = (stat($path))[9] + 10;
  utime($mtime, $mtime, $path);
  is _request($app, '/skeid/nodes', 'serve-key'), 200,
    'serve --admin-api-key: survives a changed config file';
  is $app->skeid->list_nodes->[0]{id}, 'f2', 'and the changed file was applied';
}

# --- SKEID_ADMIN_API_KEY is the fallback when the config names no key ---
{
  local $ENV{SKEID_ADMIN_API_KEY} = 'env-key';
  my $cfg = { nodes => [@nodes] };
  my $skeid = _loader_skeid(\$cfg);
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  is _request($app, '/skeid/nodes', 'env-key'), 200,
    'SKEID_ADMIN_API_KEY: in force with a config that names no key';

  $cfg = { nodes => [@nodes], admin => { api_key => 'file-key' } };
  is _request($app, '/skeid/nodes', 'file-key'), 200, 'a key in the config wins over it';
  is _request($app, '/skeid/nodes', 'env-key'), 401, 'and the variable is then not accepted';

  $cfg = { nodes => [@nodes], admin => { api_key => '' } };
  is _request($app, '/skeid/nodes', 'env-key'), 404,
    'a config that sets the key empty turns the admin API off, variable or not';

  $cfg = { nodes => [@nodes, { id => 'n3', url => 'http://127.0.0.1:5/v1', model => 'm' }] };
  is _request($app, '/skeid/nodes', 'env-key'), 200,
    'the key removed from the config again: back to SKEID_ADMIN_API_KEY';
}

# --- nothing anywhere: off ---
{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  my $cfg = { nodes => [@nodes] };
  my $skeid = _loader_skeid(\$cfg);
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  is _request($app, '/skeid/nodes', 'x'), 404, 'no key anywhere: admin API off';
}

# --- a failed reload keeps the key it found, explicit or not ---
{
  local $ENV{SKEID_ADMIN_API_KEY} = '';
  local $SIG{__WARN__} = sub { };
  my $cfg = { nodes => [@nodes], admin_api_key => 'file-key' };
  my $skeid = _loader_skeid(\$cfg);
  $cfg = { nodes => [@nodes], admin_api_key => 'new-key', default_policy => 'missing' };
  $skeid->call_function('nodes.list', {});
  is $skeid->reload_status->{ok}, 0, 'a broken config fails the reload';
  is $skeid->admin_api_key, 'file-key', 'and the admin key of the kept config stays in force';
}

done_testing;
