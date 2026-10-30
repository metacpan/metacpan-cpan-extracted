#!/usr/bin/env perl
# ABSTRACT: Commands in the skill catalogue: commands roots, plugin commands, precedence, user-invocable (ADR 0030 §1, k165)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Context;
use Langertha::Raider::Context::Plugins;
use Langertha::Raider::Context::Skills;

# Commands are skills: a commands root is searched recursively for *.md,
# named by the path with ':' between directories, kind 'command'. A skill
# beats a command of its name wherever it stands. user-invocable: false
# keeps an entry from /name, disable-model-invocation from the model; both
# take true/false/yes/no/on/off/1/0. Plugins add commands/ and the
# manifest's commands paths as plugin:name. The context reads
# .raider/commands and ~/.raider/commands, and in the Claude layout
# ~/.claude/commands before .claude/commands, then plugin commands; --bare
# reads nothing. HOME is a temp dir, CLAUDE_CONFIG_DIR unset: no real
# ~/.claude leaks in.

local %ENV = %ENV;
delete $ENV{$_} for grep { /_API_KEY$/ } keys %ENV;
delete $ENV{CLAUDE_CONFIG_DIR};
my $home = path(tempdir(CLEANUP => 1))->realpath;
$ENV{HOME} = "$home";

sub put {
  my ( $base, $rel, $text ) = @_;
  my $f = path($base)->child($rel);
  $f->parent->mkpath;
  $f->spew_utf8($text);
  return $f;
}
sub cmd   { "---\ndescription: $_[0]\n---\nbody of $_[0] \$ARGUMENTS\n" }
sub skill { "---\ndescription: $_[0]\n---\nbody of $_[0]\n" }
sub names { [ map { $_->{name} } $_[0]->skills ] }
sub cat   { Langertha::Raider::Context::Skills->new(@_) }

subtest 'a commands root: recursive, namespaced, kind command' => sub {
  my $w = path(tempdir(CLEANUP => 1));
  put($w, 'cmds/deploy.md', cmd('Deploy it'));
  put($w, 'cmds/frontend/component.md', "# Component\n\nMake a component.\n");
  put($w, 'cmds/frontend/deep/er.md', cmd('deeper'));
  put($w, 'cmds/.hidden/secret.md', cmd('hidden dir'));
  put($w, 'cmds/.dot.md', cmd('hidden file'));
  put($w, 'cmds/notes.txt', "not markdown\n");
  my $c = cat(roots => [ { dir => "$w/cmds", source => '.claude/commands', layout => 'commands' } ]);
  is(names($c), [qw( deploy frontend:component frontend:deep:er )], 'sorted names, dirs joined with :');
  is($c->find('/frontend:component'), {
    name            => 'frontend:component',
    kind            => 'command',
    description     => 'Make a component.',
    dir             => "$w/cmds/frontend",
    file            => "$w/cmds/frontend/component.md",
    source          => '.claude/commands',
    frontmatter     => {},
    model_invocable => 1,
    user_invocable  => 1,
  }, 'all fields; description from the first body line');
  is([ map { $_->{name} } $c->listed ], names($c), 'commands are listed for the model');
  like($c->prompt_text, qr/^- deploy: Deploy it$/m, 'and in the listing');
  is($c->tool_text('deploy', 'prod'), "body of Deploy it prod\n", 'command text: no Base directory line');
  is([ map { $_->{name} } $c->user_invocable ], names($c), 'all user-invocable');
};

