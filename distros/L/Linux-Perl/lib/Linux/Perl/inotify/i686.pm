package Linux::Perl::inotify::i686;

use strict;
use warnings;

use parent qw( Linux::Perl::inotify );

use constant {
    NR_inotify_init => 291,
    NR_inotify_add_watch => 292,
    NR_inotify_rm_watch => 293,
    NR_inotify_init1 => 332,
};

1;
