#!/usr/bin/env perl
# ABSTRACT: the configured MCP servers' lifecycle (mcp.server) and tools/list_changed (mcp.tools_changed) reach the session journal (ADR 0029 Addendum 1, k167)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use FindBin;
use JSON::MaybeXS ();
use Path::Tiny;
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Env qw( clear_engine_env isolate_home );
use Test::Raider::MockAI qw( mock_app );

clear_engine_env();
my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;
my $json = JSON::MaybeXS->new(utf8 => 1);

$home->child('.raider')->mkpath;
$home->child('.raider', 'config.yml')->spew_utf8(<<"YAML");
mcp:
  t:
    command: "$^X"
    args: [ "$script", "rich" ]
  broken:
    command: "$^X"
    args: [ "$script", "exit" ]
YAML

ok(Langertha::Raider::Application->is_journal_type($_), "$_ is a journal type") for qw( mcp.server mcp.tools_changed );

my $root = path(tempdir(CLEANUP => 1))->realpath;
my @events;
my $app = mock_app( root => "$root", permission_mode => 'bypassPermissions',
  on_event => sub { push @events, [ @_ ] },
  script => [ { tool_calls => [ [ 'mcp__t__bump' => {} ] ] }, { text => 'done' } ] );
my $session = $app->create_session;
$app->run_prompt('go', session => $session);

my @j = map { $json->decode($_) } path($session->path)->lines_raw({ chomp => 1 });
my %status;
push @{ $status{ $_->{name} } }, $_->{status} for grep { $_->{type} eq 'mcp.server' } @j;
is($status{t}, [qw( starting connected )], 'a server that starts: starting, connected');
is($status{broken}, [qw( starting failed )], 'one that fails: starting, failed');
my ($failed) = grep { $_->{type} eq 'mcp.server' && ( $_->{status} // '' ) eq 'failed' } @j;
like($failed, { name => 'broken', reason => qr/exited with code 3/, run => 'r1', transport => 'stdio' }, 'failed carries the reason');
my ($ready) = grep { $_->{type} eq 'mcp.server' && ( $_->{status} // '' ) eq 'connected' } @j;
ok($ready->{tools} > 0, 'connected carries the tool count');

my @changed = grep { $_->{type} eq 'mcp.tools_changed' } @j;
is(scalar @changed, 1, 'the list_changed notification of bump is journaled once');
like($changed[0], { name => 't', scope => 'raider-home', run => 'r1' }, 'with the server and the run');
ok((grep { $_->[0] eq 'mcp.tools_changed' } @events), 'and reaches on_event');

# Outside a run nothing can be journaled: stopping reaches only on_event.
@events = ();
$app->shutdown_mcp;
is([ map { {@{$_}[1 .. $#$_]}->{status} } grep { $_->[0] eq 'mcp.server' && {@{$_}[1 .. $#$_]}->{name} eq 't' } @events ],
  ['stopped'], 'shutdown: stopped, to on_event');
my @after = map { $json->decode($_) } path($session->path)->lines_raw({ chomp => 1 });
is(scalar @after, scalar @j, 'the journal is unchanged by it');

done_testing;
