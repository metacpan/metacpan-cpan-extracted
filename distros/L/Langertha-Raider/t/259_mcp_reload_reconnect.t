#!/usr/bin/env perl
# ABSTRACT: /reload and /mcp reconnect restart MCP servers in place; /mcp and config explain report them (ADR 0029 §11, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use FindBin;
use Path::Tiny;
use Scalar::Util qw( refaddr );
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Env qw( clear_engine_env isolate_home );
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;

# A filehandle that appends to a string the test may empty between checks.
package Test::Raider::StringOut {
  use Symbol ();
  sub new { my ( $class, $ref ) = @_; my $fh = Symbol::gensym(); tie *$fh, $class, $ref; return $fh }
  sub TIEHANDLE { my ( $class, $ref ) = @_; return bless { ref => $ref }, $class }
  sub PRINT { my ( $self, @text ) = @_; ${ $self->{ref} } .= join '', @text; return 1 }
  sub PRINTF { my ( $self, $fmt, @args ) = @_; ${ $self->{ref} } .= sprintf $fmt, @args; return 1 }
}

clear_engine_env();
my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;

# ~/.raider/config.yml with stdio servers: name => extra env (undef: none).
sub home_mcp {
  my ( %servers ) = @_;
  my $yaml = "mcp:\n";
  for my $name (sort keys %servers) {
    $yaml .= "  $name:\n    command: \"$^X\"\n    args: [ \"$script\", \"normal\" ]\n";
    $yaml .= "    env: { MARK: \"$servers{$name}\" }\n" if defined $servers{$name};
  }
  $home->child('.raider')->mkpath;
  $home->child('.raider', 'config.yml')->spew_utf8($yaml);
}

sub pid_of { my ( $app, $name ) = @_; my $c = $app->configured_mcp->client($name); return $c ? $c->pid : undef }
sub alive { my ( $pid ) = @_; return defined $pid && kill(0, $pid) ? 1 : 0 }
sub addrs { [ map { refaddr $_ } @_ ] }

subtest '/reload: unchanged servers keep running, changed and removed ones are stopped, new ones start' => sub {
  home_mcp( keep => undef, change => undef, drop => undef );
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  my $app = mock_app( root => "$root", script => [ { text => 'one' }, { text => 'two' } ] );
  $app->run('first');
  my %pid = map { $_ => pid_of($app, $_) } qw( keep change drop );
  ok(alive($pid{$_}), $_.' runs') for sort keys %pid;
  my $policy_servers = $app->permissions->source_servers;
  is($policy_servers, { 'engine:1' => 'change', 'engine:2' => 'drop', 'engine:3' => 'keep' }, 'engine:N before');

  home_mcp( keep => undef, change => 'new', add => undef );
  $app->reload_context;
  is([ map { $_->name } @{ $app->configured_mcp->clients } ], [qw( add change keep )], 'the new set');
  is(pid_of($app, 'keep'), $pid{keep}, 'keep: the same process');
  ok(!alive($pid{change}), 'change: the old process is stopped');
  ok(!alive($pid{drop}), 'drop: stopped');
  is(addrs(@{ $app->_mcps }[0 .. 2]), addrs(@{ $app->configured_mcp->clients }), 'the front of the engine servers is the new set');
  is($app->permissions->source_servers, { 'engine:1' => 'add', 'engine:2' => 'change', 'engine:3' => 'keep' },
    'the policy knows the new engine:N');

  $app->run('second');
  is([ map { $_->status } @{ $app->configured_mcp->clients } ], [qw( connected connected connected )], 'all connected after the next raid');
  ok(alive(pid_of($app, 'change')) && pid_of($app, 'change') != $pid{change}, 'change runs as a new process');
  $app->shutdown_mcp;
  ok(!alive($pid{keep}), 'shutdown_mcp stops them');
};

subtest '/mcp reconnect' => sub {
  home_mcp( one => undef, two => undef );
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  my $app = mock_app( root => "$root", script => [ { text => 'one' } ] );
  $app->run('first');
  my %pid = map { $_ => pid_of($app, $_) } qw( one two );
  my @front = @{ $app->_mcps }[0, 1];
  is([ $app->reconnect_mcp('two') ], ['two'], 'two reconnected');
  ok(!alive($pid{two}), 'the old process is gone');
  ok(alive(pid_of($app, 'two')) && pid_of($app, 'two') != $pid{two}, 'a new one runs');
  is($app->configured_mcp->client('two')->status, 'connected', 'connected at once');
  is(refaddr $app->_mcps->[0], refaddr $front[0], 'one keeps its place and client');
  is(refaddr $app->_mcps->[1], refaddr $app->configured_mcp->client('two'), 'two is replaced in the same place');
  is(pid_of($app, 'one'), $pid{one}, 'one untouched');
  is([ $app->reconnect_mcp('nope') ], [], 'unknown name');
  is([ $app->reconnect_mcp('all') ], [qw( one two )], 'all');
  ok(!alive($pid{one}), 'one restarted too');
  $app->shutdown_mcp;
};

