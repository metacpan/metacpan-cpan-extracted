use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestBundleHelpers;
use Test::DZil;

my $root = dir(qw( t data recovering_the_satellites ));
eval "use lib '${\ $root->subdir(q[lib])->as_foreign(q[Unix])->absolute->stringify }'";

my $exp = {
  'Dist::Zilla::PluginBundle::Catapult' => {
    file => file(qw( lib Dist Zilla PluginBundle Catapult.pm )),
    prereqs => {
      'Dist::Zilla::PluginBundle::Goodnight'   => 2.2,
      'Dist::Zilla::Plugin::Angels'            => 3,
      'Dist::Zilla::Plugin::Daylight'          => 0,
      'Dist::Zilla::Plugin::ImNotSleeping'     => 0,
    },
    pod => <<'INI',
=head1 Config

=bundle_ini_string

=cut
INI
    ini => <<'INI',
=head1 Config

  [Angels / Of::The::Silences]
  :version = 3

  [Daylight / Fading]
  [ImNotSleeping]

  [@Goodnight]
  :version = 2.2
  to       = Elisabeth

=cut
INI
  },
  'Pod::Weaver::PluginBundle::ChildrenInBloom' => {
    file => file(qw( lib Pod Weaver PluginBundle ChildrenInBloom.pm )),
    prereqs => {
      'Pod::Weaver::Plugin::SeenMeLately'      => 0,
      'Pod::Weaver::Section::Angels'           => '1.23',
      'Pod::Weaver::Section::Another'          => 0,
    },
    pod => <<'INI',
=head1 INI

=bundle_ini_string

=cut
INI
    ini => <<'INI',
=head1 INI

  [-SeenMeLately / HaveYou]

  [Angels / Millers]
  :version = 1.23

  [Another / HorseDreamersBlues]

=cut
INI
  },
};

test_dzil_build( none => );

test_dzil_build( dzil => 'Dist::Zilla::PluginBundle::Catapult' );

test_dzil_build( pod_weaver => 'Pod::Weaver::PluginBundle::ChildrenInBloom' );

test_dzil_build( both => keys %$exp );

done_testing;

sub test_dzil_build {
  my ($desc, @exp_names) = @_;

subtest "specify: $desc" => sub {
  my $extra_ini = join '', map { "bundle = $_\n" } @exp_names;

  if( !@exp_names ){
    # expect all
    @exp_names = keys %$exp;
    # specify none
    $extra_ini = '';
  }

  my $tzil = Builder->from_config(
    {
      dist_root => $root,
    },
    {
      add_files => {
        'source/dist.ini' => <<DISTINI . $extra_ini
name             = Recovering-The-Satellites
author           = Counting Crows
license          = None
copyright_holder = Counting Crows
version          = 1
abstract         = Walkaways

[GatherDir]
[Prereqs]
Dist::Zilla::Role::PluginBundle::Easy = 0.001

[BundleInspector]
DISTINI
      },
    },
  );

  $tzil->build;

  is_deeply
    [ sort @{ $tzil->plugin_named('BundleInspector')->bundles } ],
    [ sort @exp_names ],
    'expected bundles';

  is_filelist $tzil->files, [
      qw( dist.ini ),
      # both files will always be present
      map { $_->{file}->as_foreign('Unix')->stringify } values %$exp
    ], 'included files';

  is_deeply $tzil->prereqs->as_string_hash->{runtime}{requires}, {
    'Dist::Zilla::Role::PluginBundle::Easy'  => 0.001,
    map { %{ $_->{prereqs} } } @$exp{ @exp_names }
  }, 'prereqs added';

  test_munged_pod(
    $tzil,
    $root,
    map { [ @$_{qw( file pod ini )} ] } @$exp{ @exp_names }
  );
};
}

sub test_munged_pod {
  my ($tzil, $root, @tests) = @_;

  foreach my $test ( @tests ){
    my ($file, $orig, $munged) = @$test;

    pod_eq_or_diff
      disk_file($root, $file)->slurp,
      $orig,
      'disk file has pod placeholder';

    pod_eq_or_diff
      zilla_file($file, $tzil->files)->content,
      $munged,
      'zilla file munges in INI string';
  }
}
