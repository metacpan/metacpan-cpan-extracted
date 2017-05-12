#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
BEGIN { push @INC, "." }
use t::helper;

if (!fork()) {
    # I am the child
    exec "fusermount", "-u", $mountpt;
}

my $n = 0;
while ($n++ < 100) {
    last unless -e "$mountpt/a";
    select(undef, undef, undef, 0.2);
}

diag("unmount $mountpt took ".($n*0.2)."s");

rmdir $mountpt;

ok (! -e "$mountpt/a", "unmounting $mountpt");
