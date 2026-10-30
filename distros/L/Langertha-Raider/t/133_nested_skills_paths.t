#!/usr/bin/env perl
# ABSTRACT: nested .claude/skills and the paths: frontmatter of skills (k157, ADR 0019)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Context;

sub project { path(tempdir(CLEANUP => 1))->realpath }
sub put { my ( $base, $rel, $text ) = @_; $base->child($rel)->touchpath->spew_utf8($text) }
sub skill { my ( $d, %fm ) = @_; "---\n".join('', map { "$_: $fm{$_}\n" } 'description', grep { $_ ne 'description' } sort keys %fm)."---\nbody of $d\n" }
sub ctx { Langertha::Raider::Context->new(@_) }
sub listed { [ sort map { $_->{name} } $_[0]->skill_catalog->listed ] }

subtest 'paths: globs' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "x\n");
  put($p, '.claude/skills/ts/SKILL.md', skill('ts', description => 'ts', paths => '"src/**/*.{ts,tsx}, test/*.t"'));
  put($p, '.claude/skills/anyname/SKILL.md', skill('anyname', description => 'any', paths => 'Makefile'));
  put($p, '.claude/skills/listy/SKILL.md', "---\ndescription: listy\npaths:\n  - docs/*.md\n  - \"?.txt\"\n---\nbody\n");
  put($p, '.claude/skills/plain/SKILL.md', skill('plain', description => 'plain'));
  my $c = ctx(root => "$p");
  my $cat = $c->skill_catalog;
  is([ $cat->paths_of($cat->find('ts')) ], [ 'src/**/*.{ts,tsx}', 'test/*.t' ], 'comma list, not inside braces, quotes stripped');
  is([ $cat->paths_of($cat->find('listy')) ], [ 'docs/*.md', '?.txt' ], 'yaml list');
  is([ $cat->paths_of($cat->find('plain')) ], [], 'none');
  is(listed($c), ['plain'], 'conditional skills are not listed at the start');
  like($cat->prompt_text, qr/- plain: plain/, 'prompt lists the plain skill');
  unlike($cat->prompt_text, qr/ts:|listy|anyname/, 'and no conditional one');
  ok($c->has_listed_skills, 'has_listed_skills');

  my $hits = sub { [ map { $_->{name} } $cat->activate_for($p->child(@_)->stringify) ] };
  is($hits->('src/a.js'), [], 'no match');
  is($hits->('src/deep/er/a.tsx'), ['ts'], '** and {ts,tsx}');
  is($hits->('src/deep/b.ts'), [], 'not again');
  is($hits->('test/x.t'), [], 'already active (one glob of the same skill)');
  is($hits->('sub/dir/Makefile'), ['anyname'], 'a glob without / matches in any directory');
  is($hits->('docs/guide.md'), ['listy'], 'list glob');
  is($hits->('docs/sub/guide.md'), [], '* stays in one segment');
  is(listed($c), [qw( anyname listy plain ts )], 'activated skills are listed');
  like($cat->prompt_text, qr/- ts: ts/, 'now in the listing');

  my $fresh = ctx(root => "$p");
  is($fresh->skill_catalog->activate_for("$p/test/x.t") ? 'yes' : 'no', 'yes', 'test/*.t');
  is($fresh->skill_catalog->activate_for("$p/test/deep/x.t") ? 'yes' : 'no', 'no', 'test/*.t is one segment');
  is($fresh->skill_catalog->activate_for('/elsewhere/src/a.ts') ? 'yes' : 'no', 'no', 'outside the base never matches');
};

subtest 'paths: the report shows them, the tool refuses until active' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "x\n");
  put($p, '.claude/skills/ts/SKILL.md', skill('ts', description => 'ts', paths => '**/*.ts'));
  put($p, '.claude/skills/plain/SKILL.md', skill('plain', description => 'plain'));
  my $c = ctx(root => "$p");
  my %by = map { $_->{name} => $_ } @{ $c->report->{skills} };
  is($by{ts}, { name => 'ts', source => '.claude/skills', listed => 0, paths => ['**/*.ts'] }, 'conditional, not listed');
  is($by{plain}, { name => 'plain', source => '.claude/skills', listed => 1 }, 'plain');
  $c->nested_skills_for('a/b.ts');
  is({ map { $_->{name} => $_->{listed} } @{ $c->report->{skills} } }, { ts => 1, plain => 1 }, 'listed after the match');
  ok($c->skill_catalog->find('ts'), 'find sees it all along');
};

