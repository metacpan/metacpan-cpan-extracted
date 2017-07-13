use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Geo/GNS/Parser.pm';
my $pod = 'lib/Geo/GNS/Parser.pod';
my $repo = 'https://github.com/benkasminbullock/Geo-GNS';

WriteMakefile (
    NAME => 'Geo::GNS::Parser',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.006001',
);
