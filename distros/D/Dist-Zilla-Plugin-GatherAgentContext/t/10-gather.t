use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Dist::Zilla::Tester;

# Baut eine Fake-Dist, deren Quellbaum die Kontext-Dateien enthaelt, und ruft
# gather_files direkt auf (kein voller Build). Der Plugin liest relativ zu
# $zilla->root, also muessen die Dateien unter source/ liegen.
sub build_tzil {
  my (%opt) = @_;
  my @ini   = @{ $opt{ini}   || [] };
  my $files = $opt{files} || {};
  Dist::Zilla::Tester->from_config(
    { dist_root => 't/does-not-exist' },
    { add_files => {
        'source/dist.ini' => join("\n",
          'name = AC-Test',
          'author = Test <test@example.com>',
          'license = Perl_5',
          'copyright_holder = Test',
          'version = 0.001',
          '',
          '[GatherAgentContext]',
          @ini,
          '',
        ),
        'source/lib/AC/Test.pm' =>
          "package AC::Test;\n# ABSTRACT: t\nour \$VERSION='0.001';\n1;\n",
        %$files,
      } },
  );
}

sub plugin {
  my $tzil = shift;
  my ($p) = grep { $_->isa('Dist::Zilla::Plugin::GatherAgentContext') }
    @{ $tzil->plugins };
  return $p;
}

sub gathered {
  my ($tzil, $prefix) = @_;
  $prefix ||= 'misc/agent-context/';
  return sort map { $_->name }
    grep { index($_->name, $prefix) == 0 } @{ $tzil->files };
}

# --- Default (all harness): .claude-Baum wird rekursiv gesammelt ---
{
  my $tzil = build_tzil( files => {
    'source/.claude/skills/foo/SKILL.md'        => "body\n",
    'source/.claude/skills/foo/references/r.md' => "ref\n",
  });
  plugin($tzil)->gather_files;
  is_deeply [ gathered($tzil) ],
    [ 'misc/agent-context/.claude/skills/foo/SKILL.md',
      'misc/agent-context/.claude/skills/foo/references/r.md' ],
    'default gathers the .claude tree under misc/agent-context/';
}

# --- Symlink-Verzeichnis wird nicht deszendiert (keine Schleife) ---
SKIP: {
  my $tzil = build_tzil( files => {
    'source/.claude/skills/real/SKILL.md' => "x\n",
  });
  my $root = path($tzil->root);
  my $link = $root->child('.claude/skills/loop');
  skip 'symlinks unsupported here', 2
    unless eval { symlink $root->child('.claude/skills/real'), "$link"; 1 };
  plugin($tzil)->gather_files;
  my @got = gathered($tzil);
  ok( ( grep { $_ eq 'misc/agent-context/.claude/skills/real/SKILL.md' } @got ),
    'sanity: the real skill dir was gathered (path anchor correct)' );
  ok( !( grep { m{/skills/loop/} } @got ),
    'symlinked skill dir is not descended' );
}

done_testing;
