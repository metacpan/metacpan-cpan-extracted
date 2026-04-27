#!/usr/bin/env perl
# ABSTRACT: Live integration test for Langertha::Raider

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use File::Temp qw( tempdir );
use File::Spec;

BEGIN {
  my @available;
  push @available, 'anthropic' if $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY};
  push @available, 'openai'    if $ENV{TEST_LANGERTHA_OPENAI_API_KEY};
  push @available, 'deepseek'  if $ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY};
  push @available, 'minimax'   if $ENV{TEST_LANGERTHA_MINIMAX_API_KEY};
  push @available, 'tsystems'  if $ENV{TEST_LANGERTHA_TSYSTEMS_API_KEY};
  push @available, 'scaleway'  if $ENV{TEST_LANGERTHA_SCALEWAY_API_KEY};
  unless (@available) {
    plan skip_all => 'No TEST_LANGERTHA_*_API_KEY env vars set (need anthropic, openai, deepseek, minimax, tsystems, or scaleway)';
  }
  eval {
    require IO::Async::Loop;
    require Future::AsyncAwait;
    require Net::Async::MCP;
    require MCP::Server;
    require MCP::Tool;
    1;
  } or plan skip_all => 'Requires IO::Async, Net::Async::MCP, and MCP modules';
}

use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::MCP;
use MCP::Server;
use Langertha::Raider;

# --- Create test data directory ---

my $testdir = tempdir(CLEANUP => 1);
{
  open my $fh, '>', File::Spec->catfile($testdir, 'hello.txt') or die $!;
  print $fh "Hello from the test directory!\nThis is line two.\n";
  close $fh;

  open $fh, '>', File::Spec->catfile($testdir, 'numbers.txt') or die $!;
  print $fh "1\n2\n3\n4\n5\n";
  close $fh;
}

# --- Build MCP server with file tools ---

my $server = MCP::Server->new(name => 'test-files', version => '1.0');

$server->tool(
  name        => 'list_files',
  description => 'List files in a directory',
  input_schema => {
    type       => 'object',
    properties => {
      path => { type => 'string', description => 'Directory path' },
    },
    required => ['path'],
  },
  code => sub {
    my ($self, $args) = @_;
    my $path = $args->{path};
    return $self->text_result("Error: not a directory") unless -d $path;
    opendir(my $dh, $path) or return $self->text_result("Error: $!");
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir($dh);
    return $self->text_result(join("\n", @entries));
  },
);

$server->tool(
  name        => 'read_file',
  description => 'Read a file',
  input_schema => {
    type       => 'object',
    properties => {
      path => { type => 'string', description => 'File path to read' },
    },
    required => ['path'],
  },
  code => sub {
    my ($self, $args) = @_;
    my $path = $args->{path};
    return $self->text_result("Error: not a file") unless -f $path;
    open(my $fh, '<', $path) or return $self->text_result("Error: $!");
    local $/;
    my $content = <$fh>;
    close $fh;
    return $self->text_result($content);
  },
);

my $loop = IO::Async::Loop->new;
my $mcp = Net::Async::MCP->new(server => $server);
$loop->add($mcp);

