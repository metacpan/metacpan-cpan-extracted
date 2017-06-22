use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Minion::Backend::Storable',
  VERSION_FROM => 'lib/Minion/Backend/Storable.pm',
  ABSTRACT     => 'File backend for Minion',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    no_index  => {directory => ['test']},
    requires  => {perl => 5.010_001},
    resources => {
      bugtracker => 'https://github.com/niczero/minion-backend-storable/issues',
      homepage   => 'https://niczero.github.io',
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository => 'https://github.com/niczero/minion-backend-storable.git',
      x_IRC      => 'irc://irc.perl.org/#mojo'
    }
  },
  BUILD_REQUIRES     => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM          => {
    Mojolicious => 6.3,
    Minion => 6.05
  },
  test               => {TESTS => 'test/*.t'}
);
