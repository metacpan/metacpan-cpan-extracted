#!/usr/bin/env perl
# ABSTRACT: Agent catalogue: roots, precedence, frontmatter, tools, skills, plugins, model mapping (ADR 0020, k153)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env );
use Langertha::Raider::Context::Agents;
use Langertha::Raider::Context::Plugins;
use Langertha::Raider::Context;
use Langertha::Raider::CLI;

# Agent files are Claude Code's Markdown + frontmatter in every root. The
# first agent of a name wins, plugins are plugin:agent, the built-ins
# general-purpose, Explore and Plan come last. Nothing here starts an agent.

local %ENV = %ENV;
clear_engine_env();
delete $ENV{CLAUDE_CONFIG_DIR};
my $home = path(tempdir(CLEANUP => 1))->realpath;
$ENV{HOME} = "$home";

my $w = path(tempdir(CLEANUP => 1))->realpath;
sub put {
  my ( $base, $rel, $text ) = @_;
  my $f = path($base)->child($rel);
  $f->parent->mkpath;
  $f->spew_utf8($text);
  return $f;
}
sub agent_md {
  my ( %fm ) = @_;
  my $body = delete $fm{body} // 'Body.';
  return '---'."\n".YAML::PP->new->dump_string(\%fm) =~ s/\A---\n//r.'---'."\n\n".$body."\n";
}
sub catalog { Langertha::Raider::Context::Agents->new(@_) }
sub names { [ map { $_->{name} } $_[0]->agents ] }
sub project { path(tempdir(CLEANUP => 1))->realpath }

subtest 'roots: recursive walk, hidden skipped, precedence, shadowing' => sub {
  put($w, 'a/reviewer.md', agent_md(name => 'reviewer', description => 'Reviews code.'));
  put($w, 'a/zeta.md', agent_md(description => 'Named after the file.'));
  put($w, 'a/sub/deep.md', agent_md(name => 'deep', description => 'In a subdirectory.'));
  put($w, 'a/sub/dup.md', agent_md(name => 'dup', description => 'dup in a/sub'));
  put($w, 'a/dup.md', agent_md(name => 'dup', description => 'dup in a, files before subdirectories'));
  put($w, 'a/.hidden.md', agent_md(name => 'hidden-file', description => 'never'));
  put($w, 'a/.local/x.md', agent_md(name => 'hidden-dir', description => 'never'));
  put($w, 'a/notes.txt', "not markdown\n");
  put($w, 'a/README.md', "# Agents\n\nNo frontmatter, no description.\n");
  put($w, 'a/nodesc.md', agent_md(name => 'nodesc'));
  put($w, 'a/broken.md', "---\n[unclosed\n---\nbody\n");
  put($w, 'b/reviewer.md', agent_md(name => 'reviewer', description => 'Shadowed by a.'));
  put($w, 'b/other.md', agent_md(name => 'other', description => 'Only in b.'));

  my $c = catalog(roots => [
    { dir => "$w/a", source => 'root a' },
    { dir => "$w/missing", source => 'missing' },
    { dir => "$w/b", source => 'root b' },
  ]);
  is(names($c), [qw( dup reviewer zeta deep other general-purpose Explore Plan )],
    'files of a directory sorted, then its subdirectories; roots in order; built-ins last');
  is($c->find('zeta')->{description}, 'Named after the file.', 'name falls back to the file name');
  is($c->find('dup')->{description}, 'dup in a, files before subdirectories', 'first of a name wins inside a root');
  like($c->find('reviewer'), { source => 'root a', file => "$w/a/reviewer.md", dir => "$w/a", body => "Body.\n", builtin => 0 },
    'winner with file, dir, body without frontmatter');
  is([ sort map { "$_->{name} ($_->{source}) by $_->{by}" } $c->shadowed ],
    [ 'dup (root a) by root a', 'reviewer (root b) by root a' ], 'shadowed');
  is($c->find('hidden-file'), undef, 'hidden file skipped');
  is($c->find('hidden-dir'), undef, 'hidden directory skipped');
  my %problem = map { path($_->{file})->basename => $_->{reason} } $c->problems;
  is(\%problem, {
    'README.md' => 'no description: not an agent',
    'nodesc.md' => 'no description: not an agent',
    'broken.md' => match qr/\Ainvalid frontmatter: .*; no description: not an agent\z/,
  }, 'files without description are reported, not loaded');
};

