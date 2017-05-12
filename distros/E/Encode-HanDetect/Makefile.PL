# $File: //member/autrijus/Encode-HanDetect/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 4051 $ $DateTime: 2003/01/30 22:34:14 $

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Cross-encoding, cross-variant Chinese decoder',
    NAME		=> 'Encode::HanDetect',
    VERSION_FROM	=> 'HanDetect.pm',
    PREREQ_PM		=> {
	'Encode'		=> 0,
	'Encode::HanConvert'	=> 0.24,
	'Lingua::ZH::HanDetect'	=> 0.02,
    }
);
 
1;
