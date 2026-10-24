use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Mojo::File qw( tempdir );
use Digest::SHA qw( sha256_hex );
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::SwaggerUI;

# The Swagger UI (skeid k105, ADR 0025). Skeid ships none of it. Off by default -- then there is
# no UI path and nothing is ever fetched. Switched on, the first request for the UI fetches the
# pinned swagger-ui-dist files without blocking the loop, checks them against their digests,
# caches them and serves them from the cache from then on. A fetch that fails answers 502, is
# remembered for a while so that no request starts another, and a fetch that never answers
# does not hang the request. Every fetch here goes through an injected fetcher: no network.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY )};

my %BODY = (
  'swagger-ui.css'       => "/* fake swagger css */\nbody{margin:0}\n",
  'swagger-ui-bundle.js' => "/* fake swagger bundle */\nwindow.SwaggerUIBundle=function(){};\n",
);
my %DIGEST = map { $_ => sha256_hex($BODY{$_}) } keys %BODY;

my @FETCHED;
my $MODE = 'ok';

# Answers from %BODY, on a timer so the answer is never synchronous.
sub fake_fetcher {
  return sub {
    my ($url, $cb) = @_;
    push @FETCHED, $url;
    my ($name) = $url =~ m{([^/]+)\z};
    return if $MODE eq 'hang';
    Mojo::IOLoop->timer(0.05 => sub {
      return $cb->(undef, 'connection refused') if $MODE eq 'fail';
      return $cb->('<html>captive portal</html>', undef) if $MODE eq 'tampered';
      $cb->($BODY{$name}, undef);
    });
  };
}

sub ui_object {
  my (%opt) = @_;
  return Langertha::Skeid::SwaggerUI->new(fetcher => fake_fetcher(), digests => \%DIGEST, %opt);
}

my @LOG;
sub app_for {
  my ($cfg, %opts) = @_;
  my $skeid = Langertha::Skeid->new(config_loader => sub { $cfg }, config_reload_interval => 0);
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid, %opts);
  $app->log->unsubscribe('message')->on(message => sub {
    my ($log, $level, @lines) = @_;
    push @LOG, [ $level, join(' ', @lines) ];
  });
  my $t = Test::Mojo->new($app);
  $app->log->level("trace");
  return $t;
}

my $NODES = [ { id => 'n1', url => 'http://127.0.0.1:1/v1', model => 'm' } ];

# --- off: no UI path, no fetch, the document is there ---
{
  @FETCHED = ();
  my $dir = tempdir;
  my $t = app_for({ nodes => $NODES, openapi => { cache_dir => "$dir" } }, swagger_ui => ui_object());
  $t->get_ok('/docs')->status_is(404, '/docs is an unknown path by default');
  $t->get_ok('/docs/swagger-ui.css')->status_is(404);
  $t->get_ok('/docs/init.js')->status_is(404);
  $t->get_ok('/openapi.json')->status_is(200, 'the document is served without the UI');
  is scalar(@FETCHED), 0, 'nothing was fetched';

  my $t2 = app_for({ nodes => $NODES, openapi => { swagger_ui => 0 } }, swagger_ui => ui_object());
  $t2->get_ok('/docs')->status_is(404, 'swagger_ui: false is the same');
  is scalar(@FETCHED), 0, 'and fetches nothing';
}

