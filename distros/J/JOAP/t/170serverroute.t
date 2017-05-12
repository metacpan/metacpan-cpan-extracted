#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server subclass message routing

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


use Test::More tests => 55;

use Net::Jabber qw(Client);
use MyServer;

$SRC = "User\@example.net/Client";
$DEST = "joap.example.com";
$DESTCLASS = "Person\@joap.example.com";

$GIVEN = 'Evan';
$FAMILY = 'Prodromou';
$BD = '1968-10-14T07:32:00-07:00';

my $srv = new MyServer;

# describe server

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_describe_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $desc = $iq->NewQuery($JOAP::NS, 'describe');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a describe result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    my @classes = $qry->GetClass;

    is ($classes[0], $DESTCLASS, 'Right address for classes');
}

# describe class

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_describe_2';

    $iq->SetTo($DESTCLASS);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $desc = $iq->NewQuery($JOAP::NS, 'describe');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a describe result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DESTCLASS, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    my @attrs = $qry->GetAttributeDescription;
    my %attrs = map {($_->GetName, $_)} @attrs;

    ok($attrs{'given_name'}, "Has the given name attribute.");
}

# add instance

$added = undef;

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_1';

    $iq->SetTo($DESTCLASS);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $FAMILY);
    $add->AddAttribute(name => 'birthdate')->AddValue(datetime => $BD);

    my $res = $srv->on_joap($iq);

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DESTCLASS, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    $added = $qry->GetNewAddress;

    ok($added, "Could add an instance");
}

# read instance

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_1';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    my @attrib = $qry->GetAttribute();
    my %attrib = map { ($_->GetName, $_) } @attrib;

    ok(exists $attrib{'family_name'}, "Has the family name attribute");
}

# non-existent class

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_describe_2';

    my $destclass = "non-existent-class\@$DEST";

    $iq->SetTo($destclass);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $desc = $iq->NewQuery($JOAP::NS, 'describe');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a describe result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $destclass, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 404, "Error code is correct");
}

# instance of non-existent class

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_2';

    my $destinst = "non-existent-class\@$DEST/non-existent-instance";

    $iq->SetTo($destinst);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $desc = $iq->NewQuery($JOAP::NS, 'read');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a describe result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $destinst, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 404, "Error code is correct");
}

# non-existent instance of (good) class

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_2';

    my $destinst = "$DESTCLASS/non-existent-instance";

    $iq->SetTo($destinst);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $desc = $iq->NewQuery($JOAP::NS, 'read');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a describe result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $destinst, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 404, "Error code is correct");
}

# delete instance

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_delete_1';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $delete = $iq->NewQuery($JOAP::NS, 'delete');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a delete result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'delete', "Returned query has delete tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# read deleted instance

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_2';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $desc = $iq->NewQuery($JOAP::NS, 'read');

    my $res = $srv->on_joap($iq);

    ok($res, "Got a describe result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 404, "Error code is correct");
}
