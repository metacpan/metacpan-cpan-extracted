# $Id: Makefile.PL,v 1.2 2006/02/27 13:34:29 joern Exp $

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Event::ExecFlow',
    'VERSION_FROM' => 'lib/Event/ExecFlow.pm',
    'EXE_FILES'    => [ 'bin/execflow' ],
    'PREREQ_PM'    => {
    	'Test::More'         => 0,
        'AnyEvent'           => 0.4,
        'Locale::TextDomain' => 0,
    },
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX   => "gz",
	PREOP    => q[pod2text lib/Event/ExecFlow.pm > README],
	POSTOP	 => q[mkdir -p dist && mv Event-ExecFlow-*tar.gz dist/],
    },
);
