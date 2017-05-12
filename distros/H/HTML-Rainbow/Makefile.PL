# generate Makefile for building HTML::Rainbow
#
# Copyright (C) 2005-2009 David Landgren

use strict;
use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage";
print "Adding testcover target\n" unless $@;

WriteMakefile(
    NAME          => 'HTML::Rainbow',
    VERSION_FROM  => 'Rainbow.pm',
    ABSTRACT_FROM => 'Rainbow.pm',
    AUTHOR        => 'David Landgren',
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'Tie::Cycle::Sinewave' => 0.01,
    },
    clean => {
        FILES => 'cover_db',
    },
);
