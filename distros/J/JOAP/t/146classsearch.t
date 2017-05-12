#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server Class subclass <search> handling

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

use Test::More tests => 50;

use Net::Jabber qw(Client);
use JOAP;
use MyPerson;

$SRC = "User\@example.net/Client";
$DEST = "Person\@joap.example.com";

$MATCH_FAMILY = 'Prodromou';

@DATA = (
    ['Prodromou', 'Evan', '1968-10-14T07:32:00Z'],
    ['Prodromou', 'Andy', '1971-01-08T00:00:00Z'],
    ['Prodromou', 'Ted', '1973-07-07T00:00:00Z'],
    ['Prodromou', 'Nate', '1977-07-14T00:00:00Z'],
    ['Jenkins', 'Michele', '1976-08-09T00:00:00Z'],
    ['Washington', 'George', '1732-02-21T00:00:00Z'],
);

%PERSON = ();

$n = 0;

# we create an instance just like in a real situation

sub add_em {

    my($family, $given, $bd) = @_;

    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_add_$n';

    $n++;

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'given_name')->AddValue(string => $given);
    $add->AddAttribute(name => 'family_name')->AddValue(string => $family);
    $add->AddAttribute(name => 'birthdate')->AddValue(datetime => $bd);

    my $res = MyPerson->on_iq($iq);

    my $qry = $res->GetQuery;

    return $qry->GetNewAddress;
}

for $datum (@DATA) {
    my $addr = add_em(@$datum);
    $PERSON{$addr} = $datum;
}

# search without defined attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_search_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an search result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'search', "Returned query has search tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok($qry->DefinedItem, "Query has items.");

    my @items = $qry->GetItem;

    my @unknown = grep { !exists $PERSON{$_} } @items;

    ok(!@unknown, "All items are what we added.");

    my @unreturned = grep { my $n = $_; !grep {/$n/} @items } keys(%PERSON);

    ok(!@unreturned, "All people added are accounted for.");
}

# search with some defined attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_search_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    $search->AddAttribute(name => 'family_name')->AddValue(string => $MATCH_FAMILY);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an search result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'search', "Returned query has search tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    ok($qry->DefinedItem, "Query has items.");

    my @items = $qry->GetItem;

    my @unknown = grep { !exists $PERSON{$_} } @items;

    ok(!@unknown, "All items are what we added.");

    my @incorrect = grep { -1 == index($PERSON{$_}->[0], $MATCH_FAMILY) } @items;

    ok(!@incorrect, "No non-matching items were returned.");

    my @notfound = grep { my $a = $_; ((-1 != index($PERSON{$a}->[0], $MATCH_FAMILY)) && ! grep { /$a/ } @items) } keys %PERSON;

    ok(!@notfound, "No matching items were not returned.");
}

# search with non-existent attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_search_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    $search->AddAttribute(name => 'family_name')->AddValue(string => $MATCH_FAMILY);
    $search->AddAttribute(name => 'non_existent_attribute')->AddValue(string => 'gar gar gar');

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an search result.");

    is($res->GetType, "error", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'search', "Returned query has search tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    is($res->GetErrorCode, 406, "Error code is correct");
}

# search with wrong attribute type

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_search_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    $search->AddAttribute(name => 'family_name')->AddValue(i4 => 0);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an search result.");

    is($res->GetType, "error", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'search', "Returned query has search tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    is($res->GetErrorCode, 406, "Error code is correct");
}

# search with class attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_search_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    $search->AddAttribute(name => 'population')->AddValue(i4 => 0);

    my $res = MyPerson->on_iq($iq);

    ok($res, "Got an search result.");

    is($res->GetType, "error", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
    is($qry->GetTag, 'search', "Returned query has search tag.");
    is($qry->GetXMLNS, $JOAP::NS, "Returned query has joap XMLNS.");

    is($res->GetErrorCode, 406, "Error code is correct");
}