subtest 'precedence: first command wins, a skill beats a command anywhere' => sub {
  my $w = path(tempdir(CLEANUP => 1));
  put($w, 'a/pdf.md', cmd('command pdf'));
  put($w, 'a/only.md', cmd('first only'));
  put($w, 'b/only.md', cmd('second only'));
  put($w, 'skills/pdf/SKILL.md', skill('skill pdf'));
  my $c = cat(roots => [
    { dir => "$w/a",      source => 'cmds a', layout => 'commands' },
    { dir => "$w/b",      source => 'cmds b', layout => 'commands' },
    { dir => "$w/skills", source => 'skills', layout => 'skills' },
  ]);
  is(names($c), [qw( only pdf )], 'one entry per name');
  is($c->find('only')->{source}, 'cmds a', 'the first command root wins');
  is($c->find('pdf')->{kind}, 'skill', 'the skill wins although its root comes later');
  is($c->find('pdf')->{source}, 'skills', '... from its root');
  like($c->tool_text('pdf'), qr/\ABase directory for this skill: \Q$w\E\/skills\/pdf\n\nbody of skill pdf/,
    'a skill keeps the Base directory line');
  is([ sort { $a->{name} cmp $b->{name} } $c->shadowed ], [
    { name => 'only', source => 'cmds b', file => "$w/b/only.md",  by => 'cmds a' },
    { name => 'pdf',  source => 'cmds a', file => "$w/a/pdf.md",   by => 'skills' },
  ], 'shadowed: the later command, and the command the skill beat');

  # A skill that arrives later (a nested .claude/skills) still beats the command.
  put($w, 'c/only/SKILL.md', skill('late skill'));
  my @new = $c->add_roots({ dir => "$w/c", source => 'late', layout => 'skills' });
  is([ map { [ $_->{name}, $_->{kind} ] } @new ], [ [ only => 'skill' ] ], 'add_roots returns the skill that took the name');
  is($c->find('only')->{source}, 'late', 'it replaced the command');
  is(scalar( grep { $_->{name} eq 'only' } $c->skills ), 1, 'once in the catalogue');
  ok(scalar( grep { $_->{name} eq 'only' && $_->{source} eq 'cmds a' && $_->{by} eq 'late' } $c->shadowed ),
    'the command is shadowed by it');

  # The other way round a command never takes a skill's name.
  put($w, 'd/pdf.md', cmd('late command'));
  is([ $c->add_roots({ dir => "$w/d", source => 'late cmds', layout => 'commands' }) ], [], 'nothing new');
  is($c->find('pdf')->{source}, 'skills', 'the skill stays');
};

subtest 'user-invocable and disable-model-invocation, boolean words' => sub {
  my $w = path(tempdir(CLEANUP => 1));
  my %flag = (
    'u-false' => [ 'user-invocable: false',  0, 1 ],
    'u-no'    => [ 'user-invocable: no',     0, 1 ],
    'u-off'   => [ 'user-invocable: off',    0, 1 ],
    'u-zero'  => [ 'user-invocable: 0',      0, 1 ],
    'u-FALSE' => [ 'user-invocable: FALSE',  0, 1 ],
    'u-true'  => [ 'user-invocable: true',   1, 1 ],
    'u-yes'   => [ 'user-invocable: yes',    1, 1 ],
    'u-junk'  => [ 'user-invocable: maybe',  1, 1 ],
    'u-empty' => [ 'user-invocable:',        1, 1 ],
    'm-true'  => [ 'disable-model-invocation: true', 1, 0 ],
    'm-yes'   => [ 'disable-model-invocation: yes',  1, 0 ],
    'm-on'    => [ 'disable-model-invocation: On',   1, 0 ],
    'm-one'   => [ 'disable-model-invocation: 1',    1, 0 ],
    'm-no'    => [ 'disable-model-invocation: no',   1, 1 ],
    'm-zero'  => [ 'disable-model-invocation: 0',    1, 1 ],
    # Not YAML (an unquoted ': ' in the description): the lenient reader.
    'l-no'    => [ "description: a: b\nuser-invocable: no\ndisable-model-invocation: on", 0, 0 ],
    'l-off'   => [ "description: a: b\nuser-invocable: off", 0, 1 ],
  );
  put($w, "c/$_.md", "---\n$flag{$_}[0]\n---\nbody $_\n") for keys %flag;
  my $c = cat(roots => [ { dir => "$w/c", source => 'cmds', layout => 'commands' } ]);
  for my $name (sort keys %flag) {
    my $e = $c->find($name);
    is([ $e->{user_invocable}, $e->{model_invocable} ], [ @{ $flag{$name} }[1, 2] ], $name);
  }
  is($c->problems, 0, 'no frontmatter problems');
  is($c->find_user_invocable('/u-no'), undef, 'user-invocable: no is not found for /name');
  is($c->find('u-no')->{name}, 'u-no', '... but find has it');
  ok(scalar( grep { $_->{name} eq 'u-no' } $c->listed ), '... and the model may load it');
  is($c->find_user_invocable('m-true')->{name}, 'm-true', 'disable-model-invocation: the user still runs it');
  ok(!scalar( grep { $_->{name} eq 'm-true' } $c->listed ), '... it is not listed');
  ok(!scalar( grep { $_->{name} eq 'm-true' } $c->invocable ), '... nor model-invocable');
  is($c->find_user_invocable('nope'), undef, 'unknown name');
  is([ sort map { $_->{name} } $c->user_invocable ],
    [ sort grep { $flag{$_}[1] } keys %flag ], 'user_invocable lists the others');
};

