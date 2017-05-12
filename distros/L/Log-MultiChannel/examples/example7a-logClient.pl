#!/usr/bin/perl
#
# This example will echo logged messages to a remove
# server using a socket and a simple custom printHandler.
#
# To use it, start the example server (example7b-logServer.pl)
#
# -------------------- Notice ---------------------
# Copyright 2014 Paul LaPointe
# www.PaullaPointe.com/CommonProject
# This program is dual licensed under the (Perl) Artistic License 2.0,
# and the GNU General Public License 3.0 (GPL).
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License 3.0 for more details.
# You should have received a copy of the GNU General Public License 3.0
# in the licenses directory along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 
# You should have received a copy of the Artistic License 2.
# in the licenses directory along with this program.  If not, see
# <http://directory.fsf.org/wiki/License:ArtisticLicense2.0/>.
# 
# -------------------- End Notice ---------------------
use strict;
use Socket;
use Log::MultiChannel qw (Log);
use IO::Socket;
use IO::Select;
use Term::ReadKey;

my $address="127.0.0.1";
my $port=9001;
# Read any arguments passed to the script

# Open a socket to the agent

# create a connecting socket
my $sock = new IO::Socket::INET ( PeerHost => $address, PeerPort => $port,    Proto => 'tcp' );
die "Cannot connect to the log server $!\n" unless $sock;
print "Connected to $address:$port.\n";
print $sock "Remote client connected\n";

# Open two logs - one local and one remote (using the connected socket handle)
my $localLog="example7-Here.log";
my $remoteLog='Remote logger';
Log::MultiChannel::startLogging($localLog);
Log::MultiChannel::startLoggingOnHandle($remoteLog,$sock,\&sendLogMessage); # Open a second log, using the &sendLogMessage fn

# Map the channel 'INFO' to both logs
Log::MultiChannel::mapChannel('ERR',$localLog,$remoteLog);

# Main loop
while (1) {
    print ">";
    chomp(my $line=<STDIN>);
    if ($line=~/exit/i) {
	Log::MultiChannel::closeLogs();
	close($sock);
	exit 0;
    }
    else {
	&Log('ERR',$line); 
    }
}
exit (0);

# This will send a command to the agent
# These are the args:
# 0 - Epoch Time
# 1 - Local Time as a string
# 2 - Real Filehandle
# 3 - The Log object
# 4 - source module
# 5 - source filename
# 6 - source line #
# 7 - desired color
# 8 - channel name
# 9 - message
# 10 - Severity
# 11 - System
# 12 - Object
sub sendLogMessage() {
    my $channel=$_[8];
    my $line=$_[9];

    if ($sock) {
        # Send the command to the agent
        print $sock "$channel~$line\n";
    }
    else {
	Log('ERR','Client is not connected to the log server.');
    }
}

