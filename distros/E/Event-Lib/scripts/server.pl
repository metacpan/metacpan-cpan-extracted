#! /usr/bin/perl -w

use strict;
use POSIX qw/SIGHUP/;
use IO::Socket::INET;
use Event::Lib;

$| = 1;

# invoked when a new client connects to us
sub handle_incoming {
    my $e = shift;
    my $h = $e->fh;
    
    my $client = $h->accept or die "Should not happen";
    $client->blocking(0);

    # set up a new event that watches the client socket
    my $event = event_new($client, EV_READ|EV_PERSIST, \&handle_client);
    $event->add;
}

# invoked when the client's socket becomes readable
sub handle_client {
    my $e = shift;
    my $h = $e->fh;
    printf "Handling %s:%s\n", $h->peerhost, $h->peerport;
    while (<$h>) {
	print "\t$_";
	if (/^quit$/) {
	    # this client says goodbye
	    close $h;
	    $e->del;
	    last;
	}
    }
}	
    
my $secs;
sub show_time {
    my $e = shift;
    print "\r", $secs++;
    $e->add;
}

# do something when receiving SIGHUP
sub sighup {
    my $e = shift;
    print "Received SIGHUP\n";
    # a common thing to do would be
    # re-reading a config-file or so
}

# create a listening socket
my $server = IO::Socket::INET->new(
    LocalAddr   => 'localhost',
    LocalPort   => 9000,
    Proto	=> 'tcp',
    ReuseAddr   => SO_REUSEADDR,
    Listen	=> 1,
    Blocking    => 0,
) or die $!;
  
my $main  = event_new($server, EV_READ|EV_PERSIST, \&handle_incoming);
my $timer = timer_new(\&show_time);
my $hup   = signal_new(SIGHUP, \&sighup);

$_->add for $main, $timer, $hup;

$main->dispatch;
