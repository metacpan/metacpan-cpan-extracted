
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Metabase backend implemented using Amazon Web Services",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Metabase::Test::Archive" => 0,
    "Metabase::Test::Index" => 0,
    "Net::Amazon::Config" => 0,
    "Test::Deep" => 0,
    "Test::More" => "0.92",
    "Test::Routine" => 0,
    "Test::Routine::Util" => 0,
    "re" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Metabase-Backend-AWS",
  "EXE_FILES" => [],
  "LICENSE" => "apache",
  "NAME" => "Metabase::Backend::AWS",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Compress::Zlib" => 2,
    "Data::Dumper" => 0,
    "Data::GUID" => 0,
    "Data::Stream::Bulk::Callback" => 0,
    "Data::Stream::Bulk::Filter" => "0.08",
    "JSON" => 2,
    "List::AllUtils" => 0,
    "Metabase::Archive" => 1,
    "Metabase::Fact" => 0,
    "Metabase::Index" => 1,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Net::Amazon::S3" => 0,
    "Path::Class" => 0,
    "SimpleDB::Client" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.000",
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



