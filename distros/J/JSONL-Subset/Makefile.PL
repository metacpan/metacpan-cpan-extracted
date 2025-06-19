use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'JSONL::Subset',
    VERSION      => '0.04',
    AUTHOR       => 'Matt Doughty <matt@apogee.guru>',
    ABSTRACT     => 'Subset extractor for JSONL files',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'IO::File'       => 0,
        'Exporter'       => 0,
        'Getopt::Long'   => 0,
    },
    EXE_FILES    => ['bin/jsonl-subset'],
    META_MERGE   => {
        'x_authority' => 'cpan:APOGEE',
    }
);
