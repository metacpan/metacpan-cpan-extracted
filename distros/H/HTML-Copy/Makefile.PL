#!/usr/bin/env perl -w
use 5.008;
use strict;
use ExtUtils::MakeMaker;

my @programs_to_install = qw(htmlcopy);

WriteMakefile(
    'NAME'          => 'HTML::Copy',
    'VERSION_FROM'  => 'lib/HTML/Copy.pm',
    'EXE_FILES'     => [ map {"bin/$_"} @programs_to_install ],
    'PREREQ_PM'     => {
        'Test::More'   => 0,
        'HTML::Parser' => 3.40,
        'HTTP::Headers' => 0,
        'Class::Accessor' => 0,
        'URI' => 0
    },
    'dist'          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },	
    'clean'         => { FILES => 'HTML-Copy-*' },

);