subtest 'frontmatter: tools, disallowedTools, model, skills, ignored keys' => sub {
  my $d = $w->child('fm');
  put($d, 'list.md', agent_md(name => 'list', description => 'd',
    tools => [qw( Read Grep Bash mcp__github__create_issue perl_eval NotebookEdit Read read_file )]));
  put($d, 'string.md', agent_md(name => 'string', description => 'd', tools => 'Read, Edit,MultiEdit , WebFetch',
    disallowedTools => 'Write, KillShell, SendMessage, ListAgents'));
  put($d, 'star.md', agent_md(name => 'star', description => 'd', tools => '*', disallowedTools => [ 'Bash', 'ask_user' ]));
  put($d, 'empty.md', agent_md(name => 'empty', description => 'd', tools => ''));
  put($d, 'none.md', agent_md(name => 'none', description => 'd', tools => [ 'NotebookEdit' ]));
  put($d, 'skills.md', agent_md(name => 'skills', description => 'd', model => 'sonnet',
    skills => [qw( a b )], briefing => { skills => [qw( b c )] },
    color => 'blue', permissionMode => 'plan', maxTurns => 3));
  put($d, 'flow.md', agent_md(name => 'flow', description => 'd', skills => 'x, y', briefing => { skills => 'y,z' }));
  # What YAML rejects but Claude Code reads: an unquoted ': ' in the
  # description, with the briefing block below it.
  put($d, 'lenient.md', "---\nname: lenient\ndescription: Use this agent when: the YAML breaks\n"
    ."tools: Read, Grep\nmodel: haiku\nbriefing:\n  skills:\n    - one\n    - 'two'\ncolor: red\n---\nLenient body.\n");
  put($d, 'leflow.md', "---\nname: leflow\ndescription: Flow: in a broken file\nbriefing:\n  skills: [p, \"q\"]\n---\nb\n");

  my $c = catalog(roots => [ { dir => "$d", source => 'fm' } ]);
  like($c->find('list'), {
    tools         => [qw( read_file grep bash mcp__github__create_issue perl_eval )],
    disallowed    => [],
    unknown_tools => [ 'NotebookEdit' ],
  }, 'list: Claude names mapped, raider and mcp names kept, unknown reported, each once');
  like($c->find('string'), {
    tools         => [qw( read_file edit_file multi_edit web_fetch )],
    disallowed    => [qw( write_file kill_shell send_message )],
    unknown_tools => [ 'ListAgents' ],
  }, 'comma-separated string; MultiEdit, KillShell (ADR 0025) and SendMessage (ADR 0027) mapped; disallowed mapped, unknown reported');
  like($c->find('star'), { tools => undef, disallowed => [qw( bash ask_user )] }, '* means every tool');
  is($c->find('empty')->{tools}, undef, 'empty tools: every tool');
  is($c->find('none')->{tools}, [], 'only unknown names: no tool');
  is($c->find('list')->{model}, undef, 'no model');
  like($c->find('skills'), {
    model        => 'sonnet',
    skills       => [qw( a b c )],
    ignored_keys => [qw( color maxTurns permissionMode )],
  }, 'skills first, then briefing.skills, each once; unused keys listed');
  is($c->find('flow')->{skills}, [qw( x y z )], 'skills as comma-separated strings');
  like($c->find('lenient'), {
    description  => 'Use this agent when: the YAML breaks',
    tools        => [qw( read_file grep )],
    model        => 'haiku',
    skills       => [qw( one two )],
    ignored_keys => [ 'color' ],
    body         => "Lenient body.\n",
  }, 'lenient reader keeps the nested briefing.skills');
  is($c->find('leflow')->{skills}, [qw( p q )], 'lenient reader: a [a, b] flow');
  is([ $c->problems ], [], 'no problems');
};

