#!perl
#
# This file is part of Language::Befunge::Vector::XS.
# Copyright (c) 2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

BEGIN { require 5.010; }
use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Language::Befunge::Vector::XS',
    AUTHOR        => 'Jerome Quelin, <jquelin@cpan.org>',
    VERSION_FROM  => 'lib/Language/Befunge/Vector/XS.pm',
    ABSTRACT_FROM => 'lib/Language/Befunge/Vector/XS.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => { 'Test::More' => 0 },
    LIBS          => [''],  # e.g., '-lm'
    DEFINE        => '',    # e.g., '-DHAVE_SOMETHING'
    INC           => '-I.', # e.g., '-I. -I/usr/include/other'
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => [
        'Language-Befunge-Vector-XS-*',
        'const-c.inc', 'const-xs.inc',
        map { ( '*/' x $_ ) . '*~' } 0..4 ],
    },
);

