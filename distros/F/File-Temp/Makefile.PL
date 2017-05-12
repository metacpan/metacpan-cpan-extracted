
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.17;



my %WriteMakefileArgs = (
  "ABSTRACT" => "return name and handle of a temporary file safely",
  "AUTHOR" => "Tim Jenness <tjenness\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "File-Temp",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "File::Temp",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Carp::Heavy" => 0,
    "Cwd" => 0,
    "Exporter" => "5.57",
    "Fcntl" => "1.03",
    "File::Path" => "2.06",
    "File::Spec" => "0.8",
    "IO::Handle" => 0,
    "IO::Seekable" => 0,
    "POSIX" => 0,
    "Scalar::Util" => 0,
    "Symbol" => 0,
    "constant" => 0,
    "overload" => 0,
    "parent" => "0.221",
    "strict" => 0,
    "vars" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "FileHandle" => 0,
    "List::Util" => 0,
    "Test::More" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.2304",
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

if ( $^O eq 'VMS' ) {
	$WriteMakefileArgs{PREREQ_PM}{'VMS::Stdio'} = '0';
}

$WriteMakefileArgs{INSTALLDIRS} = 'perl'
    if $] >= 5.006001 && $] <= 5.011000;

WriteMakefile(%WriteMakefileArgs);



