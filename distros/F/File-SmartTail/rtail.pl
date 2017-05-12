#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
#
# Cover for remote use of Tail.pm
# Will be called by a local Tail process if a file of type UNIX-REMOTE
# is specified.
# Called e.g.: rtail.pl -file somefile -heartbeat send -type UNIX
# Args are passed directly to WatchFile.
# See Tail.pm.
#
# $Id: rtail.pl,v 2.21 2008/07/03 20:30:58 mprewitt Exp $
# $Source: /usr/local/src/perllib/Tail/0.1/RCS/rtail.pl,v $
# $Locker:  $
#
# DMJA, Inc <mprewitt@dmja.com>
# 
# Copyright (C) 2003-2008 DMJA, Inc, File::SmartTail comes with 
# ABSOLUTELY NO WARRANTY. This is free software, and you are welcome to 
# redistribute it and/or modify it under the same terms as Perl itself.
# See the "The Artistic License" L<perlartistic> for more details.

use strict;

use IO::Socket;
use Getopt::Std;
use Sys::Hostname;
use Fcntl;
use File::SmartTail;

my %args = @ARGV;
if (exists $args{-help}) {
    die "Usage: $0 -file name -host host[-type UNIX -date parsed -heartbeat send -test yes -tietype [ DB_File | NDBM_File ] ]\n";
}

my $test = 0;
if (exists $args{-test}) {
    $test++;
    delete $args{-test};
}

my $tietype;
if (exists $args{-tietype}) {
    $tietype = $args{-tietype};
} else {
    $tietype = 'DB_File';
}

my ($port, $sock);
if (!$test) {
    if ( fork ) {
        #
        #  Parent.
        #
	wait;
	exit 0;
    } else {
	($port, $sock) = MakeSocket();
	die "failure creating socket [$!]\n"
	    unless $sock;
	
	$|=1;
	print "$port\n"; 
	close(STDIN);
	close(STDERR);
	close(STDOUT);
	if ( my $pid = fork ) {
            #
            #  Parent again.
            #
	    exit 0;
	}
    }
} else {
    #
    # We're testing, so make the socket outside the fork.
    #
    ($port, $sock) = MakeSocket();
    die "failure creating socket [$!]\n"
	unless $sock;

}

my $timeout = 45; # seconds

$SIG{ALRM} = \&timer;
$SIG{TERM} = $SIG{QUIT} = $SIG{HUP} = $SIG{PIPE} = \&cleanup;

my @newargs = ( '-tietype' => $tietype );
$args{-statuskey} and push @newargs, '-statuskey' => $args{-statuskey};
my $tail = new File::SmartTail( @newargs );

$tail->WatchFile(%args);

open (STDOUT, ">> /tmp/rtail.out.$$"); # Diagnostics.
open (STDERR, ">> /tmp/rtail.out.$$"); # Diagnostics.
chmod( 0700, "/tmp/rtail.out.$$" );

my $oldfh = select(STDOUT); $| = 1; select(STDERR); $| = 1; select($oldfh);

alarm $timeout;
my $new_sock = $sock->accept();
undef $sock;

$new_sock->autoflush(1);

alarm 0;

while (my $line = $tail->GetLine()) {
    print $new_sock $line || do {
	print STDERR "Print failed: $!\n";
	last;
    };
}

cleanup();

sub timer {
    print "peer did not connect within $timeout secs.\n";
    cleanup();
}

sub cleanup {
    print "SIGPIPE or timeout. cleaning up.\n";
    close($sock);
    close($new_sock);
    $File::SmartTail::STATFILE->sync if $File::SmartTail::STATFILE;
    close(STDOUT);
    exit 0;
}

sub MakeSocket {
    #
    # Seed random number with process id.
    #
    srand($$);
    #
    # Pick a port
    #
    my $port = int (rand(3073) + 1024);
    
    my $sock;
    for (my $i = 0; $i < 15; $i++) {
	$sock = new IO::Socket::INET(LocalPort => $port,
				     Proto => 'tcp',
				     Listen => 5,
				     Reuse => 1);
	if (defined $sock) {
	    last;
	    #
	    # EBADF here may mean port is in use. Try again.
	    #
	} elsif ($! =~ /^Bad file/) {
	    $port = int (rand(3073) + 1024);
	}
    }
    return ($port, $sock);
}


