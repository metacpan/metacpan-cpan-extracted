use strict;
use XS::Install;

write_makefile(
    NAME          => 'Export::XS',
    CPLUS         => 11,
    SRC           => 'src',
    INC           => '-Isrc',
    CCFLAGS       => '-Wall -Wextra',
    TEST_REQUIRES => {'Test::Exception' => 0},
    BIN_DEPS      => 'XS::Framework',
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
);
