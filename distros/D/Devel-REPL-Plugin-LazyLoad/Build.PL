
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "Test::NoWarnings" => 0,
    "Test::SharedFork" => 0,
    "autodie" => 0,
    "parent" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Lazily load packages into your REPL",
  "dist_author" => [
    "Rob Hoelz <rob\@hoelz.ro>"
  ],
  "dist_name" => "Devel-REPL-Plugin-LazyLoad",
  "dist_version" => "0.01",
  "license" => "perl",
  "module_name" => "Devel::REPL::Plugin::LazyLoad",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Devel::REPL" => 0,
    "perl" => "v5.8.9"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
