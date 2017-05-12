
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Log data to a file as JSON",
  "AUTHOR" => "Eric Johnson <cpan at iijo dot org>",
  "BUILD_REQUIRES" => {
    "Directory::Scratch" => 0,
    "File::Find" => 0,
    "File::Slurp" => 0,
    "File::Temp" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Log-JSON",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Log::JSON",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DateTime" => 0,
    "English" => 0,
    "JSON" => 0,
    "Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Path::Class::File" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


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



