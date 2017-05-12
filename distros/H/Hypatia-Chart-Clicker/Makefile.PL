
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Hypatia Bindings for Chart::Clicker",
  "AUTHOR" => "Jack Maney <jack\@jackmaney.com>",
  "BUILD_REQUIRES" => {
    "Hypatia" => 0,
    "Hypatia::DBI::Test::SQLite" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Hypatia-Chart-Clicker",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Hypatia::Chart::Clicker",
  "PREREQ_PM" => {
    "Chart::Clicker" => 0,
    "Chart::Clicker::Data::DataSet" => 0,
    "Chart::Clicker::Data::Series" => 0,
    "Chart::Clicker::Data::Series::Size" => 0,
    "Chart::Clicker::Renderer::Area" => 0,
    "Chart::Clicker::Renderer::Bar" => 0,
    "Chart::Clicker::Renderer::Bubble" => 0,
    "Chart::Clicker::Renderer::Pie" => 0,
    "Chart::Clicker::Renderer::Point" => 0,
    "Chart::Clicker::Renderer::StackedArea" => 0,
    "Chart::Clicker::Renderer::StackedBar" => 0,
    "Data::Dumper" => 0,
    "Graphics::Color::RGB" => 0,
    "Graphics::Primitive::Font" => 0,
    "Graphics::Primitive::Insets" => 0,
    "Hypatia" => "0.029",
    "Hypatia::Base" => 0,
    "Hypatia::Columns" => 0,
    "Hypatia::Types" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Aliases" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Scalar::Util" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.026",
  "test" => {
    "TESTS" => "t/*.t t/sqlite/*.t t/sqlite/options/*.t t/sqlite/options/axis/*.t"
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



