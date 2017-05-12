
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Demo app for showing the synergy between perl and javascript",
  "AUTHOR" => "Tudor Constantin <tconst\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Expense-Tracker",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Expense::Tracker",
  "PREREQ_PM" => {
    "DBD::SQLite" => 0,
    "DBI" => 0,
    "DBIx::Class" => 0,
    "DBIx::Class::Tree::AdjacencyList" => 0,
    "DateTime" => 0,
    "Digest::MD5" => 0,
    "File::Find" => 0,
    "FindBin::libs" => 0,
    "Lingua::EN::Inflect" => 0,
    "Lingua::EN::Inflect::Phrase" => 0,
    "Mojolicious" => 0,
    "Mojolicious::Plugin::Authentication" => 0,
    "Mojolicious::Plugin::YamlConfig" => 0,
    "Test::BDD::Cucumber" => 0,
    "YAML" => 0,
    "YAML::XS" => 0
  },
  "VERSION" => "0.008",
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



