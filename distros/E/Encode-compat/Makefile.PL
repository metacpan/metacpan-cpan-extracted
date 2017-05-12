#!/usr/bin/perl
# $File: //member/autrijus/Encode-compat/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 1014 $ $DateTime: 2002/09/24 02:24:44 $

use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Encode.pm compatibility layer',
    NAME		=> 'Encode::compat',
    VERSION_FROM	=> 'lib/Encode/compat.pm', 
    DISTNAME		=> 'Encode-compat',
    BINARY_LOCATION	=> 'x86/Encode-compat.tar.gz',

    PREREQ_PM		=> {
	($] < 5.007001 ? (
	    'Text::Iconv'	=> '0',
	) : ())
    },

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

1;
