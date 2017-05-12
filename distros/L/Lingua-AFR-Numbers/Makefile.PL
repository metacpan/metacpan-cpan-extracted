
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Converts numeric values into their Afrikaans equivalents.",
  "AUTHOR" => "Alistair Francis <cpan\@alizta.com>",
  "BUILD_REQUIRES" => {
    "Test::Exception" => 0,
    "Test::More" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Lingua-AFR-Numbers",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Lingua::AFR::Numbers",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Perl6::Export::Attrs" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.1106",
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



