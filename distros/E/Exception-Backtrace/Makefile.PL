use 5.018;
use warnings;
use XS::Install;

my %params = (
    NAME          => 'Exception::Backtrace',
    TEST_REQUIRES => {'Test::More' => 0, 'Test::Warnings' => 0},
    CPLUS         => 11,
    SRC           => ['src'],
    INC           => '-Isrc',
    BIN_DEPS      => ['XS::Framework', 'XS::libpanda', 'XS::libdwarf'],
    BIN_SHARE     => {INCLUDE  => {'src' => '/'}},
    CCFLAGS       => '-Wall -Wextra',
    test          => {
        SRC => 't',
    },
    MIN_PERL_VERSION => '5.20.0',
);

if ($ENV{SANITIZE}) {
    ($params{CCFLAGS}||='') .= ' -fsanitize=undefined -fsanitize=address -fno-omit-frame-pointer';
    $params{LIBS}[1] .= ' -lubsan -lasan';
    $params{LIBS}[0] .= ' -lubsan -lasan';
}

write_makefile(%params);

