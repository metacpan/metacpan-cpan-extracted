use strict;
no strict 'subs';
use warnings;

use Test::More tests => 4;
use POSIX qw(uname);
use Linux::Prctl qw(:constants :functions);

my $arch = uname;

SKIP: {
    skip "get_tsc/set_tsc are x86 specific", 4 unless $arch =~ /^i.86$/;
    skip "get_tsc not available", 4 unless Linux::Prctl->can('set_tsc');
    for(TSC_ENABLE, TSC_SIGSEGV) {
        is(set_tsc($_), 0, "Setting tsc to $_");
        is(get_tsc, $_, "Checking whether tsc is $_");
    }
}
