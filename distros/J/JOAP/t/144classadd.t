#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server Class subclass <add> handling

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

use Test::More tests => 64;

use Net::Jabber qw(Client);
use MyPerson;

$SRC = "User\@example.net/Client";
$DEST = "Person\@joap.example.com";
$GIVEN = 'Evan';
$FAMILY = 'Prodromou';
$BD = '1968-10-14T07:32:00-07:00';

# add a new instance, with all required writables

$added = undef;

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $FAMILY);
    $add->AddAttribute(name => 'birthdate')->AddValue(datetime => $BD);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an add result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'add', "Returned query has add tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    $added = $qry->GetNewAddress;

    ok($added, "Can get the new address from the results.");
}

# get after add

{
    my $jid = new Net::Jabber::JID($added);
    my $instid = $jid->GetResource;

    my $inst = MyPerson->get($instid);

    ok($inst, "Can get the (recently added) instance");
}

# add without all required

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an add result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'add', "Returned query has add tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# add with non-existent attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_3';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $FAMILY);
    $add->AddAttribute(name => 'birthdate')->AddValue(dateTime.iso8601 => $BD);
    $add->AddAttribute(name => 'nonexistent_attribute')->AddValue(double => 3.3);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an add result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'add', "Returned query has add tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# add with non-writable attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_4';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $FAMILY);
    $add->AddAttribute(name => 'birthdate')->AddValue(dateTime.iso8601 => $BD);
    $add->AddAttribute(name => 'sign')->AddValue(string => 'aries');

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an add result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'add', "Returned query has add tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# add with bad value

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_5';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $FAMILY);
    $add->AddAttribute(name => 'birthdate')->AddValue(string => $BD); # bad value; should be datetime

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an add result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'add', "Returned query has add tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# add with class attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_6';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $FAMILY);
    $add->AddAttribute(name => 'birthdate')->AddValue(dateTime.iso8601 => $BD);
    $add->AddAttribute(name => 'population')->AddValue(i4 => 42);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an add result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'add', "Returned query has add tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# add with duplicate ID fields

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_7';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $FAMILY);
    $add->AddAttribute(name => 'birthdate')->AddValue(datetime => $BD);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an add result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'add', "Returned query has add tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}
