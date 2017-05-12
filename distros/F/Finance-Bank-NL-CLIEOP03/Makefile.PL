#
# Makefile.PL for Finance::Bank::NL::CLIEOP03
#
# Copyright (C) 2007 Sebastiaan Hoogeveen. All rights reserved.
#
# $Id: Makefile.PL 1305 2005-10-11 21:34:13Z sebastiaan $
#

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME		=> 'Finance::Bank::NL::CLIEOP03',
  VERSION_FROM	=> 'lib/Finance/Bank/NL/CLIEOP03.pm',
  PREREQ_PM	=> {
    'Carp'	=> 0
  }
);
