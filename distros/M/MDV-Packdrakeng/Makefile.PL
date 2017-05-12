# $Id: Makefile.PL 219699 2007-05-17 17:01:46Z nanardon $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

sub MY::postamble {
    <<MAKE;
.PHONY: ChangeLog 

ChangeLog:
	LC_ALL=C svn2cl -o ChangeLog
	rm -f *.bak

MAKE
}

WriteMakefile(
    NAME	 => 'MDV::Packdrakeng',
    VERSION_FROM => 'lib/MDV/Packdrakeng.pm',
);
