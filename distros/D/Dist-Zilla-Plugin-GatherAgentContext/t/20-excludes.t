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
