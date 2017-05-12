use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Lingua/JA/Moji.pm';
my $pod = 'lib/Lingua/JA/Moji.pod';
my $repo = 'https://github.com/benkasminbullock/Lingua-JA-Moji';

WriteMakefile (
    NAME => 'Lingua::JA::Moji',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    PREREQ_PM => {
        'Convert::Moji' => '0.05',
	'JSON::Parse' => '0.49',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
        no_index => {
            directory => 'build',
        },
	x_contributors => [
	    'Naoki Tomita <tomita@cpan.org>',
	    'David Steinbrunner',
	    'Neil Bowers <neilb@cpan.org>',
	],
    },
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.008009',
);
