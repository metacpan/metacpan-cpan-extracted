#      /\
#     /  \		(C) Copyright 2003 Parliament Hill Computers Ltd.
#     \  /		All rights reserved.
#      \/
#       .		Author: Alain Williams, January 2003
#       .		addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: @(#)Makefile.PL	1.2 03/05/07 14:43:51
#

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Expression',
    'VERSION_FROM'	=> 'Expression.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Expression.pm', # retrieve abstract from module
       AUTHOR     => 'Alain D D Williams <addw@phcomp.co.uk>') : ()),
    ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
      ('LICENSE'	=> 'perl', ) : ()),
);
