use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Dist::Zilla::Tester;

sub build_tzil {
  my (%opt) = @_;
  my @ini   = @{ $opt{ini}   || [] };
  my $files = $opt{files} || {};
  Dist::Zilla::Tester->from_config(
    { dist_root => 't/does-not-exist' },
    { add_files => {
        'source/dist.ini' => join("\n",
          'name = AC-Test', 'author = Test <test@example.com>',
          'license = Perl_5', 'copyright_holder = Test', 'version = 0.001',
          '', '[GatherAgentContext]', @ini, '',
        ),
        'source/lib/AC/Test.pm' =>
          "package AC::Test;\n# ABSTRACT: t\nour \$VERSION='0.001';\n1;\n",
        %$files,
      } },
  );
}
sub plugin { my $t = shift; (grep { $_->isa('Dist::Zilla::Plugin::GatherAgentContext') } @{ $t->plugins })[0] }
sub gathered { my $t = shift; sort map { $_->name } grep { index($_->name,'misc/agent-context/')==0 } @{ $t->files } }

{
  my $tzil = build_tzil( files => {
    'source/.claude/skills/foo/SKILL.md'                 => "body\n",
    'source/.claude/skills/foo/.gitignore'               => "*\n",
    'source/.claude/settings.json'                       => "{}\n",
    'source/.claude/settings.local.json'                 => "{}\n",
    'source/.claude/skilletor.local.json'                => "{}\n",
    'source/.claude/skilletor.json'                      => "{}\n",
    'source/.claude/skilletor.lock.json'                 => "{}\n",
    'source/.claude/agents/.local.karr-coordinator.md'   => "agent\n",
    'source/.claude/rules/.local.house.md'               => "rule\n",
    'source/.claude/worktrees/wt/f'                       => "wt\n",
  });
  plugin($tzil)->gather_files;
  my @got = gathered($tzil);
  my %have = map { $_ => 1 } @got;

  # KEPT
  ok $have{'misc/agent-context/.claude/skills/foo/SKILL.md'}, 'SKILL.md kept';
  ok $have{'misc/agent-context/.claude/skilletor.json'},      'skilletor.json kept';
  ok $have{'misc/agent-context/.claude/skilletor.lock.json'}, 'skilletor.lock.json kept (provenance index)';
  ok $have{'misc/agent-context/.claude/agents/.local.karr-coordinator.md'},
     '.local.<name>.md agent kept (consumed content)';
  ok $have{'misc/agent-context/.claude/rules/.local.house.md'},
     '.local.<name>.md rule kept (consumed content)';

  # DROPPED
  ok !( grep { m{/\.gitignore$} } @got ),      'skilletor .gitignore dropped';
  ok !( grep { m{/settings\.json$} } @got ),   'settings.json dropped';
  ok !( grep { m{\.local\.json$} } @got ),     '*.local.json config dropped';
  ok !( grep { m{/worktrees/} } @got ),        'worktrees/ dropped';
}

# --- Local state and secrets below a harness directory never reach the build.
# The harness and the user park session logs, todos, caches and login tokens in
# .claude/ and .codex/. Nothing of that may be gathered -- including names no
# list anticipated (history.jsonl, a stray backup, a new cache dir): below a
# harness directory only known agent content is taken.
{
  my %state = (
    # what the fleet .gitignore calls "never track"
    'source/.claude/.credentials.json'          => "{\"token\":\"s3cret\"}\n",
    'source/.claude/projects/-home-x/abc.jsonl' => "session log\n",
    'source/.claude/todos/a.json'               => "[]\n",
    'source/.claude/statsig/cache.json'         => "{}\n",
    'source/.claude/local/notes.md'             => "private\n",
    'source/.claude/settings.local.json'        => "{}\n",
    'source/.claude/settings.local.json.bak'    => "{}\n",
    'source/.claude/CLAUDE.local.md'            => "private memory\n",
    'source/.codex/auth.json'                   => "{\"token\":\"s3cret\"}\n",
    # names nobody put on a list
    'source/.claude/history.jsonl'              => "prompt history\n",
    'source/.claude/shell-snapshots/s.sh'       => "export TOKEN=s3cret\n",
    'source/.claude/notes.txt'                  => "scratch\n",
    'source/.codex/config.toml'                 => "[mcp_servers.x]\n",
    'source/.codex/sessions/2026/s.jsonl'       => "session log\n",
    # a content name of the wrong kind is not content
    'source/.codex/rules'                       => "a file, not the rules dir\n",
    # tokens and local overrides tucked into otherwise gathered directories
    'source/.claude/skills/foo/auth.json'         => "{}\n",
    'source/.claude/skills/foo/.credentials.json' => "{}\n",
    'source/.claude/agents/reviewer.local.md'     => "local override\n",
    'source/.agents/skills/bar/auth.json'         => "{}\n",
  );
  my %content = (
    'source/CLAUDE.md'                                 => "c\n",
    'source/AGENTS.md'                                 => "a\n",
    'source/.claude/CLAUDE.md'                         => "c\n",
    'source/.claude/agents/worker.md'                  => "agent\n",
    'source/.claude/agents/.local.karr-coordinator.md' => "agent\n",
    'source/.claude/skills/foo/SKILL.md'               => "body\n",
    'source/.claude/skills/foo/references/projects/p.md' => "ref\n",
    'source/.claude/rules/house.md'                    => "rule\n",
    'source/.claude/hooks/pre.sh'                      => "#!/bin/sh\n",
    'source/.claude/commands/ship.md'                  => "cmd\n",
    'source/.claude/skilletor.json'                    => "{}\n",
    'source/.claude/skilletor.lock.json'               => "{}\n",
    'source/.codex/agents/.local.x.toml'               => "x\n",
    'source/.codex/skills/baz/SKILL.md'                => "s\n",
    'source/.codex/skilletor-rules.md'                 => "rules\n",
    'source/.agents/skills/bar/SKILL.md'               => "b\n",
  );
  my $tzil = build_tzil( files => { %state, %content } );
  plugin($tzil)->gather_files;
  my @got  = gathered($tzil);
  my %have = map { $_ => 1 } @got;

  for my $src (sort keys %state) {
    (my $rel = $src) =~ s{^source/}{};
    ok !$have{"misc/agent-context/$rel"}, "$rel stays out of the build";
  }
  is_deeply \@got,
    [ sort map { (my $rel = $_) =~ s{^source/}{misc/agent-context/}; $rel } keys %content ],
    'exactly the agent content is gathered, nothing else';
}

