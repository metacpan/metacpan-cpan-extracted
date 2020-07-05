use strict;
use warnings;
use ExtUtils::MakeMaker;

# $pm points to the main file of this package.

my $pm = 'lib/Image/SVG/Path.pm';
my $pod = 'lib/Image/SVG/Path.pod';
my $repo = 'https://github.com/benkasminbullock/Image-SVG-Path';

WriteMakefile (
    NAME => 'Image::SVG::Path',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
	x_contributors => [
	    'Alessandro Ranellucci <aar@cpan.org>',
	    'Colin Kuskie <colink@cpan.org>',
	    'Alexander Gorlov',
	    'kekoa',
	],
    },
    MIN_PERL_VERSION => '5.006001',
);
