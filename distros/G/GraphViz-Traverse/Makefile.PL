#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'GraphViz::Traverse',
    VERSION_FROM  => 'lib/GraphViz/Traverse.pm',
    PREREQ_PM => {
        'GraphViz' => 0,
        'File::Basename' => 0,
        'File::Find' => 0,
        'Test::More' => 0,
        'Carp' => 0,
    },
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/GraphViz/Traverse.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()
    ),
);