subtest 'plugin commands: commands/ and manifest paths, plugin:name' => sub {
  my $w = path(tempdir(CLEANUP => 1));
  my $root = $w->child('plug');
  put($root, 'commands/hello.md', cmd('plugin hello'));
  put($root, 'commands/sub/deep.md', cmd('plugin deep'));
  put($root, 'commands/clash.md', cmd('plugin command clash'));
  put($root, 'skills/clash/SKILL.md', skill('plugin skill clash'));
  put($root, 'custom/one.md', cmd('custom file'));
  put($root, 'more/two.md', cmd('custom dir'));
  put($root, 'more/x/three.md', cmd('custom dir sub'));
  put($root, 'custom/notmd.txt', 'nope');
  put($w, 'outside/escape.md', cmd('outside'));
  put($root, '.claude-plugin/plugin.json', '{}');

  my $plugins = Langertha::Raider::Context::Plugins->new(cwd => "$w", claude_home => "$w", enabled => {});
  my $entry = { name => 'pl', key => 'pl@m', root => "$root",
    manifest => { commands => [ './custom/one.md', 'more', 'more/', '../outside', 'custom/notmd.txt', 'missing', { x => 1 } ] } };
  is([ $plugins->command_dirs($entry) ], [ "$root/commands", "$root/custom/one.md", "$root/more" ],
    'commands/, then the manifest paths: files and dirs, once, inside the root, existing');
  is([ $plugins->command_dirs({ %$entry, manifest => { commands => 'custom/one.md' } }) ],
    [ "$root/commands", "$root/custom/one.md" ], 'a string is one path; commands/ stays');
  is([ $plugins->command_dirs({ %$entry, manifest => { commands => { hello => {} } } }) ],
    [ "$root/commands" ], 'an object adds nothing');

  my $c = cat(roots => [], plugins => [ {
    name     => 'pl',
    root     => "$root",
    dirs     => [ $plugins->skill_dirs($entry) ],
    commands => [ $plugins->command_dirs($entry) ],
  } ]);
  is(names($c), [qw( pl:clash pl:hello pl:sub:deep pl:one pl:two pl:x:three )],
    'plugin skills, then its commands namespaced, path by path');
  ok(scalar( grep { $_->{name} eq 'pl:clash' && $_->{by} eq 'plugin pl' } $c->shadowed ), 'the clashing command is shadowed');
  my %by = map { $_->{name} => $_ } $c->skills;
  is($by{'pl:clash'}{kind}, 'skill', 'the plugin skill beats the plugin command of its name');
  is($by{'pl:hello'}{kind}, 'command', 'command');
  is($by{'pl:hello'}{source}, 'plugin pl', 'source');
  is($by{'pl:hello'}{plugin_root}, "$root", 'plugin_root for ${CLAUDE_PLUGIN_ROOT}');
  is($by{'pl:clash'}{plugin_root}, "$root", '... on plugin skills too');
  is($by{'pl:one'}{dir}, "$root/custom", 'a file path: dir is its directory');
};

