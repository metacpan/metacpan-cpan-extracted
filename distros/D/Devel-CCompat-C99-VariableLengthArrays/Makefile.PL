use 5.006000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME       => 'Devel::CCompat::C99::VariableLengthArrays',
    LICENSE    => 'perl',
    META_MERGE => {
        resources => {
            repository => {
                type => 'git',
                url =>
'git@github.com:ericherman/p5-devel-ccompat-c99-variablelengtharrays.git',
                web =>
'https://github.com/ericherman/p5-devel-ccompat-c99-variablelengtharrays',
            },
        },
        'meta-spec' => { version => 2 },
    },

    VERSION_FROM  => 'lib/Devel/CCompat/C99/VariableLengthArrays.pm',
    ABSTRACT_FROM => 'lib/Devel/CCompat/C99/VariableLengthArrays.pm',
    AUTHOR        => 'Eric Herman',
    PREREQ_PM     => { 'Test/More' => 0, 'Exporter' => '5.57' },

    LIBS   => [''],            # e.g., '-lm'
    DEFINE => '',              # e.g., '-DHAVE_SOMETHING'
    INC    => '-I.',           # e.g., '-I. -I/usr/include/other'
    OBJECT => '$(O_FILES)',    # link all the C files too
);
