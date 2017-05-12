
use strict;
use warnings;

use 5.012004;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl extension to download realtime quotes for all major markets indices sectors",
  "AUTHOR" => "santex <santex\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "blib" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Finance-NASDAQ-Markets",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Finance::NASDAQ::Markets",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "HTML::TableContentParser" => 0,
    "HTML::TableExtract" => 0,
    "LWP::Simple" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.006",
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



