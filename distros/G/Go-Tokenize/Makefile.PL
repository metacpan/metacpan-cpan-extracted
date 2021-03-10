use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Go/Tokenize.pm';
my $pod = 'lib/Go/Tokenize.pod';
my $github = 'github.com/benkasminbullock/go-tokenize';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'Go::Tokenize',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Text::LineNumber' => '0',
	'C::Tokenize' => '0',
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
);
