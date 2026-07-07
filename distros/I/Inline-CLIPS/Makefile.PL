use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Inline::CLIPS',
  VERSION_FROM => 'lib/Inline/CLIPS.pm',
  ABSTRACT     => 'Perl interface for CLIPS with Alien::Build-backed CLIPS discovery',
  AUTHOR       => 'Inline-CLIPS contributors',
  LICENSE      => 'gpl_3',
  PREREQ_PM    => {
    'Test::More' => 0,
  },
  META_MERGE   => {
    resources => {
      repository => 'https://github.com/jtrujil43/Inline-CLIPS',
    },
  },
);
