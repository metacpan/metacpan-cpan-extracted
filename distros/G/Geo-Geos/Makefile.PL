use 5.018;
use Config;
use XS::Install;

my %params = (
    NAME          => 'Geo::Geos',
    TEST_REQUIRES => {'Test::More' => 0, 'Test::Fatal' => 0, 'Test::Warnings' => 0, 'File::Find::Rule' => 0},
    CPLUS         => 11,
    SRC           => ['src', 'xsi', 'xsi/algorithm', 'xsi/noding'],
    INC           => '-Isrc',
    BIN_DEPS      => ['XS::Framework', 'Export::XS', 'Alien::libgeos'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra -DUSE_UNSTABLE_GEOS_CPP_API',
);

write_makefile(%params);

