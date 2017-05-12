#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server Class subclass instance <edit> handling

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


use Test::More tests => 56;

use Net::Jabber qw(Client);
use MyPerson;

$SRC = "User\@example.net/Client";
$DEST = "Person\@joap.example.com";
$GIVEN = 'Evan';
$GIVEN2 = 'Evangelo';
$FAMILY = 'Prodromou';
$BD = '1968-10-14T07:32:00-07:00';
$BD2 = '1968-10-14T00:00:00Z';

# we create an instance just like in a real situation

$added = undef;
$inst = undef;

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
    my $qry = $res->GetQuery;

    $added = $qry->GetNewAddress;

    my $jid = new Net::Jabber::JID($added);
    my $instid = $jid->GetResource;

    $inst = MyPerson->get($instid);
}

# edit one attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_1';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'birthdate')->AddValue(datetime => $BD2);

    my $res = $inst->on_iq($iq);

    ok($res, "Got an edit result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
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

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('birthdate');

    my $res = $inst->on_iq($iq);

    my $qry = $res->GetQuery;

    my @attrib = $qry->GetAttribute();

    my %attrib = map { ($_->GetName, $_) } @attrib;

    is($attrib{'birthdate'}->GetValue->GetDateTime, $BD2,
	"Value for birthdate attribute is what we set");
}

# edit read-only value

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_2';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    # Try to set sign

    $edit->AddAttribute(name => 'sign')->AddValue(string => 'neon');

    my $res = $inst->on_iq($iq);

    ok($res, "Got an edit result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    is($res->GetErrorCode, 403, "Error code is correct one.");
}

# edit non-existent attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_3';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'non_existent_attribute')->AddValue(double => 1.1);

    my $res = $inst->on_iq($iq);

    ok($res, "Got an edit result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
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

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'birthdate')->AddValue(double => 3.3);

    my $res = $inst->on_iq($iq);

    ok($res, "Got an edit result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# edit class attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_5';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'population')->AddValue(i4 => 42);

    my $res = $inst->on_iq($iq);

    ok($res, "Got an edit result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");
}

# read after edit class

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_read_2';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('population');

    my $res = $inst->on_iq($iq);

    my $qry = $res->GetQuery;

    my @attrib = $qry->GetAttribute();

    my %attrib = map { ($_->GetName, $_) } @attrib;

    is($attrib{'population'}->GetValue->GetI4, 42,
	"Value for population attribute is what we set");
}

# edit ID attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_6';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'given_name')->AddValue(string => $GIVEN2);

    my $res = $inst->on_iq($iq);

    ok($res, "Got an edit result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'edit', "Returned query has edit tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok($qry->DefinedNewAddress, 'It has a new address');

    $added2 = $qry->GetNewAddress;
    my $jid = new Net::Jabber::JID($added2);
    my $instid = $jid->GetResource;

    $inst = MyPerson->get($instid);

    ok($inst, "Can get an instance with the new address.");
}

# read after edit ID

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_read_3';

    $iq->SetTo($added2);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('given_name');

    my $res = $inst->on_iq($iq);

    my $qry = $res->GetQuery;

    my @attrib = $qry->GetAttribute();

    my %attrib = map { ($_->GetName, $_) } @attrib;

    is($attrib{'given_name'}->GetValue->GetString, $GIVEN2,
	"Value for given_name attribute is what we set");
}
