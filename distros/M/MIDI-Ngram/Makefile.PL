# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.025.
use strict;
use warnings;

use 5.012;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Find the top repeated note phrases of MIDI files",
  "AUTHOR" => "Gene Boggs <gene\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "MIDI-Ngram",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.012",
  "NAME" => "MIDI::Ngram",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Lingua::EN::Ngram" => "0.03",
    "List::Util" => "1.44",
    "List::Util::WeightedChoice" => 0,
    "MIDI::Util" => "0.0800",
    "Moo" => 2,
    "Music::Note" => 0,
    "namespace::clean" => 0,
    "strictures" => 2
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.1808",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Lingua::EN::Ngram" => "0.03",
  "List::Util" => "1.44",
  "List::Util::WeightedChoice" => 0,
  "MIDI::Util" => "0.0800",
  "Moo" => 2,
  "Music::Note" => 0,
  "Test::Exception" => 0,
  "Test::More" => 0,
  "namespace::clean" => 0,
  "strict" => 0,
  "strictures" => 2,
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
