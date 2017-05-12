#!/usr/local/bin/perl

use warnings;
use strict;

#use lib '.';
use IPC::Fork::Simple qw/:block_flags/;
use Data::Dumper;

my $ipc = IPC::Fork::Simple->new();
my $master_pid = $$;
my $pid = fork();
die 'stupid fork' unless defined $pid;

if ( $pid ) {
    warn "master waiting for child to send connection info";
    my $child_connection_data;

    $ipc->process_child_data(BLOCK_UNTIL_DATA);
    $child_connection_data = $ipc->from_child( $pid, 'connection_info' );

    warn "master got connection data!";

    my $ipc2 = IPC::Fork::Simple->new_child( ${$child_connection_data} ) || die;

    $ipc2->to_master( 'master_test', 'a' x 300 );
    warn "master exiting";

} else {
    $ipc->init_child();

    warn "child starting";
    my $ipc2 = IPC::Fork::Simple->new();
    $ipc2->spawn_data_handler();
    $ipc->to_master( 'connection_info', $ipc2->get_connection_info() ) || die $!;
    warn "child waiting for master to reply";
    my $test;

    do {
        sleep(0);
        $ipc2->collect_data_from_handler(1);
        $test = $ipc2->from_child( $master_pid, 'master_test' )
    } until ( $test );

    die unless length( ${$test} ) == 300;
}
