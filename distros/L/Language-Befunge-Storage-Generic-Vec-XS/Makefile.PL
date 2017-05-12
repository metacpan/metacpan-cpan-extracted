#!perl
#
# This file is part of Language::Befunge::Storage::Generic::Vec::XS.
# Copyright (c) 2008 Mark Glines, all rights reserved.
#
# This program is made available under the terms of the Artistic License, v2.0.
# See the "LICENSE" file for details.
#
#

BEGIN { require 5.010; }
use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Language::Befunge::Storage::Generic::Vec::XS',
    AUTHOR        => 'Mark Glines, <mark@glines.org>',
    VERSION_FROM  => 'lib/Language/Befunge/Storage/Generic/Vec/XS.pm',
    ABSTRACT_FROM => 'lib/Language/Befunge/Storage/Generic/Vec/XS.pm',
    LICENSE       => 'artistic_2',
    PREREQ_PM     => {
                       'Test::More' => 0,
                       'Language::Befunge' => '4.00',
                       'Language::Befunge::Vector::XS' => '1.1.1',
                     },
    LIBS          => [''],  # e.g., '-lm'
    DEFINE        => '',    # e.g., '-DHAVE_SOMETHING'
    INC           => '-I.', # e.g., '-I. -I/usr/include/other'
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => [
        'Language-Befunge-Storage-Generic-Vec-XS-*',
        'const-c.inc', 'const-xs.inc',
        map { ( '*/' x $_ ) . '*~' } 0..4 ],
    },
);

