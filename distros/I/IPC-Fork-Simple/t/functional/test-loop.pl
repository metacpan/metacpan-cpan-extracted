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
#    do {
#        $ipc->process_child_data(0);
#        sleep(0);
#    } while ( waitpid( -1, WNOHANG ) > 0 );
    while ( ! $ipc->finished_children() ) {
        $ipc->process_child_data(0);
        waitpid( -1, WNOHANG );
        sleep(0);
    }
    warn scalar( $ipc->finished_children() );
    warn length(${$ipc->from_child( $pid, 'test' )});
} else {
    $ipc->init_child();
    #$ipc->to_master( 'test', 'a' x 3009460 ) || die $!;
    $ipc->to_master( 'test', 'a' x 300 ) || die $!;
    undef $ipc;
    warn "child exiting!";
}
