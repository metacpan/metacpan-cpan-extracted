# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.032.
use strict;
use warnings;

use 5.036000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Gene's RtController filters",
  "AUTHOR" => "Gene Boggs <gene.boggs\@gmail.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "MIDI-RtController-Filter-Gene",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.036000",
  "NAME" => "MIDI::RtController::Filter::Gene",
  "PREREQ_PM" => {
    "Array::Circular" => 0,
    "List::SomeUtils" => 0,
    "List::Util" => 0,
    "MIDI::RtMidi::ScorePlayer" => 0,
    "Moo" => 2,
    "Music::Chord::Note" => 0,
    "Music::Note" => 0,
    "Music::Scales" => 0,
    "Music::ToRoman" => 0,
    "Music::VoiceGen" => 0,
    "Types::Standard" => 0,
    "namespace::clean" => 0,
    "strictures" => 2
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0105",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Array::Circular" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::SomeUtils" => 0,
  "List::Util" => 0,
  "MIDI::RtMidi::ScorePlayer" => 0,
  "Moo" => 2,
  "Music::Chord::Note" => 0,
  "Music::Note" => 0,
  "Music::Scales" => 0,
  "Music::ToRoman" => 0,
  "Music::VoiceGen" => 0,
  "Test::More" => "0.88",
  "Types::Standard" => 0,
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
