#!perl

use strict;
use warnings;

use 5.007_003;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Internals::GraphArenas',
    VERSION_FROM   => 'lib/Internals/GraphArenas.pm',
    ABSTRACT_FROM  => 'lib/Internals/GraphArenas.pm',
    AUTHOR         => 'Josh ben Jore <jjore@cpan.org>',
    PREREQ_PM => {
        Imager => 0,
    },
);
