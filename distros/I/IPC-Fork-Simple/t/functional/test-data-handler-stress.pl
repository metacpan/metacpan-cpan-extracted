#!/usr/local/bin/perl

use warnings;
use strict;

#use lib '.';
use IPC::Fork::Simple;
use Time::HiRes;
use Carp;

use constant MAX_CONCURRENT_FORKS => 500;
use constant TOTAL_FORKS => 100;
use constant FORK_SPAM => 4;

$SIG{INT}=sub{Carp::confess("INT");exit;};

my $ipc = IPC::Fork::Simple->new();
my $total_forks = 0;
my $running_forks = 0;
my @fork_pids;

sub make_fork {
    return unless $running_forks < MAX_CONCURRENT_FORKS;
    return unless $total_forks < TOTAL_FORKS;
    my $a = fork();
    if ( !defined $a ) { die "Failed to fork! $!"; }
    if ( !$a ) { do_child(); }
    push @fork_pids, $a;
    $running_forks++;
    $total_forks++;
}

sub do_child {
    $ipc->init_child();
    $0 = 'stress_fork';
    my $x = 0;
    srand($$);
    while( ++$x < FORK_SPAM ) {
        if ( int(rand(FORK_SPAM/2)) == 0 ) { $ipc->to_master( 'test'.rand(), 'a' x (int(rand(1024))) ) || die $!; }
        sleep( rand( 2 ) );
    }
    $ipc->to_master( 'test'.rand(), 'a' x (int(rand(1024))) ) || die $!;
    exit;
}

$ipc->spawn_data_handler();

for ( 1 .. ( int(MAX_CONCURRENT_FORKS / 4) ) ) { make_fork(); }

while($total_forks < TOTAL_FORKS) {
    if ( $total_forks % 2 == 0 ) { warn "Concurrent forks: $running_forks, Total: $total_forks\n"; }

    if ( $running_forks ) {
        wait();
        $running_forks--;
    }
    while ( int( rand( int( MAX_CONCURRENT_FORKS/10) ) ) == 0 ) {
        my $a = int(rand(int(MAX_CONCURRENT_FORKS/2)));
        for ( 1 .. $a ) { make_fork(); }
    }
}

warn "Waiting for last $running_forks forks to exit...\n";
while ( $ipc->finished_children() < $running_forks ) {sleep(0)};
while( $running_forks-- ) {
    wait();
}

warn "Collecting data...\n";

$ipc->collect_data_from_handler();
warn "Listing finished children\n";
my @ipc_finished = $ipc->finished_children();
if ( scalar( @ipc_finished ) != TOTAL_FORKS ) {
    die "Didn't get the right number of finished children, only got " .
        scalar( @ipc_finished ) .
        ", expected " .
        TOTAL_FORKS .
        "!\n";
}
warn "Success";
