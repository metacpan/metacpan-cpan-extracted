use 5.012;
use XS::Install;

my $cmake_project = "panda-encode-base2n";
my $cmake_tests   = "$cmake_project-tests";

write_makefile(
    NAME      => 'Encode::Base2N',
    CPLUS     => 11,
    CCFLAGS   => '-Wall -Wextra',
    PREREQ_PM => {'Export::XS' => 0},
    BIN_DEPS  => 'XS::libpanda',
    BIN_SHARE => 1,
    CLIB      => {
        DIR          => 'clib',
        CMAKE_TARGET => $cmake_project,
        FILE         => "lib${cmake_project}.a",
    },
    test      => {
        BIN_DEPS => 'Test::Catch',
        CLIB     => {
            DIR          => 'clib',
            CMAKE_TARGET => "${cmake_tests}",
            FILE         => "lib${cmake_tests}.a",
        },
    },
);
