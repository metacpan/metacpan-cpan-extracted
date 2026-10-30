#!/usr/bin/env perl
# ABSTRACT: Skill catalogue: discovery, precedence, frontmatter, tool text (ADR 0019 §4, k151)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Context::Skills;

# Roots in precedence order, plugins last as plugin:skill; the first name
# wins and the rest is reported as shadowed. Frontmatter is parsed and kept,
# descriptions fall back to the body, disable-model-invocation hides a skill
# from the model, $ARGUMENTS is substituted or appended.

local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{CLAUDE_CONFIG_DIR} = tempdir(CLEANUP => 1);

my $w = path(tempdir(CLEANUP => 1));
sub put { my ( $rel, $text ) = @_; my $f = $w->child($rel); $f->parent->mkpath; $f->spew_utf8($text); return $f }

# root 1: explicit, skills layout
put('explicit/pdf/SKILL.md', "---\nname: pdf\ndescription: Work with PDF files.\nlicense: MIT\n---\n\n\n# PDF\n\nUse pdftotext on \$ARGUMENTS now. Again: \$ARGUMENTS\n");
put('explicit/renamed/SKILL.md', "---\nname: other-name\ndescription: >\n  Folded\n  description\n---\nBody of renamed.\n");
put('explicit/no-skill-md/README.md', "not a skill\n");
put('explicit/stray.md', "a file in a skills-layout root is not a skill\n");
# root 2: flat layout
put('flat/notes.md', "# Notes\n\n   First real line of notes.   \nsecond line\n");
put('flat/pdf.md', "flat pdf, shadowed by explicit\n");
put('flat/ignored.txt', "not markdown\n");
put('flat/sub/inner.md', "nested files are not flat skills\n");
# root 3: skills layout, shadowing + hidden + broken frontmatter
put('native/pdf/SKILL.md', "---\ndescription: native pdf\n---\nnative\n");
put('native/hidden/SKILL.md', "---\ndescription: Only for humans\ndisable-model-invocation: true\n---\nhidden body\n");
put('native/notyaml/SKILL.md', "---\n[unclosed\n---\nBroken frontmatter body line.\n");   # neither YAML nor key: value lines
put('native/scalar/SKILL.md', "---\njust a string\n---\nScalar frontmatter.\n");
put('native/long/SKILL.md', "# Long\n\n".( 'x' x 400 )."\n");
put('native/empty/SKILL.md', "---\n---\n");
put('native/noargs/SKILL.md', "---\ndescription: no placeholder\n---\nDo the thing.\n\n");
put('native/off/SKILL.md', "---\ndescription: falsy flag\ndisable-model-invocation: false\n---\noff\n");
# plugins
put('plug/a/skills/brainstorm/SKILL.md', "---\nname: brainstorm\ndescription: Think first.\n---\nPlugin body.\n");
put('plug/b/skills/brainstorm/SKILL.md', "---\ndescription: second install\n---\nsecond\n");
put('plug/a/skills/pdf/SKILL.md', "---\ndescription: plugin pdf\n---\nplugin pdf\n");

my @roots = (
  { dir => "$w/explicit", source => '--skills explicit', layout => 'skills' },
  { dir => "$w/missing",  source => 'missing',           layout => 'skills' },
  { dir => "$w/flat",     source => '--skills flat',     layout => 'flat' },
  { dir => "$w/native",   source => '.raider/skills',    layout => 'skills' },
);
my @plugins = (
  { name => 'sp',  dirs => [ "$w/plug/a/skills/brainstorm", "$w/plug/a/skills/pdf", "$w/plug/a/skills/gone" ] },
  { name => 'sp',  dirs => [ "$w/plug/b/skills/brainstorm" ] },
);

my $cat = Langertha::Raider::Context::Skills->new(roots => \@roots, plugins => \@plugins);

subtest 'discovery and precedence order' => sub {
  is([ map { $_->{name} } $cat->skills ], [qw(
    pdf renamed
    notes
    empty hidden long noargs notyaml off scalar
    sp:brainstorm sp:pdf
  )], 'roots in order, sorted inside a root, plugins last');
  is([ map { $_->{source} } $cat->skills ], [
    ('--skills explicit') x 2, '--skills flat', ('.raider/skills') x 7, ('plugin sp') x 2,
  ], 'sources');
};

