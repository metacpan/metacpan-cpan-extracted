#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Langertha::Skeid;
use Langertha::Skeid::NodeFiles;
use Langertha::Skeid::Proxy;

# Node files (ADR 0031): nodes from a second, less trusted file. Whoever writes it -- a GPU
# manager -- must not be able to make Skeid send an environment variable or a broker secret of
# its choosing to a URL of its choosing. The main config names the file with constraints; a node
# that breaks one is left out, the rest of the file loads, and the status names position and
# rule, never the value.

my $dir = tempdir(CLEANUP => 1);
my $main = "$dir/skeid.yaml";
my $gpm  = "$dir/gpm-nodes.yaml";

my $SEQ = 1_000;
sub write_file {
  my ($path, $text) = @_;
  open my $out, '>', $path or die "open $path: $!";
  print {$out} $text;
  close $out or die "close $path: $!";
  $SEQ += 10;
  utime($SEQ, $SEQ, $path) or die "utime $path: $!";
}

sub ids { [ map { $_->{id} } @{ $_[0]->list_nodes } ] }

my $MAIN = <<'YAML';
nodes:
  - { id: trusted, url: 'http://trusted/v1', model: m, api_key_ref: secret/skeid/remote/groq }
node_files:
  - path: GPM
    allow_api_key_env: '^SKEID_NODE_GPM_[A-Z0-9_]+_API_KEY$'
    allow_url_hosts: [ '*.cai-gpm.svc' ]
    allow_kinds: [ chat, documents ]
    trust: internal
YAML
(my $main_yaml = $MAIN) =~ s/GPM/$gpm/;

write_file($gpm, <<'YAML');
nodes:
  - { id: gpu-1, url: 'http://gpu-1.cai-gpm.svc:8000/v1', model: m, api_key_env: SKEID_NODE_GPM_GPU1_API_KEY }
  - { id: steal-env, url: 'http://gpu-2.cai-gpm.svc/v1', api_key_env: SKEID_ADMIN_API_KEY }
  - { id: steal-ref, url: 'http://gpu-3.cai-gpm.svc/v1', api_key_ref: secret/skeid/remote/groq }
  - { id: elsewhere, url: 'https://attacker.example/v1', api_key_env: SKEID_NODE_GPM_X_API_KEY }
  - { id: deeper, url: 'http://a.b.cai-gpm.svc/v1' }
  - { id: trusted, url: 'http://gpu-4.cai-gpm.svc/v1' }
  - { id: probe, url: 'http://gpu-5.cai-gpm.svc/v1', capacity: { probe: prometheus, url: 'http://x/metrics' } }
  - { id: docs, url: 'http://docling.cai-gpm.svc/v1', kind: documents }
  - { id: bad-engine, url: 'http://gpu-6.cai-gpm.svc/v1', engine: no-such-engine }
  - { id: userinfo, url: 'http://u:p@gpu-7.cai-gpm.svc/v1' }
  - not-a-node
  - { url: 'http://gpu-8.cai-gpm.svc/v1' }
YAML
write_file($main, $main_yaml);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $skeid = Langertha::Skeid->new(config_file => $main);

is_deeply ids($skeid), [qw( trusted gpu-1 docs )],
  'the main config\'s nodes come first, then the node file\'s nodes that pass';
my ($gpu1) = grep { $_->{id} eq 'gpu-1' } @{ $skeid->nodes };
is $gpu1->{api_key_env}, 'SKEID_NODE_GPM_GPU1_API_KEY', 'an allowed api_key_env is kept';
is_deeply $skeid->reload_status, { ok => 1 }, 'rejected nodes do not fail the load';

