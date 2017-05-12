
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "file storage and file readers",
  "AUTHOR" => "Vyacheslav Matyukhin <me\@berekuk.ru>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Flux-File",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Flux::File",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "Flux::In" => 0,
    "Flux::In::Role::Lag" => 0,
    "Flux::Role::Description" => 0,
    "Flux::Role::Owned" => 0,
    "Flux::Storage" => 0,
    "IO::Handle" => 0,
    "Lock::File" => 0,
    "Moo" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "Params::Validate" => 0,
    "autodie" => 0
  },
  "TEST_REQUIRES" => {
    "Test::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Time::HiRes" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