subtest 'frontmatter reader: one level of nesting in the lenient reader' => sub {
  my $F = 'Langertha::Raider::Context::Frontmatter';
  my ( $fm, $body, $problem ) = $F->parse("---\nname: x\ndescription: a: b\nbriefing:\n  skills:\n    - one\n"
    ."  other: v: w\nnotes: |\n  key: not nested\nflag: true\n---\n\nBody\n", booleans => [ 'flag' ]);
  is($problem, undef, 'no problem');
  is($body, "Body\n", 'body');
  is($fm, { name => 'x', description => 'a: b', briefing => { skills => [ 'one' ], other => 'v: w' },
    notes => 'key: not nested', flag => T() }, 'nested mapping, block scalar stays flat, boolean key');
  is([ $F->parse("---\n[x\n---\nb\n") ], [ {}, "b\n", match qr/\Ainvalid frontmatter: / ], 'broken');
  is([ $F->parse("---\n- a\n---\nb\n") ], [ {}, "b\n", 'frontmatter is not a mapping' ], 'not a mapping');
  is([ $F->parse("no frontmatter\n") ], [ {}, "no frontmatter\n", undef ], 'none');
};

subtest 'raider_tool_name' => sub {
  my $c = catalog(roots => []);
  is($c->raider_tool_name('Read'), 'read_file', 'Claude name');
  is($c->raider_tool_name('Task'), 'agent', 'Task is agent');
  is($c->raider_tool_name('list_files'), 'list_files', 'raider name of the table');
  is($c->raider_tool_name('raider_pause'), 'raider_pause', 'built-in tool outside the Claude table');
  is($c->raider_tool_name('hall_spawn'), 'hall_spawn', 'hall tool');
  is($c->raider_tool_name('mcp__srv__do_it'), 'mcp__srv__do_it', 'mcp passes through');
  is($c->raider_tool_name('read'), undef, 'case matters');
  is($c->raider_tool_name('Bash(git:*)'), undef, 'a permission pattern is not a tool name');
  is($c->raider_tool_name(''), undef, 'empty');
};

subtest 'general-purpose: built-in, shadowable' => sub {
  my $c = catalog(roots => []);
  my $gp = $c->find('general-purpose');
  like($gp, {
    source => 'built-in', file => undef, builtin => 1, tools => undef, disallowed => [],
    model => undef, skills => [],
    description => match qr/\AGeneral-purpose agent for researching complex questions, searching for code, and executing multi-step tasks\. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you\.\z/,
    body => match qr/nothing more, nothing less/,
  }, 'built-in with Claude Code\'s description and every tool');
  is([ $c->shadowed ], [], 'nothing shadowed');

  put($w, 'gp/general-purpose.md', agent_md(description => 'My own general-purpose.'));
  my $own = catalog(roots => [ { dir => "$w/gp", source => 'gp' } ]);
  is(names($own), [qw( general-purpose Explore Plan )], 'one general-purpose');
  is($own->find('general-purpose')->{source}, 'gp', 'the file wins');
  is([ $own->shadowed ], [ { name => 'general-purpose', source => 'built-in', file => undef, by => 'gp' } ],
    'the built-in is reported as shadowed');
};

