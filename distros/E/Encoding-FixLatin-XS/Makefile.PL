
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "XS implementation layer for Encoding::FixLatin",
  "AUTHOR" => "Grant McLean <grantm\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.90"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Encoding-FixLatin-XS",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Encoding::FixLatin::XS",
  "PREREQ_PM" => {
    "Encoding::FixLatin" => "1.03"
  },
  "VERSION" => "1.01",
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



