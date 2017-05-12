# $Id: Makefile.PL 38877 2006-07-12 12:16:51Z nanardon $

use 5.008;
use strict;
use ExtUtils::MakeMaker;

sub MY::postamble {
    <<MAKE;
.PHONY: ChangeLog

ChangeLog:
	svn2cl -o ChangeLog || :
	rm -f *.bak

MAKE
}

WriteMakefile(
    NAME	 => 'MDV::Repsys',
    VERSION_FROM => 'lib/MDV/Repsys.pm',
    EXE_FILES => [ qw(bin/mdvsys) ],
    PREREQ_PM => {
        'File::Tempdir' => undef,
        'RPM4' => undef,
        'SVN::Client' => undef,
        'Date::Parse' => undef,
        'Config::IniFiles' => undef,
        'Date::Format' => undef,
    },
);
