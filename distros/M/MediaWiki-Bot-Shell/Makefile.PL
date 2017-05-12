
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'a shell interface to your MediaWiki::Bot',
  'AUTHOR' => 'Mike.lifeguard <lifeguard@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'MediaWiki-Bot-Shell',
  'EXE_FILES' => [
    'bin/pwb'
  ],
  'LICENSE' => 'gpl',
  'NAME' => 'MediaWiki::Bot::Shell',
  'PREREQ_PM' => {
    'Config::General' => '0',
    'Encode' => '0',
    'File::Copy' => '0',
    'Getopt::Long' => '0',
    'IO::Handle' => '0',
    'MediaWiki::Bot' => '0',
    'Pod::Select' => '0',
    'Pod::Text::Termcap' => '0',
    'Term::Prompt' => '0',
    'Term::Shell' => '0'
  },
  'VERSION' => '0.002',
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



