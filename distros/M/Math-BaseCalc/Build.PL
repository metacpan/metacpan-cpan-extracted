
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Convert numbers between various bases",
  "dist_author" => [
    "Ken Williams <kwilliams\@cpan.org>"
  ],
  "dist_name" => "Math-BaseCalc",
  "dist_version" => "1.019",
  "license" => "perl",
  "module_name" => "Math::BaseCalc",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "integer" => 0,
    "strict" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Test::More" => 0,
    "warnings" => 0
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.3601",
  "Test::More" => 0,
  "warnings" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
