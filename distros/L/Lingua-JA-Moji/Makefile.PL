use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Lingua/JA/Moji.pm';
my $pod = 'lib/Lingua/JA/Moji.pod';
my $repo = 'https://github.com/benkasminbullock/Lingua-JA-Moji';

WriteMakefile (
    NAME => 'Lingua::JA::Moji',
    AUTHOR => 'Ben Bullock <benkasminbullock@gmail.com>',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    PREREQ_PM => {
        'Convert::Moji' => '0.11',
	'JSON::Parse' => '0.62',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
        no_index => {
            directory => 'build',
	    file => [
		't/LJMT.pm',
	    ],
        },
    },
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.008009',
);
