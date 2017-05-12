#!/usr/bin/perl -w

# Copyright (c) Mark Summerfield 2000. All Rights Reserved.
# 
# Copyright (c) Kevin Ryde 2010, 2011, 2012.
# 
# This file may be used/distributed/modified under the LGPL. 

use 5.004;
use strict;
use ExtUtils::MakeMaker ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Image::Base',
    'VERSION_FROM' => 'lib/Image/Base.pm', # finds $VERSION
    'DISTNAME'     => 'Image-Base',
    ($] >= 5.005 ?
        (
            ABSTRACT => 'Base class for image manipulation',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    PREREQ_PM      => { 'Test' => 0 },
    MIN_PERL_VERSION => '5.004',

    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" },
) ;
