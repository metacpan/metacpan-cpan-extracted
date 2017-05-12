#!/usr/local/bin/perl

use warnings;
use strict;

#use lib '.';
use IPC::Fork::Simple;
use Data::Dumper;
use POSIX ":sys_wait_h";
use Carp;

#$SIG{INT}=sub{Carp::confess("INT");exit;};

my $ipc = IPC::Fork::Simple->new();

my $pid = fork();

if ( $pid ) {
    my $kid;
    $ipc->spawn_data_handler();
#    warn "starting : " . time() . "\n";
    waitpid( $pid, 0 );
    $ipc->collect_data_from_handler();
    #warn ${$ipc->from_child( $pid, 'test' )};
#    warn "collection complete";
    die unless 300 == length(${$ipc->from_child( $pid, 'test' )});
} else {
    $ipc->init_child();
    #$ipc->to_master( 'test', 'a' x 3009460 ) || die $!;
    $ipc->to_master( 'test', 'a' x 300 ) || die $!;
}
