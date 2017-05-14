
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A collection of tools for working with Mendeley Desktop's SQLite backend.",
  "AUTHOR" => "Spiros Denaxas <s.denaxas\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::Deep" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "MendeleySQLite",
  "EXE_FILES" => [
    "bin/maketagcloud.pl",
    "bin/migrate_keywords_to_tags.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "MendeleySQLite",
  "PREREQ_PM" => {
    "DBD::SQLite" => 0,
    "DBI" => 0,
    "Data::Dumper" => 0,
    "Getopt::Long" => 0,
    "HTML::TagCloud" => 0,
    "SQL::Abstract" => 0,
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



