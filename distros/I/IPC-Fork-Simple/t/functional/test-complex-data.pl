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
    my $kid;
    $ipc->process_child_data( 1 );
    warn scalar( $ipc->finished_children() );
    warn Dumper $ipc->from_child( $pid, 'test' );
} else {
    $ipc->init_child();
    #$ipc->to_master( 'test', 'a' x 3009460 ) || die $!;
    $ipc->to_master( 'test', { hash => [ 0,1,2,3,4 ], hash2 => 2 } ) || die $!;
}
warn "exiting!";
