#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server Class subclass instance <read> handling

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


use Test::More tests => 86;

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

# read default

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_1';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    my $res = $inst->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
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

    ok($attrib{'given_name'}, "Has the given_name attribute.");
    ok($attrib{'given_name'}->DefinedValue, "Has a value for given_name attribute");
    ok($attrib{'given_name'}->GetValue->DefinedString, "Value for given_name attribute is right type");
    is($attrib{'given_name'}->GetValue->GetString, $GIVEN, "It's what we set in the add.");

    ok($attrib{'family_name'}, "Has the family_name attribute.");
    ok($attrib{'family_name'}->DefinedValue, "Has a value for family_name attribute");
    ok($attrib{'family_name'}->GetValue->DefinedString, "Value for family_name attribute is right type");
    is($attrib{'family_name'}->GetValue->GetString, $FAMILY, "It's what we set in the add.");

    ok($attrib{'birthdate'}, "Has the birthdate attribute.");
    ok($attrib{'birthdate'}->DefinedValue, "Has a value for birthdate attribute");
    ok($attrib{'birthdate'}->GetValue->DefinedDateTime, "Value for birthdate attribute is right type");
    is($attrib{'birthdate'}->GetValue->GetDateTime, $BD, "It's what we set in the add.");

    ok($attrib{'age'}, "Has the age attribute.");
    ok($attrib{'age'}->DefinedValue, "Has a value for age attribute");
    ok($attrib{'age'}->GetValue->DefinedI4, "Value for age attribute is right type");

    ok($attrib{'sign'}, "Has the sign attribute.");
    ok($attrib{'sign'}->DefinedValue, "Has a value for sign attribute");
    ok($attrib{'sign'}->GetValue->DefinedString, "Value for sign attribute is right type");

    ok(!exists $attrib{'species'}, "Doesn't have the class species attribute");
    ok(!exists $attrib{'population'}, "Doesn't have the class population attribute");
}

# read some
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_2';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('age');
    $read->SetName('family_name');

    my $res = $inst->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
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

    ok($attrib{'family_name'}, "Has the family_name attribute.");
    ok($attrib{'family_name'}->DefinedValue, "Has a value for family_name attribute");
    ok($attrib{'family_name'}->GetValue->DefinedString, "Value for family_name attribute is right type");
    is($attrib{'family_name'}->GetValue->GetString, $FAMILY, "It's what we set in the add.");

    ok($attrib{'age'}, "Has the age attribute.");
    ok($attrib{'age'}->DefinedValue, "Has a value for age attribute");
    ok($attrib{'age'}->GetValue->DefinedI4, "Value for age attribute is right type");

    ok(!exists $attrib{'given_name'}, "Doesn't have the unrequested given name attribute");
    ok(!exists $attrib{'birthdate'}, "Doesn't have the unrequested birthdate attribute");
    ok(!exists $attrib{'sign'}, "Doesn't have the unrequested sign attribute");
    ok(!exists $attrib{'species'}, "Doesn't have the class species attribute");
    ok(!exists $attrib{'population'}, "Doesn't have the class population attribute");
}

# read with a class name
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_2';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('age');
    $read->SetName('species');

    my $res = $inst->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
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

    ok($attrib{'age'}, "Has the age attribute.");
    ok($attrib{'age'}->DefinedValue, "Has a value for age attribute");
    ok($attrib{'age'}->GetValue->DefinedI4, "Value for age attribute is right type");

    ok($attrib{'species'}, "Has the species attribute.");
    ok($attrib{'species'}->DefinedValue, "Has a value for species attribute");
    ok($attrib{'species'}->GetValue->DefinedString, "Value for species attribute is right type");

    ok(!exists $attrib{'given_name'}, "Doesn't have the unrequested given name attribute");
    ok(!exists $attrib{'family_name'}, "Doesn't have the unrequested family name attribute");
    ok(!exists $attrib{'birthdate'}, "Doesn't have the unrequested birthdate attribute");
    ok(!exists $attrib{'sign'}, "Doesn't have the unrequested sign attribute");
    ok(!exists $attrib{'population'}, "Doesn't have the class population attribute");
}

# read with a non-existent name
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_3';

    $iq->SetTo($added);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('given_name');
    $read->SetName('a_nonexistent_attribute');

    my $res = $inst->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $added, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct one.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");

    is($qry->GetTag, 'read', "Returned query has read tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok(!$qry->DefinedAttribute, "No attributes defined");
}
