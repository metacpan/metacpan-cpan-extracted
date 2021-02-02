use ExtUtils::MakeMaker;
my $pm = 'lib/Lingua/Guess.pm';
my $pod = 'lib/Lingua/Guess.pod';
my $repo = 'https://github.com/benkasminbullock/lingua-guess';

WriteMakefile(
    'NAME' => 'Lingua::Guess',
    'VERSION_FROM' => $pm,
    'ABSTRACT_FROM' => $pod,
    LICENSE => 'gpl',
    'PREREQ_PM'		=> {
	Carp => '0.01',
	Encode => '0.01',
	File::Spec::Functions => '0.01',
	JSON::Parse => '0.60',
	Unicode::Normalize => '0.01',
	Unicode::UCD => '0.01',
    },
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
	x_contributors => [
	    'Ben Bullock <bkb@cpan.org>',
	    'Maciej Ceglowski <mceglows@cpan.org>',
	],
    },
    MIN_PERL_VERSION => '5.008009',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    EXE_FILES => ['script/linguaguess',],
);
