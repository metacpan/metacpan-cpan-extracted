use strict;
use warnings;

use Test::More tests => 4;
use POSIX qw(uname);
use Linux::Prctl qw(:constants :functions);

my $arch = uname;

SKIP: {
    skip "get_unalign/set_unalign are ia64 specific", 4, unless $arch eq 'ia64';
    for(UNALIGN_NOPRINT, UNALIGN_SIGBUS) {
        is(set_unalign($_), 0, "Setting unalign to $_");
        is(get_unalign, $_, "Checking whether unalign is $_");
    }
}
