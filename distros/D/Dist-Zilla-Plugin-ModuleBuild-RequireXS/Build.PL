
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => "0.88",
    "Test::Most" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Auto-promote recommended XS modules to required, when a C compiler is available.",
  "dist_author" => [
    "Clinton Gormley <drtech\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-ModuleBuild-RequireXS",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::ModuleBuild::RequireXS",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Dist::Zilla" => 4
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
