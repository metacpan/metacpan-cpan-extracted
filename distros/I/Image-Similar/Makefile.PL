use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Image/Similar.pm';
my $pod = 'lib/Image/Similar.pod';
my $github = 'github.com/benkasminbullock/image-similar';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'Image::Similar',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Scalar::Util' => '0',
	'Image::PNG::Libpng' => '0.42',
    },
    META_MERGE => {
	'meta-spec' => {
	    version => 2,
	},
        resources => {
            repository => {
		type => 'git',
		url => "git://$github.git",
		web => $repo,
	    },
            bugtracker => {
		web => "$repo/issues",
	    },
#	    homepage => 'http://',
        },
    },
    MIN_PERL_VERSION => '5.006001',
    OBJECT => 'Similar.o similar-image.o',
#    OPTIMIZE => '-g -Wall -O',
);
