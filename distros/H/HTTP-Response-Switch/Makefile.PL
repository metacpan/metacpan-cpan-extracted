
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "handle many HTTP response possibilities",
  "AUTHOR" => "Alex Peters <lxp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HTTP-Response-Switch",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "HTTP::Response::Switch",
  "PREREQ_PM" => {
    "Module::Find" => 0,
    "Module::Load" => 0,
    "Moose" => 0,
    "Throwable" => "0.200001",
    "TryCatch" => "1.001000",
    "namespace::autoclean" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "HTTP::Response" => 0,
    "Module::Loaded" => 0,
    "Scalar::Util" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::Routine" => 0
  },
  "VERSION" => "1.1.1",
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



