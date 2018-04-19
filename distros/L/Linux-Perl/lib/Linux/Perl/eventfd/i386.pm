package Linux::Perl::eventfd::x86_64;

use strict;
use warnings;

use parent 'Linux::Perl::eventfd';

use Linux::Perl::Constants::i386;

use constant {
    NR_eventfd  => 323,
    NR_eventfd2 => 328,

    flag_SEMAPHORE => 1,
};

*flag_CLOEXEC = *Linux::Perl::Constants::i386::flag_CLOEXEC;
*flag_NONBLOCK = *Linux::Perl::Constants::i386::flag_NONBLOCK;

1;