subtest 'the context: roots per mode' => sub {
  # The home: native and Claude commands, one installed and enabled plugin with commands.
  put($home, '.raider/commands/home-native.md', cmd('home native'));
  put($home, '.raider/commands/dup.md', cmd('dup from ~/.raider/commands'));
  put($home, '.claude/commands/user-claude.md', cmd('user claude'));
  put($home, '.claude/commands/both.md', cmd('both from ~/.claude/commands'));
  put($home, '.claude/skills/skilled/SKILL.md', skill('a user skill'));
  my $plugin = $home->child('.claude/plugins/cache/m/helper/1.0');
  put($plugin, 'commands/greet.md', cmd('plugin greet'));
  put($plugin, 'commands/git/commit.md', cmd('plugin commit'));
  put($home, '.claude/plugins/installed_plugins.json', JSON::MaybeXS->new->encode({
    version => 2, plugins => { 'helper@m' => [ { scope => 'user', installPath => "$plugin" } ] } }));
  put($home, '.claude/settings.json', '{ "enabledPlugins": { "helper@m": true } }');

  my $project = sub {
    my $p = path(tempdir(CLEANUP => 1))->realpath;
    put($p, '.raider/commands/dup.md', cmd('dup from .raider/commands'));
    put($p, '.raider/commands/proj/native.md', cmd('project native'));
    put($p, '.claude/commands/both.md', cmd('both from .claude/commands'));
    put($p, '.claude/commands/proj-claude.md', cmd('project claude'));
    put($p, '.claude/commands/skilled.md', cmd('a command a skill beats'));
    return $p;
  };
  my $ctx = sub { Langertha::Raider::Context->new(@_) };
  my $cnames = sub { [ map { $_->{name} } grep { $_->{kind} eq 'command' } $_[0]->skill_catalog->skills ] };

  # Native: a plain directory (a .claude/ would make it Claude mode), no Claude layout.
  my $native = path(tempdir(CLEANUP => 1))->realpath;
  put($native, '.raider/commands/dup.md', cmd('dup from .raider/commands'));
  my $n = $ctx->(root => "$native");
  is($n->mode, 'native', 'native mode');
  is([ map { [ $_->{source}, $_->{layout} ] } $n->command_roots ],
    [ [ '.raider/commands' => 'commands' ], [ '~/.raider/commands' => 'commands' ] ], 'native command roots');
  is($cnames->($n), [qw( dup home-native )], '.raider/commands, then ~/.raider/commands');
  is($n->skill_catalog->find('dup')->{source}, '.raider/commands', 'the project wins');
  ok($n->skill_tool_wanted, 'a model-invocable command mounts the skill tool');

  # Claude layout: personal before project, plugin commands last.
  my $p = $project->();
  my $c = $ctx->(root => "$p", config_claude => 1);
  ok($c->claude_layout, 'Claude layout');
  is([ map { $_->{source} } $c->command_roots ],
    [ '.raider/commands', '~/.raider/commands', '~/.claude/commands', '.claude/commands' ], 'Claude command roots');
  is($cnames->($c), [qw( dup proj:native home-native both user-claude proj-claude helper:git:commit helper:greet )],
    'commands in precedence order, plugin commands namespaced');
  my $cat = $c->skill_catalog;
  is($cat->find('both')->{source}, '~/.claude/commands', '~/.claude/commands beats .claude/commands');
  is($cat->find('skilled')->{kind}, 'skill', 'the user skill beats the project command');
  ok(scalar( grep { $_->{name} eq 'skilled' && $_->{source} eq '.claude/commands' } $cat->shadowed ), '... which is shadowed');
  is($cat->find('helper:greet')->{plugin_root}, "$plugin", 'plugin command with its root');
  is($cat->find('proj-claude')->{dir}, "$p/.claude/commands", 'dir of a command');
  my %report = map { $_->{name} => $_ } @{ $c->report->{skills} };
  is($report{'proj-claude'}, { name => 'proj-claude', source => '.claude/commands', listed => 1, kind => 'command' },
    'config explain: commands carry kind');
  is($report{skilled}, { name => 'skilled', source => '~/.claude/skills', listed => 1 }, '... skills do not');

  # Without the Claude layout the .claude roots and plugins are not read.
  my $raider = $project->();
  put($raider, '.raider/config.yml', "model: x\n");
  my $r = $ctx->(root => "$raider");
  ok(!$r->claude_layout, 'raider project: Claude layout off');
  is($cnames->($r), [qw( dup proj:native home-native )], 'only the native command roots');

  # /reload reads the command roots again.
  put($raider, '.raider/commands/later.md', cmd('added later'));
  is($r->skill_catalog->find('later'), undef, 'not before the reload');
  $r->reload;
  is($r->skill_catalog->find('later')->{kind}, 'command', 'after the reload');

  # --bare: nothing.
  my $b = $ctx->(root => "$p", bare => 1, force_claude => 1);
  is([ $b->command_roots ], [], 'bare: no command roots');
  is($cnames->($b), [], 'bare: no commands');
};

done_testing;
