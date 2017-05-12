
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "log storage and log readers",
  "AUTHOR" => "Vyacheslav Matyukhin <me\@berekuk.ru>",
  "BUILD_REQUIRES" => {
    "IPC::System::Simple" => 0,
    "Test::Class" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0,
    "autodie" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Flux-Log",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Flux::Log",
  "PREREQ_PM" => {
    "File::Basename" => 0,
    "Flux::File" => 0,
    "Flux::In::Role::Easy" => 0,
    "Flux::In::Role::Lag" => 0,
    "Flux::Role::Description" => 0,
    "Flux::Storage::Role::ClientList" => 0,
    "Log::Unrotate" => 0,
    "Moo" => 0,
    "Type::Library" => 0,
    "Type::Params" => 0,
    "Type::Utils" => 0,
    "Types::Standard" => 0
  },
  "VERSION" => "1.00",
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



