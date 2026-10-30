#!/usr/bin/env perl
# ABSTRACT: MCP server entries: fields, statuses, names, ${VAR} expansion, timeouts (ADR 0029 §3-6, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Langertha::Raider::MCP::Config;

# Entries are user-scope servers of ~/.claude.json here (no approval in the
# way), so the status says only what the entry itself says.

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $root = path(tempdir(CLEANUP => 1))->realpath;

sub model {
  my ( $servers, %args ) = @_;
  $home->child('.claude.json')->spew_raw($json->encode({ mcpServers => $servers }));
  return Langertha::Raider::MCP::Config->new(
    root          => "$root",
    claude_layout => 1,
    env           => {},
    %args,
  );
}

sub one {
  my ( $entry, %args ) = @_;
  return model({ srv => $entry }, %args)->server('srv');
}

subtest 'stdio entry: fields, cwd, project dir' => sub {
  my $s = one({ command => 'npx', args => [ '-y', 'pkg', 3 ], env => { A => 'x', N => 5 } });
  is($s->{status}, 'configured', 'configured');
  is($s->{transport}, 'stdio', 'no type is stdio');
  is($s->{command}, 'npx', 'command');
  is($s->{args}, [ '-y', 'pkg', '3' ], 'args, numbers as strings');
  is($s->{env}, { A => 'x', N => '5' }, 'env');
  is($s->{cwd}, "$root", 'runs in the root');
  is($s->{project_dir}, "$root", 'project dir');
  is($s->{key}, 'srv', 'key');
  is($s->{tool_prefix}, 'mcp__srv__', 'tool prefix');
  is($s->{approval}, { required => 0, state => 'not required', source => undef, by => undef }, 'user scope: no approval');
  is($s->{warnings}, [], 'no warnings');
  is([ map { $_->{name} } Langertha::Raider::MCP::Config->new( root => "$root", claude_layout => 1, env => {} )->startable ],
    ['srv'], 'startable');
};

subtest 'http entry' => sub {
  for my $type (qw( http streamable-http )) {
    my $s = one({ type => $type, url => 'https://x.test/mcp', headers => { 'X-Key' => 'k' } });
    is([ @$s{qw( status transport url )} ], [ 'configured', 'http', 'https://x.test/mcp' ], $type);
    is($s->{headers}, { 'X-Key' => 'k' }, 'headers');
  }
  is(one({ type => 'http', url => '' })->{status}, 'not_configured', 'empty url: not configured');
  is(one({ type => 'http' })->{reason}, 'no URL configured for this server', 'no url: not configured');
};

subtest 'invalid entries' => sub {
  my %cases = (
    'url without type'   => [ { url => 'https://x' }, qr/needs a "type"/ ],
    'unknown type'       => [ { type => 'grpc', command => 'x' }, qr/unknown type "grpc"/ ],
    'no command'         => [ { args => [] }, qr/needs a "command"/ ],
    'empty command'      => [ { command => '' }, qr/needs a "command"/ ],
    'args not a list'    => [ { command => 'x', args => 'a b' }, qr/"args" must be a list/ ],
    'args with a map'    => [ { command => 'x', args => [ {} ] }, qr/"args" must be a list/ ],
    'args with a bool'   => [ { command => 'x', args => [ JSON::MaybeXS->true ] }, qr/"args" must be a list/ ],
    'env not a map'      => [ { command => 'x', env => [ 'A=1' ] }, qr/"env" must be a map/ ],
    'headers not a map'  => [ { type => 'http', url => 'https://x', headers => 'h' }, qr/"headers" must be a map/ ],
    'url not a string'   => [ { type => 'http', url => [ 'x' ] }, qr/"url" must be a string/ ],
    'timeout not a num'  => [ { command => 'x', timeout => '10s' }, qr/timeout must be a number/ ],
    'entry not a map'    => [ 'npx foo', qr/not an object/ ],
  );
  for my $case (sort keys %cases) {
    my ( $entry, $re ) = @{ $cases{$case} };
    my $s = one($entry);
    is($s->{status}, 'invalid', $case.': invalid');
    like($s->{reason}, $re, $case.': reason');
  }
  is([ Langertha::Raider::MCP::Config->new( root => "$root", claude_layout => 1, env => {} )->startable ], [],
    'an invalid server is not startable');
};

