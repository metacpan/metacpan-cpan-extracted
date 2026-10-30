#!/usr/bin/env perl
# ABSTRACT: .mcp.json from parent directories and approval in bypassPermissions (ADR 0029 Addendum 1, k167)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Langertha::Raider::Config;
use Langertha::Raider::Context::Settings;
use Langertha::Raider::MCP::Config;

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub spew_json { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_raw($json->encode($data)) }

sub model {
  my ( $root, %args ) = @_;
  my $settings = Langertha::Raider::Context::Settings->new( project_dir => "$root" );
  return Langertha::Raider::MCP::Config->new(
    root => "$root", claude_layout => 1, settings => $settings, home => "$home",
    config => Langertha::Raider::Config->new( root => "$root" ),
    env => {}, %args,
  );
}
sub by_name { my ( $m ) = @_; return { map { $_->{name} => $_ } @{ $m->servers } } }

subtest 'home .mcp.json reaches a project below it' => sub {
  $home->child('.mcp.json')->remove;
  my $proj = $home->child('dev', 'app');
  $proj->mkpath;
  spew_json($home->child('.mcp.json'), { mcpServers => { hub => { command => 'hub-srv' } } });
  my $m = model($proj);
  my $s = by_name($m)->{hub};
  ok $s, 'server from ~/.mcp.json';
  is $s->{scope}, 'project', 'scope project';
  is $s->{source}, '~/.mcp.json', 'labelled with ~';
  is $s->{status}, 'pending', 'still needs approval';
  is $s->{command}, 'hub-srv';
  is [ map { $_->{label} } $m->mcp_json_files ], ['~/.mcp.json'];
};

subtest 'nearer file wins per name, whole entry' => sub {
  my $base = path(tempdir(CLEANUP => 1))->realpath;
  my $proj = $base->child('a', 'b');
  $proj->mkpath;
  spew_json($base->child('.mcp.json'), { mcpServers => { x => { command => 'far', args => ['1'] }, only_far => { command => 'f' } } });
  spew_json($base->child('a', '.mcp.json'), { mcpServers => { x => { command => 'mid' } } });
  spew_json($proj->child('.mcp.json'), { mcpServers => { x => { command => 'near' } } });
  my $m = model($proj);
  my $s = by_name($m);
  is $s->{x}{command}, 'near', 'nearest wins';
  is $s->{x}{args}, [], 'no field merged from farther files';
  is $s->{x}{source}, '.mcp.json';
  is [ map { $_->{source} } @{ $s->{x}{shadowed} } ], [ "$base/a/.mcp.json", "$base/.mcp.json" ], 'shadowed in order';
  is $s->{only_far}{source}, "$base/.mcp.json", 'unique far server stays';
};

subtest 'broken parent file is reported, not fatal' => sub {
  my $base = path(tempdir(CLEANUP => 1))->realpath;
  my $proj = $base->child('p');
  $proj->mkpath;
  $base->child('.mcp.json')->spew_utf8('{not json');
  my $m = model($proj);
  is [ map { $_->{source} } @{ $m->errors } ], [ "$base/.mcp.json" ];
};

subtest 'approval by name works for a parent-dir server' => sub {
  my $base = path(tempdir(CLEANUP => 1))->realpath;
  my $proj = $base->child('p');
  $proj->mkpath;
  spew_json($base->child('.mcp.json'), { mcpServers => { up => { command => 'u' } } });
  my $m = model($proj, session_approvals => { up => 'approved' });
  is by_name($m)->{up}{status}, 'configured', 'approved for the session';
  $m = model($proj, session_approvals => { up => 'rejected' });
  is by_name($m)->{up}{status}, 'rejected';
};

subtest 'bypassPermissions + skipDangerousModePermissionPrompt approves project servers' => sub {
  my $base = path(tempdir(CLEANUP => 1))->realpath;
  my $proj = $base->child('p');
  $proj->mkpath;
  spew_json($proj->child('.mcp.json'), { mcpServers => { a => { command => 'a' }, b => { command => 'b' } } });
  my $user = $home->child('.claude', 'settings.json');

  $user->remove;
  is by_name(model($proj, bypass_approval => 1))->{a}{status}, 'pending', 'bypass alone is not enough';

  spew_json($user, { skipDangerousModePermissionPrompt => JSON::MaybeXS->true });
  is by_name(model($proj))->{a}{status}, 'pending', 'the setting alone is not enough';
  my $m = model($proj, bypass_approval => 1);
  is by_name($m)->{a}{status}, 'configured', 'both: approved';
  is by_name($m)->{a}{approval}{by}, 'skipDangerousModePermissionPrompt in bypassPermissions mode';

  spew_json($user, { skipDangerousModePermissionPrompt => JSON::MaybeXS->true,
                     disabledMcpjsonServers => ['b'] });
  $m = model($proj, bypass_approval => 1);
  is by_name($m)->{b}{status}, 'rejected', 'disabledMcpjsonServers still blocks';
  is by_name($m)->{a}{status}, 'configured';

  # the project file cannot grant it
  $user->remove;
  spew_json($proj->child('.claude', 'settings.json'), { skipDangerousModePermissionPrompt => JSON::MaybeXS->true });
  is by_name(model($proj, bypass_approval => 1))->{a}{status}, 'pending', 'only the user settings count';
  $proj->child('.claude')->remove_tree;
};

done_testing;
