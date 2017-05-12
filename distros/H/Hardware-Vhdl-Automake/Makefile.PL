use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hardware::Vhdl::Automake',
    AUTHOR              => 'Michael Attenborough <michael.attenborough at physics.org>',
    VERSION_FROM        => 'lib/Hardware/Vhdl/Automake/Project.pm',
    #~ ABSTRACT_FROM       => 'lib/Hardware/Vhdl/Automake/Project.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Hardware::Vhdl::Lexer' => 1.0,
        'Test::More' => 0, # Core since 5.8
        'File::Spec::Functions' => 0,
        'File::Path' => 0,
        'File::Temp' => 0,
        'File::Copy' => 0,
        'File::Temp' => 0,
        'File::Basename' => 0,
        'Digest::MD5' => 0,
        'Math::Expression' => 0,
        'List::Util' => 0,
        'Carp' => 0, # core since 5.6
        'YAML' => 0.62,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Hardware-Vhdl-Automake-*' },
);
