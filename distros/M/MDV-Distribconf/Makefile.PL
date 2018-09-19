# $Id$

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
    dist => { DIST_DEFAULT => 'change_dist', COMPRESS => "xz -f", SUFFIX => ".xz" },
    EXE_FILES => [ qw(bin/checkdistrib) ],
    PREREQ_PM => {
        'Config::IniFiles' => undef,
        'MDV::Packdrakeng' => undef,
        'Digest::MD5' => undef,
    },
);