subtest 'a skill' => sub {
  my $s = $cat->find('pdf');
  is($s, {
    name            => 'pdf',
    kind            => 'skill',
    description     => 'Work with PDF files.',
    dir             => "$w/explicit/pdf",
    file            => "$w/explicit/pdf/SKILL.md",
    source          => '--skills explicit',
    frontmatter     => { name => 'pdf', description => 'Work with PDF files.', license => 'MIT' },
    model_invocable => 1,
    user_invocable  => 1,
  }, 'all fields');
  my $r = $cat->find('renamed');
  is($r->{frontmatter}{name}, 'other-name', 'frontmatter name kept ...');
  is($cat->find('other-name'), undef, '... but the directory name is the identifier');
  is($r->{description}, 'Folded description', 'description whitespace collapsed');
  my $f = $cat->find('notes');
  is($f->{dir}, "$w/flat", 'flat skill: the containing dir');
  is($f->{file}, "$w/flat/notes.md", 'flat skill file');
  is($f->{description}, 'First real line of notes.', 'fallback: first non-heading line, trimmed');
  is($f->{frontmatter}, {}, 'no frontmatter');
  is(length $cat->find('long')->{description}, 250, 'fallback cut to 250');
  like($cat->find('long')->{description}, qr/\.\.\.\z/, 'with an ellipsis');
  is($cat->find('empty')->{description}, '', 'nothing to describe');
};

subtest 'shadowed' => sub {
  is([ $cat->shadowed ], [
    { name => 'pdf', source => '--skills flat',  file => "$w/flat/pdf.md",            by => '--skills explicit' },
    { name => 'pdf', source => '.raider/skills', file => "$w/native/pdf/SKILL.md",    by => '--skills explicit' },
    { name => 'sp:brainstorm', source => 'plugin sp', file => "$w/plug/b/skills/brainstorm/SKILL.md", by => 'plugin sp' },
  ], 'later names lose; plugin pdf is sp:pdf and shadows nothing');
};

subtest 'problems: broken frontmatter loads with {}' => sub {
  my @p = $cat->problems;
  is([ map { $_->{file} } @p ], [ "$w/native/notyaml/SKILL.md", "$w/native/scalar/SKILL.md" ], 'two files');
  like($p[0]{reason}, qr/\Ainvalid frontmatter: /, 'invalid YAML');
  unlike($p[0]{reason}, qr/ line \d+\.?\z/, 'without Perl source location');
  is($p[1]{reason}, 'frontmatter is not a mapping', 'scalar frontmatter');
  is($cat->find('notyaml')->{frontmatter}, {}, 'empty frontmatter');
  is($cat->find('notyaml')->{description}, 'Broken frontmatter body line.', 'body still used');
};

subtest 'disable-model-invocation' => sub {
  is($cat->find('hidden')->{model_invocable}, 0, 'true: not invocable');
  is($cat->find('off')->{model_invocable}, 1, 'false: invocable');
  ok(!(grep { $_->{name} eq 'hidden' } $cat->listed), 'not listed');
  is(scalar($cat->listed), scalar($cat->skills) - 1, 'everything else listed');
};

subtest 'find' => sub {
  is($cat->find('/pdf')->{name}, 'pdf', 'leading slash accepted');
  is($cat->find('sp:pdf')->{source}, 'plugin sp', 'plugin skill');
  is($cat->find('PDF'), undef, 'exact name only');
  is($cat->find('stray'), undef, 'a .md in a skills root is no skill');
  is($cat->find('inner'), undef, 'flat is not recursive');
  is($cat->find('ignored'), undef, 'flat takes .md only');
  is($cat->find(undef), undef, 'undef');
};

subtest 'body and tool_text' => sub {
  is($cat->body('pdf'), "# PDF\n\nUse pdftotext on \$ARGUMENTS now. Again: \$ARGUMENTS\n", 'no frontmatter, no leading blank lines');
  is($cat->body('nope'), undef, 'unknown');
  is($cat->tool_text('pdf', 'a.pdf'),
    "Base directory for this skill: $w/explicit/pdf\n\n# PDF\n\nUse pdftotext on a.pdf now. Again: a.pdf\n",
    'every $ARGUMENTS replaced');
  is($cat->tool_text('/pdf'),
    "Base directory for this skill: $w/explicit/pdf\n\n# PDF\n\nUse pdftotext on  now. Again: \n",
    'no args: placeholder emptied');
  is($cat->tool_text('noargs', 'x y'),
    "Base directory for this skill: $w/native/noargs\n\nDo the thing.\n\nARGUMENTS: x y",
    'no placeholder: appended');
  is($cat->tool_text('noargs', ''),
    "Base directory for this skill: $w/native/noargs\n\nDo the thing.\n\n", 'empty args: nothing appended');
  is($cat->tool_text('notes'), "Base directory for this skill: $w/flat\n\n# Notes\n\n   First real line of notes.   \nsecond line\n",
    'flat skill: whole file');
  is($cat->tool_text('nope', 'x'), undef, 'unknown');
};

