
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
  "dist_abstract" => "Parse the output from massif just like msparser.py",
  "dist_author" => [
    "Stephen R. Scaffidi <sscaffidi\@cpan.org>"
  ],
  "dist_name" => "Devel-Valgrind-Massif-OutputParser",
  "dist_version" => "0.005",
  "license" => "perl",
  "module_name" => "Devel::Valgrind::Massif::OutputParser",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "autodie" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
