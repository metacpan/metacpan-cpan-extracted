
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4203"
  },
  "configure_requires" => {
    "Module::Build" => "0.4203"
  },
  "dist_abstract" => "Work with refs",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Util-Git-Refs",
  "dist_version" => "0.002000",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Util::Git::Refs",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Dist::Zilla::UtilRole::MaybeGit" => 0,
    "Moose" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Dist::Zilla::Util::Git::Wrapper" => 0,
    "Git::Wrapper" => 0,
    "Path::Tiny" => 0,
    "Sort::Versions" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Dist::Zilla::Util::Git::Wrapper" => 0,
  "Git::Wrapper" => 0,
  "Module::Build" => "0.4203",
  "Path::Tiny" => 0,
  "Sort::Versions" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
