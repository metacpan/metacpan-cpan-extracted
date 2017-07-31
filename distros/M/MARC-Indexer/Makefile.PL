use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'MARC::Indexer',
    VERSION_FROM => 'lib/MARC/Indexer.pm',
    AUTHOR       => 'Paul Hoffman <paul@flo.org>',
    ABSTRACT     => 'MARC::Indexer',
    EXE_FILES    => [
        'bin/marcindex',
    ],
    PREREQ_PM    => {
                        'MARC::Loop' => 0,
                        'Time::HiRes' => 0,
                        'Unicode::Normalize' => 0,
                        'POSIX' => 0,
                    },
);
