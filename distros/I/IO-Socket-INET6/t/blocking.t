#!/usr/bin/perl

use strict;
use warnings;

use Config;

BEGIN {
    if (-d "lib" && -f "TEST") {
	my $reason;
	if ($Config{'extensions'} !~ /\bSocket\b/) {
	    $reason = 'Socket extension unavailable';
	}
	elsif ($Config{'extensions'} !~ /\bIO\b/) {
	    $reason = 'IO extension unavailable';
	}
	if ($reason) {
	    print "1..0 # Skip: $reason\n";
	    exit 0;
        }
    }
    if ($^O eq 'MSWin32') {
        print "1..0 # Skip: accept() fails for IPv6 under MSWin32\n";
        exit 0;
    }
}

use Test::More;

plan tests => 2;

use IO::Socket::INET6;

my $listen = IO::Socket::INET6->new(Listen => 2,
				Proto => 'tcp',
				Timeout => 15,
				Blocking => 0,
			       ) or die "$@";

# TEST
is($listen->blocking(), 0, 'Non-blocking works on listeners');

my $port = $listen->sockport;

if(my $pid = fork()) {
    # Connect to ourselves with a non-blocking socket
    my $sock = IO::Socket::INET6->new(PeerAddr => '::1',
				PeerPort => $port,
				Blocking => 0);
    # TEST
    is($sock->blocking(), 0, 'Non-blocking works on outbound connections');

    undef($sock);
} elsif (defined $pid) {
    my $sock = $listen->accept();
    my $line = <$sock>;
    $listen->close;
    exit;
} else {
    die $!;
}


