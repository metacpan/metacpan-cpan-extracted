#! /usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Global::IPC::StaticVariable qw/var_append/;

my $id = $ARGV[0] // 0;
die "usage: ./02_worker.pl IPCID\n" if (!$id || $id !~ /^\d+$/);

my $i = 0;

while(1) {
    my $msg = sprintf "job %d\n", $i;
    var_append($id, $msg);
    print $msg;
    $i++;
}