# --- on: fetched at the first request, then served from the cache ---
{
  @FETCHED = ();
  $MODE = 'ok';
  my $dir = tempdir;
  my $t = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => "$dir" } },
    swagger_ui => ui_object());
  is scalar(@FETCHED), 0, 'switched on, still nothing is fetched at start';

  $t->get_ok('/docs')->status_is(200)->content_type_like(qr{text/html})
    ->content_like(qr{/docs/swagger-ui-bundle\.js})->content_unlike(qr{<script>[^<]});
  is scalar(@FETCHED), 2, 'the first request fetched the two files';
  like $_, qr{\Ahttps://cdn\.jsdelivr\.net/npm/swagger-ui-dist\@5\.17\.14/swagger-ui}, 'from the pinned release'
    for @FETCHED;
  ok -f "$dir/$_", "$_ is in the cache directory" for sort keys %BODY;

  $t->get_ok('/docs/swagger-ui.css')->status_is(200)->content_type_like(qr{text/css})
    ->content_is($BODY{'swagger-ui.css'});
  $t->get_ok('/docs/swagger-ui-bundle.js')->status_is(200)->content_type_like(qr{javascript})
    ->content_is($BODY{'swagger-ui-bundle.js'});
  $t->get_ok('/docs/init.js')->status_is(200)->content_type_like(qr{javascript})
    ->content_like(qr{/openapi\.json});
  $t->get_ok('/docs')->status_is(200);
  is scalar(@FETCHED), 2, 'later requests were served from the cache: no further fetch';

  $t->get_ok('/docs/other.js')->status_is(404, 'only the known assets are served');
  $t->get_ok('/docs/..%2Fswagger-ui.css')->status_is(404);
  $t->get_ok('/docs/.swagger-ui.css.tmp')->status_is(404);

  my @tmp = glob("$dir/.*.tmp");
  is scalar(@tmp), 0, 'no temporary file is left in the cache';

  # A new app on the same cache directory: the assets are already there.
  @FETCHED = ();
  my $again = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => "$dir" } },
    swagger_ui => ui_object());
  $again->get_ok('/docs')->status_is(200);
  is scalar(@FETCHED), 0, 'a restart finds the cache and fetches nothing';
}

# --- concurrent first requests share one fetch, without blocking the loop ---
{
  @FETCHED = ();
  $MODE = 'ok';
  my $dir = tempdir;
  my $t = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => "$dir" } },
    swagger_ui => ui_object());
  my @status;
  my $pending = 5;
  for my $i (1 .. 5) {
    $t->ua->get('/docs' => sub {
      my ($ua, $tx) = @_;
      push @status, $tx->res->code;
      Mojo::IOLoop->stop unless --$pending;
    });
  }
  # The loop is free while the fetch is out: a request for a route that needs no assets answers.
  my $health;
  $t->ua->get('/health' => sub { $health = $_[1]->res->code });
  Mojo::IOLoop->start;
  is_deeply \@status, [ (200) x 5 ], 'every concurrent first request is answered';
  is scalar(@FETCHED), 2, 'and the files were fetched once, not once per request';
  is $health, 200, 'the loop served another route meanwhile';
}

# --- a failing fetch: 502, remembered, no retry storm, no cache, then it recovers ---
{
  @FETCHED = ();
  @LOG = ();
  $MODE = 'fail';
  my $dir = tempdir;
  my $t = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => "$dir" } },
    swagger_ui => ui_object(retry_after => 0.4));
  $t->get_ok('/docs')->status_is(502, 'a fetch that fails is a clean 502');
  $t->json_is('/error/type' => 'upstream_error');
  my $fetched = scalar @FETCHED;
  ok $fetched >= 1, 'it was tried';
  ok !glob("$dir/*"), 'nothing was cached';

  $t->get_ok('/docs')->status_is(503, 'within the window the failure is remembered')
    ->header_like('Retry-After' => qr/\A\d+(?:\.\d+)?\z/);
  $t->get_ok('/docs/swagger-ui.css')->status_is(503);
  is scalar(@FETCHED), $fetched, 'no further fetch was started: no retry storm';
  ok scalar(grep { $_->[0] eq "error" && $_->[1] =~ /swagger ui: / } @LOG), "the failure is logged" or diag explain \@LOG;
  ok !grep({ $_->[1] =~ /Bearer|api[_-]?key/i } @LOG), 'and the log line names no credential';

  # Wait the window out; the next request tries again and, the network back, succeeds.
  Mojo::IOLoop->timer(0.5 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  $MODE = 'ok';
  $t->get_ok('/docs')->status_is(200, 'after the window it tries again');
  ok -f "$dir/swagger-ui.css", 'and caches';
}

