use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Linux::Event::Stream',
  AUTHOR       => 'Joshua S. Day <hax@cpan.org>',
  VERSION_FROM => 'lib/Linux/Event/Stream.pm',
  ABSTRACT_FROM=> 'lib/Linux/Event/Stream.pm',
  LICENSE      => 'perl',
  MIN_PERL_VERSION => '5.036000',
  PREREQ_PM => {
    'Linux::Event' => 0.009,
  },
  TEST_REQUIRES => {
    'Test::More' => 0,
    'Socket'     => 0,
  },
);
