#!perl
#
# This file is part of Language::Ook.
# Copyright (c) 2002-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

BEGIN { require 5.006; }

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Language::Ook',
    AUTHOR              => 'Jerome Quelin <jquelin@cpan.org>',
    VERSION_FROM        => 'lib/Language/Ook.pm',
    ABSTRACT_FROM       => 'lib/Language/Ook.pm',
    LICENSE             => 'perl',
    PREREQ_PM           => {
        'Test::More'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [
                'Language-Ook-*',
                map { ( '*/' x $_ ) . '*~' } 0..3
                ] },
);