async sub test_raider {
  my ($name, $engine) = @_;

  my $raider = Langertha::Raider->new(
    engine  => $engine,
    mission => 'You are a file explorer. Use tools to answer questions about files. Be concise.',
  );

  # --- Raid 1: list and explore ---
  my $r1 = await $raider->raid_f("List the files in $testdir and read hello.txt");
  diag "$name raid 1: $r1";
  like($r1, qr/hello|Hello/i, "$name: raid 1 mentions hello.txt content");

  # Check history accumulated
  my $history_after_1 = scalar @{$raider->history};
  cmp_ok($history_after_1, '>=', 2, "$name: history has at least 2 messages after raid 1");

  # Check metrics
  my $m = $raider->metrics;
  is($m->{raids}, 1, "$name: metrics show 1 raid");
  cmp_ok($m->{tool_calls}, '>=', 1, "$name: metrics show at least 1 tool call");
  cmp_ok($m->{time_ms}, '>', 0, "$name: metrics show positive time");

  # --- Raid 2: follow-up using history ---
  my $r2 = await $raider->raid_f("Now read numbers.txt and tell me what numbers are in it");
  diag "$name raid 2: $r2";
  like($r2, qr/[1-5]/, "$name: raid 2 mentions numbers");

  my $history_after_2 = scalar @{$raider->history};
  cmp_ok($history_after_2, '>', $history_after_1,
    "$name: history grew after raid 2");
  is($raider->metrics->{raids}, 2, "$name: metrics show 2 raids");

  # --- Langfuse flush ---
  if ($engine->can('langfuse_enabled') && $engine->langfuse_enabled) {
    my $batch_size = scalar @{$engine->_langfuse_batch};
    $engine->langfuse_flush;
    diag "$name: flushed $batch_size Langfuse events";
  }

  # --- clear_history ---
  $raider->clear_history;
  is(scalar @{$raider->history}, 0, "$name: clear_history empties history");
  is($raider->metrics->{raids}, 2, "$name: clear_history preserves metrics");

  # --- reset ---
  $raider->reset;
  is($raider->metrics->{raids}, 0, "$name: reset clears metrics");
}

async sub run_tests {
  await $mcp->initialize;

  my $tools = await $mcp->list_tools;
  is(scalar @$tools, 2, 'MCP server has 2 tools');

  if ($ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY}) {
    require Langertha::Engine::Anthropic;
    eval {
      await test_raider('Anthropic', Langertha::Engine::Anthropic->new(
        api_key => $ENV{TEST_LANGERTHA_ANTHROPIC_API_KEY},
        model => 'claude-sonnet-4-6', mcp_servers => [$mcp],
      ));
    };
    diag "Anthropic error: $@" if $@;
  }

  if ($ENV{TEST_LANGERTHA_OPENAI_API_KEY}) {
    require Langertha::Engine::OpenAI;
    eval {
      await test_raider('OpenAI', Langertha::Engine::OpenAI->new(
        api_key => $ENV{TEST_LANGERTHA_OPENAI_API_KEY},
        model => 'gpt-4o-mini', mcp_servers => [$mcp],
      ));
    };
    diag "OpenAI error: $@" if $@;
  }

  if ($ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY}) {
    require Langertha::Engine::DeepSeek;
    eval {
      await test_raider('DeepSeek', Langertha::Engine::DeepSeek->new(
        api_key => $ENV{TEST_LANGERTHA_DEEPSEEK_API_KEY},
        model => 'deepseek-chat', mcp_servers => [$mcp],
      ));
    };
    diag "DeepSeek error: $@" if $@;
  }

  if ($ENV{TEST_LANGERTHA_MINIMAX_API_KEY}) {
    require Langertha::Engine::MiniMax;
    eval {
      await test_raider('MiniMax', Langertha::Engine::MiniMax->new(
        api_key => $ENV{TEST_LANGERTHA_MINIMAX_API_KEY},
        mcp_servers => [$mcp],
      ));
    };
    diag "MiniMax error: $@" if $@;
  }

  if ($ENV{TEST_LANGERTHA_TSYSTEMS_API_KEY}) {
    require Langertha::Engine::TSystems;
    eval {
      await test_raider('TSystems', Langertha::Engine::TSystems->new(
        api_key => $ENV{TEST_LANGERTHA_TSYSTEMS_API_KEY},
        model => 'gpt-oss-120b', mcp_servers => [$mcp],
      ));
    };
    diag "TSystems error: $@" if $@;
  }

  if ($ENV{TEST_LANGERTHA_SCALEWAY_API_KEY}) {
    require Langertha::Engine::Scaleway;
    eval {
      await test_raider('Scaleway', Langertha::Engine::Scaleway->new(
        api_key => $ENV{TEST_LANGERTHA_SCALEWAY_API_KEY},
        model => 'llama-3.1-8b-instruct', mcp_servers => [$mcp],
      ));
    };
    diag "Scaleway error: $@" if $@;
  }
}

run_tests()->get;

done_testing;
