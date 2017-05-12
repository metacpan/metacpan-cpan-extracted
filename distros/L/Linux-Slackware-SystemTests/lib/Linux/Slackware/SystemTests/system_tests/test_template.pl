#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use File::Valet;  # gives you file-slurping functions rd_f(), wr_f(), ap_f(), also find_bin() and some other things

use lib "./lib";
use Linux::Slackware::SystemTests;

my $st = Linux::Slackware::SystemTests->new();

# Copy a module file to /tmp or wherever when you need a writable file:
# my ($ok, $target_file) = $st->init_work_file("example.txt");
# BAIL_OUT("init_work_file failed: $target_file") unless ($ok eq 'OK');

# Put your tests here

# unlink($target_file);  # clean up any turds

done_testing();
exit 0;
