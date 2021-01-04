use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/JSON/Repair.pm';
my $pod = 'lib/JSON/Repair.pod';
my $github = 'github.com/benkasminbullock/json-repair';
my $repo = "https://$github";
WriteMakefile (
    NAME => 'JSON::Repair',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Carp' => '0',
	'JSON::Parse' => '0.58',
	'C::Tokenize' => '0.11',
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
	'script/repairjson',
    ],
    MIN_PERL_VERSION => '5.014001',
);
