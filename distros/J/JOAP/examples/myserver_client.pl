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

# tag: base JOAP server example client with raw IQ

use strict;
use warnings;

use lib '..';

use Getopt::Long;
use Net::Jabber qw(Client);
use JOAP;

sub describe_server;
sub describe_class;
sub read_server;

sub usage {
    print STDERR "Usage: myserver.pl --username [HOSTNAME] --server [SERVER] --port [PORT] --resource [RESOURCE] --password [PASSWORD]\n";
}

sub main {

    my $username = undef;
    my $server = undef;
    my $port = 5222;
    my $resource = "MyServerClient";
    my $help = undef;
    my $password = undef;

    GetOptions ("username=s" => \$username,
                "server=s" => \$server,
                "port=i" => \$port,
                "resource=s" => \$resource,
                "password=s" => \$password,
                "help" => \$help);

    if ($help) {
        usage();
        exit(0);
    }

    my $con = new Net::Jabber::Client();

    my $status = $con->Connect(hostname => $server,
                               port => $port);

    if (!(defined($status))) {
        print "ERROR:  Jabber server is down or connection was not allowed.\n";
        print "        ($!)\n";
        exit(0);
    }

    my @result = $con->AuthSend(username => $username,
                                password => $password,
                                resource => $resource);

    if ($result[0] ne "ok") {
        print "ERROR: Authorization failed: $result[0] - $result[1]\n";
        exit(0);
    }

    $con->RosterGet();
    $con->PresenceSend();

    describe_server($con);
    describe_class($con);
    read_server($con);

    $con->Disconnect;
}

sub describe_server {

    my $con = shift;

    my $desc = new Net::Jabber::IQ;
    $desc->SetIQ(to => 'joap.localhost', type => 'get');

    $desc->NewQuery($JOAP::NS, 'describe');

    my $desc_res = $con->SendAndReceiveWithID($desc);

    print $desc_res->GetXML, "\n";
}

sub describe_class {

    my $con = shift;

    my $desc = new Net::Jabber::IQ;
    $desc->SetIQ(to => 'Person@joap.localhost',
                  type => 'get');

    $desc->NewQuery($JOAP::NS, 'describe');

    my $desc_res = $con->SendAndReceiveWithID($desc);

    print $desc_res->GetXML, "\n";
}

sub read_server {

    my $con = shift;

    my $read = new Net::Jabber::IQ;
    $read->SetIQ(to => 'joap.localhost', type => 'get');

    $read->NewQuery($JOAP::NS, 'read');

    my $read_res = $con->SendAndReceiveWithID($read);

    print $read_res->GetXML, "\n";
}

&main();

