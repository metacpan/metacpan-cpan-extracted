
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Stash containing list of contributors",
  "dist_author" => [
    "Yanick Champoux <yanick\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Stash-Contributors",
  "dist_version" => "0.1.0",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Stash::Contributors",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Moose" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