subtest 'config explain and /mcp' => sub {
  home_mcp( good => undef );
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  $root->child('.raider')->mkpath;
  $root->child('.raider', 'config.yml')->spew_utf8("mcp:\n  proj:\n    command: x\n  old:\n    type: sse\n    url: https://x\n");
  my $out_text = '';
  my $output = Langertha::Raider::CLI::Output->new( out => Test::Raider::StringOut->new(\$out_text), color => 0 );
  my $app = Langertha::Raider::CLI->new( root => "$root", engine_name => 'openai', api_key => 'x' );
  my $r = $app->explain_config->{mcp};
  is([ map { [ $_->{name}, $_->{status} ] } @{ $r->{servers} } ],
    [ [ old => 'unsupported' ], [ proj => 'pending' ], [ good => 'configured' ] ], 'explain: every server with its status');
  is($r->{startup_timeout_ms}, 30000, 'timeouts');
  is($r->{approvals_go_to}, '~/.raider/config.yml', 'where answers go');
  $output->config_report($app->explain_config);
  like($out_text, qr/^mcp servers: 3 \(start 30s each\)$/m, 'config report: the section');
  like($out_text, qr/^  proj pending approval  raider-project, stdio, \.raider\/config\.yml$/m, 'a pending project server');
  like($out_text, qr/^    approval: pending$/m, 'its approval');
  like($out_text, qr/^  old unsupported  raider-project, sse, \.raider\/config\.yml\n    the sse transport is not supported/m, 'reason');
  like($out_text, qr/^  folder not trusted by Claude Code; answers are saved in ~\/\.raider\/config\.yml$/m, 'trust line');

  $out_text = '';
  my $commands = Langertha::Raider::CLI::Commands->new( app => $app, output => $output );
  $commands->dispatch('/mcp reconnect good');
  like($out_text, qr/^reconnected: good$/m, '/mcp reconnect');
  like($out_text, qr/^  good connected  raider-home, stdio, ~\/\.raider\/config\.yml\n    tools: mcp__good__boom, mcp__good__echo_env/m,
    '/mcp: status and tools');
  $out_text = '';
  $commands->dispatch('/mcp reconnect proj');
  like($out_text, qr/no configured MCP server proj that can start/, 'a server that cannot start');
  $out_text = '';
  $commands->dispatch('/help');
  like($out_text, qr{/mcp reconnect \[NAME\]}, '/help lists it');
  $app->shutdown_mcp;
};

subtest '/mcp is a built-in; a custom command of that name wins (ADR 0030 §3)' => sub {
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  my $output = Langertha::Raider::CLI::Output->new( out => Test::Raider::StringOut->new(\my $text), color => 0 );
  my $app = Langertha::Raider::CLI->new( root => "$root", engine_name => 'openai', api_key => 'x' );
  my $commands = Langertha::Raider::CLI::Commands->new( app => $app, output => $output );
  is($commands->resolve('/mcp reconnect db'), hash { field kind => 'builtin'; field method => 'cmd_mcp';
    field arguments => 'reconnect db'; etc() }, 'built-in with its arguments');
  $root->child('.raider', 'commands')->mkpath;
  $root->child('.raider', 'commands', 'mcp.md')->spew_utf8("---\ndescription: mine\n---\nMy own mcp command.\n");
  my $app2 = Langertha::Raider::CLI->new( root => "$root", engine_name => 'openai', api_key => 'x' );
  is(Langertha::Raider::CLI::Commands->new( app => $app2, output => $output )->resolve('/mcp')->{kind}, 'entry',
    'the custom command replaces the built-in');
};

subtest 'a failed server shows its stderr in /mcp' => sub {
  $home->child('.raider')->mkpath;
  $home->child('.raider', 'config.yml')->spew_utf8("mcp:\n  bad:\n    command: \"$^X\"\n    args: [ \"$script\", exit ]\n");
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  my $out_text = '';
  my $output = Langertha::Raider::CLI::Output->new( out => Test::Raider::StringOut->new(\$out_text), color => 0 );
  my $app = Langertha::Raider::CLI->new( root => "$root", engine_name => 'openai', api_key => 'x' );
  $app->loop->await($app->configured_mcp->start_f);
  $output->mcp_report($app->mcp_report, tools => 1);
  like($out_text, qr/^  bad failed .*\n    exited with code 3 \(stderr: test server: fatal: no configuration\)\n    stderr: test server: fatal: no configuration$/m,
    'reason and stderr');
};

done_testing;
