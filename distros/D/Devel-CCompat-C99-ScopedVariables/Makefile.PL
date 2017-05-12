use 5.006000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME       => 'Devel::CCompat::C99::ScopedVariables',
    LICENSE    => 'perl',
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url =>
'git@github.com:ericherman/p5-devel-ccompat-c99-scopedvariables.git',
                web =>
'https://github.com/ericherman/p5-devel-ccompat-c99-scopedvariables',
            },
        },
        'meta-spec' => { version => 2 },
    },
    AUTHOR        => 'Eric Herman',
    VERSION_FROM  => 'lib/Devel/CCompat/C99/ScopedVariables.pm',
    ABSTRACT_FROM => 'lib/Devel/CCompat/C99/ScopedVariables.pm',
    PREREQ_PM     => { 'Test/More' => 0, 'Exporter' => '5.57' },

    DEFINE => '-std=c99',      # e.g., '-DHAVE_SOMETHING'
    INC    => '-I.',           # e.g., '-I. -I/usr/include/other'
    LIBS   => [''],            # e.g., '-lm'
    OBJECT => '$(O_FILES)',    # link all the C files too
);
