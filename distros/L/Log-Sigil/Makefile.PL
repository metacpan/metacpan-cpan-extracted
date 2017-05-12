
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "show warnings with sigil prefix",
  "AUTHOR" => "Kuniyoshi Kouji <kuniyoshi\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Log-Sigil",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Log::Sigil",
  "PREREQ_PM" => {
    "Class::Accessor" => 0,
    "Class::Singleton" => 0,
    "Readonly" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
    "Test::Output" => 0
  },
  "VERSION" => "1.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::Accessor" => 0,
  "Class::Singleton" => 0,
  "Readonly" => 0,
  "Test::More" => 0,
  "Test::Output" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



