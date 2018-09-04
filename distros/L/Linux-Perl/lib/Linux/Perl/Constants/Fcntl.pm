package Linux::Perl::Constants::Fcntl;

use strict;
use warnings;

use constant {
    flag_CLOEXEC => 524288,
    flag_NONBLOCK => 2048,

    flag_CREAT => 64,
    flag_EXCL => 128,

    mode_RDONLY => 0,
    mode_WRONLY => 1,
    mode_RDWR => 2,
};

1;
