# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.029.
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker 6.78;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl module to simulate die rolls",
  "AUTHOR" => "Philip Newton <pne\@cpan.org>, Ricardo Signes <cpan\@semiotic.systems>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.78"
  },
  "DISTNAME" => "Games-Dice",
  "EXE_FILES" => [
    "bin/roll"
  ],
  "LICENSE" => "mit",
  "MIN_PERL_VERSION" => "5.012",
  "NAME" => "Games::Dice",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "if" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::MockRandom" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "0.046",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Test::MockRandom" => 0,
  "Test::More" => "0.96",
  "if" => 0,
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

if ( $^O eq 'MSWin32' ) {
	$WriteMakefileArgs{PREREQ_PM}{'Math::Random::MT::Perl'} = $FallbackPrereqs{'Math::Random::MT::Perl'} = '1.1';
}

WriteMakefile(%WriteMakefileArgs);
