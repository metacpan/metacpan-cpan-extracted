
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "installs your dist after releasing",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-InstallRelease",
  "dist_version" => "0.008",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::InstallRelease",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Dist::Zilla::Role::AfterRelease" => 0,
    "Dist::Zilla::Role::Plugin" => 0,
    "File::pushd" => 0,
    "Moose" => 0,
    "autodie" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
