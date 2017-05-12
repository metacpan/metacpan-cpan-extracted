use strict;
use warnings;

use Test::More tests => 4;
use POSIX qw(uname SIGHUP);
use Linux::Prctl qw(:constants :functions);

my $arch = uname;

SKIP: {
    skip "get_fpemu/set_fpemu are ia64 specific", 4, unless $arch eq 'ia64';
    for(FPEMU_NOPRINT, FPEMU_SIGFPE) {
        is(set_fpemu($_), 0, "Setting fpemu to $_");
        is(get_fpemu, $_, "Checking whether fpemu is $_");
    }
}
