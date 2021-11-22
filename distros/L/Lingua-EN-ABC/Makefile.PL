use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Lingua/EN/ABC.pm';
my $pod = 'lib/Lingua/EN/ABC.pod';
my $repo = 'https://github.com/benkasminbullock/Lingua-EN-ABC';

WriteMakefile (
    NAME => 'Lingua::EN::ABC',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	# We need "read_json"
	'JSON::Parse' => '0.61',
	'Carp' => '0',
	'Convert::Moji' => '0.10',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
        x_contributors => [
	    'Nigel Horne <njh@cpan.org>',
	    'Ed Avis <edavis@cpan.org>',
        ],
    },
    EXE_FILES => [
	'script/econv',
    ],
    # Speculated necessary version of Perl. I have no test results
    # which say otherwise. As of this moment, the earliest results are
    # for 5.8.9. Note that JSON::Parse relies on 5.8.9, I think, so we
    # probably cannot install on earlier versions of Perl anyway.
    MIN_PERL_VERSION => '5.006001',
);