subtest 'unsupported entries' => sub {
  like(one({ type => 'sse', url => 'https://x' })->{reason}, qr/sse transport is not supported/, 'sse');
  like(one({ type => 'ws', url => 'wss://x' })->{reason}, qr/ws transport is not supported/, 'ws');
  like(one({ type => 'sdk', name => 'x' })->{reason}, qr/Agent SDK/, 'sdk');
  like(one({ type => 'http', url => 'https://x', headersHelper => '/bin/h' })->{reason}, qr/headersHelper/, 'headersHelper');
  like(one({ type => 'http', url => 'https://x', oauth => { clientId => 'c' } })->{reason}, qr/oauth/, 'oauth');
  is(one({ type => 'sse', url => 'https://x' })->{status}, 'unsupported', 'status unsupported');
};

subtest 'unknown fields warn, timeouts' => sub {
  my $s = one({ command => 'x', description => 'd', url2 => 1 });
  is($s->{status}, 'configured', 'still configured');
  is($s->{warnings}, [ 'unknown field "description" ignored', 'unknown field "url2" ignored' ], 'warned');

  is(one({ command => 'x', timeout => 60000 })->{timeout_ms}, 60000, 'server timeout');
  my $low = one({ command => 'x', timeout => 500 });
  is($low->{timeout_ms}, undef, 'below 1000 ignored');
  is($low->{warnings}, [ 'timeout 500 below 1000 ms is ignored' ], 'with a warning');

  my $env = { MCP_TIMEOUT => '10000', MCP_TOOL_TIMEOUT => '45000' };
  my $m = model({ a => { command => 'x' }, b => { command => 'x', timeout => 2000 } }, env => $env);
  is($m->startup_timeout_ms, 10000, 'MCP_TIMEOUT');
  is($m->tool_timeout_ms, 45000, 'MCP_TOOL_TIMEOUT');
  is($m->server('a')->{timeout_ms}, 45000, 'MCP_TOOL_TIMEOUT for a server without timeout');
  is($m->server('b')->{timeout_ms}, 2000, 'a server timeout wins');

  my $d = model({}, env => {});
  is([ $d->startup_timeout_ms, $d->tool_timeout_ms ], [ 30000, undef ], 'defaults: 30 s, no tool limit');
  my $bad = model({}, env => { MCP_TIMEOUT => 'soon', MCP_TOOL_TIMEOUT => '0' });
  is($bad->startup_timeout_ms, 30000, 'bad MCP_TIMEOUT: default');
  is($bad->tool_timeout_ms, undef, 'zero MCP_TOOL_TIMEOUT: ignored');
  is($bad->env_warnings, [
    'MCP_TIMEOUT=soon is not a positive number of milliseconds; ignored',
    'MCP_TOOL_TIMEOUT=0 is not a positive number of milliseconds; ignored',
  ], 'reported');
};

subtest 'names: normalisation, refused names, collisions' => sub {
  my $m = model({
    'my.server' => { command => 'x' },
    'a b/c'     => { command => 'x' },
    'ok-name_1' => { command => 'x' },
  });
  is($m->server('my.server')->{key}, 'my_server', 'dot becomes _');
  is($m->server('a b/c')->{key}, 'a_b_c', 'space and slash become _');
  is($m->server('ok-name_1')->{key}, 'ok-name_1', 'letters, digits, - and _ stay');
  is($m->tool_name($m->server('my.server'), 'get.thing/x'), 'mcp__my_server__get_thing_x', 'tool part normalised too');
  is($m->normalize_name("caf\x{e9}"), 'caf_', 'a non-ASCII character becomes _');

  for my $bad ('a__b', '_lead', 'trail_', '.dot', 'x..y') {
    my $s = model({ $bad => { command => 'x' } })->server($bad);
    is($s->{status}, 'invalid', $bad.': invalid');
    like($s->{reason}, qr/could not be told apart/, $bad.': reason');
  }

  my $c = model({ 'a.b' => { command => 'x' }, 'a_b' => { command => 'y' } });
  is($c->server('a.b')->{status}, 'configured', 'the first of the colliding names stays');
  is($c->server('a_b')->{status}, 'invalid', 'the second is invalid');
  like($c->server('a_b')->{reason}, qr/collide with server a\.b/, 'naming the first');
};

