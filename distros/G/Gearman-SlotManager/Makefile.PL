
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Managing Worker's lifecycle with Slots",
  "AUTHOR" => "HyeonSeung Kim <sng2nara\@hanmail.net>",
  "BUILD_REQUIRES" => {
    "AnyEvent::Gearman" => 0,
    "Exporter" => 0,
    "Gearman::Client" => 0,
    "JSON" => 0,
    "POSIX" => 0,
    "Storable" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Gearman-SlotManager",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Gearman::SlotManager",
  "PREREQ_PM" => {
    "Any::Moose" => 0,
    "AnyEvent" => 0,
    "AnyEvent::HTTPD" => 0,
    "Data::Dumper" => 0,
    "Devel::GlobalDestruction" => 0,
    "Gearman::Server" => 0,
    "Gearman::Worker" => 0,
    "LWP::Simple" => 0,
    "Log::Log4perl" => 0,
    "Scalar::Util" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.3",
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



