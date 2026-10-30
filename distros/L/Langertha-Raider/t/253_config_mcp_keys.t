#!/usr/bin/env perl
# ABSTRACT: the mcp: and mcp_approvals: keys of the raider config files (ADR 0029 §2, §7, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Langertha::Raider::Config;

# mcp: (project file and home file, top level only) holds MCP servers in
# Claude Code's entry format; mcp_approvals: (home file only) approves
# project servers per project dir. Both are raider keys: never engine
# options, never sections.

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";

sub spew_yaml { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_utf8(ref $data ? YAML::PP->new->dump_string($data) : $data) }
sub project { path(tempdir(CLEANUP => 1))->realpath }
sub config { Langertha::Raider::Config->new( root => "$_[0]" ) }
sub reset_home { $home->child('.raider')->remove_tree }

subtest 'mcp_servers: project file, then home file' => sub {
  reset_home();
  my $root = project();
  spew_yaml($root->child('.raider/config.yml'), { engine => 'openai', mcp => {
    zeta => { command => 'z' },
    alpha => { type => 'http', url => 'https://a/mcp' },
  } });
  spew_yaml($home->child('.raider/config.yml'), { mcp => { alpha => { command => 'home-alpha' } } });
  my $c = config($root);
  is($c->mcp_servers, [
    { name => 'alpha', entry => { type => 'http', url => 'https://a/mcp' }, scope => 'raider-project', source => '.raider/config.yml' },
    { name => 'zeta',  entry => { command => 'z' },                          scope => 'raider-project', source => '.raider/config.yml' },
    { name => 'alpha', entry => { command => 'home-alpha' },                 scope => 'raider-home',    source => '~/.raider/config.yml' },
  ], 'both files, project first, sorted by name, entries as written');
  is($c->engine_options('openai'), {}, 'never an engine option');
  ok($c->is_app_key($_), $_.' is a raider key') for qw( mcp mcp_approvals );
  ok(!(grep { $_->{key} eq 'mcp' } @{ $c->explain('openai')->{values} }), 'not a layered value');
};

subtest 'legacy .raider.yml takes mcp: too' => sub {
  reset_home();
  my $root = project();
  spew_yaml($root->child('.raider.yml'), { mcp => { x => { command => 'x' } } });
  is([ map { $_->{source} } @{ config($root)->mcp_servers } ], ['.raider.yml'], 'source .raider.yml');
};

subtest 'mcp: inside a section is reported, not read' => sub {
  reset_home();
  my $root = project();
  spew_yaml($root->child('.raider/config.yml'), { engine => 'openai', openai => { mcp => { x => { command => 'x' } } },
    default => { mcp_approvals => { '/x' => { enable_all => 1 } } } });
  my $c = config($root);
  is($c->mcp_servers, [], 'nothing read');
  my %ignored = map { $_->{key} => $_->{reason} } @{ $c->explain('openai')->{ignored} };
  is($ignored{'openai.mcp'}, 'read only at the top level of a config file', 'mcp in a section');
  is($ignored{'default.mcp_approvals'}, 'read only at the top level of ~/.raider/config.yml', 'mcp_approvals in a section');
  is($c->engine_options('openai'), {}, 'not an engine option either');
};

subtest 'wrong shapes croak' => sub {
  reset_home();
  my $root = project();
  spew_yaml($root->child('.raider/config.yml'), "mcp: [ a, b ]\n");
  like(dies { config($root)->mcp_servers }, qr/Invalid mcp setting in \.raider\/config\.yml: mcp: must be a mapping/, 'a list');
  spew_yaml($root->child('.raider/config.yml'), "mcp:\n  x: npx foo\n");
  like(dies { config($root)->mcp_servers }, qr/mcp\.x: must be a mapping/, 'an entry that is a string');
  spew_yaml($root->child('.raider/config.yml'), "mcp: ~\n");
  is(config($root)->mcp_servers, [], 'an empty mcp: is nothing');
};

