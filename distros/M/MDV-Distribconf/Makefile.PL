# $Id: Makefile.PL 231527 2007-11-14 21:39:03Z nanardon $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

# where to find the rpm utility

sub MY::postamble {
    <<MAKE;
ChangeLog: \$(TO_INST_PM)
	svn2cl -o ChangeLog || :
	rm -f *.bak || :

change_dist: ChangeLog tardist

MAKE
}

WriteMakefile(
    NAME	 => 'MDV::Distribconf',
    VERSION_FROM => 'lib/MDV/Distribconf.pm',
    dist => { DIST_DEFAULT => 'change_dist' },
    EXE_FILES => [ qw(bin/checkdistrib) ],
    PREREQ_PM => {
        'Config::IniFiles' => undef,
        'MDV::Packdrakeng' => undef,
        'Digest::MD5' => undef,
    },
);
