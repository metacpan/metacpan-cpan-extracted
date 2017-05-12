#############################################################################
#
# Math::CatmullRom - Catmull-Rom splines
#
# $Id: Makefile.PL,v 1.1.1.1 2003/08/31 16:53:16 wiggly Exp $
#
# $Author: wiggly $
#
# $Revision: 1.1.1.1 $
#
#############################################################################

use ExtUtils::MakeMaker;

&WriteMakefile(
	NAME		=> 'Math::CatmullRom',
	DISTNAME	=> 'Math-CatmullRom',
	VERSION_FROM	=> 'lib/Math/CatmullRom.pm',
	AUTHOR		=> 'Nigel Rantor <wiggly@wiggly.org>',
	ABSTRACT_FROM	=> 'lib/Math/CatmullRom.pm',
	dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
		);
