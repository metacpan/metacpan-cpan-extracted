# $Id: Makefile.PL,v 1.1 2004/11/20 11:14:47 joern Exp $

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Gtk2::Ex::FormFactory',
    'VERSION_FROM' => 'lib/Gtk2/Ex/FormFactory.pm',
    'PREREQ_PM'    => {
    	'Gtk2'             => 0,
	'Gtk2::SimpleList' => 0,
	'Gtk2::SimpleMenu' => 0,
    },
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX   => "gz",
	PREOP    => q[tools/genreadme],
	POSTOP	 => q[mkdir -p dist; mv Gtk2-Ex-FormFactory*tar.gz dist/],
    },
);
