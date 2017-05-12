#! /usr/bin/env perl
use strict;
use warnings;
use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update/;

my $id = $ARGV[0] // 0;
die "usage: ./04_destory.pl LOCKID\n" if (!$id || $id !~ /^\d+$/);

var_destory($id);
