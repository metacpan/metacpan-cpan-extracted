#!/usr/local/bin/perl

use warnings;
use strict;

#use lib '.';
use IPC::Fork::Simple;
use Data::Dumper;
use POSIX ":sys_wait_h";

my $ipc = IPC::Fork::Simple->new();

my $pid = fork();
die 'stupid fork' unless defined $pid;

if ( $pid ) {
    $ipc->process_child_data(1);
    my @finished = $ipc->finished_children();
    die unless 1 == scalar( $ipc->finished_children() );
    die unless 300 == length(${$ipc->from_child( $pid, 'test' )});
    die unless 300 == length(${$ipc->from_cid( $finished[0], 'test' )});
} else {
    $ipc->init_child();
    $ipc->to_master( 'test', 'a' x 300 ) || die $!;
}
