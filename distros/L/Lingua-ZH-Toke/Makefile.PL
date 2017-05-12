# $File: //member/autrijus/Lingua-ZH-Toke/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 9667 $ $DateTime: 2004/01/11 12:56:49 $

use 5.006001;
use ExtUtils::MakeMaker;

if ($] < 5.007 and not eval { require Encode::compat; 1 }) {
    warn << '.';
If you wish to use unicode strings with Lingua::ZH::Toke,
please install Encode::compat from CPAN first.

Otherwise, only Big5 strings are supported.
.
}

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang <autrijus@autrijus.org>',
    ABSTRACT		=> 'Chinese Tokenizer',
    NAME		=> 'Lingua::ZH::Toke',
    VERSION_FROM	=> 'lib/Lingua/ZH/Toke.pm',
    PREREQ_PM		=> {
	'Lingua::ZH::TaBE' => '0',
    }
);
 
1;
