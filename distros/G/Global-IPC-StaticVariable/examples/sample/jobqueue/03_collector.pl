#! /usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Global::IPC::StaticVariable qw/var_getreset/;

my $id = $ARGV[0] // 0;
die "usage: ./03_collector.pl IPCID\n" if (!$id || $id !~ /^\d+$/);

while (1) {
    if (my $v = var_getreset($id)) {
        my @arr = split "\n", $v;
        for (@arr) {
            print "$_\n";
        }
    }
    usleep 10000;
}