subtest 'plugins: agent_dirs and plugin:agent names' => sub {
  my $root = $w->child('plugin');
  put($root, 'agents/helper.md', agent_md(name => 'helper', description => 'Plugin helper.'));
  put($root, 'agents/nested/inner.md', agent_md(description => 'Nested plugin agent.'));
  put($root, 'extra/one.md', agent_md(name => 'one', description => 'From a manifest file path.'));
  put($root, 'more/two.md', agent_md(name => 'two', description => 'From a manifest directory.'));
  put($w, 'outside/evil.md', agent_md(name => 'evil', description => 'Outside the plugin root.'));
  my $plugins = Langertha::Raider::Context::Plugins->new(cwd => "$w", enabled => {});
  my $entry = { name => 'kit', root => "$root",
    manifest => { agents => [ './extra/one.md', 'more', '../outside', 'agents', 'missing' ] } };
  is([ $plugins->agent_dirs($entry) ], [ "$root/agents", "$root/extra/one.md", "$root/more" ],
    'agents/, then manifest paths; outside, missing and duplicate paths dropped');
  is([ $plugins->agent_dirs({ %$entry, manifest => { agents => 'more' } }) ], [ "$root/agents", "$root/more" ],
    'manifest agents as a string');

  put($w, 'proot/helper.md', agent_md(name => 'helper', description => 'Root helper.'));
  my $c = catalog(
    roots   => [ { dir => "$w/proot", source => 'proot' } ],
    plugins => [ { name => 'kit', dirs => [ $plugins->agent_dirs($entry) ] } ],
  );
  is(names($c), [qw( helper kit:helper kit:inner kit:one kit:two general-purpose Explore Plan )],
    'plugin agents after the roots, named plugin:agent, never shadowed by a root');
  is($c->find('kit:helper')->{source}, 'plugin kit', 'source');
};

subtest 'resolve_model' => sub {
  my $c = catalog(roots => []);
  my %ant = ( engine_class => 'Langertha::Engine::Anthropic', engine_name => 'anthropic' );
  my %oai = ( engine_class => 'Langertha::Engine::OpenAI', engine_name => 'openai' );
  is($c->resolve_model(undef, %ant), { inherit => 1, reason => 'no model set' }, 'absent');
  is($c->resolve_model('inherit', %ant), { inherit => 1, reason => 'model inherit' }, 'inherit');
  is($c->resolve_model('opus', %ant), { model => 'claude-opus-5-5' }, 'opus');
  is($c->resolve_model('sonnet', %ant), { model => 'claude-sonnet-5-5' }, 'sonnet');
  is($c->resolve_model('Haiku', %ant), { model => 'claude-haiku-5-5' }, 'haiku, any case');
  is($c->resolve_model('claude-opus-4-1', %ant), { model => 'claude-opus-4-1' }, 'full claude-* id passes through');
  is($c->resolve_model('sonnet', %oai),
    { inherit => 1, reason => 'model sonnet: inherited, engine openai is not the Anthropic API' }, 'other engine');
  is($c->resolve_model('claude-opus-4-1', %oai)->{inherit}, 1, 'full id on another engine: inherit');
  is($c->resolve_model('sonnet', engine_class => 'Langertha::Engine::MiniMax', engine_name => 'minimax')->{inherit}, 1,
    'an Anthropic-dialect engine is not the Anthropic API');
  is($c->resolve_model('gpt-4o', %ant),
    { inherit => 1, reason => 'model gpt-4o: inherited, not an alias (haiku, opus, sonnet) or a claude-* model id' },
    'unknown model string');
  is($c->resolve_model('sonnet', %ant, agent_models => { sonnet => 'claude-sonnet-4-6', fast => 'x', opus => '' }),
    { model => 'claude-sonnet-4-6' }, 'agent_models overrides an alias');
  is($c->resolve_model('opus', %ant, agent_models => { opus => '' }), { model => 'claude-opus-5-5' },
    'an empty override is ignored');
  is($c->resolve_model('fast', %ant, agent_models => { fast => 'claude-x' })->{inherit}, 1,
    'agent_models adds no new alias');
  is($c->resolve_model('sonnet', %oai, agent_models => { sonnet => 'claude-sonnet-4-6' })->{inherit}, 1,
    'the override does not change the engine rule');
  is($c->resolve_model('sonnet', engine_class => undef)->{reason},
    'model sonnet: inherited, engine unknown is not the Anthropic API', 'no engine');
  is($c->resolve_model('sonnet', engine_class => 'No::Such::Engine')->{reason},
    'model sonnet: inherited, engine No::Such::Engine is not the Anthropic API', 'engine class that does not load');
};

