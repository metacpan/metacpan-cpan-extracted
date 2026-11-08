use strict;
use warnings;

use Test::More;
use File::Temp ();
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
  Dist::Zilla::Plugin::DBIO::LicenseFile
  Dist::Zilla::Plugin::TestRelease
  Dist::Zilla::Plugin::Test::ChangesHasContent
  Dist::Zilla::Plugin::InstallRelease
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
  is_deeply $rw->finder, [':InstallModules'],
    'driver: RewriteVersion patches :InstallModules';
  ok $rw->global, 'driver: RewriteVersion global';

  my $bump = $driver->{'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional'};
  is_deeply $bump->finder, [':InstallModules'],
    'driver: BumpVersionAfterRelease patches :InstallModules';
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

# --- PruneCruft is gone: what is tracked is what ships ---
ok ! $driver->{'Dist::Zilla::Plugin::PruneCruft'}, 'driver: no PruneCruft';
ok ! $core->{'Dist::Zilla::Plugin::PruneCruft'},   'core: no PruneCruft';

# --- Git::GatherDir: tracked files incl. dotfiles, only build products out ---
for my $set ([driver => $driver], [core => $core]) {
  my ($label, $plugins) = @$set;
  my $gd = $plugins->{'Dist::Zilla::Plugin::Git::GatherDir'};
  ok $gd->include_dotfiles, "$label: GatherDir includes dotfiles";
  is_deeply [ sort @{ $gd->exclude_filename } ],
    [ sort qw(META.yml META.json MANIFEST README README.md .karr) ],
    "$label: GatherDir excludes only the generated files and .karr";
  is_deeply $gd->exclude_match, [], "$label: GatherDir has no exclude_match";
}

# --- LicenseFile follows heritage ---
ok ! by_class( tzil_for('') )->{'Dist::Zilla::Plugin::DBIO::LicenseFile'}->heritage,
  'LicenseFile: heritage off by default';
ok   by_class( tzil_for('heritage = 1') )->{'Dist::Zilla::Plugin::DBIO::LicenseFile'}->heritage,
  'LicenseFile: heritage = 1 reaches the plugin';

# --- release chain: the three checks run before ConfirmRelease ---
for my $set ([driver => tzil_for('')], [core => tzil_for('core = 1')]) {
  my ($label, $tzil) = @$set;
  my @order = map { ref $_ } @{ $tzil->plugins };
  my %pos; @pos{@order} = (0 .. $#order);
  my $confirm = $pos{'Dist::Zilla::Plugin::ConfirmRelease'};
  ok defined $confirm, "$label: ConfirmRelease present";
  for my $p (qw(TestRelease Test::ChangesHasContent InstallRelease)) {
    my $pos = $pos{"Dist::Zilla::Plugin::$p"};
    ok defined $pos && $pos < $confirm, "$label: $p runs before ConfirmRelease";
  }
  my ($install) = grep { ref $_ eq 'Dist::Zilla::Plugin::InstallRelease' } @{ $tzil->plugins };
  is $install->install_command, 'cpanm .', "$label: InstallRelease uses cpanm .";
}

done_testing;
