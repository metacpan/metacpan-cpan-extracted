#
# Makefile.PL
#
# Copyright (C) 1999-2006 Gregor N. Purdy. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
#
# [ $Revision: $ ]
#

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'Games::Chess::Referee',
  VERSION_FROM => 'lib/Games/Chess/Referee.pm',
  PREREQ_PM    => {
    Games::Chess         => 0.003,
  },
  EXE_FILES    => [
    'script/mkbd',
    'script/tryme',
  ],
  AUTHOR       => 'Gregor N. Purdy (gregor@focusresearch.com)',
#  ABSTRACT     => '',
  dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);

#
# End of file.
#
