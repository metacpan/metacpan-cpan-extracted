
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Get It Done - with Perl",
  "AUTHOR" => "Torsten Raudssus <torsten\@raudss.us>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "GID",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "GID",
  "PREREQ_PM" => {
    "Carp::Always" => "0.12",
    "Class::Load" => "0.20",
    "Class::Method::Modifiers" => "1.12",
    "Class::Method::ModifiersX::Augment" => "0.001",
    "Class::Method::ModifiersX::Override" => "0.001",
    "Data::Printer" => "0.35",
    "DateTime" => "0.78",
    "File::Copy::Recursive" => "0.38",
    "File::Remove" => "1.52",
    "File::ShareDir" => "1.03",
    "File::Temp" => "0.22",
    "File::chdir" => "0.1008",
    "IO::All" => "0.46",
    "LWP::Simple" => "6.00",
    "List::MoreUtils" => "0.33",
    "Moo" => "1.000006",
    "MooX" => "0.101",
    "MooX::ClassStash" => "0.004",
    "MooX::HasEnv" => "0.003",
    "MooX::Options" => "3.73",
    "MooX::Types::MooseLike" => "0.16",
    "MooX::late" => "0.006",
    "Path::Class" => "0.27",
    "Scalar::Util" => "1.25",
    "URI" => "1.60",
    "URL::Encode" => "0.01",
    "namespace::clean" => "0.24",
    "strictures" => "1.004004"
  },
  "TEST_REQUIRES" => {
    "Test::LoadAllModules" => "0.021",
    "Test::More" => "0.98"
  },
  "VERSION" => "0.004",
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



