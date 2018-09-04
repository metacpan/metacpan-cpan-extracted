package Linux::Perl::inotify::x86_64;

use strict;
use warnings;

use parent qw( Linux::Perl::inotify );

use constant {
    NR_inotify_init => 253,
    NR_inotify_add_watch => 254,
    NR_inotify_rm_watch => 255,
    NR_inotify_init1 => 294,
};

1;
