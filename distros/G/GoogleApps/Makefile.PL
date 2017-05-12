
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Base class for all commands",
  "AUTHOR" => "Joenio Costa <joenio\@colivre.coop.br>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "GoogleApps",
  "EXE_FILES" => [
    "bin/google-apps"
  ],
  "LICENSE" => "gpl",
  "NAME" => "GoogleApps",
  "PREREQ_PM" => {
    "Config::Auto" => 0,
    "Data::Dumper" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Test::Class::Most" => 0,
    "Test::MockObject" => 0,
    "Test::More" => 0,
    "VUser::Google::ApiProtocol::V2_0" => 0,
    "VUser::Google::Provisioning::V2_0" => 0,
    "strict" => 0
  },
  "VERSION" => "0.002",
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



