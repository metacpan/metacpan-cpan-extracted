
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Post-modern Gtk+ applications\r",
  "AUTHOR" => "Jeffrey Ray Hallock <jeffrey.hallock\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Gapp",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Gapp",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DateTime" => 0,
    "Gtk2" => 0,
    "List::MoreUtils" => "0.09",
    "Moose" => "2.0",
    "MooseX::Clone" => 0,
    "MooseX::LazyRequire" => 0,
    "MooseX::SemiAffordanceAccessor" => 0,
    "MooseX::StrictConstructor" => 0,
    "MooseX::Types" => 0,
    "Scalar::Util" => 0,
    "Sub::Exporter" => "0.90"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.60",
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



