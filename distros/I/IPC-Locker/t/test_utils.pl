#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Common routines required by package tests
#
# Copyright 1999-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use IO::File;
use IO::Socket;
use Sys::Hostname;
use vars qw($PERL);

$PERL = "$^X -Iblib/arch -Iblib/lib";

if (!$ENV{HARNESS_ACTIVE}) {
    use lib '.';
    use lib '..';
    use lib "blib/lib";
    use lib "blib/arch";
}

######################################################################
# Run

sub run_rtn {
    my $cmd = shift;
    print "\t$cmd\n";
    my $rtn = `$cmd`;
    chomp $rtn;
    print "\treturns: $rtn\n";
    return $rtn;
}

######################################################################
# Socket subroutines

sub socket_find_free {
    my $port = shift;	# Port # to start looking on

    for (; $port<(1<<15); $port++) {
	print "Looking for free port $port\n" if $Debug;
	my $fh;
	$fh = IO::Socket::INET->new( Proto     => "tcp",
				     PeerAddr  => hostname(),
				     PeerPort  => $port,
				     Timeout   => 0.1,
				     );
	if ($fh) { # Port exists, try again
	    $fh->close();
	    next;
	}
	$fh = IO::Socket::INET->new( Proto     => 'tcp',
				     LocalPort => $port,
				     Listen    => SOMAXCONN,
				     Reuse     => 0);
	if ($fh) {
	    $fh->close();
	    return $port;
	}
    }
    die "%Error: Can't find free socket port\n";
}

1;
