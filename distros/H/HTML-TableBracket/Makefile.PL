#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'T. J. Eckman (jeek@jeek.net)',
    ABSTRACT		=> 'Tournament Table Bracket Generator',
    NAME		=> 'HTML::TableBracket',
    VERSION_FROM	=> 'TableBracket.pm', 
    DISTNAME		=> 'HTML-TableBracket',
    BINARY_LOCATION	=> 'x86/HTML-TableBracket.tar.gz',

    dist		=> {
        COMPRESS	=> 'gzip',
        SUFFIX		=> '.gz',
    },
);

