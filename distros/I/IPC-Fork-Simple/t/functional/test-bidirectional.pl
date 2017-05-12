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
    $ipc->process_child_data(BLOCK_UNTIL_DATA);

    my $child_connection_data = $ipc->from_child( $pid, 'connection_info' );
    die unless $child_connection_data;
    warn "master got connection data!";

    my $ipc2 = IPC::Fork::Simple->new_child( ${$child_connection_data} ) || die;

    $ipc2->to_master( 'master_test', 'a' x 300 );
    warn "master exiting";

} else {
    $ipc->init_child();

    warn "child starting";
    my $ipc2 = IPC::Fork::Simple->new();
    $ipc->to_master( 'connection_info', $ipc2->get_connection_info() ) || die $!;
    warn "child waiting for master to reply";
    $ipc2->process_child_data(BLOCK_UNTIL_DATA);
    die unless length( ${$ipc2->from_child( $master_pid, 'master_test' )} ) == 300;
}