subtest 'report: plain data' => sub {
  put($w, 'rep/r.md', agent_md(name => 'r', description => 'd', tools => 'Read, NotebookEdit', model => 'sonnet',
    disallowedTools => 'Bash', briefing => { skills => [ 's' ] }, color => 'x'));
  put($w, 'rep/bad.md', "no frontmatter\n");
  my $r = catalog(roots => [ { dir => "$w/rep", source => 'rep' } ])
    ->report(engine_class => 'Langertha::Engine::Anthropic', engine_name => 'anthropic');
  is($r, {
    agents => [
      { name => 'r', source => 'rep', file => "$w/rep/r.md", tools => [ 'read_file' ], disallowed => [ 'bash' ],
        model => { declared => 'sonnet', model => 'claude-sonnet-5-5' }, skills => [ 's' ],
        unknown_tools => [ 'NotebookEdit' ], ignored_keys => [ 'color' ] },
      { name => 'general-purpose', source => 'built-in', file => undef, tools => '*', disallowed => [],
        model => { declared => undef, inherit => 1, reason => 'no model set' }, skills => [],
        unknown_tools => [], ignored_keys => [] },
      ( map { {
        name => $_, source => 'built-in', file => undef, tools => '*',
        disallowed => [qw( agent send_message write_file edit_file multi_edit exit_plan_mode )],
        model => { declared => undef, inherit => 1, reason => 'no model set' }, skills => [],
        unknown_tools => [], ignored_keys => [] } } qw( Explore Plan ) ),
    ],
    shadowed => [],
    problems => [ { file => "$w/rep/bad.md", reason => 'no description: not an agent' } ],
  }, 'shape');
  ok(JSON::MaybeXS->new(canonical => 1)->encode($r), 'JSON-safe');
};

# The context: native roots always, Claude roots and plugins only in the
# Claude layout, nothing with --bare.
put($home, '.raider/agents/home-native.md', agent_md(description => 'home native'));
put($home, '.raider/agents/dup.md', agent_md(description => 'dup from ~/.raider/agents'));
put($home, '.claude/agents/user-claude.md', agent_md(description => 'user claude'));
put($home, '.claude/agents/both.md', agent_md(description => 'both from ~/.claude/agents'));
my $plugin = $home->child('.claude/plugins/cache/m/helper/1.0');
put($plugin, 'agents/tidy.md', agent_md(description => 'plugin tidy'));
my $off = $home->child('.claude/plugins/cache/m/off/1.0');
put($off, 'agents/never.md', agent_md(description => 'disabled plugin'));
put($home, '.claude/plugins/installed_plugins.json', JSON::MaybeXS->new->encode({ version => 2, plugins => {
  'helper@m' => [ { scope => 'user', installPath => "$plugin" } ],
  'off@m'    => [ { scope => 'user', installPath => "$off" } ],
} }));
put($home, '.claude/settings.json', '{ "enabledPlugins": { "helper@m": true, "off@m": false } }');

