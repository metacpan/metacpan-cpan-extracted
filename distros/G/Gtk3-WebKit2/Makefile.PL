
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

my @authors = ( 'Jason Shaun Carty <jc@atikon.com>',  'Philipp Voglhofer <pv@atikon.com>', 'Philipp A. Lehner <pl@atikon.com>' );

my %WriteMakefileArgs = (
  "ABSTRACT" => "WebKit2 bindings for Perl",
  "AUTHOR" => \@authors,
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Gtk3-WebKit2",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Gtk3::WebKit2",
  "PREREQ_PM" => {
    "Glib::Object::Introspection" => 0,
    "Gtk3" => 0
  },
  "TEST_REQUIRES" => {
    "Test::NeedsDisplay" => 0
  },
  "VERSION" => "0.011",
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
