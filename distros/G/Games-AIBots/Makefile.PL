#!/usr/bin/env perl
# $File: //member/autrijus/AIBots/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 634 $ $DateTime: 2002/08/14 02:58:47 $

use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile (
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'An improved clone of A.I.Wars in Perl',
    NAME		=> 'Games::AIBots',
    VERSION_FROM	=> 'lib/Games/AIBots.pm',
    DISTNAME		=> 'Games-AIBots',
    BINARY_LOCATION	=> 'x86/Games-AIBots.tar.gz',

    PREREQ_PM		=> {
    	($^O eq 'MSWin32') ? (
	    'Win32::Console'	=> '0.03',
	    'Win32::Sound'	=> '0.40',
	    'Win32::Process'	=> '0.01',
        ) : (
	    'Term::ANSIScreen'	=> '1.2',
	),
	'Tk'			=> '800.021',
	'Term::ReadKey'		=> '2.14',
    },

    EXE_FILES		=> [ <bin/*> ],

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

