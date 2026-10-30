#!/usr/bin/env perl
# ABSTRACT: the REPL asks once about pending project MCP servers with Claude Code's three choices (ADR 0029 §7, k164)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Raider::Env qw( clear_engine_env isolate_home );
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;

clear_engine_env();
my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

sub cli {
  my $root = path(tempdir( CLEANUP => 1 ))->realpath;
  $root->child('CLAUDE.md')->spew_utf8("# p\n");
  $root->child('.mcp.json')->spew_raw($json->encode({ mcpServers => {
    db  => { command => 'npx', args => [ '-y', 'dbhub' ] },
    web => { type => 'http', url => 'https://mcp.example.com/mcp' },
  } }));
  my $app = Langertha::Raider::CLI->new( root => "$root", engine => 'openai', api_key => 'test', model => 'gpt-4o-mini',
    trace => 0, detect => 0 );
  return ( $app, $root );
}

sub repl {
  my ( $app, $input, %o ) = @_;
  open my $in, '<', \$input or die $!;
  my $out = '';
  open my $fh, '>', \$out or die $!;
  my $repl = Langertha::Raider::CLI::REPL->new(
    app => $app, in => $in, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ), can_ask => 1, %o,
  );
  return ( $repl, sub { $out } );
}

subtest 'mcp_approval: the question and the three answers' => sub {
  my ( $app ) = cli();
  my $db = $app->configured_mcp->config->server('db');
  my ( $r, $out ) = repl( $app, "1\n" );
  is $r->mcp_approval($db), 'approve', '1: approve';
  is $out->(), "? new MCP server in .mcp.json: db\n  stdio: npx -y dbhub\n  1) use this MCP server\n"
    ."  2) use this and all future MCP servers in this project\n  3) continue without using this MCP server\nchoice> ",
    'what, where, the choices';
  is [ repl( $app, "y\n" ) ]->[0]->mcp_approval($db), 'approve', 'y';
  is [ repl( $app, "2\n" ) ]->[0]->mcp_approval($db), 'all', '2: all';
  is [ repl( $app, "3\n" ) ]->[0]->mcp_approval($db), 'reject', '3: reject';
  is [ repl( $app, "maybe\nn\n" ) ]->[0]->mcp_approval($db), 'reject', 'anything else asks again';
  is [ repl( $app, "" ) ]->[0]->mcp_approval($db), undef, 'closed input: no answer';
  my ( $wr, $wout ) = repl( $app, "1\n" );
  $wr->mcp_approval($app->configured_mcp->config->server('web'));
  like $wout->(), qr/^  http: https:\/\/mcp\.example\.com\/mcp$/m, 'an http server shows its url';
};

subtest 'approve_mcp_servers: asks each, saves, reports' => sub {
  my ( $app, $root ) = cli();
  my ( $r, $out ) = repl( $app, "1\n3\n" );
  $r->approve_mcp_servers;
  like $out->(), qr/mcp: db approved \(saved in ~\/\.raider\/config\.yml\)$/m, 'db approved, where saved';
  like $out->(), qr/^mcp: web rejected \(saved in ~\/\.raider\/config\.yml\)$/m, 'web rejected';
  my $data = YAML::PP->new->load_file($home->child('.raider', 'config.yml')->stringify);
  is $data->{mcp_approvals}{"$root"}, { enabled => ['db'], disabled => ['web'] }, 'written';
  is { map { $_->{name} => $_->{status} } @{ $app->configured_mcp->config->servers } }, { db => 'configured', web => 'rejected' },
    'and in force';
};

subtest 'cannot ask: the notes, nothing asked' => sub {
  my ( $app ) = cli();
  my ( $r, $out ) = repl( $app, "1\n", can_ask => 0 );
  $r->approve_mcp_servers;
  like $out->(), qr/^mcp: server db \(\.mcp\.json\) is not approved and stays off; /m, 'note for db';
  unlike $out->(), qr/choice>/, 'no question';
};

done_testing;
