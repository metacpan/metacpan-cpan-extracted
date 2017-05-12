#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server Class subclass <read> handling

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


use Test::More tests => 62;

use Net::Jabber qw(Client);
use MyPerson;

$SRC = "User\@example.net/Client";
$DEST = "Person\@joap.example.com";

# read all
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'read', "Returned query has read tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok($qry->DefinedTimestamp, "Has a timestamp.");
    like($qry->GetTimestamp,
         qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/,
         "It looks like a timestamp.");

    my @attrib = $qry->GetAttribute();

    ok(@attrib, "Can get attributes.");

    my %attrib = map { ($_->GetName, $_) } @attrib;

    ok($attrib{'species'}, "Has the species attribute.");
    ok($attrib{'species'}->DefinedValue, "Has a value for species attribute");
    ok($attrib{'species'}->GetValue->DefinedString, "Value for species attribute is right type");

    ok($attrib{'population'}, "Has the population attribute.");
    ok($attrib{'population'}->DefinedValue, "Has a value for population attribute");
    ok($attrib{'population'}->GetValue->DefinedI4, "Value for population attribute is right type");

    ok(!exists $attrib{'given_name'}, "Doesn't have the instance given name attribute");
    ok(!exists $attrib{'family_name'}, "Doesn't have the instance family name attribute");
    ok(!exists $attrib{'birthdate'}, "Doesn't have the instance birthdate attribute");
    ok(!exists $attrib{'age'}, "Doesn't have the instance age attribute");
    ok(!exists $attrib{'sign'}, "Doesn't have the instance sign attribute");
}

# read some
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('population');

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'read', "Returned query has read tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok($qry->DefinedTimestamp, "Has a timestamp.");
    like($qry->GetTimestamp,
         qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/,
         "It looks like a timestamp.");

    my @attrib = $qry->GetAttribute();

    ok(@attrib, "Can get attributes.");

    my %attrib = map { ($_->GetName, $_) } @attrib;

    ok($attrib{'population'}, "Has the population attribute.");
    ok($attrib{'population'}->DefinedValue, "Has a value for population attribute");
    ok($attrib{'population'}->GetValue->DefinedI4, "Value for population attribute is right type");

    ok(!exists $attrib{'given_name'}, "Doesn't have the instance given name attribute");
    ok(!exists $attrib{'family_name'}, "Doesn't have the instance family name attribute");
    ok(!exists $attrib{'birthdate'}, "Doesn't have the instance birthdate attribute");
    ok(!exists $attrib{'age'}, "Doesn't have the instance age attribute");
    ok(!exists $attrib{'sign'}, "Doesn't have the instance sign attribute");
    ok(!exists $attrib{'species'}, "Doesn't have the unrequested species attribute");
}

# read with a non-existent name
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_3';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('population');
    $read->SetName('a_nonexistent_attribute');

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");

    is($qry->GetTag, 'read', "Returned query has read tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok(!$qry->DefinedAttribute, "No attributes defined");
}

# read with an instance name
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_4';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('population');
    $read->SetName('birthdate');

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");

    is($qry->GetTag, 'read', "Returned query has read tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok(!$qry->DefinedAttribute, "No attributes defined");
}
