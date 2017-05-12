
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'A simple lightweight memory-growth tracer',
  'AUTHOR' => 'Matthew Horsfall <WolfSage@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Devel-MemoryTrace-Light',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Devel::MemoryTrace::Light',
  'PREREQ_PM' => {
  },
  'VERSION' => '0.09',
  'test' => {
    'TESTS' => 't/*.t t/*/*.t'
  }
);

# Only require GTop on FreeBSD if it's already installed
if ($^O eq 'freebsd') {
  eval "use GTop";
  if ($@) {
    $WriteMakefileArgs{'PREREQ_PM'}{'BSD::Process'} = '0';
  } else {
    $WriteMakefileArgs{'PREREQ_PM'}{'GTop'} = '0'
  }
} else {
  $WriteMakefileArgs{'PREREQ_PM'}{'GTop'} = '0'
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



