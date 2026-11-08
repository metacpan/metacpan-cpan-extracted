use strict;
use warnings;

use Test::More;
use File::Temp ();
use Dist::Zilla::Tester;
use IPC::Open3;
use Path::Tiny;

# Pins how the [@DBIO] bundle wires Dist::Zilla::Plugin::DBIO::CoverageTest:
# - the plugin is present in both driver and core configurations
# - coverage_threshold defaults to 80
# - a custom coverage_threshold is forwarded to the plugin
# - coverage_threshold = 0 collapses the generated test to a no-op skip
#
# Generated file content is checked by running gather_files on the
# CoverageTest plugin instance and inspecting the file it added to the
# in-memory dist. from_config is enough -- no real build is needed.

sub tzil_for {
  my ($bundle_args) = @_;
  Dist::Zilla::Tester->from_config(
    { dist_root => '/tmp/dbio-dzil-corpus-does-not-exist' },
    { tempdir_root => File::Temp::tempdir(CLEANUP => 1), add_files => {
        'source/dist.ini' => join("\n",
          'name = DBIO-Test',
          'author = Test <test@example.com>',
          'license = Perl_5',
          'copyright_holder = DBIO Contributors',
          '',
          "[\@DBIO]",
          $bundle_args,
          '',
        ),
        'source/lib/DBIO/Test.pm' =>
          "package DBIO::Test;\n# ABSTRACT: test\nour \$VERSION = '0.001';\n1;\n",
        'source/cpanfile' => "requires 'perl', '5.020';\n",
      } },
  );
}

sub by_class {
  my $tzil = shift;
  my %c;
  $c{ ref $_ } = $_ for @{ $tzil->plugins };
  return \%c;
}

# --- CoverageTest plugin is wired in both driver and core configurations ---
{
  my $driver = by_class( tzil_for('') );
  my $core   = by_class( tzil_for("core = 1") );

  ok $driver->{'Dist::Zilla::Plugin::DBIO::CoverageTest'},
    'driver: CoverageTest present';
  ok $core->{'Dist::Zilla::Plugin::DBIO::CoverageTest'},
    'core:   CoverageTest present';
}

# --- default coverage_threshold = 80 ---
{
  my $tzil = by_class( tzil_for('') );
  my $ct = $tzil->{'Dist::Zilla::Plugin::DBIO::CoverageTest'};
  is $ct->coverage_threshold, 80,
    'default coverage_threshold = 80';
}

# --- custom coverage_threshold is forwarded ---
{
  my $tzil = by_class( tzil_for("coverage_threshold = 95") );
  my $ct = $tzil->{'Dist::Zilla::Plugin::DBIO::CoverageTest'};
  is $ct->coverage_threshold, 95,
    'coverage_threshold = 95 -> CoverageTest threshold = 95';
}

# Helper: run gather_files on the CoverageTest plugin in $tzil and
# return the generated xt/release/coverage.t body.
sub coverage_body {
  my $tzil = shift;
  my $ct = by_class($tzil)->{'Dist::Zilla::Plugin::DBIO::CoverageTest'}
    or die "no CoverageTest plugin in dist";

  # gather_files pushes onto $zilla->files via FileInjector::add_file
  $ct->gather_files;
  my @cov = grep { $_->name eq 'xt/release/coverage.t' } @{ $tzil->files };
  return @cov ? $cov[0]->content : undef;
}

# --- coverage_threshold = 0 disables enforcement: generated file is skip-only ---
{
  my $tzil = tzil_for("coverage_threshold = 0");
  my $body = coverage_body($tzil);
  ok defined $body, 'xt/release/coverage.t gathered when threshold = 0';
  like $body, qr/coverage enforcement disabled/,
    'off-body says coverage enforcement disabled';
  like $body, qr/plan skip_all/,
    'off-body emits plan skip_all';
  unlike $body, qr/COVERAGE_STRICT/,
    'off-body omits the COVERAGE_STRICT strict branch';
}

# --- strict (default) body contains the gating logic and env var references ---
{
  my $tzil = tzil_for('');
  my $body = coverage_body($tzil);
  ok defined $body, 'xt/release/coverage.t gathered (default threshold)';

  like $body, qr/cover_db/,        'body references cover_db';
  like $body, qr/Devel::Cover::DB/, 'body uses Devel::Cover::DB';
  like $body, qr/COVERAGE_STRICT/,  'body honours COVERAGE_STRICT';
  like $body, qr/\$ENV\{RELEASE\}/, 'body honours RELEASE';
  like $body, qr/my \$THRESHOLD\s*=\s*80\b/,
    'body has threshold 80 substituted in';
  like $body, qr/^use strict;\s*\nuse warnings;/m,
    'body has the required strict/warnings preamble';
}

