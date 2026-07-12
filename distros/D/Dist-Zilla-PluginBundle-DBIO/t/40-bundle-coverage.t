use strict;
use warnings;

use Test::More;
use Dist::Zilla::Tester;

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
    { add_files => {
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

done_testing;