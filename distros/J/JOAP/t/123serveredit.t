#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server subclass <edit> handling

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


use Test::More tests => 36;

use Net::Jabber qw(Client);
use MyServer;

$SRC = "User\@example.net/Client";
$DEST = "joap.example.com";
$LOGLEVEL = 42;

my $srv = new MyServer;

# edit one attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'logLevel')->AddValue(i4 => $LOGLEVEL);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a edit result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# read after edit

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_read_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('logLevel');

    my $res = $srv->on_read($iq);

    my $qry = $res->GetQuery;

    my @attrib = $qry->GetAttribute();

    my %attrib = map { ($_->GetName, $_) } @attrib;

    is($attrib{'logLevel'}->GetValue->GetI4, $LOGLEVEL,
	"Value for logLevel attribute is what we set");
}

# edit read-only value

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    # Try to set back time

    $edit->AddAttribute(name => 'time')->AddValue(datetime => '19761014T120000Z');

    my $res = $srv->on_iq($iq);

    ok($res, "Got a edit result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 403, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# edit non-existent attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_3';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'non_existent_attribute')->AddValue(double => 1.1);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a edit result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# edit with bad value

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_4';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'logLevel')->AddValue(double => 3.3);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a edit result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}