subtest 'nested .claude/skills: found on the way down, once, after the others' => sub {
  my $p = project();
  put($p, 'CLAUDE.md', "x\n");
  put($p, '.claude/skills/shared/SKILL.md', skill('shared', description => 'root shared'));
  put($p, 'pkg/.claude/skills/shared/SKILL.md', skill('shared', description => 'pkg shared'));
  put($p, 'pkg/.claude/skills/pkgonly/SKILL.md', skill('pkgonly', description => 'pkg only', paths => 'lib/**/*.pm'));
  put($p, 'pkg/inner/.claude/skills/deep/SKILL.md', skill('deep', description => 'deep one'));
  put($p, 'pkg/inner/f.txt', "f\n");
  put($p, 'other/f.txt', "f\n");
  my $c = ctx(root => "$p");
  is($c->nested_skills_for('other/f.txt'), undef, 'nothing in a subtree without skills');
  is($c->nested_skills_for('pkg/inner/f.txt'),
    "The following skills are available for use with the Skill tool:\n\n- deep: deep one",
    'the skills of the way, only the listed ones (pkgonly waits for its paths)');
  is($c->nested_skills_for('pkg/inner/f.txt'), undef, 'once');
  is($c->skill_catalog->find('shared')->{source}, '.claude/skills', 'a taken name keeps the first skill');
  is([ map { "$_->{name} <- $_->{source}" } $c->skill_catalog->shadowed ], ['shared <- pkg/.claude/skills'], 'shadowing is reported');
  is($c->skill_catalog->find('deep')->{source}, 'pkg/inner/.claude/skills', 'source label');
  is($c->nested_skills_for('pkg/lib/A/B.pm'), "The following skills are available for use with the Skill tool:\n\n- pkgonly: pkg only",
    'a paths: glob of a nested skill is relative to the directory of its .claude');
  is($c->nested_skills_for('pkg/x.pm'), undef, 'outside lib/ it does not match again');

  $c->reload;
  is(listed($c), [qw( deep pkgonly shared )], 'after a reload the nested roots and the activations are kept');
  is($c->nested_skills_for('pkg/inner/f.txt'), undef, 'and nothing is announced again');
  is([ $c->nested_reminders_for('pkg/inner/f.txt') ], [], 'no reminders either');
};

subtest 'nested skills: Claude layout only; paths: also elsewhere; bare reads nothing' => sub {
  my $p = project();
  put($p, '.raider/config.yml', "engine: openai\n");
  put($p, 'pkg/.claude/skills/nested/SKILL.md', skill('nested', description => 'nested'));
  put($p, '.raider/skills/cond/SKILL.md', skill('cond', description => 'cond', paths => '*.pm'));
  my $c = ctx(root => "$p");
  is($c->mode, 'raider', 'raider project');
  is($c->nested_skills_for('pkg/a.txt'), undef, 'no nested skills outside the Claude layout');
  ok($c->skill_tool_wanted, 'but a conditional skill wants the tool');
  is($c->nested_skills_for('lib/A.pm'), "The following skills are available for use with the Skill tool:\n\n- cond: cond",
    '.raider/skills with paths: fires');

  my $bare = ctx(root => "$p", bare => 1);
  is($bare->nested_skills_for('lib/A.pm'), undef, 'bare');
  ok(!$bare->skill_tool_wanted, 'bare: no tool');

  my $claude = project();
  put($claude, 'CLAUDE.md', "x\n");
  ok(ctx(root => "$claude")->skill_tool_wanted, 'Claude layout: tool always');
  ok(!ctx(root => '' . project())->skill_tool_wanted, 'native without skills: no tool');
};

done_testing;
