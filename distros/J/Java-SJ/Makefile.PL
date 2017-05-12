#############################################################################
#
# Java::SJ - Start Java
#
# $Id: Makefile.PL,v 1.1.1.1 2003/07/19 02:17:34 wiggly Exp $
#
# $Author: wiggly $
#
# $DateTime$
#
# $Revision: 1.1.1.1 $
#
#############################################################################

use ExtUtils::MakeMaker;

&WriteMakefile(
	NAME		=> 'Java::SJ',
	DISTNAME	=> 'Java-SJ',
	VERSION_FROM	=> 'lib/Java/SJ.pm',
	EXE_FILES	=> 
			[ 
				'bin/sj',
			],
	PREREQ_PM	=> 
			{
				'File::Slurp' => 0,
				'XML::XPath' => 0,
			},
	AUTHOR		=> 'Nigel Rantor <wiggly@wiggly.org>',
	ABSTRACT_FROM	=> 'lib/Java/SJ.pm',
	dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
		);
