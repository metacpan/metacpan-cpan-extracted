use strict;
use warnings;
use ExtUtils::Constant 'WriteConstants';
use ExtUtils::MakeMaker 'WriteMakefile';

WriteConstants(
  NAME => 'Dir::TempChdir',
  NAMES => [qw(O_PATH O_SEARCH)],
  PROXYSUBS => {croak_on_error => 1},
);

WriteMakefile(
  NAME          => 'Dir::TempChdir',
  AUTHOR        => 'Carsten Gaebler',
  LICENSE       => 'unrestricted', # WTFPL
  VERSION_FROM  => 'lib/Dir/TempChdir.pm',
  ABSTRACT_FROM => 'lib/Dir/TempChdir.pod',
  LIBS          => [],
  DEFINE        => '',
  INC           => '-I.',
  realclean     => { FILES => 'const-c.inc const-xs.inc' },
);
