use strict;
use warnings;
use ExtUtils::MakeMaker '6.63_03';

my $pm = 'lib/JSON/Create.pm';
my $pod = 'lib/JSON/Create.pod';
my $github = 'github.com/benkasminbullock/json-create';
my $repo = "https://$github";

my %WriteMakefileArgs = (
    NAME => 'JSON::Create',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    # JSON::Create doesn't need any of these, they are only used by
    # JSON::Create::PP
    PREREQ_PM => {
	'B' => 0,
	'Carp' => 0,
	'JSON::Parse' => '0.60',
	'POSIX' => 0,
	'Scalar::Util' => 0,
	'Unicode::UTF8' => '0.62',
    },
    TEST_REQUIRES => {
	'File::Spec' => '0',
	'File::Temp' => '0',
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
        },
	no_index => {
	    # Module for testing only
	    file => ['t/JCT.pm',],
	},
    },
    MIN_PERL_VERSION => '5.006001',
    OBJECT => 'Create.o unicode.o',
);

 
WriteMakefile(
    %WriteMakefileArgs,
#    OPTIMIZE => ' -g -Wall -O ',
);
