package Linux::Perl::inotify::arm;

use strict;
use warnings;

use parent qw( Linux::Perl::inotify );

use constant {
    NR_inotify_init => 316,
    NR_inotify_add_watch => 317,
    NR_inotify_rm_watch => 318,
    NR_inotify_init1 => 360,
};

1;

