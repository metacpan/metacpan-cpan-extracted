use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Lingua/JA/Name/Splitter.pm';
my $pod = 'lib/Lingua/JA/Name/Splitter.pod';
my $repo = 'https://github.com/benkasminbullock/Lingua-JA-Name-Splitter';

WriteMakefile (
    NAME => 'Lingua::JA::Name::Splitter',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'Lingua::JA::Moji' => '0.42',
    },
    EXE_FILES => [
	'script/splitjname',
    ],
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008009',
);
