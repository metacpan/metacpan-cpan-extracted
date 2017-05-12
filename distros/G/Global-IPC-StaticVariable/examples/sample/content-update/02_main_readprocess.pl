#! /usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update/;

my $id = $ARGV[0] // 0;
die "usage: ./02_main_readprocess.pl IPCID\n" if (!$id || $id !~ /^\d+$/);

while(1) {
    if (my $v = var_read($id)) {
        print "read value: $v\n";
    }
    usleep(100000);
}
