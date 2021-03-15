use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/HTML/Make/Calendar.pm';
my $pod = 'lib/HTML/Make/Calendar.pod';
my $github = 'github.com/benkasminbullock/html-make-calendar';
my $repo = "https://$github";
WriteMakefile (
    EXE_FILES => ['script/html-cal',],
    NAME => 'HTML::Make::Calendar',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Date::Calc' => '6.4',
	'HTML::Make' => '0.13',
	'Table::Readable' => '0.03',
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
