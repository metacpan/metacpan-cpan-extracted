#!/usr/bin/perl
#
# This example will echo logged messages to a remove
# server using a socket and a simple custom printHandler.
#
# This is the example server. To send messages to it,
# use the example client (example7a-logClient.pl)
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
use IO::Socket::INET;
use strict;
use Log::MultiChannel qw (Log);

my $remoteLog='example7-There.log';
Log::MultiChannel::startLogging($remoteLog);

# auto-flush on socket
$| = 1;
 
# creating a listening socket
my $address="127.0.0.1";
my $port=9001;
my $socket = new IO::Socket::INET (LocalHost => '0.0.0.0', LocalPort => $port, Proto => 'tcp', Listen => 5, Reuse => 1 );
die "cannot create socket $!\n" unless $socket;
print "Log server waiting for client connection on port $port\n";
 
while(1) {
    # Wait for a new client connection
    Log('INF','Waiting for a log client connection.');
    my $clientSocket = $socket->accept();
   
    my $data;
    while (($data ne 'exit') and ($clientSocket)) {
	Log('INF','Waiting for a log message.');
	chomp($data = $clientSocket->getline());
	if ($data=~/\A([^~]*)~(.*)/) {
	    my ($channel,$line)=($1,$2);
	    Log($channel,$line);
	}
    }
    doExit();
}
Log::MultiChannel::closeLogs();

sub doExit {
# Close and exit
    $socket->close();
    exit 0;
}