subtest 'prompt_text' => sub {
  my $text = $cat->prompt_text;
  like($text, qr/\ASkills: specialised instructions loaded on demand\. When a task matches a skill's description, call the `skill` tool with its name BEFORE acting, then follow what it returns\. Available skills:\n/,
    'header');
  my @lines = grep { /^- / } split /\n/, $text;
  is($lines[0], '- pdf: Work with PDF files.', 'name: description');
  ok((grep { $_ eq '- empty' } @lines), 'no description: name alone');
  ok((grep { $_ eq '- sp:brainstorm: Think first.' } @lines), 'plugin skill listed');
  ok(!(grep { /hidden/ } @lines), 'hidden not listed');
  is(scalar(@lines), scalar($cat->listed), 'one line per listed skill');

  my $none = Langertha::Raider::Context::Skills->new(roots => [ { dir => "$w/missing", source => 'x', layout => 'flat' } ]);
  is([ $none->skills ], [], 'missing root: no skills');
  is($none->prompt_text, undef, 'nothing listed: undef');
  put('hidden-only/h/SKILL.md', "---\ndescription: h\ndisable-model-invocation: true\n---\nh\n");
  my $only_hidden = Langertha::Raider::Context::Skills->new(roots => [ { dir => "$w/hidden-only", source => 'n', layout => 'skills' } ]);
  is(scalar($only_hidden->skills), 1, 'one skill found');
  is($only_hidden->prompt_text, undef, 'but none listed: undef');
};

subtest 'lenient frontmatter: what YAML rejects but Claude Code reads' => sub {
  # The shapes of two real SKILL.md files: an unquoted ': ' inside a plain
  # description (karr coordination), and '# ...: ' plus quotes in it (briefing).
  put('lenient/karr/SKILL.md', "---\nname: kanban-issues-karr-coordination\n"
    ."description: Use when reading a karr board, or syncing karr. For working one card you were handed: kanban-issues-karr-ticket.\n"
    ."---\nbody\n");
  put('lenient/brief/SKILL.md', "---\nname: briefing\n"
    ."description: Author agents that use the `briefing` plugin \x{2014} when adding a `# briefing: skills = [...]` comment to an agent's TOML, or \"MANDATORY: load skill X first\" prose.\n"
    ."---\nbody\n");
  put('lenient/more/SKILL.md', "---\n# a comment\nname: \"more\"\ndescription: First part: with a colon,\n  continued here\n"
    ."disable-model-invocation: true\nuser-invocable: false\nallowed-tools:\n  - Read\n  - 'Bash(ls)'\nnotes: |\n  line one\n  line two\n---\nbody\n");
  my $c = Langertha::Raider::Context::Skills->new(roots => [ { dir => "$w/lenient", source => 'l', layout => 'skills' } ]);
  is([ $c->problems ], [], 'no problems');
  is($c->find('karr')->{description},
    'Use when reading a karr board, or syncing karr. For working one card you were handed: kanban-issues-karr-ticket.',
    'description after the first ": " kept whole');
  like($c->find('brief')->{description}, qr/\AAuthor agents .* `# briefing: skills = \[\.\.\.\]` comment .* "MANDATORY: load skill X first" prose\.\z/,
    'comment-like and quoted parts kept');
  is($c->find('brief')->{frontmatter}{name}, 'briefing', 'name');
  my $more = $c->find('more');
  is($more->{frontmatter}, {
    name                       => 'more',
    description                => 'First part: with a colon, continued here',
    'disable-model-invocation' => T(),
    'user-invocable'           => F(),
    'allowed-tools'            => [ 'Read', 'Bash(ls)' ],
    notes                      => 'line one line two',
  }, 'quotes stripped, continuation joined, booleans, list, block');
  is($more->{model_invocable}, 0, 'disable-model-invocation: true honoured');
  is($more->{description}, 'First part: with a colon, continued here', 'description');
};

subtest 'flat root without top-level .md holds nothing' => sub {
  put('flatless/sub/x.md', "x\n");
  put('flatless/y/SKILL.md', "y\n");
  my $c = Langertha::Raider::Context::Skills->new(roots => [ { dir => "$w/flatless", source => 'f', layout => 'flat' } ]);
  is([ $c->skills ], [], 'none');
};

done_testing;
