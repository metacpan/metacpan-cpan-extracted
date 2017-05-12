#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Chia-liang Kao (clkao@clkao.org)',
    ABSTRACT		=> "Check emerging stock quotes from Taiwan's OTC with Perl",
    NAME		=> 'Finance::TW::EmergingQuote',
    VERSION_FROM	=> 'lib/Finance/TW/EmergingQuote.pm',
    DISTNAME		=> 'Finance-TW-EmergingQuote',
    PREREQ_PM		=> {
	'LWP::Simple'	=> 0,
    },

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