subtest 'mcp_approvals: home file only' => sub {
  reset_home();
  my $root = project();
  my $sub = $home->child('dev', 'app');
  $sub->mkpath;
  spew_yaml($home->child('.raider/config.yml'), { mcp_approvals => {
    '~/dev/app' => { enabled => [ 'a', 'b' ], disabled => 'c' },
    "$root"     => { enable_all => 'on' },
    '/not/there' => {},
  } });
  my $c = config($root);
  my $got = $c->mcp_approvals;
  is([ map { $_->{path} } @$got ], [ sort '~/dev/app', "$root", '/not/there' ], 'sorted by path');
  is({ map { $_->{path} => $_ } @$got }, {
    "$root"      => { path => "$root", dir => "$root", enable_all => 1, enabled => [], disabled => [], source => '~/.raider/config.yml' },
    '/not/there' => { path => '/not/there', dir => '/not/there', enable_all => undef, enabled => [], disabled => [], source => '~/.raider/config.yml' },
    '~/dev/app'  => { path => '~/dev/app', dir => "$sub", enable_all => undef, enabled => [ 'a', 'b' ], disabled => ['c'], source => '~/.raider/config.yml' },
  }, 'paths resolved, ~ expanded, booleans parsed, a string is a list of one');
  my %ignored = map { $_->{key} => 1 } @{ $c->explain->{ignored} };
  ok(!$ignored{mcp_approvals}, 'in the home file it is not reported');

  spew_yaml($root->child('.raider/config.yml'), { mcp_approvals => { "$root" => { enable_all => 1 } } });
  reset_home();
  $c = config($root);
  is($c->mcp_approvals, [], 'a project file cannot approve');
  is((grep { $_->{key} eq 'mcp_approvals' } @{ $c->explain->{ignored} })[0]{reason},
    'only ~/.raider/config.yml approves MCP servers; a project file cannot', 'reported');
};

subtest 'mcp_approvals: read when raider runs in the home directory' => sub {
  reset_home();
  spew_yaml($home->child('.raider/config.yml'), { mcp_approvals => { "$home" => { enabled => ['x'] } } });
  my $c = config($home);
  is([ map { $_->{enabled} } @{ $c->mcp_approvals } ], [ ['x'] ], 'the home file is the file in use');
  ok(!(grep { $_->{key} eq 'mcp_approvals' } @{ $c->explain->{ignored} }), 'not reported');
};

subtest 'mcp_approvals: wrong shapes croak' => sub {
  my $root = project();
  my %bad = (
    "mcp_approvals: [ x ]\n"                              => qr/mcp_approvals: must be a mapping/,
    "mcp_approvals:\n  rel/path: {}\n"                    => qr/mcp_approvals\.rel\/path: must be an absolute path or start with ~\//,
    "mcp_approvals:\n  /x/*: {}\n"                        => qr/cannot hold \* or \?/,
    "mcp_approvals:\n  /x: [ a ]\n"                       => qr/mcp_approvals\.\/x: must be a mapping/,
    "mcp_approvals:\n  /x: { enabledMcpjsonServers: [a] }\n" => qr/enabledMcpjsonServers: unknown key \(use enabled\)/,
    "mcp_approvals:\n  /x: { enable_all: maybe }\n"       => qr/enable_all: must be a boolean/,
    "mcp_approvals:\n  /x: { enabled: [ [a] ] }\n"        => qr/enabled: must be a list of server names/,
    "mcp_approvals:\n  /x: { disabled: { a: 1 } }\n"      => qr/disabled: must be a list of server names/,
  );
  for my $yaml (sort keys %bad) {
    reset_home();
    spew_yaml($home->child('.raider/config.yml'), $yaml);
    like(dies { config($root)->mcp_approvals }, $bad{$yaml}, 'croaks: '.( split /\n/, $yaml )[-1]);
  }
  reset_home();
};

done_testing;
