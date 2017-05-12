#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server subclass <add> handling

# Copyright (c) 2003, Evan Prodromou <evan@prodromou.san-francisco.ca.us>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA


use Test::More tests => 9;

use Net::Jabber qw(Client);
use MyServer;

$SRC = "User\@example.net/Client";
$DEST = "joap.example.com";
$LOGLEVEL = 42;

my $srv = new MyServer;

$srv, "Can make a MyServer";

# add (erroneously) a server

my $iq = new Net::Jabber::IQ;
my $ID = 'joap_add_1';

$iq->SetTo($DEST);
$iq->SetFrom($SRC);
$iq->SetID($ID);
$iq->SetType('set');

my $add = $iq->NewQuery($JOAP::NS, 'add');

$add->AddAttribute(name => 'logLevel')->AddValue(i4 => $LOGLEVEL);

my $res = $srv->on_iq($iq);

ok($res, "Got a add result.");

is($res->GetType, "error", "It's an error result.");
is($res->GetID, $ID, "ID came back correct.");
is($res->GetFrom, $DEST, "from is right.");
is($res->GetTo, $SRC, "to is right.");

my $qry = $res->GetQuery;

is($res->GetErrorCode, 405, "Error code is correct.");

ok($qry, "Can get the query.");
is($qry->GetTag, 'add', "Returned query has add tag.");
is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