my $status = $skeid->node_files_status;
is scalar(@$status), 1, 'one node file in the status';
is $status->[0]{path}, $gpm, 'named by its path';
is $status->[0]{ok}, 1, 'read fine';
is $status->[0]{accepted}, 2, 'two nodes accepted';
is_deeply $status->[0]{rejected}, [
  { position => 1,  rule => 'api_key_env' },
  { position => 2,  rule => 'api_key_ref' },
  { position => 3,  rule => 'url_host' },
  { position => 4,  rule => 'url_host' },
  { position => 5,  rule => 'id_taken' },
  { position => 6,  rule => 'field' },
  { position => 8,  rule => 'invalid' },
  { position => 9,  rule => 'url_host' },
  { position => 10, rule => 'entry' },
  { position => 11, rule => 'id' },
], 'each rejected node by position and rule';
my $all = join '', @warnings, map { "$_" } %{ $status->[0] };
unlike $all, qr/SKEID_ADMIN_API_KEY|attacker|secret\/skeid/, 'no rejected value in the status or the log';
is scalar(grep { /node \d+ rejected/ } @warnings), 10, 'each rejection logged once';

# --- a change to the node file alone reloads; the main file is untouched ---
@warnings = ();
write_file($gpm, "- { id: gpu-9, url: 'http://gpu-9.cai-gpm.svc/v1' }\n");
$skeid->call_function('nodes.list', {});
is_deeply ids($skeid), [qw( trusted gpu-9 )], 'a changed node file is picked up on the next dispatch';
is_deeply $skeid->node_files_status->[0]{rejected}, [], 'and judged afresh';

$skeid->call_function('nodes.list', {}) for 1 .. 5;
is scalar(@warnings), 0, 'an unchanged node file is not read again';

# --- a broken version keeps the last good nodes ---
write_file($gpm, "nodes: [\n");
$skeid->call_function('nodes.list', {});
is_deeply ids($skeid), [qw( trusted gpu-9 )], 'a node file that does not parse keeps its last good nodes';
$status = $skeid->node_files_status->[0];
is $status->{ok}, 0, 'and says so';
like $status->{error}, qr/not valid YAML/, 'with a reason';
ok $status->{failed_at}, 'and when';
is_deeply $skeid->reload_status, { ok => 1 }, 'the main config is not failed by it';

write_file($gpm, "nodes: []\npolicies: { open: {} }\n");
$skeid->call_function('nodes.list', {});
like $skeid->node_files_status->[0]{error}, qr/may hold only nodes\z/,
  'a node file that says more than nodes is refused whole';
is_deeply ids($skeid), [qw( trusted gpu-9 )], '...and the last good nodes stay';

unlink $gpm;
$skeid->call_function('nodes.list', {});
like $skeid->node_files_status->[0]{error}, qr/missing/, 'a node file that is gone is reported';
is_deeply ids($skeid), [qw( trusted gpu-9 )], '...and its last good nodes stay';

write_file($gpm, "nodes: []\n");
$skeid->call_function('nodes.list', {});
is_deeply ids($skeid), [qw( trusted )], 'an empty node file contributes nothing';
is $skeid->node_files_status->[0]{ok}, 1, 'and is fine';

# --- a node file adds no node with a key the main config forbids, even when the main config changes ---
{
  my $strict = $main_yaml;
  $strict =~ s/    allow_api_key_env:.*\n//;
  write_file($gpm, "- { id: gpu-1, url: 'http://gpu-1.cai-gpm.svc/v1', api_key_env: SKEID_NODE_GPM_GPU1_API_KEY }\n");
  write_file($main, $strict);
  $skeid->call_function('nodes.list', {});
  is_deeply ids($skeid), [qw( trusted )], 'without allow_api_key_env no node of the file may name a variable';
  is_deeply $skeid->node_files_status->[0]{rejected}, [{ position => 0, rule => 'api_key_env' }], '...';
}

# --- removing the section drops the file's nodes ---
write_file($main, "nodes:\n  - { id: trusted, url: 'http://trusted/v1', trust: internal }\n");
$skeid->call_function('nodes.list', {});
is_deeply ids($skeid), [qw( trusted )], 'without node_files only the main nodes';
is $skeid->node_files_status, undef, 'and no node file status';

