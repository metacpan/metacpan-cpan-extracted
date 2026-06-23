use strict;
use warnings;

use Test::More;
use Dist::Zilla::Tester;

# Pins the plugin set the [@DBIO] bundle wires up, and how it differs between a
# driver distribution (default) and the core distribution (core = 1). Plugins
# are resolved by from_config without a full build, so no git repo is needed.
#
# This doubles as the reference for what [@DBIO] does -- see
# DBIO::Manual / the dbio-perl-release skill.

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

# class => plugin object, for the plugins this bundle added
sub by_class {
  my $tzil = shift;
  my %c;
  $c{ ref $_ } = $_ for @{ $tzil->plugins };
  \%c;
}

my $driver = by_class( tzil_for('') );
my $core   = by_class( tzil_for("core = 1") );

# --- shared plugins (both driver and core) ---
for my $p (qw(
  Dist::Zilla::Plugin::DBIO::SetMeta
  Dist::Zilla::Plugin::DBIO::CodebergMeta
  Dist::Zilla::Plugin::DBIO::GatherSkills
  Dist::Zilla::Plugin::ShareDir
  Dist::Zilla::Plugin::Git::GatherDir
  Dist::Zilla::Plugin::PruneCruft
  Dist::Zilla::Plugin::PodWeaver
  Dist::Zilla::Plugin::Prereqs::FromCPANfile
  Dist::Zilla::Plugin::Git::Check
)) {
  ok $driver->{$p}, "driver: $p present";
  ok $core->{$p},   "core: $p present";
}

# --- core-only: VersionFromMainModule + MakeMaker::Awesome + ExecDir ---
ok   $core->{'Dist::Zilla::Plugin::VersionFromMainModule'}, 'core: VersionFromMainModule';
ok   $core->{'Dist::Zilla::Plugin::MakeMaker::Awesome'},    'core: MakeMaker::Awesome';
ok   $core->{'Dist::Zilla::Plugin::ExecDir'},               'core: ExecDir (bin/)';
ok ! $driver->{'Dist::Zilla::Plugin::VersionFromMainModule'},
  'driver: no VersionFromMainModule (uses git tags)';
ok ! $driver->{'Dist::Zilla::Plugin::MakeMaker::Awesome'},
  'driver: plain MakeMaker, not Awesome';

# --- driver-only: @Git::VersionManager ---
ok   $driver->{'Dist::Zilla::Plugin::RewriteVersion::Transitional'},
  'driver: @Git::VersionManager wired in';
ok ! $core->{'Dist::Zilla::Plugin::RewriteVersion::Transitional'},
  'core: no @Git::VersionManager';

# --- versioning policy: only the main module is versioned (driver) ---
{
  my $rw = $driver->{'Dist::Zilla::Plugin::RewriteVersion::Transitional'};
  is_deeply $rw->finder, [':MainModule'],
    'driver: RewriteVersion only patches :MainModule';
  ok ! $rw->global, 'driver: RewriteVersion not global (sub-modules unversioned)';

  my $bump = $driver->{'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional'};
  is_deeply $bump->finder, [':MainModule'],
    'driver: BumpVersionAfterRelease only patches :MainModule';
}

# --- share_skill is forwarded to DBIO::GatherSkills as its 'skill' list ---
{
  my $with_skills = by_class(
    tzil_for("share_skill = dbio-foo\nshare_skill = dbio-bar")
  );
  my $gs = $with_skills->{'Dist::Zilla::Plugin::DBIO::GatherSkills'};
  ok $gs, 'GatherSkills present when share_skill is set';
  is_deeply $gs->skill, [qw(dbio-foo dbio-bar)],
    'share_skill list reaches GatherSkills->skill';

  # No share_skill -> GatherSkills still wired, with an empty explicit list
  # (it falls back to deriving owned skills from the dist name at build time).
  is_deeply $driver->{'Dist::Zilla::Plugin::DBIO::GatherSkills'}->skill, [],
    'no share_skill -> empty explicit skill list (name-rule fallback)';
}

done_testing;
