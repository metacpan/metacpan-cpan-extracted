
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
  "dist_abstract" => "Manage a release repository of Git submodules",
  "dist_author" => [
    "Doug Bell <preaction\@cpan.org>",
    "Andrew Goudzwaard <adgoudz\@gmail.com>"
  ],
  "dist_name" => "Git-ReleaseRepo",
  "dist_version" => "0.006",
  "license" => "perl",
  "module_name" => "Git::ReleaseRepo",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::Cmd" => "0.318",
    "File::HomeDir" => "1.00",
    "File::Path" => 0,
    "File::Spec::Functions" => 0,
    "Git::Repository" => "1.26",
    "Moose" => "2.000",
    "Progress::Any" => 0,
    "Progress::Any::Output" => 0,
    "Progress::Any::Output::TermProgressBarColor" => 0,
    "YAML" => "0.84"
  },
  "script_files" => [
    "bin/git-release"
  ],
  "test_requires" => {
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "Test::Compile" => 0,
    "Test::Most" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
