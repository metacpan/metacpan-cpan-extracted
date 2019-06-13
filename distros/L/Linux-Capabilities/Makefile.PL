use 5.026;
use XS::Install;

write_makefile(
    NAME          => 'Linux::Capabilities',
    VERSION_FROM  => 'lib/Linux/Capabilities.pm',
    ABSTRACT_FROM => 'lib/Linux/Capabilities.pod',
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    LIBS          => ['-lcap'],
    BIN_DEPS      => ['Panda::Export', 'XS::Framework'],
    BIN_SHARE     => {
        CPLUS     => 11,
        INCLUDE   => {src => '/'},
    },
    CCFLAGS       => '-Wall -Wextra',
    test          => {SRC => 't'},
);