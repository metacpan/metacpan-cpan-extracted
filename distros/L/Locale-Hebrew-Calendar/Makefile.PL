#!/usr/bin/perl
# $File: //member/autrijus/Locale-Hebrew-Calendar/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 3587 $ $DateTime: 2003/01/17 05:30:22 $

use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	    => 'Locale::Hebrew::Calendar',
    'VERSION_FROM'  => 'Calendar.pm',
    'OBJECT'	    => join(' ', map "$_$Config{obj_ext}", qw(Calendar hdate hcom)),
    'FUNCLIST'	    => [qw(g2j j2g)],
);

1;
