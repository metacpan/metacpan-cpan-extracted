
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Code coverage metrics for your distribution",
  "dist_author" => [
    "Marcel Gr\303\274nauer <marcel\@cpan.org>",
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-App-Command-cover",
  "dist_version" => "1.101001",
  "license" => "perl",
  "module_name" => "Dist::Zilla::App::Command::cover",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Devel::Cover" => 0,
    "Dist::Zilla::App" => 0,
    "File::Temp" => 0,
    "File::chdir" => 0,
    "Path::Class" => 0,
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