subtest 'context: roots per layout' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "Project memory.\n");
  put($p, '.raider/agents/dup.md', agent_md(description => 'dup from .raider/agents'));
  put($p, '.raider/agents/proj-native.md', agent_md(description => 'project native'));
  put($p, '.claude/agents/both.md', agent_md(description => 'both from .claude/agents'));
  put($p, '.claude/agents/proj-claude.md', agent_md(description => 'project claude'));
  # .raider/ makes it a raider project: claude: true turns the layout on.
  my $c = Langertha::Raider::Context->new(root => "$p", config_claude => 1);
  is($c->claude_layout, 1, 'raider project reading the Claude layout');
  is([ map { $_->{source} } @{ $c->agent_roots } ],
    [ '.raider/agents', '~/.raider/agents', '.claude/agents', '~/.claude/agents' ], 'root order');
  my $cat = $c->agent_catalog;
  is(names($cat), [qw( dup proj-native home-native both proj-claude user-claude helper:tidy general-purpose Explore Plan )],
    'native, then project .claude/agents before the user\'s, then enabled plugins, then the built-in');
  is($cat->find('dup')->{description}, 'dup from .raider/agents', 'project native first');
  is($cat->find('both')->{description}, 'both from .claude/agents', 'Claude project before user');
  is($cat->find('off:never'), undef, 'disabled plugin not read');
  is([ sort map { "$_->{name} $_->{source} by $_->{by}" } $cat->shadowed ],
    [ 'both ~/.claude/agents by .claude/agents', 'dup ~/.raider/agents by .raider/agents' ], 'shadowed');
  like($c->report, {
    agents          => [ { name => 'dup' }, {}, {}, {}, {}, {}, { name => 'helper:tidy', source => 'plugin helper' }, { name => 'general-purpose' },
      { name => 'Explore' }, { name => 'Plan' } ],
    shadowed_agents => [ {}, {} ],
    agent_problems  => [],
  }, 'report carries the agents');

  my $native = project();
  put($native, '.raider/agents/n.md', agent_md(description => 'n'));
  put($native, '.claude/agents/c.md', agent_md(description => 'not read outside the Claude layout'));
  my $nc = Langertha::Raider::Context->new(root => "$native");
  ok(!$nc->claude_layout, 'no Claude layout');
  is(names($nc->agent_catalog), [qw( n dup home-native general-purpose Explore Plan )], 'native roots only, no plugins');

  my $bare = Langertha::Raider::Context->new(root => "$p", bare => 1);
  is($bare->agent_roots, [], 'bare: no roots');
  is(names($bare->agent_catalog), [qw( general-purpose Explore Plan )], 'bare: the built-ins only');
};

subtest 'context: CLAUDE_CONFIG_DIR is the user Claude directory' => sub {
  my $cfg = path(tempdir(CLEANUP => 1))->realpath;
  put($cfg, 'agents/from-config-dir.md', agent_md(description => 'via CLAUDE_CONFIG_DIR'));
  local $ENV{CLAUDE_CONFIG_DIR} = "$cfg";
  my $p = project();
  put($p, 'CLAUDE.md', "x\n");
  my $cat = Langertha::Raider::Context->new(root => "$p")->agent_catalog;
  ok($cat->find('from-config-dir'), 'read from $CLAUDE_CONFIG_DIR/agents');
  is($cat->find('user-claude'), undef, '~/.claude/agents not read then');
};

subtest "the repository's own .claude/agents" => sub {
  my $dir = path('.claude/agents');
  skip_all 'no .claude/agents in this checkout' unless -d $dir;
  my $c = catalog(roots => [ { dir => "$dir", source => '.claude/agents' } ]);
  is([ $c->problems ], [], 'no problems');
  my %want = (
    'raider-worker' => [qw( getty-perl-core perl-ai-langertha raider-core getty-perl-moose perl-io-async-future
                            perl-mcp kanban-issues-karr-ticket getty-perl-pod )],
    'raider-test-writer' => [qw( getty-perl-core perl-ai-langertha raider-core perl-io-async-future perl-mcp
                                 kanban-issues-karr-ticket )],
    'raider-binary-worker' => [qw( raider-core raider-single-binary getty-perl-core kanban-issues-karr-ticket )],
    'raider-release-manager' => [qw( raider-core getty-git-commit-style getty-git-usage getty-perl-release-author-getty
                                     perl-release-dist-ini kanban-issues-karr-ticket )],
  );
  for my $name (sort keys %want) {
    my $a = $c->find($name);
    ok($a, $name.' found') or next;
    is($a->{skills}, $want{$name}, $name.': briefing.skills');
    is($a->{tools}, undef, $name.': every tool');
    like($a->{description}, qr/\S/, $name.': description');
    like($a->{body}, qr/\AYou are the \Q$name\E/, $name.': body without frontmatter');
  }
  is($c->find('raider-release-manager')->{model}, 'sonnet', 'model as written');
  is($c->find('raider-worker')->{model}, 'inherit', 'inherit as written');
};

