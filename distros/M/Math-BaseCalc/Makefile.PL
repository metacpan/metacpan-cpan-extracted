
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert numbers between various bases",
  "AUTHOR" => "Ken Williams <kwilliams\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Math-BaseCalc",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Math::BaseCalc",
  "PREREQ_PM" => {
    "Carp" => 0,
    "integer" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.019",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Module::Build" => "0.3601",
  "Test::More" => 0,
  "integer" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