# --- what is fetched has to be what was pinned ---
{
  @FETCHED = ();
  $MODE = 'tampered';
  my $dir = tempdir;
  my $t = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => "$dir" } },
    swagger_ui => ui_object());
  $t->get_ok('/docs')->status_is(502, 'content that does not match its digest is refused');
  ok !glob("$dir/*"), 'and not cached';

  # The real object, the real digests: a body that is not the release fails the same way.
  my $real = Langertha::Skeid::SwaggerUI->new(fetcher => fake_fetcher());
  my $t2 = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => "$dir" } },
    swagger_ui => $real);
  $MODE = 'ok';
  $t2->get_ok('/docs')->status_is(502, 'the compiled-in digests are not satisfied by a fake body');
}

# --- a fetch that never answers does not hang the request ---
{
  @FETCHED = ();
  $MODE = 'hang';
  my $dir = tempdir;
  my $t = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => "$dir" } },
    swagger_ui => ui_object(timeout => 0.3));
  my $start = time;
  $t->get_ok('/docs')->status_is(502, 'a silent fetch ends in a 502');
  ok time - $start < 5, 'in bounded time';
  $MODE = 'ok';
}

# --- a cache directory that cannot be written is a 502, not a crash ---
{
  @FETCHED = ();
  $MODE = 'ok';
  my $t = app_for({ nodes => $NODES, openapi => { swagger_ui => 1, cache_dir => '/proc/skeid-no/such' } },
    swagger_ui => ui_object());
  $t->get_ok('/docs')->status_is(502);
}

# --- the config section is strict, and a reload takes the UI away again ---
{
  my $load = sub {
    my ($section) = @_;
    my $ok = eval { Langertha::Skeid->new(config_loader => sub { { openapi => $section } }); 1 };
    return $ok ? '' : "$@";
  };
  like $load->('on'),                         qr/openapi must be a hash/, 'a scalar section is refused';
  like $load->({ ui => 1 }),                  qr/openapi: unknown key 'ui'/, 'an unknown key is refused';
  like $load->({ swagger_ui => 'maybe' }),    qr/swagger_ui must be true or false/, 'a non-boolean switch is refused';
  like $load->({ swagger_ui => 1, cache_dir => 'relative/dir' }), qr/cache_dir must be an absolute path/,
    'a relative cache_dir is refused';
  is $load->({}), '', 'an empty section loads';
  is $load->({ swagger_ui => 'true', cache_dir => '/var/cache/skeid' }), '', 'true and an absolute path load';

  my $cfg = { openapi => { swagger_ui => 1, cache_dir => '/var/cache/skeid' } };
  my $skeid = Langertha::Skeid->new(config_loader => sub { $cfg }, config_reload_interval => 0);
  ok $skeid->openapi_swagger_ui, 'on';
  is $skeid->openapi_cache_dir, '/var/cache/skeid', 'with its directory';
  $cfg = { nodes => [] };
  $skeid->reload_config;
  ok !$skeid->openapi_swagger_ui, 'removed from the file: off again';
  ok !defined $skeid->openapi_cache_dir, 'and the directory forgotten';
}

# --- the default cache directory is a private per-user one, never a shared path ---
{
  local $ENV{XDG_CACHE_HOME} = '/xdg';
  is(Langertha::Skeid::SwaggerUI->default_cache_dir, '/xdg/skeid/swagger-ui-5.17.14', 'XDG_CACHE_HOME first');
  local $ENV{XDG_CACHE_HOME};
  delete $ENV{XDG_CACHE_HOME};
  local $ENV{HOME} = '/home/someone';
  is(Langertha::Skeid::SwaggerUI->default_cache_dir, '/home/someone/.cache/skeid/swagger-ui-5.17.14', 'then HOME');
}

done_testing;
