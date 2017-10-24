use strict;
use warnings;
use ExtUtils::MakeMaker;

if ($^O =~ /solaris|sunos/i) {
    exit;
}

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
        x_contributors => [
	    'Shlomi Fish <shlomif@cpan.org>',
            'kolmogorov42',
        ],
    },
    # All the C files are actually #included into Json3.xs so there is
    # only one object file.
    OBJECT => 'Json3.o',
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
);