# --- the generated script counts a non-object statement entry as uncovered ---
#
# The statement loop guards every entry before it calls ->val on it. The claim
# of that guard: an entry that is not a Devel::Cover::Statement object is
# counted as an uncovered statement -- it never kills the coverage test, and it
# never inflates the number. Before k9 the guard was ref($stmt) && $stmt->can,
# which turned away non-references but died on exactly the other thing it was
# there for: "Can't call method "can" on unblessed reference".
#
# This has to be run, not grepped: only executing the loop shows whether the
# guard holds. And it needs a stand-in Devel::Cover::DB, because the real one
# (1.52, objectify_cover) blesses every entry or dies itself, so no cover_db/
# on disk can produce such an entry. The stand-in serves one lib/ file with
# three entries on one line: a covered statement object, an unblessed arrayref
# in the shape of a raw statement record, and a plain scalar.
{
  my $body = coverage_body( tzil_for('') );

  my $dir = Path::Tiny->tempdir;
  $dir->child('cover_db')->mkpath;
  $dir->child('coverage.t')->spew_utf8($body);

  my $fake = $dir->child('fakelib', 'Devel', 'Cover', 'DB.pm');
  $fake->parent->mkpath;
  $fake->spew_utf8(<<'FAKE');
package Devel::Cover::DB;
use strict;
use warnings;
sub new      { bless {}, shift }
sub is_valid { 1 }
sub merge_runs { $_[0] }
sub cover    { bless {}, 'Fake::Cover' }

package Fake::Cover;
sub items { 'lib/DBIO/Test.pm' }
sub file  { bless {}, 'Fake::File' }

package Fake::File;
sub items     { 'statement' }
sub criterion { bless {}, 'Fake::Criterion' }

package Fake::Criterion;
sub items    { 1 }
sub location { [ bless([1], 'Fake::Statement'), [1], 1 ] }

package Fake::Statement;
sub val { $_[0][0] }

1;
FAKE

  my ($output, $exit);
  {
    # PERL5OPT: a suite run under -MDevel::Cover must not load the real
    # Devel::Cover into the child on top of the stand-in. COVERAGE_STRICT /
    # RELEASE: the fixture sits below the threshold on purpose, and whether
    # that gap fails is not what is under test here.
    delete local @ENV{qw(PERL5OPT COVERAGE_STRICT RELEASE)};

    my $pid = open3(
      my $in, my $out, undef,   # no separate stderr handle: merged into $out
      $^X, '-I' . $dir->child('fakelib'), $dir->child('coverage.t')->stringify,
    );
    close $in;
    $output = do { local $/; <$out> };
    waitpid $pid, 0;
    $exit = $? >> 8;
  }

  is $exit, 0, 'generated coverage.t survives non-object statement entries'
    or diag $output;
  like $output, qr/statement coverage 33\.3%/,
    'non-object entries count as uncovered statements (1 of 3 covered)';
}

# --- the generated script gates on a fresh cover_db and a missing run ---
#
# The claim (karr k12): under RELEASE=1 a coverage run that did not happen is a
# failure, not a skip. A fresh cover_db -- what a plain run under
# -MDevel::Cover leaves, runs/ and structure/ but no merged database -- must be
# merged by the test itself and scored; before k12 it ended in skip_all even
# under RELEASE=1, so the release gate only bit after a manual `cover`. And the
# per-module diag line must not warn. Real Devel::Cover, nothing stubbed.
SKIP: {
  eval { require Devel::Cover::DB; 1 }
    or skip 'Devel::Cover not installed', 7;

  my $body = coverage_body( tzil_for('') );

  my $dir = Path::Tiny->tempdir;
  $dir->child('lib')->mkpath;
  $dir->child('t')->mkpath;
  $dir->child('lib', 'Cov.pm')->spew_utf8(
    "package Cov;\nuse strict;\nuse warnings;\nsub a { 1 }\nsub b { 2 }\n1;\n");
  $dir->child('t', 'coverage.t')->spew_utf8($body);
  $dir->child('prog.pl')->spew_utf8("use lib 'lib'; use Cov; Cov::a(); Cov::b();\n");

  my $cwd = Path::Tiny->cwd;
  chdir $dir or die $!;

  my $run = sub {
    my (@cmd) = @_;
    my $out;
    my $pid = open3(my $in, my $o, undef, @cmd);
    close $in;
    $out = do { local $/; <$o> };
    waitpid $pid, 0;
    return ($? >> 8, $out);
  };

  # fresh cover_db made by a real Devel::Cover run, never merged
  {
    delete local @ENV{qw(PERL5OPT COVERAGE_STRICT RELEASE)};
    $run->($^X, '-MDevel::Cover=-silent,1,-db,cover_db', 'prog.pl');

    ok -d 'cover_db/runs', 'fixture: fresh cover_db with runs/';
    ok !glob('cover_db/cover.*'), 'fixture: no merged database yet';

    local $ENV{RELEASE} = 1;
    my ($exit, $out) = $run->($^X, 't/coverage.t');
    is $exit, 0, 'RELEASE=1 on a fresh cover_db: script exits 0'
      or diag $out;
    like $out, qr/^(?:not )?ok 1 - statement coverage [\d.]+%/m,
      'fresh cover_db is merged and scored, not skipped'
      or diag $out;
    unlike $out, qr/uninitialized/, 'no uninitialized warning in the diag line';

    # no cover_db at all
    $dir->child('cover_db')->remove_tree;
    ($exit, $out) = $run->($^X, 't/coverage.t');
    isnt $exit, 0, 'RELEASE=1 without any cover_db fails';

    delete local $ENV{RELEASE};
    ($exit, $out) = $run->($^X, 't/coverage.t');
    is $exit, 0, 'without RELEASE a missing cover_db still skips';
  }
  chdir $cwd or die $!;
}

done_testing;