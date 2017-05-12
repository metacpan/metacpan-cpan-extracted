use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
  NAME          => 'Log::Dump',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Log/Dump.pm',
  ABSTRACT_FROM => 'lib/Log/Dump.pm',
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/log-dump',
    },
  },
);
