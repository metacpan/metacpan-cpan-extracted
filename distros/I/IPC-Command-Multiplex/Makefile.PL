use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'IPC::Command::Multiplex',
  VERSION_FROM => 'lib/IPC/Command/Multiplex.pm',
  ABSTRACT_FROM => 'lib/IPC/Command/Multiplex.pm',
  AUTHOR => 'Matt S Trout (mst) - <mst@shadowcat.co.uk>',
  LICENSE => 'perl',
  PREREQ_PM => { POE => 0, 'POE::Wheel::Run' => 0 },
);
