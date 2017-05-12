#!/usr/bin/env perl

use 5.4.0;
use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker qw(:DEFAULT);
use File::Spec;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Geo::Calc::XS',
    VERSION_FROM => File::Spec->catfile( 'lib', 'Geo', 'Calc', 'XS.pm' ), # finds $VERSION
    PREREQ_PM    => {
        'File::Spec'  => 0,
        'Test::More'  => 0,
        },
    LIBS         => [''], # e.g., '-lm'
    DEFINE       => '', # e.g., '-DBYPASS'
    INC          => '', # e.g., '-I/usr/include/other'
    SIGN         => 1,
    XS => {
        'XS.xs' => 'XS.c',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/Flimm/perl5-geo-calc-xs.git',
                web => 'https://github.com/Flimm/perl5-geo-calc-xs',
            },
        },
    },
    MIN_PERL_VERSION => '5.4.0',
    LICENSE => 'perl_5',
);
