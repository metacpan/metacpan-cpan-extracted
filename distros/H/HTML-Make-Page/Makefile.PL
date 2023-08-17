use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/HTML/Make/Page.pm';
my $pod = 'lib/HTML/Make/Page.pod';
my $github = 'github.com/benkasminbullock/html-make-page';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'HTML::Make::Page',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'HTML::Make' => '0.16',
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
