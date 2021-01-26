use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/JSON/Parse.pm';
my $pod = 'lib/JSON/Parse.pod';
my $github = 'github.com/benkasminbullock/JSON-Parse';
my $repo = "https://$github";

WriteMakefile (
    NAME => 'JSON::Parse',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Carp' => '0',
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
	    file => [
		'build/JPB.pm',
		't/JPT.pm',
		'xt/JPXT.pm',
	    ],
	},
    },
    # All the C files are actually #included into Parse.xs so there is
    # only one object file.
    OBJECT => 'Parse.o',
    # Currently the oldest version to pass at CPAN testers.
    # http://matrix.cpantesters.org/?dist=JSON-Parse+0.24
    MIN_PERL_VERSION => '5.008009',
    EXE_FILES => [
	'script/validjson',
    ],

# Uncomment the following to get "author tests"
#    OPTIMIZE => '-Wall -g',
#    OPTIMIZE => '-Wall -O',
# This achieves only small speedups with GCC.
#    OPTIMIZE => '-O3',

#    CC => 'gcc',
);
