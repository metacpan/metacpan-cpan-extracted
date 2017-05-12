
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Tidy Perl code in Mason templates',
  'AUTHOR' => 'Jonathan Swartz <swartz@pobox.com>',
  'BUILD_REQUIRES' => {
    'Test::Class::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Mason-Tidy',
  'EXE_FILES' => [
    'bin/masontidy'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Mason::Tidy',
  'PREREQ_PM' => {
    'Capture::Tiny' => '0',
    'File::Slurp' => '0',
    'File::Temp' => '0',
    'Getopt::Long' => '0',
    'IPC::System::Simple' => '0',
    'Method::Signatures::Simple' => '1.02',
    'Moo' => '0.0091010',
    'Perl::Tidy' => '0',
    'Pod::Usage' => '0'
  },
  'VERSION' => '2.57',
  'test' => {
    'TESTS' => 't/*.t'
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



