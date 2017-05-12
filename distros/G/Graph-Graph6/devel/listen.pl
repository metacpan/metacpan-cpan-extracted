#!/usr/bin/perl -w

# Copyright 2015 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Socket;

$| = 1;
socket(my $socket, Socket::PF_INET, Socket::SOCK_STREAM, 0)
  or die "socket(): $!";

print "bind\n";
my $port = 10000;
bind($socket, Socket::pack_sockaddr_in($port, inet_aton("localhost")))
  or die "bind(): $!";

print "listen\n";
listen($socket, 1)
  or die "listen(): $!";

print "accept\n";
my $addr = accept(my $fh, $socket)
  or die "accept(): $!";

print "read\n";
my $str;
while (defined (sysread($fh, $str, 1024))) {
  print $str;
}
