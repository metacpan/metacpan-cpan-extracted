#!perl
#
# This file is part of Inline::Befunge.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Inline::Befunge',
    AUTHOR              => 'Jerome Quelin <jquelin@cpan.org>',
    VERSION_FROM        => 'lib/Inline/Befunge.pm',
    ABSTRACT_FROM       => 'lib/Inline/Befunge.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
		'Inline'            => '0.43',
		'Language::Befunge' => '3.00',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [
                'Inline-Befunge-*', '_Inline',
                map { ( '*/' x $_ ) . '*~' } 0..3
                ] },
);
