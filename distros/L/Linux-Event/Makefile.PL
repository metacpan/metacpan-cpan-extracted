use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME            => 'Linux::Event',
  VERSION_FROM    => 'lib/Linux/Event.pm',
  ABSTRACT_FROM   => 'lib/Linux/Event.pm',
  AUTHOR          => 'Joshua S. Day',
  LICENSE         => 'perl',
  MIN_PERL_VERSION=> '5.36.0',
  META_MERGE      => {
    resources => {
      repository => { type => 'git', url => 'https://github.com/haxmeister/perl-linux-event', web => 'https://github.com/haxmeister/perl-linux-event' },
      bugtracker  => { web => 'https://github.com/haxmeister/perl-linux-event/issues' },
    },
  },
  PREREQ_PM       => {
    'Carp'                => 0,
    'Test2::V0'           => 0,
    'Linux::Epoll'        => 0,
    'Linux::FD::Signal'   => 0,
    'Linux::Event::Timer' => 0.010,
    'Linux::Event::Clock' => 0.011,
    'IO::Uring'           => 0,
    'Time::Spec'          => 0,
  },
);
