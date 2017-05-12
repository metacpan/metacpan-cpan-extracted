#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR	    => 'Greg Banks <gnb@fastmail.fm>',
    NAME	    => 'Devel::Plumber',
    VERSION_FROM    => 'lib/Devel/Plumber.pm',
    EXE_FILES	    => [ 'plumber' ],
    PREREQ_PM => {
	'Tree::Interval' => 0,
	'Devel::GDB'     => 0,
	'threads'	 => 0,
    },
);
