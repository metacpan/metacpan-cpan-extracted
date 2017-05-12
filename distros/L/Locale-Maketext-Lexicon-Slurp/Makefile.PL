use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Locale::Maketext::Lexicon::Slurp',
    'VERSION_FROM' => 'lib/Locale/Maketext/Lexicon/Slurp.pm',
    'PREREQ_PM'    => {
        'Locale::Maketext::Lexicon' => '0',
        'Path::Class'               => '0',
        'Test::More'                => '0.62'
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {},
    'SIGN'        => 1,
);