# --- a config_loader with a version still sees node file changes ---
{
  write_file($gpm, "- { id: a, url: 'http://a.cai-gpm.svc/v1' }\n");
  my $loader_skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader => sub {
      return ({ node_files => [{ path => $gpm, allow_url_hosts => ['*.cai-gpm.svc'], trust => 'internal' }] }, 'v1');
    },
  );
  is_deeply ids($loader_skeid), ['a'], 'a loader config takes nodes from a node file';
  write_file($gpm, "- { id: b, url: 'http://b.cai-gpm.svc/v1' }\n");
  $loader_skeid->call_function('nodes.list', {});
  is_deeply ids($loader_skeid), ['b'], 'and a changed file reloads although the loader\'s version did not move';
}

# --- a less trusted writer cannot make reading the file expensive ---
{
  my $bomb = "a0: &a0 [x, x, x, x, x, x, x, x, x, x]\n";
  $bomb .= "a$_: &a$_ [" . join(', ', ("*a" . ($_ - 1)) x 10) . "]\n" for 1 .. 8;
  $bomb .= "nodes: [ { id: b, url: 'http://b.cai-gpm.svc/v1', metadata: { x: *a8 } } ]\n";
  write_file($gpm, $bomb);
  my $t0 = time;
  my $s = Langertha::Skeid->new(config_loader => sub {
    +{ node_files => [{ path => $gpm, allow_url_hosts => ['*.cai-gpm.svc'], trust => 'internal' }] } });
  ok time - $t0 < 5, 'a file of nested YAML aliases is refused quickly';
  like $s->node_files_status->[0]{error}, qr/YAML alias|only nodes/, 'and says why';
  is_deeply ids($s), [], 'and contributes nothing';

  write_file($gpm, "- { id: d, url: 'http://d.cai-gpm.svc/v1', metadata: " . ('[' x 20) . (']' x 20) . " }\n");
  $s = Langertha::Skeid->new(config_loader => sub {
    +{ node_files => [{ path => $gpm, allow_url_hosts => ['*.cai-gpm.svc'], trust => 'internal' }] } });
  like $s->node_files_status->[0]{error}, qr/nests deeper/, 'deep nesting is refused';
}

# --- a node file change keeps the main nodes' admin-set health ---
{
  write_file($gpm, "- { id: g1, url: 'http://g1.cai-gpm.svc/v1' }\n");
  my $s = Langertha::Skeid->new(config_reload_interval => 0, config_loader => sub { +{
    nodes => [{ id => 'main', url => 'http://main/v1', trust => 'internal' }],
    node_files => [{ path => $gpm, allow_url_hosts => ['*.cai-gpm.svc'], trust => 'internal' }] } });
  $s->set_node_health('main', 0);
  write_file($gpm, "- { id: g1, url: 'http://g1.cai-gpm.svc/v1' }\n- { id: g2, url: 'http://g2.cai-gpm.svc/v1' }\n");
  $s->call_function('nodes.list', {});
  is_deeply ids($s), [qw( main g1 g2 )], 'the changed node file is applied';
  my ($m) = grep { $_->{id} eq 'main' } @{ $s->nodes };
  is $m->{healthy}, 0, 'and the main node keeps the health an admin set';
}

# --- a keyless node from a node file never gets the client's credentials ---
{
  require Mojolicious;
  require Mojo::Server::Daemon;
  my @auth;
  my $up = Mojolicious->new;
  $up->log->level('fatal');
  $up->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    push @auth, [ $c->req->headers->authorization, $c->req->headers->header('X-Api-Key') ];
    $c->render(json => { id => 'c', object => 'chat.completion', model => 'm',
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }] });
  });
  my $d = Mojo::Server::Daemon->new(app => $up, listen => ['http://127.0.0.1'], silent => 1);
  $d->start;
  my $port = $d->ports->[0];
  write_file($gpm, "- { id: f1, url: 'http://127.0.0.1:$port/v1', model: from-file }\n");
  my $s = Langertha::Skeid->new(config_loader => sub { +{
    nodes      => [{ id => 'trusted', url => "http://127.0.0.1:$port/v1", model => 'from-main', trust => 'internal' }],
    node_files => [{ path => $gpm, allow_url_hosts => ['127.0.0.1'], trust => 'internal' }] } });
  require Test::Mojo;
  my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $s));
  $t->app->log->level('fatal');
  my %h = (Authorization => 'Bearer sk-customer-secret', 'X-Api-Key' => 'sk-customer-secret');
  $t->post_ok('/v1/chat/completions' => \%h => json => { model => 'from-file', messages => [{ role => 'user', content => 'x' }] })
    ->status_is(200);
  is_deeply $auth[-1], [ undef, undef ], 'the node from the node file sees no client credential';
  $t->post_ok('/v1/chat/completions' => \%h => json => { model => 'from-main', messages => [{ role => 'user', content => 'x' }] })
    ->status_is(200);
  is $auth[-1][0], 'Bearer sk-customer-secret', 'a keyless main-config node keeps the documented pass-through';
}

