use 5.012;
use XS::Install;

write_makefile(
    NAME      => 'Encode::Base2N',
    CPLUS     => 11,
    PREREQ_PM => {'Export::XS' => 0},
    BIN_DEPS  => 'XS::libpanda',
    SRC       => 'src',
    INC       => '-Isrc',
    BIN_SHARE => {INCLUDE => {'src' => '/'}},
    CCFLAGS   => '-Wall -Wextra',
);
