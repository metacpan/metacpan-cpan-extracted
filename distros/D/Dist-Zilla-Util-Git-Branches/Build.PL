
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
  "dist_abstract" => "Extract branches from Git",
  "dist_author" => [
    "Kent Fredric <kentfredric\@gmail.com>"
  ],
  "dist_name" => "Dist-Zilla-Util-Git-Branches",
  "dist_version" => "0.001000",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Util::Git::Branches",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Dist::Zilla::Util::Git::Refs" => 0,
    "Dist::Zilla::Util::Git::Refs::Ref" => 0,
    "Dist::Zilla::Util::Git::Wrapper" => 0,
    "Moose" => 0,
    "MooseX::LazyRequire" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Git::Wrapper" => 0,
    "Path::Tiny" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Git::Wrapper" => 0,
  "Module::Build" => "0.4203",
  "Path::Tiny" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
