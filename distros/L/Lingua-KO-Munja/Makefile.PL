use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Lingua/KO/Munja.pm';
my $pod = 'lib/Lingua/KO/Munja.pod';

my $repo = 'https://github.com/benkasminbullock/Lingua-KO-Munja';

WriteMakefile (
    NAME => 'Lingua::KO::Munja',
    VERSION_FROM => $pm,
    PREREQ_PM => {
        'Convert::Moji' => 0.03,
    },
    LICENSE => 'perl',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    ABSTRACT_FROM => $pod,
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.008009',
);
