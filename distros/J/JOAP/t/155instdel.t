#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server Class subclass instance <delete> handling

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
use MyPerson;

$SRC = "User\@example.net/Client";
$DEST = "Person\@joap.example.com";
$GIVEN = 'Evan';
$FAMILY = 'Prodromou';
$BD = '1968-10-14T07:32:00-07:00';

# we create an instance just like in a real situation

$added = undef;
$inst = undef;
$instid = undef;

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
    $instid = $jid->GetResource;

    $inst = MyPerson->get($instid);
}

# delete the instance
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_delete_1';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $delete = $iq->NewQuery($JOAP::NS, 'delete');

    my $res = $inst->on_iq($iq);

    ok($res, "Got an delete result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'delete', "Returned query has delete tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok (!MyPerson->get($instid), "Can no longer get the instance.");
}
