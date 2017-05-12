#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
BEGIN { push @INC, "." }
use t::helper;

my $child = fork();

if (! $child) {
    # I am the child
    close STDIN;
    close STDOUT;
    close STDERR;
    mkdir $mountpt;
    
    exec "perl -Iblib/lib -Iblib/arch t/filesystem.pl $mountpt";
    exit 1;
}

# I am the parent
diag("pid $child started");

my $n=0;
while ($n++ < 100) {
    last if -e "$mountpt/a";
    select(undef, undef, undef, 0.2);
}

diag("mounting $mountpt took ".($n*0.2)."s");

ok( -e "$mountpt/a", "mounted");
