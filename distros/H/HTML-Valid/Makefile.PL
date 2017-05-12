use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/HTML/Valid.pm';
my $pod = 'lib/HTML/Valid.pod';
my $github = 'github.com/benkasminbullock/html-valid';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'HTML::Valid',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'JSON::Parse' => '0.49',
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
    EXE_FILES => [
	'script/htmlok',
	'script/htmltidy',
    ],
    MIN_PERL_VERSION => '5.006001',
    OBJECT => 'Valid.o tidy-html5.o',
#    OPTIMIZE => '-g -Wall -O3',
);
