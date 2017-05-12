use ExtUtils::MakeMaker;

my $pm = 'lib/Lingua/EN/PluralToSingular.pm';
my $pod = 'lib/Lingua/EN/PluralToSingular.pod';
my $repo = 'https://github.com/benkasminbullock/Lingua-EN-PluralToSingular';

WriteMakefile (
    NAME => 'Lingua::EN::PluralToSingular',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    EXE_FILES => [
        'scripts/singular',
    ],
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
            homepage => 'http://prepan.org/module/3Yz7PYrBN8',
        },
	x_contributors => [
	    'Xan Charbonnet',
	    'H2CHANG',
	    'Lisa Hare',
	],
    },
    # Passes 5.6.2 at CPANTESTERS as of version 0.10.
    MIN_PERL_VERSION => '5.006001',
);
