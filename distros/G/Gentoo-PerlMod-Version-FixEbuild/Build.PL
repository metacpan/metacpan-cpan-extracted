
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Automatically fix an old-style ebuild to a new style ebuild.',
  'dist_author' => [
    'Kent Fredric <kentnl@cpan.org>'
  ],
  'dist_name' => 'Gentoo-PerlMod-Version-FixEbuild',
  'dist_version' => '0.1.1',
  'license' => 'perl',
  'module_name' => 'Gentoo::PerlMod::Version::FixEbuild',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'File::pushd' => '0',
    'Gentoo::PerlMod::Version' => '0',
    'Moose' => '0',
    'Params::Util' => '0',
    'Path::Class' => '0'
  },
  'script_files' => [
    'bin/gentoo-perlmod-version-fixebuild.pl'
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