# --- GET /skeid/config shows the node files, /health does not ---
{
  require Test::Mojo;
    write_file($gpm, "- { id: a, url: 'http://a.cai-gpm.svc/v1' }\n- { id: z, url: 'http://attacker.example/v1' }\n");
  my $admin = 'sk-admin-test-only';
  my $s = Langertha::Skeid->new(admin_api_key => $admin, config_loader => sub {
    +{ node_files => [{ path => $gpm, allow_url_hosts => ['*.cai-gpm.svc'], trust => 'internal' }] } });
  my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $s));
  $t->get_ok('/skeid/config' => { Authorization => "Bearer $admin" })->status_is(200)
    ->json_is('/node_files/0/path', $gpm)
    ->json_is('/node_files/0/accepted', 1)
    ->json_is('/node_files/0/rejected', [{ position => 1, rule => 'url_host' }]);
  unlike $t->tx->res->body, qr/attacker/, 'the rejected value is not shown';
  $t->get_ok('/health')->status_is(200);
  unlike $t->tx->res->body, qr/node_files/, '/health says nothing about node files';
}

# --- the section itself belongs to the main config: malformed fails the load ---
for my $case (
  [ [ { allow_url_hosts => ['x'] } ],                      qr/path required/ ],
  [ [ { path => $gpm } ],                                  qr/allow_url_hosts must list/ ],
  [ [ { path => $gpm, allow_url_hosts => ['x/y'] } ],      qr/no host name/ ],
  [ [ { path => $gpm, allow_url_hosts => ['x'], allow_api_key_env => '(' } ], qr/not a valid regular/ ],
  [ [ { path => $gpm, allow_url_hosts => ['x'], allow_kinds => ['video'] } ], qr/unknown kind/ ],
  [ [ map { +{ path => $gpm, allow_url_hosts => ['x'] } } 1 .. 2 ], qr/listed twice/ ],
  [ 'nope', qr/must be a list/ ],
) {
  my ($section, $error) = @$case;
  ok !eval { Langertha::Skeid->new(config_loader => sub { +{ node_files => $section } }); 1 },
    'a malformed node_files section fails the load';
  like $@, $error, "... ($error)";
}

# --- host patterns ---
{
  my ($entry) = @{ Langertha::Skeid::NodeFiles->normalize_config(
    [{ path => 'x', allow_url_hosts => [ '*.cai-gpm.svc', 'exact.example' ], trust => 'internal' }]) };
  my $check = sub { Langertha::Skeid::NodeFiles->check($skeid, $entry, { id => 'n', url => $_[0] }) };
  is $check->('http://gpu-1.CAI-GPM.svc:8000/v1'), undef, 'a host matches case-insensitively, any port';
  is $check->('https://exact.example/v1'), undef, 'an exact pattern matches';
  is $check->('http://cai-gpm.svc/v1'), 'url_host', '* needs a label';
  is $check->('http://evil.exact.example/v1'), 'url_host', 'an exact pattern is not a suffix';
  is $check->('ftp://gpu-1.cai-gpm.svc/'), 'url_host', 'only http and https';
  is $check->('http://gpu-1.cai-gpm.svc.attacker.example/'), 'url_host', 'anchored at the end';
}

done_testing;
