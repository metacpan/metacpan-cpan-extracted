#!/usr/local/bin/perl

use warnings;
use strict;

#use lib '.';
use IPC::Fork::Simple;
use POSIX ":sys_wait_h";

my $ipc = IPC::Fork::Simple->new();

my $pid = fork();
die 'stupid fork' unless defined $pid;

if ( $pid ) {
    $ipc->process_child_data(1);
    my @fin = $ipc->finished_children();
    die unless 300 == length(${$ipc->pop_from_child( $pid, 'test' )});
    die unless 301 == length(${$ipc->pop_from_child( $pid, 'test' )});
    die unless 302000 == length(${$ipc->pop_from_cid( $fin[0], 'test' )});
} else {
    $ipc->init_child();
    #$ipc->to_master( 'test', 'a' x 3009460 ) || die $!;
    $ipc->push_to_master( 'test', 'a' x 300 ) || die $!;
    $ipc->push_to_master( 'test', 'b' x 301 ) || die $!;
    $ipc->push_to_master( 'test', 'c' x 302000 ) || die $!;
}
