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

# --- RequireCoreVersion: every dist but core ---
ok   $driver->{'Dist::Zilla::Plugin::DBIO::RequireCoreVersion'}, 'driver: RequireCoreVersion present';
ok ! $core->{'Dist::Zilla::Plugin::DBIO::RequireCoreVersion'},   'core: no RequireCoreVersion';

# --- ExecDir (bin/) for every dist ---
{
  for my $set ([driver => $driver], [core => $core]) {
    my ($label, $plugins) = @$set;
    my $exec = $plugins->{'Dist::Zilla::Plugin::ExecDir'};
    ok $exec, "$label: ExecDir present";
    is $exec->dir, 'bin', "$label: ExecDir reads bin/";
  }
}

# --- core-only: MakeMaker::Awesome; neither uses VersionFromMainModule ---
ok   $core->{'Dist::Zilla::Plugin::MakeMaker::Awesome'},    'core: MakeMaker::Awesome';
ok ! $core->{'Dist::Zilla::Plugin::VersionFromMainModule'},
  'core: no VersionFromMainModule (versions like the drivers)';
ok ! $driver->{'Dist::Zilla::Plugin::VersionFromMainModule'},
  'driver: no VersionFromMainModule (uses git tags)';
ok ! $driver->{'Dist::Zilla::Plugin::MakeMaker::Awesome'},
  'driver: plain MakeMaker, not Awesome';

# --- eumm_version: forwarded to MakeMaker (driver) / MakeMaker::Awesome (core) ---
{
  my $mm   = 'Dist::Zilla::Plugin::MakeMaker';
  my $awe  = 'Dist::Zilla::Plugin::MakeMaker::Awesome';
  my $d_def = by_class( tzil_for('') )->{$mm};
  my $d_set = by_class( tzil_for("eumm_version = 7.1101") )->{$mm};
  my $c_def = by_class( tzil_for("core = 1") )->{$awe};
  my $c_set = by_class( tzil_for("core = 1\neumm_version = 7.1101") )->{$awe};

  ok $d_def, 'driver: MakeMaker present without eumm_version';
  is $d_set->eumm_version, '7.1101', 'driver: eumm_version reaches MakeMaker';
  isnt $d_def->eumm_version, '7.1101', 'driver: without the option MakeMaker keeps its own default';
  is $c_def->eumm_version, '6.78', 'core: eumm_version stays 6.78 without the option';
  is $c_set->eumm_version, '7.1101', 'core: eumm_version reaches MakeMaker::Awesome';
}

# --- core and driver: @Git::VersionManager ---
for my $set ([driver => $driver], [core => $core]) {
  my ($label, $plugins) = @$set;
  for my $p (qw(
    RewriteVersion::Transitional BumpVersionAfterRelease::Transitional
    NextRelease Git::Tag Git::Commit
  )) {
    ok $plugins->{"Dist::Zilla::Plugin::$p"}, "$label: $p from \@Git::VersionManager";
  }
}

# --- versioning policy: only the main module is versioned (driver) ---
{
  for my $set ([driver => $driver], [core => $core]) {
    my ($label, $plugins) = @$set;
    my $rw = $plugins->{'Dist::Zilla::Plugin::RewriteVersion::Transitional'};
    is_deeply $rw->finder, [':InstallModules'],
      "$label: RewriteVersion patches :InstallModules";
    ok $rw->global, "$label: RewriteVersion global";

    my $bump = $plugins->{'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional'};
    is_deeply $bump->finder, [':InstallModules'],
      "$label: BumpVersionAfterRelease patches :InstallModules";
  }
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

# --- release chain: the checks run before ConfirmRelease ---
for my $set ([driver => tzil_for('')], [core => tzil_for('core = 1')]) {
  my ($label, $tzil) = @$set;
  my @order = map { ref $_ } @{ $tzil->plugins };
  my %pos; @pos{@order} = (0 .. $#order);
  my $confirm = $pos{'Dist::Zilla::Plugin::ConfirmRelease'};
  my $upload  = $pos{'Dist::Zilla::Plugin::UploadToCPAN'};
  ok $confirm < $upload, "$label: ConfirmRelease runs before UploadToCPAN";
  ok $pos{'Dist::Zilla::Plugin::Git::Push'} > $upload, "$label: Git::Push runs after UploadToCPAN";
  ok defined $confirm, "$label: ConfirmRelease present";
  for my $p (qw(TestRelease Test::ChangesHasContent InstallRelease)) {
    my $pos = $pos{"Dist::Zilla::Plugin::$p"};
    ok defined $pos && $pos < $confirm, "$label: $p runs before ConfirmRelease";
  }
  my ($install) = grep { ref $_ eq 'Dist::Zilla::Plugin::InstallRelease' } @{ $tzil->plugins };
  is $install->install_command, 'cpanm .', "$label: InstallRelease uses cpanm .";
}
{
  my $tzil = tzil_for('');
  my @order = map { ref $_ } @{ $tzil->plugins };
  my %pos; @pos{@order} = (0 .. $#order);
  my $req = $pos{'Dist::Zilla::Plugin::DBIO::RequireCoreVersion'};
  ok defined $req && $req < $pos{'Dist::Zilla::Plugin::ConfirmRelease'},
    'driver: RequireCoreVersion runs before ConfirmRelease';
}

done_testing;
