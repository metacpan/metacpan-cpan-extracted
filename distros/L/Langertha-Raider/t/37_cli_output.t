#!/usr/bin/env perl
# ABSTRACT: The raider CLI renderer: lines and the config report

use strict;
use warnings;
use utf8;
use Test2::V0;
use Langertha::Raider::CLI::Output;

# An Output writing into a string through the same :encoding(UTF-8) layer
# bin/raider puts on STDOUT. Returns the output and a reader for the octets.
sub output {
  my ( %args ) = @_;
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  my $out = Langertha::Raider::CLI::Output->new(out => $fh, %args);
  return ( $out, sub { close $fh; my $b = $buf; $b } );
}

subtest 'plain lines without a terminal' => sub {
  my ( $out, $read ) = output();
  ok(!$out->color, 'no color on a non-terminal handle');
  $out->say_meta('history cleared.');
  $out->say_error('boom');
  $out->say_agent('run `prove`');
  is($read->(), "history cleared.\nerror: boom\nrun `prove`\n", 'lines');
};

subtest 'colors and inline code' => sub {
  local $ENV{ANSI_COLORS_DISABLED};
  my ( $out, $read ) = output(color => 1);
  like($out->c(meta => 'x'), qr/\e\[[\d;]+mx\e\[0m/, 'colored');
  like($out->render_inline_code('a `b` c'), qr/a \e\[[\d;]+mb\e\[0m\e\[[\d;]+m c/, 'inline code highlighted');
  is($out->render_inline_code("```\ncode\n```"), "```\ncode\n```", 'fences untouched');
};

subtest 'config report' => sub {
  my ( $out, $read ) = output();
  $out->config_report({
    file    => '/x/.raider.yml',
    exists  => 0,
    engine  => 'openai',
    values  => [
      { key => 'model', value => 'm', source => '-m', shadowed => ['.raider.yml'], applies_to => 'engine' },
      { key => 'skills', value => ['claude'], source => '.raider.yml', shadowed => [], merged => 1,
        applies_to => 'raider' },
    ],
    ignored => [ { key => 'anthropic', reason => 'section of an inactive engine' } ],
  });
  is($read->(), <<'OUT', 'report');
file:   /x/.raider.yml (not present)
engine: openai
  model                  m  (from -m, overrides .raider.yml; engine)
  skills                 ["claude"]  (from .raider.yml, merged; raider)
  ignored anthropic: section of an inactive engine
OUT
};

subtest 'config report: the skill name column fits the longest name' => sub {
  my ( $out, $read ) = output();
  $out->config_report({
    file => '/x/.raider.yml', exists => 1, engine => 'openai', values => [], ignored => [],
    skills => [
      { name => 'pdf', source => '.claude/skills', listed => 1 },
      { name => 'mattpocock-skills:improve-codebase-architecture', source => 'plugin mattpocock-skills', listed => 1 },
      { name => 'deploy', source => '.claude/skills', listed => 0 },
    ],
  });
  my @rows = grep { /^  \S/ } split /\n/, $read->();
  is(scalar @rows, 3, 'one row per skill');
  is([ map { index($_, ' listed') > 0 ? index($_, ' listed') : index($_, ' hidden') } @rows ],
    [ (2 + 47) x 3 ], 'the state column lines up behind the longest name (47 characters)');
  like($rows[2], qr/^  deploy +hidden    \.claude\/skills; disable-model-invocation$/, 'hidden row');
};

subtest 'config report: agents' => sub {
  my ( $out, $read ) = output();
  $out->config_report({
    file => '/x/.raider.yml', exists => 1, engine => 'openai', values => [], ignored => [],
    agents => [
      { name => 'reviewer', source => '.claude/agents', file => '/p/.claude/agents/reviewer.md',
        tools => [qw( read_file grep )], disallowed => [ 'bash' ],
        model => { declared => 'sonnet', inherit => 1, reason => 'model sonnet: inherited, engine openai is not the Anthropic API' },
        skills => [qw( a b )], unknown_tools => [ 'NotebookEdit' ], ignored_keys => [qw( color maxTurns )] },
      { name => 'none', source => '.raider/agents', file => '/p/.raider/agents/none.md', tools => [], disallowed => [],
        model => { declared => 'opus', model => 'claude-opus-5-5' }, skills => [], unknown_tools => [], ignored_keys => [] },
      { name => 'general-purpose', source => 'built-in', file => undef, tools => '*', disallowed => [],
        model => { declared => undef, inherit => 1, reason => 'no model set' }, skills => [], unknown_tools => [], ignored_keys => [] },
    ],
    shadowed_agents => [ { name => 'reviewer', source => '~/.claude/agents', file => '/h/r.md', by => '.claude/agents' } ],
    agent_problems  => [ { file => '/p/.claude/agents/README.md', reason => 'no description: not an agent' } ],
  });
  is($read->(), <<'OUT', 'one block per agent, then shadowed and problems');
file:   /x/.raider.yml
engine: openai
agents: (started by the agent tool; tools in raider names)
  reviewer               .claude/agents
    tools read_file, grep; not bash; model inherit (model sonnet: inherited, engine openai is not the Anthropic API); skills a, b
    unknown tools: NotebookEdit
    not used by raider: color, maxTurns
  none                   .raider/agents
    tools none; model claude-opus-5-5
  general-purpose        built-in
    tools *; model inherit (no model set)
  shadowed agent reviewer (~/.claude/agents) by .claude/agents
  agent file /p/.claude/agents/README.md: no description: not an agent
OUT
};

done_testing;
