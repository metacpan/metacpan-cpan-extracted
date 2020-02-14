use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/JSON/Create.pm';
my $pod = 'lib/JSON/Create.pod';
my $github = 'github.com/benkasminbullock/json-create';
my $repo = "https://$github";

# This methodology was poached from
#
# https://metacpan.org/source/MIYAGAWA/App-cpanminus-1.7039/Makefile.PL#L1
# 
# due to
#
# http://www.cpantesters.org/cpan/report/bbe5eb4b-6bf3-1014-b983-90639bcee8ff
#

my $tr = {
    'Test::More' => '0',

    # The internal handling of "true" and "false" values changed from
    # version 0.36 to version 0.37 of JSON::Parse for the sake of
    # simpler round-trip compatibility with JSON::Create. The tests in
    # this module assume we are using JSON::Parse's new "true" and
    # "false" values.

    # This only affects the file t/json-parse.t, the other tests are
    # unaffected.

    'JSON::Parse' => '0.38',
};

my %WriteMakefileArgs = (
    NAME => 'JSON::Create',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	# Used in the PP version
	'B' => 0,
	# Used in the PP version
	'Carp' => 0,
	# Used in the PP version
	'Scalar::Util' => 0,
	# Used in the PP version
	'POSIX' => 0,
    },
    TEST_REQUIRES => $tr,
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
    OBJECT => 'Create.o unicode.o',
);

my %FallbackPrereqs = (
    "ExtUtils::MakeMaker" => 0,
    %$tr,
);
 
unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}
 
WriteMakefile(
    %WriteMakefileArgs,
#    OPTIMIZE => '-g -Wall ',
);
