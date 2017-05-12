#!/usr/bin/perl -w

# Copyright (C) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>.

# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with GNU Emacs; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

# tag: basic JOAP server example using test server

use lib '../t/lib';
use lib '..';

use strict;
use warnings;
use Getopt::Long;
use MyServer;

sub usage {
    print STDERR "Usage: myserver.pl --hostname [HOSTNAME] --port [PORT] --name [NAME] --secret [SECRET]\n";
}

sub main {

    my $hostname = undef;
    my $port = undef;
    my $name = undef;
    my $secret = undef;
    my $help = undef;

    GetOptions ("hostname=s" => \$hostname,
                "port=i" => \$port,
                "name=s" => \$name,
                "help" => \$help,
                "secret=s" => \$secret);

    if ($help) {
        usage();
        exit(0);
    }

    if (!$hostname) {
        # we assume the hostname is everything after the first dot
        my @parts = split(/\./, $name, 2);
        $hostname = $parts[1];
    }

    my $srv = new MyServer(debuglevel => 0, debugtime => 1);

    $srv->execute(hostname => $hostname,
                  port => $port,
                  componentname => $name,
                  secret => $secret,
                  connectiontype => 'accept');
}

&main();
