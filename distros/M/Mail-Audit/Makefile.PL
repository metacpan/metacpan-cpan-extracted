
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "library for creating easy mail filters",
  "AUTHOR" => "Simon Cozens, Meng Weng Wong, Ricardo SIGNES",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Mail-Audit",
  "EXE_FILES" => [
    "bin/popread",
    "bin/proc2ma"
  ],
  "LICENSE" => "perl",
  "NAME" => "Mail::Audit",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "File::HomeDir" => "0.61",
    "File::Path" => 0,
    "File::Spec" => 0,
    "File::Tempdir" => 0,
    "MIME::Entity" => 0,
    "MIME::Parser" => 0,
    "Mail::Internet" => 0,
    "Mail::Mailer" => 0,
    "Mail::POP3Client" => 0,
    "Mail::Send" => 0,
    "Net::SMTP" => 0,
    "POSIX" => 0,
    "Parse::RecDescent" => 0,
    "Symbol" => 0,
    "Sys::Hostname" => 0,
    "constant" => 0,
    "parent" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "2.228",
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



