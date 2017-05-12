# $File: //member/autrijus/Lingua-ZH-HanDetect/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 3923 $ $DateTime: 2003/01/27 20:55:42 $

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> "Guess Chinese text's variant and encoding",
    NAME		=> 'Lingua::ZH::HanDetect',
    VERSION_FROM	=> 'HanDetect.pm',
);
 
1;
