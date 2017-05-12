use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Gcode::Interpreter',
    AUTHOR           => q{Ralph Bolton <coofercat@cpan.org>},
    VERSION_FROM     => 'lib/Gcode/Interpreter.pm',
    ABSTRACT_FROM    => 'lib/Gcode/Interpreter.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Gcode-Interpreter-*' },
);
