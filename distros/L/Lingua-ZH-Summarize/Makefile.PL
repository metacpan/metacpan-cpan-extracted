# $File: //member/autrijus/Lingua-ZH-Summarize/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 3686 $ $DateTime: 2003/01/20 07:16:38 $

use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Summarizing bodies of Chinese text',
    NAME		=> 'Lingua::ZH::Summarize',
    VERSION_FROM	=> 'Summarize.pm',
    PREREQ_PM		=> {
	'Lingua::ZH::Toke' => '0',
	'Lingua::ZH::Wrap' => '0',
    }
);
 
1;
