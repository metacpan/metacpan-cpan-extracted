#!/usr/bin/perl

use strict;
use warnings;

use Config;

BEGIN {
    if (-d "lib" && -f "TEST") {
	my $reason;
	if (! $Config{'d_fork'}) {
	    $reason = 'no fork';
	}
	elsif ($Config{'extensions'} !~ /\bSocket\b/) {
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

use IO::Socket::INET6;

my $listen = IO::Socket::INET6->new(Listen => 2,
				Proto => 'tcp',
				# some systems seem to need as much as 10,
				# so be generous with the timeout
				Timeout => 15,
			       ) or die "$@";

# TEST
my $sockhost = $listen->sockhost();


my $port = $listen->sockport;

if(my $pid = fork()) {
    my $sock = $listen->accept();
    my $line = <$sock>;
    $listen->close;
    exit;
} elsif (defined $pid) {

    plan tests => 4;
    # child, try various ways to connect
    my $sock = IO::Socket::INET6->new("[::1]:$port");

    # TEST
    ok ($sockhost, "Checking for sockhost() success");

    # TEST
    ok ($sock->peerhost(), "Checking for peerhost() success");

    # TEST
    is ($sock->sockflow(), 0, "Checking for sockflow() success");

    # TEST
    is ($sock->peerflow(), 0, "Checking for peerflow() success");

    print {$sock} "H\n";
    undef($sock);
} else {
    die $!;
}


