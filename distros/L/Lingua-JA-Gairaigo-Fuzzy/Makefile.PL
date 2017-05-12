use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Lingua/JA/Gairaigo/Fuzzy.pm';
my $pod = 'lib/Lingua/JA/Gairaigo/Fuzzy.pod';
my $repo = 'https://github.com/benkasminbullock/Lingua-JA-Gairaigo-Fuzzy';

WriteMakefile (
    NAME => 'Lingua::JA::Gairaigo::Fuzzy',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Lingua::JA::Moji' => '0.24',
	'Text::Fuzzy' => '0.14',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008009',
);
