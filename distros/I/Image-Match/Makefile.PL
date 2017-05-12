# $Id: Makefile.PL,v 1.1 2008/09/01 09:25:48 dk Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Image::Match',
	AUTHOR        => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	ABSTRACT_FROM => 'lib/Image/Match.pm',
	VERSION_FROM  => 'lib/Image/Match.pm',
	PREREQ_PM     => { Prima => 0 },
);