subtest 'application: config keys and explain_config' => sub {
  my $p = project();
  put($p, '.raider.yml', YAML::PP->new->dump_string({
    claude          => 1,
    max_agent_depth => 2,
    agent_models    => { sonnet => 'claude-sonnet-4-6' },
  }));
  put($p, '.claude/agents/rev.md', agent_md(description => 'Reviewer.', model => 'sonnet', tools => 'Read, NotebookEdit'));
  my %a = ( root => "$p", api_key => 'x', trace => 0 );
  my $app = Langertha::Raider::CLI->new(%a, engine => 'anthropic');
  is($app->max_agent_depth, 2, 'max_agent_depth from the config');
  is($app->agent_models, { sonnet => 'claude-sonnet-4-6' }, 'agent_models from the config');
  my $report = $app->explain_config;
  my ( $rev ) = grep { $_->{name} eq 'rev' } @{ $report->{agents} };
  like($rev, { name => 'rev', source => '.claude/agents', tools => [ 'read_file' ],
    unknown_tools => [ 'NotebookEdit' ], model => { declared => 'sonnet', model => 'claude-sonnet-4-6' } },
    'agents section: the override under the Anthropic API');
  like([ grep { $_->{key} =~ /\A(?:agent_models|max_agent_depth)\z/ } @{ $report->{values} } ], [
    { key => 'agent_models', value => { sonnet => 'claude-sonnet-4-6' }, applies_to => 'raider' },
    { key => 'max_agent_depth', value => 2, applies_to => 'raider' },
  ], 'both keys listed as raider settings');
  is($app->config->engine_options('anthropic'), {}, 'neither key reaches the engine');

  my $oai = Langertha::Raider::CLI->new(%a, engine => 'openai')->explain_config;
  like([ grep { $_->{name} eq 'rev' } @{ $oai->{agents} } ], [ { model => { inherit => 1,
    reason => 'model sonnet: inherited, engine openai is not the Anthropic API' } } ], 'inherited under openai');
  is([ map { $_->{name} } @{ $oai->{agents} }[-3 .. -1] ], [qw( general-purpose Explore Plan )], 'the built-ins last');

  my $flag = Langertha::Raider::CLI->new(%a, engine => 'openai', engine_options => { max_agent_depth => 0 });
  is($flag->max_agent_depth, 0, '-o max_agent_depth= overrides the config');
  my $plain = project();
  is(Langertha::Raider::CLI->new(%a, root => "$plain", engine => 'openai')->max_agent_depth, 3, 'default 3 (ADR 0027)');
  my $deep = Langertha::Raider::CLI->new(%a, root => "$plain", engine => 'openai',
    engine_options => { max_agent_depth => 'deep' });
  is($deep->max_agent_depth, 3, 'not an integer: default');
  like([ grep { $_->{key} eq 'max_agent_depth' } @{ $deep->explain_config->{ignored} } ],
    [ { reason => 'not a non-negative integer' } ], 'listed as ignored');
  is(Langertha::Raider::CLI->new(%a, root => "$plain", engine => 'openai')->agent_models, {}, 'no agent_models');
};

done_testing;
