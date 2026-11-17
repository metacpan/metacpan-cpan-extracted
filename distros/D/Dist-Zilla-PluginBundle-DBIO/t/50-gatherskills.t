use strict;
use warnings;

use Test::More;
use File::Temp ();
use Path::Tiny;
use Dist::Zilla::Tester;

# Pins how Dist::Zilla::Plugin::DBIO::GatherSkills gathers a distribution's own
# skills from .claude/skills/ into share/skills/. Two behaviours the skilletor
# switchover (core ADR 0058) depends on:
#
#   1. skilletor writes a per-skill .gitignore (content "*") into every installed
#      skill dir. It is skilletor's management file, not content, and must never
#      be shipped into the tarball. Everything else (SKILL.md, references/, ...)
#      still ships -- the skill dirs are deliberate build provenance.
#   2. A skill declared explicitly via share_skill=/skill= whose dir is absent is
#      FATAL (a build without a prior skilletor sync must fail loud, not silently
#      ship a dist missing a declared skill). The name-derived fallback (no
#      explicit skill list) stays a silent skip -- there "ship what matches" and
#      "nothing matches" is a valid answer, not an error.
#
# The plugin reads from disk, so each case builds a corpus in a tempdir, points a
# bare [DBIO::GatherSkills] at it via an absolute from=, runs gather_files, and
# inspects the in-memory files it added. No full build is needed.

sub write_corpus {
  my (%files) = @_;                    # rel path => content
  my $dir = Path::Tiny->tempdir;
  for my $rel (sort keys %files) {
    my $f = $dir->child($rel);
    $f->parent->mkpath;
    $f->spew_utf8($files{$rel});
  }
  return $dir;
}

sub build_tzil {
  my ($corpus, @skill_lines) = @_;     # extra dist.ini lines, e.g. 'skill = dbio-test'
  Dist::Zilla::Tester->from_config(
    { dist_root => '/tmp/dbio-dzil-corpus-does-not-exist' },
    { tempdir_root => File::Temp::tempdir(CLEANUP => 1), add_files => {
        'source/dist.ini' => join("\n",
          'name = DBIO-Test',
          'author = Test <test@example.com>',
          'license = Perl_5',
          'copyright_holder = DBIO Contributors',
          'version = 0.001',
          '',
          '[DBIO::GatherSkills]',
          "from = $corpus",
          @skill_lines,
          '',
        ),
        'source/lib/DBIO/Test.pm' =>
          "package DBIO::Test;\n# ABSTRACT: test\nour \$VERSION = '0.001';\n1;\n",
      } },
  );
}

sub plugin {
  my $tzil = shift;
  my ($gs) = grep { $_->isa('Dist::Zilla::Plugin::DBIO::GatherSkills') }
    @{ $tzil->plugins };
  return $gs;
}

sub gathered {
  my $tzil = shift;
  return sort map { $_->name }
    grep { $_->name =~ m{^share/skills/} } @{ $tzil->files };
}

# --- (a) explicit skill: ships content, drops skilletor's .gitignore ---
{
  my $corpus = write_corpus(
    'dbio-test/SKILL.md'        => "skill body\n",
    'dbio-test/references/r.md' => "ref body\n",
    'dbio-test/.gitignore'      => "*\n",
  );
  my $tzil = build_tzil($corpus, 'skill = dbio-test');
  plugin($tzil)->gather_files;

  my @got = gathered($tzil);
  is_deeply \@got,
    [ 'share/skills/dbio-test/SKILL.md',
      'share/skills/dbio-test/references/r.md' ],
    'gathers SKILL.md and references/, drops skilletor .gitignore';
  ok !( grep { m{/\.gitignore$} } @got ),
    'no .gitignore shipped into share/skills/';
}

# --- (b) explicitly declared but missing skill dir is fatal ---
{
  my $corpus = write_corpus('dbio-test/SKILL.md' => "body\n");
  my $tzil = build_tzil($corpus, 'skill = dbio-missing');

  ok !eval { plugin($tzil)->gather_files; 1 },
    'explicitly declared skill with no dir makes the build die (fail loud)';
  like $@, qr/dbio-missing/,
    'the fatal message names the missing declared skill';
}

# --- (c) name-derived fallback tolerates a missing/partial match ---
{
  # Dist DBIO-Test owns dbio-test and dbio-test-*. Only the prefixed
  # dbio-test-extra exists; the exact dbio-test dir is absent. The fallback is
  # "ship what matches" -- a missing member is not an error.
  my $corpus = write_corpus(
    'dbio-test-extra/SKILL.md'   => "body\n",
    'dbio-test-extra/.gitignore' => "*\n",
  );
  my $tzil = build_tzil($corpus);      # no skill = line -> name-derived fallback

  ok eval { plugin($tzil)->gather_files; 1 },
    'name-derived fallback with a missing/partial match does not die';
  is_deeply [ gathered($tzil) ],
    [ 'share/skills/dbio-test-extra/SKILL.md' ],
    'fallback ships the matching dir and still drops .gitignore';
}

# --- (d) files ship as bytes: a binary file arrives unchanged ---
{
  my $binary = join '', map { chr } 0xFF, 0xD8, 0x00, 0x01, 0x80, 0xC3, 0x28, 0x0A, 0xFE;
  my $text   = "caf\xC3\xA9 skill body\n";    # UTF-8 bytes of "caf\x{e9}"
  my $corpus = Path::Tiny->tempdir;
  my $skill  = $corpus->child('dbio-test');
  $skill->child('assets')->mkpath;
  $skill->child('SKILL.md')->spew_raw($text);
  $skill->child('assets', 'logo.bin')->spew_raw($binary);

  my $tzil = build_tzil($corpus, 'skill = dbio-test');
  plugin($tzil)->gather_files;

  my %file = map { $_->name => $_ } grep { $_->name =~ m{^share/skills/} } @{ $tzil->files };
  ok $file{'share/skills/dbio-test/assets/logo.bin'}, 'binary file gathered';
  ok $file{'share/skills/dbio-test/assets/logo.bin'}->encoded_content eq $binary,
    'binary file content is byte-identical';
  ok $file{'share/skills/dbio-test/SKILL.md'}->encoded_content eq $text,
    'text file content is byte-identical (UTF-8 bytes stay as they are)';
}

done_testing;
