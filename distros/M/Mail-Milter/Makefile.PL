# $Id: Makefile.PL,v 1.1 2004/02/23 19:43:11 tvierling Exp $

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT_FROM	=> 'lib/Mail/Milter.pm',
    AUTHOR		=> 'Todd Vierling <tv@duh.org>',
    NAME		=> 'Mail::Milter',
    PREREQ_PM		=> {
	'Sendmail::Milter' => '0.18',
    },
    VERSION_FROM	=> 'lib/Mail/Milter.pm',
);
