#!/usr/bin/env perl
# ABSTRACT: the application with MCP prompts as /commands and servers of a parent .mcp.json (ADR 0029 Addendum 1, k167)
use strict;
use warnings;
use utf8;
use Test2::V0;
use FindBin;
use Encode qw( decode_utf8 );
use JSON::MaybeXS ();
use Path::Tiny;
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

clear_engine_env();
my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

# A raider CLI over no real model: only its commands run here.
package My::App {
  use Moose;
  extends 'Langertha::Raider::CLI';
  __PACKAGE__->meta->make_immutable;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t } );
}

sub commands {
  my ( $app ) = @_;
  my ( $fh, $read ) = buffer();
  return ( Langertha::Raider::CLI::Commands->new( app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ) ), $read );
}

subtest 'a server of ~/.mcp.json starts for a project below the home directory, once approved' => sub {
  my $root = $home->child('dev', 'app');
  $root->mkpath;
  $root->child('CLAUDE.md')->spew_utf8("# app\n");
  $home->child('.mcp.json')->spew_raw($json->encode({ mcpServers => {
    hub  => { command => $^X, args => [ $script, 'normal' ] },
    wait => { command => $^X, args => [ $script, 'normal' ] },
  } }));
  $home->child('.claude')->mkpath;
  $home->child('.claude', 'settings.json')->spew_raw($json->encode({ enabledMcpjsonServers => ['hub'] }));
  my $app = mock_app( root => "$root", permission_mode => 'bypassPermissions', script => [ { tool_calls => [ [ mcp__hub__with_dot => {} ] ] }, { text => 'done' } ] );
  is([ map { $_->name } @{ $app->configured_mcp->clients } ], ['hub'], 'only the approved one starts');
  my $row = ( grep { $_->{name} eq 'wait' } @{ $app->mcp_report->{servers} } )[0];
  is($row->{status}, 'pending', 'the other waits for its approval');
  is($row->{source}, '~/.mcp.json', 'reported with its file');
  is($app->run('go')->text, 'done', 'run');
  my ( $res ) = @{ $app->mock_engine->results };
  is($res->{tool_call}{name}, 'mcp__hub__with_dot', 'its tool was called');
  is($res->{result}{content}[0]{text}, 'dotted', 'and ran');
  $app->shutdown_mcp;
  $home->child('.mcp.json')->remove;
  $home->child('.claude', 'settings.json')->remove;
};

subtest 'bypassPermissions with skipDangerousModePermissionPrompt approves the project servers' => sub {
  my $root = $home->child('dev', 'app2');
  $root->mkpath;
  $root->child('CLAUDE.md')->spew_utf8("# app\n");
  $root->child('.mcp.json')->spew_raw($json->encode({ mcpServers => { proj => { command => $^X, args => [ $script, 'normal' ] } } }));
  $home->child('.claude')->mkpath;
  $home->child('.claude', 'settings.json')->spew_raw($json->encode({ skipDangerousModePermissionPrompt => JSON::MaybeXS->true }));

  my $plain = mock_app( root => "$root", permission_mode => 'default' );
  is([ map { $_->name } @{ $plain->configured_mcp->clients } ], [], 'default mode: still pending');
  my $bypass = mock_app( root => "$root", permission_mode => 'bypassPermissions' );
  is([ map { $_->name } @{ $bypass->configured_mcp->clients } ], ['proj'], 'bypassPermissions: no approval asked');
  $bypass->shutdown_mcp;
  $home->child('.claude', 'settings.json')->remove;
};

subtest 'prompts: /help lists them, /mcp__server__prompt is a run request' => sub {
  my $tmp = Path::Tiny->tempdir;
  my $root = $tmp->realpath;
  $home->child('.raider')->mkpath;
  $home->child('.raider', 'config.yml')->spew_utf8("mcp:\n  t:\n    command: \"$^X\"\n    args: [ \"$script\", rich ]\n");
  my $app = My::App->new( root => "$root", engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0 );
  my ( $commands, $read ) = commands($app);

  my $r = $commands->dispatch('/mcp__t__greet Ada Hi');
  is(ref $r, 'HASH', 'a run request');
  like($r->{prompt}, qr{\A<command-message>mcp__t__greet is running\x{2026}</command-message>\n<command-name>/mcp__t__greet</command-name>\n<command-args>Ada Hi</command-args>\n\nHi, Ada!\n\nUnderstood\.\z},
    'framed like a custom command, messages joined');

  $r = $commands->dispatch('/mcp__t__plain');
  like($r->{prompt}, qr{\n\nplain prompt\z}, 'a prompt without arguments');

  is($commands->dispatch('/mcp__t__greet'), 0, 'a missing required argument is refused');
  like($read->(), qr{Missing required argument for MCP prompt mcp__t__greet: name \(usage: /mcp__t__greet name \[style\]\)}, 'with the usage');
  is($commands->dispatch('/mcp__t__plain extra'), 0, 'too many arguments');
  like($read->(), qr{takes 0 arguments}, 'says so');
  is($commands->dispatch('/mcp__t__nope'), 0, 'unknown prompt');
  like($read->(), qr{unknown command: /mcp__t__nope}, 'is an unknown command');
  is($commands->dispatch('/mcp__zzz__greet'), 0, 'unknown server');
  like($read->(), qr{unknown command: /mcp__zzz__greet}, 'too');

  $commands->dispatch('/help');
  my $help = $read->();
  like($help, qr{MCP prompts:\n\s+/mcp__t__greet name \[style\]\s+Greets someone \(MCP, t\)\n\s+/mcp__t__plain\s+No arguments \(MCP, t\)}, '/help lists the prompts of connected servers');
  $app->shutdown_mcp;
};

subtest 'resource tools are mounted only when servers are configured' => sub {
  my $tmp = Path::Tiny->tempdir;
  my $root = $tmp->realpath;
  $home->child('.raider', 'config.yml')->remove;
  my $none = mock_app( root => "$root" );
  ok(!( grep { $_->name eq 'list_mcp_resources' } map { @{ $_->tools } } @{ $none->_tool_servers } ), 'no server configured: no resource tools');
  $home->child('.raider', 'config.yml')->spew_utf8("mcp:\n  t:\n    command: \"$^X\"\n    args: [ \"$script\", rich ]\n");
  my $some = mock_app( root => "$root" );
  ok(( grep { $_->name eq 'list_mcp_resources' } map { @{ $_->tools } } @{ $some->_tool_servers } ), 'configured: mounted');
  $some->shutdown_mcp;
};

done_testing;
