
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "User management and authorization for web applications and subscription-based services.",
  "AUTHOR" => "Ido Perlmuter <ido\@ido50.net>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Entities",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Entities",
  "PREREQ_PM" => {
    "Abilities" => 0,
    "Abilities::Features" => 0,
    "Carp" => 0,
    "DateTime" => 0,
    "DateTime::Format::ISO8601" => 0,
    "Digest::MD5" => 0,
    "MongoDB" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "MooX::Types::MooseLike::Email" => 0,
    "Scalar::Util" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0
  },
  "VERSION" => "0.5",
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