subtest 'expansion' => sub {
  my $env = { HOST => 'h.test', EMPTY => '', TOKEN => 't0k', ANTHROPIC_API_KEY => 'sk-secret',
    LANGERTHA_OPENAI_API_KEY => 'sk-2', CLAUDE_PROJECT_DIR => '/from/env' };
  my $m = model({
    s => {
      command => '${BIN:-/usr/bin/srv}',
      args    => [ '--host=${HOST}', '${EMPTY:-fallback}', '${MISSING}', '${CLAUDE_PROJECT_DIR:-.}', '$HOST', '${:-x}' ],
      env     => { KEY => '${ANTHROPIC_API_KEY}', T => 'a${TOKEN}b' },
    },
    h => {
      type    => 'http',
      url     => 'https://${HOST}/mcp?k=${ANTHROPIC_API_KEY:-dflt}',
      headers => { Authorization => 'Bearer ${LANGERTHA_OPENAI_API_KEY}', X => '${TOKEN} ${NOPE}' },
    },
  }, env => $env);
  my $s = $m->server('s');
  is($s->{command}, '/usr/bin/srv', 'unset with default: the default');
  is($s->{args}, [ '--host=h.test', '', '${MISSING}', '/from/env', '$HOST', '${:-x}' ],
    'set, set-but-empty (no default), unset left as written, env CLAUDE_PROJECT_DIR, bare $VAR and odd text untouched');
  is($s->{env}, { KEY => 'sk-secret', T => 'at0kb' }, 'env values; a credential reaches a stdio server');
  is($s->{warnings}, [ '${MISSING} is not set' ], 'one warning for the unset variable');
  is($s->{status}, 'configured', 'a missing variable does not stop the server');

  my $h = $m->server('h');
  is($h->{url}, 'https://h.test/mcp?k=', 'credential in a remote url: empty, default ignored');
  is($h->{headers}, { Authorization => 'Bearer ', X => 't0k ${NOPE}' }, 'raider engine key in headers: empty');
  is($h->{warnings}, [
    '${ANTHROPIC_API_KEY} is a credential and is not passed to a remote server',
    '${LANGERTHA_OPENAI_API_KEY} is a credential and is not passed to a remote server',
    '${NOPE} is not set',
  ], 'warned');

  ok($m->is_credential_variable($_), $_.' is a credential')
    for qw( ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN AWS_BEARER_TOKEN_BEDROCK LANGERTHA_GROQ_API_KEY );
  ok(!$m->is_credential_variable($_), $_.' is not') for qw( GITHUB_API_KEY TOKEN OPENAI_API_KEY_X );

  my @w;
  is($m->expand('${A}${A}', warnings => \@w), '${A}${A}', 'expand on its own');
  is(scalar @w, 2, 'warns per occurrence');
  is($m->expand('x${A:-}y'), 'xy', 'empty default');
  is($m->expand('${HOST}', vars => { HOST => 'vars-win' }), 'vars-win', 'vars before env');
};

subtest 'expansion uses %ENV by default' => sub {
  local $ENV{RAIDER_T251_X} = 'from-env';
  $home->child('.claude.json')->spew_raw($json->encode({ mcpServers => { e => { command => '${RAIDER_T251_X}' } } }));
  my $m = Langertha::Raider::MCP::Config->new( root => "$root", claude_layout => 1 );
  is($m->server('e')->{command}, 'from-env', 'copied from %ENV');
};

done_testing;
