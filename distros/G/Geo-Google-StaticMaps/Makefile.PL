#!/usr/bin/perl
#
#   Perl Makefile for Geo-Google-StaticMaps
#
#   Invoke with 'perl Makefile.PL'
#
#   See ExtUtils::MakeMaker (3) for more information on how to influence
#    the contents of the Makefile that is written
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'Geo::Google::StaticMaps',
    VERSION_FROM            => 'lib/Geo/Google/StaticMaps.pm',
    AUTHOR                  => 'Martin Atkins <mart@degeneration.co.uk>',
    ABSTRACT                => 'API for generating URLs for static Google Maps',
    PREREQ_PM               => {
        'Carp'          => 0,
    },

);

