use strict;
no strict 'subs';
use warnings;

use Test::More tests => 20;
use POSIX qw(uname SIGHUP);
use Linux::Prctl qw(:constants :functions);

my $arch = uname;

SKIP: {
    skip "get_fpexc/set_fpexc are powerpc specific", 20 unless $arch eq 'powerpc';
    for(FP_EXC_SW_ENABLE, FP_EXC_DIV, FP_EXC_OVF, FP_EXC_UND, FP_EXC_RES, FP_EXC_INV, FP_EXC_DISABLED, FP_EXC_NONRECOV, FP_EXC_ASYNC, FP_EXC_PRECISE) {
        is(set_fpexc($_), 0, "Setting fpexc to $_");
        is(get_fpexc, $_, "Checking whether fpexc is $_");
    }
}
