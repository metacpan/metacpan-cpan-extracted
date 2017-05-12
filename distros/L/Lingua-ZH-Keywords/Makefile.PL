# $File: //member/autrijus/Lingua-ZH-Keywords/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 3690 $ $DateTime: 2003/01/20 11:08:53 $

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Extract keywords from Chinese text',
    NAME		=> 'Lingua::ZH::Keywords',
    VERSION_FROM	=> 'Keywords.pm',
    PREREQ_PM		=> {
	'Lingua::ZH::TaBE' => '0',
    }
);
 
1;
