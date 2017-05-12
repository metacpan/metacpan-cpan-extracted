
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Manage a release repository of Git submodules",
  "AUTHOR" => "Doug Bell <preaction\@cpan.org>, Andrew Goudzwaard <adgoudz\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Git-ReleaseRepo",
  "EXE_FILES" => [
    "bin/git-release"
  ],
  "LICENSE" => "perl",
  "NAME" => "Git::ReleaseRepo",
  "PREREQ_PM" => {
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
  "TEST_REQUIRES" => {
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "Test::Compile" => 0,
    "Test::Most" => 0
  },
  "VERSION" => "0.006",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



