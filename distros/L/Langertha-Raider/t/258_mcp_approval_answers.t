#!/usr/bin/env perl
# ABSTRACT: asking about pending project MCP servers, writing the answers where they count (ADR 0029 §7, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use FindBin;
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP ();
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Env qw( clear_engine_env isolate_home );
use Test::Raider::MockAI qw( mock_app );

# A Claude Code project with three .mcp.json servers. The person answers
# approve, reject and nothing; the answers hold at once and are written to
# .claude/settings.local.json in a folder Claude Code trusts, else to
# mcp_approvals of ~/.raider/config.yml.

clear_engine_env();
my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

sub project {
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  $root->child('CLAUDE.md')->spew_utf8("# p\n");
  $root->child('.mcp.json')->spew_raw($json->encode({ mcpServers => {
    map { $_ => { command => $^X, args => [ $script, 'normal' ] } } qw( a b c )
  } }));
  return $root;
}

sub reset_home { $home->child($_)->remove_tree for qw( .raider .claude ); $home->child('.claude.json')->remove }

sub states { my ( $app ) = @_; return { map { $_->{name} => $_->{status} } @{ $app->configured_mcp->config->servers } } }

subtest 'untrusted folder: answers go to ~/.raider/config.yml' => sub {
  reset_home();
  my $root = project();
  my $app = mock_app( root => "$root", script => [ { text => 'done' } ] );
  is(states($app), { a => 'pending', b => 'pending', c => 'pending' }, 'all pending');
  like([ $app->mcp_notes ], [
    qr/\Amcp: server a \(\.mcp\.json\) is not approved and stays off; approve it in an interactive raider, or add it to mcp_approvals of ~\/\.raider\/config\.yml\z/,
    qr/server b/, qr/server c/,
  ], 'notes for a run nobody can ask in');

  my @asked;
  my %answer = ( a => 'approve', b => 'reject' );
  my @answers = $app->ask_mcp_approvals(sub { push @asked, $_[0]{name}; $answer{ $_[0]{name} } });
  is(\@asked, [qw( a b c )], 'each pending server asked once');
  is(\@answers, [
    { name => 'a', answer => 'approve', written => '~/.raider/config.yml' },
    { name => 'b', answer => 'reject',  written => '~/.raider/config.yml' },
  ], 'answers written');
  is(states($app), { a => 'configured', b => 'rejected', c => 'pending' }, 'they hold at once');
  my $data = YAML::PP->new->load_file($home->child('.raider', 'config.yml')->stringify);
  is($data->{mcp_approvals}{"$root"}, { enabled => ['a'], disabled => ['b'] }, 'mcp_approvals of the project dir');
  is([ $app->mcp_notes ], [ match qr/server c/ ], 'only c still waits');

  $app->run('hi');
  is($app->configured_mcp->client('a')->status, 'connected', 'the approved server runs');
  $app->shutdown_mcp;

  my $again = mock_app( root => "$root" );
  is(states($again), { a => 'configured', b => 'rejected', c => 'pending' }, 'a new run reads the answers');
  my @asked2;
  $again->ask_mcp_approvals(sub { push @asked2, $_[0]{name}; undef });
  is(\@asked2, ['c'], 'only c is asked again');
  ok(!-e $root->child('.claude', 'settings.local.json'), 'nothing written into the untrusted project');
};

subtest 'trusted folder: answers go to .claude/settings.local.json; all ends the asking' => sub {
  reset_home();
  my $root = project();
  $home->child('.claude.json')->spew_raw($json->encode({ projects => { "$root" => { hasTrustDialogAccepted => JSON::MaybeXS->true } } }));
  $root->child('.claude')->mkpath;
  $root->child('.claude', 'settings.local.json')->spew_raw($json->encode({ permissions => { allow => ['Read'] } }));
  my $app = mock_app( root => "$root" );
  my @asked;
  my @answers = $app->ask_mcp_approvals(sub { push @asked, $_[0]{name}; $_[0]{name} eq 'a' ? 'reject' : 'all' });
  is(\@asked, [qw( a b )], 'after all, nobody is asked');
  is([ map { $_->{written} } @answers ], [ ('.claude/settings.local.json') x 2 ], 'written to settings.local.json');
  my $local = $json->decode($root->child('.claude', 'settings.local.json')->slurp_raw);
  is($local, { permissions => { allow => ['Read'] }, disabledMcpjsonServers => ['a'], enableAllProjectMcpServers => JSON::MaybeXS->true },
    "Claude Code's keys, the other keys kept");
  is(states($app), { a => 'rejected', b => 'configured', c => 'configured' }, 'a rejected, the rest approved');
  is(states(mock_app( root => "$root" )), { a => 'rejected', b => 'configured', c => 'configured' }, 'and next time');
};

subtest 'no file to write to: the answer holds for the session' => sub {
  reset_home();
  my $root = project();
  my $app = mock_app( root => "$root" );
  local *Langertha::Raider::MCP::Config::approval_target = sub { undef };
  my @answers = $app->ask_mcp_approvals(sub { 'approve' });
  is([ map { $_->{written} } @answers ], [ undef, undef, undef ], 'nowhere written');
  is(states($app), { a => 'configured', b => 'configured', c => 'configured' }, 'but approved now');
};

done_testing;
