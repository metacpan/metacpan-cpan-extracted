
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "validate assembly stash with Rx (from JSON in kit)",
  "AUTHOR" => "Ricardo SIGNES <rjbs\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Email-MIME-Kit-Validator-Rx",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Email::MIME::Kit::Validator::Rx",
  "PREREQ_PM" => {
    "Data::Rx" => "0.007",
    "Data::Rx::TypeBundle::Perl" => "0.005",
    "Email::MIME::Kit::Role::Validator" => "0",
    "JSON" => "0",
    "Moose" => "0",
    "Moose::Util::TypeConstraints" => "0",
    "Try::Tiny" => "0"
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => "0",
    "Email::MIME::Kit" => "0",
    "Test::More" => "0.96",
    "blib" => "0",
    "lib" => "0",
    "strict" => "0",
    "warnings" => "0"
  },
  "VERSION" => "0.200001",
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



