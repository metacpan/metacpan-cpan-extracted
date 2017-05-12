use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Email::MIME::Creator::ISO_2022_JP',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Email/MIME/Creator/ISO_2022_JP.pm',
  ABSTRACT_FROM => 'lib/Email/MIME/Creator/ISO_2022_JP.pm',
  PREREQ_PM => {
    'Email::MIME'         => '1.900',
    'Encode'              => '0',
    'Sub::Install'        => '0',
    'Test::Classy'        => '0.07',
    'Test::More'          => '0.47',
    'Test::UseAllModules' => '0.10',
    ( $] < 5.008008
      ? ('Encode::compat::MIME::Header::ISO_2022_JP' => 0 )
      : ()
    ),
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
