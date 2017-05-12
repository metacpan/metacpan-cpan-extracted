use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hardware::Vhdl::Tidy',
    AUTHOR              => 'Michael Attenborough <michael.attenborough at physics.org>',
    VERSION_FROM        => 'lib/Hardware/Vhdl/Tidy.pm',
    ABSTRACT_FROM       => 'lib/Hardware/Vhdl/Tidy.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Hardware::Vhdl::Lexer' => 1.00,
        'Getopt::Long' => 0,
        'Carp' => 0,
        'Exporter' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hardware-Vhdl-Tidy-*' },
);
