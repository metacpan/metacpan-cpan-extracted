
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "provides screen dump of Perl data.",
  "AUTHOR" => "Ilya Zakharevich <ilya\@math.berkeley.edu>, The Perl 5 Porters",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dumpvalue",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Dumpvalue",
  "PREREQ_PM" => {
    "Devel::Peek" => 0
  },
  "VERSION" => "1.17",
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

$WriteMakefileArgs{INSTALLDIRS} = 'perl'
    if $] >= 5.009005 && $] <= 5.011000;

WriteMakefile(%WriteMakefileArgs);



