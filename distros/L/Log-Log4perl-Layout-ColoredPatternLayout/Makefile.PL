use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Log::Log4perl::Layout::ColoredPatternLayout',
    VERSION_FROM      => 'lib/Log/Log4perl/Layout/ColoredPatternLayout.pm', 
    PREREQ_PM         => {
        "Log::Log4perl" => 0,
        "Term::ANSIColor" => 0
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Log::Log4perl' => 0,
        'Term::ANSIColor' => 0
    },    

    ABSTRACT_FROM     => 'lib/Log/Log4perl/Layout/ColoredPatternLayout.pm',
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'perl'
);