# --- An explicitly configured harness directory is filtered the same way:
# `dir = .claude` means "the agent content of .claude", not "all of .claude".
{
  my $tzil = build_tzil(
    ini   => [ 'dir = .claude' ],
    files => {
      'source/.claude/skills/foo/SKILL.md'  => "body\n",
      'source/.claude/.credentials.json'    => "{}\n",
      'source/.claude/projects/p/abc.jsonl' => "session log\n",
    },
  );
  plugin($tzil)->gather_files;
  is_deeply [ gathered($tzil) ],
    [ 'misc/agent-context/.claude/skills/foo/SKILL.md' ],
    'explicit dir = .claude still takes agent content only';
}

# --- A harness directory met deeper in a configured tree is filtered too.
{
  my $tzil = build_tzil(
    ini   => [ 'dir = sub' ],
    files => {
      'source/sub/notes.md'                     => "n\n",
      'source/sub/.claude/skills/foo/SKILL.md'  => "body\n",
      'source/sub/.claude/todos/a.json'         => "[]\n",
      'source/sub/.codex/auth.json'             => "{}\n",
    },
  );
  plugin($tzil)->gather_files;
  is_deeply [ gathered($tzil) ],
    [ 'misc/agent-context/sub/.claude/skills/foo/SKILL.md',
      'misc/agent-context/sub/notes.md' ],
    'nested harness directories take agent content only';
}

# --- The way to take more: name the subdirectory itself. It is then walked in
# full (built-in excludes still apply).
{
  my $tzil = build_tzil(
    ini   => [ 'dir = .claude', 'dir = .claude/output-styles' ],
    files => {
      'source/.claude/skills/foo/SKILL.md'        => "body\n",
      'source/.claude/output-styles/terse.md'     => "style\n",
      'source/.claude/output-styles/x.local.json' => "{}\n",
      'source/.claude/todos/a.json'               => "[]\n",
    },
  );
  plugin($tzil)->gather_files;
  is_deeply [ gathered($tzil) ],
    [ 'misc/agent-context/.claude/output-styles/terse.md',
      'misc/agent-context/.claude/skills/foo/SKILL.md' ],
    'a subdirectory outside the content set is gathered when configured by name';
}

# --- Binär-/Nicht-UTF-8-Datei -> fataler Abbruch, der die Datei benennt ---
{
  my $tzil = build_tzil( files => {
    'source/.claude/skills/bin/SKILL.md' => "ok\n",
  });
  # add_files kodiert Perl-Strings zu UTF-8; fuer echte INVALIDE Bytes hier
  # direkt roh unter den zilla-root schreiben.
  path($tzil->root)->child('.claude/skills/bin/image.bin')
    ->spew_raw("\xff\xfe\x00\x80\xc0\xc1");
  ok !eval { plugin($tzil)->gather_files; 1 },
     'a non-UTF-8 context file makes the build die (fail loud)';
  like $@, qr/image\.bin/, 'the fatal message names the offending file';
}

done_testing;
