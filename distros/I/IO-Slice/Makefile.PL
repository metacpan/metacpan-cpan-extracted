
use strict;
use warnings;

use 5.008_000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "restrict reads to a range in a file",
  "AUTHOR" => "Flavio Poletti <polettix\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "IO-Slice",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "IO::Slice",
  "PREREQ_PM" => {
    "Log::Log4perl::Tiny" => "1.002003"
  },
  "TEST_REQUIRES" => {
    "Test::Exception" => "0.032",
    "Test::More" => "1.001008"
  },
  "VERSION" => "0.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Log::Log4perl::Tiny" => "1.002003",
  "Test::Exception" => "0.032",
  "Test::More" => "1.001008"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



