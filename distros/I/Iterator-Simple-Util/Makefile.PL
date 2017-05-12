
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Port of List::Util and List::MoreUtils to Iterator::Simple",
  "AUTHOR" => "Ray Miller <raym\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "List::MoreUtils" => 0,
    "Test::More" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Iterator-Simple-Util",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Iterator::Simple::Util",
  "PREREQ_PM" => {
    "B" => 0,
    "Carp" => 0,
    "Const::Fast" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "Iterator::Simple" => 0,
    "Sub::Exporter" => 0,
    "Text::CSV_XS" => 0,
    "strict" => 0,
    "warnings" => 0
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



