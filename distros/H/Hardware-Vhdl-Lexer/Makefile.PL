use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hardware::Vhdl::Lexer',
    AUTHOR              => 'Michael Attenborough <michael.attenborough at physics.org>',
    VERSION_FROM        => 'lib/Hardware/Vhdl/Lexer.pm',
    ABSTRACT_FROM       => 'lib/Hardware/Vhdl/Lexer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Class::Std' => 0,
        'Readonly' => 1.03,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hardware-Vhdl-Lexer-*' },
);
