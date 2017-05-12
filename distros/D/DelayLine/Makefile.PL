# $Id: Makefile.PL,v 1.1 2000/07/09 19:20:10 lth Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'DelayLine',
	      'VERSION_FROM' => 'DelayLine.pm', # finds $VERSION
);
