use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Linux::Event::Connect',
  VERSION_FROM => 'lib/Linux/Event/Connect.pm',
  ABSTRACT     => 'Nonblocking outbound socket connect for Linux::Event',
  AUTHOR       => 'Joshua S. Day <haxmeister@cpan.org>',
  LICENSE      => 'perl',
  PREREQ_PM    => {
    'Linux::Event' => 0,
  },
);
