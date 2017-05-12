#! /usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update/;

my $id = $ARGV[0] // 0;
die "usage: ./03_update_process.pl IPCID\n" if (!$id || $id !~ /^\d+$/);

for(0..10000) {
    var_update($id, $_);
    usleep 100000;
}
