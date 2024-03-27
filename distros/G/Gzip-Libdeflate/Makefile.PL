use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Gzip/Libdeflate.pm';
my $pod = 'lib/Gzip/Libdeflate.pod';
my $github = 'github.com/benkasminbullock/gzip-libdeflate';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'Gzip::Libdeflate',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <benkasminbullock@gmail.com>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'File::Slurper' => '0.012',
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
    OBJECT => 'Libdeflate.o',
    #    OPTIMIZE => '-g -Wall',
);
