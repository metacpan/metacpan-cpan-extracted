use 5.018;
use XS::Install;

write_makefile(
    NAME      => 'Linux::Capabilities',
    CPLUS     => 11,
    SRC       => ['src'],
    INC       => '-Isrc',
    LIBS      => ['-lcap'],
    BIN_DEPS  => ['Export::XS', 'XS::Framework'],
    BIN_SHARE => {INCLUDE   => {src => '/'}},
    CCFLAGS   => '-Wall -Wextra',
    MIN_PERL_VERSION => '5.18.0',
);