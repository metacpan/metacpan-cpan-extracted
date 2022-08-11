###############################################################################
##                                                                           ##
##  Copyright (c) 2022 - by Carlos Celso.                                    ##
##  All rights reserved.                                                     ##
##                                                                           ##
##  This package is free software; can, at your discretion, also be used,    ##
##  modified and redistributed under the terms of the "GPLv3 - GNU Library   ##
##  General Public License".                                                 ##
##                                                                           ##
###############################################################################

	use 5.006001;

	use ExtUtils::MakeMaker;

	WriteMakefile(
		NAME		=> 'Math::Notation::PostfixInfix',
		VERSION_FROM	=> 'lib/Math/Notation/PostfixInfix.pm',
		PREREQ_PM	=> { },
		ABSTRACT_FROM	=> 'lib/Math/Notation/PostfixInfix.pod',
		AUTHOR		=> 'Carlos Celso <CCELSO@cpan.org>',
		LICENSE		=> 'GPL_3',
		dist		=> { COMPRESS => "gzip -9", SUFFIX => "gz" },
);

##ENDED
