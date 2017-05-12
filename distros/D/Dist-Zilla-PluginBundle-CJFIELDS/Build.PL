
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Build your modules like CJFIELDS (not sure that's a recommendation)",
  "dist_author" => [
    "Chris Fields <cjfields\@bioperl.org>"
  ],
  "dist_name" => "Dist-Zilla-PluginBundle-CJFIELDS",
  "dist_version" => "0.06",
  "license" => "perl",
  "module_name" => "Dist::Zilla::PluginBundle::CJFIELDS",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla::Plugin::ModuleBuild::Custom" => 0,
    "Dist::Zilla::Plugin::OurPkgVersion" => 0,
    "Dist::Zilla::Plugin::Test::Compile" => 0,
    "Dist::Zilla::PluginBundle::FLORA" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
