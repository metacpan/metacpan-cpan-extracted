
use strict;
use warnings;

use 5.008_009;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "High speed Base58 encoding using GMP with BigInt and MD5 support",
  "AUTHOR" => "John Wang <johncwang\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Config" => 0,
    "Test::Base" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Encode-Base58-GMP",
  "EXE_FILES" => [],
  "LICENSE" => "mit",
  "NAME" => "Encode::Base58::GMP",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Digest::MD5" => 0,
    "Exporter" => 0,
    "Math::GMPz" => 0,
    "Scalar::Util" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
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



