use 5.026;
use XS::Install;

write_makefile(
    NAME      => 'Linux::Capabilities',
    CPLUS     => 11,
    SRC       => ['src'],
    INC       => '-Isrc',
    LIBS      => ['-lcap'],
    BIN_DEPS  => ['Panda::Export', 'XS::Framework'],
    BIN_SHARE => {INCLUDE   => {src => '/'}},
    CCFLAGS   => '-Wall -Wextra',
);