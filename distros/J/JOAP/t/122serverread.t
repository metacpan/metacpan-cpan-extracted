#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server subclass <read> handling

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


use Test::More tests => 59;

use Net::Jabber qw(Client);
use MyServer;

$SRC = "User\@example.net/Client";
$DEST = "joap.example.com";

my $srv = new MyServer;

# read all
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    my $res = $srv->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry->DefinedTimestamp, "Has a timestamp.");
    like($qry->GetTimestamp,
         qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/,
         "It looks like a timestamp.");

    ok($qry, "Can get the query.");

    my @attrib = $qry->GetAttribute();

    ok(@attrib, "Can get attributes.");

    my %attrib = map { ($_->GetName, $_) } @attrib;

    ok($attrib{'time'}, "Has the default time attribute.");
    ok($attrib{'version'}, "Has the default version attribute.");
    ok($attrib{'logLevel'}, "Has the logLevel attribute.");
    ok($attrib{'time'}->DefinedValue, "Has a value for default time attribute");
    ok($attrib{'version'}->DefinedValue, "Has a value for default version attribute");
    ok($attrib{'logLevel'}->DefinedValue, "Has a value for logLevel attribute");
    ok($attrib{'time'}->GetValue->DefinedDateTime, "Value for default time attribute is right type");
    ok($attrib{'version'}->GetValue->DefinedStruct, "Value for default version attribute is right type");
    ok($attrib{'logLevel'}->GetValue->DefinedI4, "Value for logLevel attribute is right type");
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

    $read->SetName('logLevel');
    $read->SetName('time');

    my $res = $srv->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");

    ok($qry->DefinedTimestamp, "Has a timestamp.");
    like($qry->GetTimestamp,
         qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/,
         "It looks like a timestamp.");

    my @attrib = $qry->GetAttribute();

    ok(@attrib, "Can get attributes.");

    my %attrib = map { ($_->GetName, $_) } @attrib;

    ok(exists $attrib{'time'}, "Has the default time attribute.");
    ok(exists $attrib{'logLevel'}, "Has the logLevel attribute.");
    ok(!exists $attrib{'version'}, "Has the default version attribute.");
    ok($attrib{'time'}->DefinedValue, "Has a value for default time attribute");
    ok($attrib{'logLevel'}->DefinedValue, "Has a value for logLevel attribute");
    ok($attrib{'time'}->GetValue->DefinedDateTime, "Value for default time attribute is right type");
    like($attrib{'time'}->GetValue->GetDateTime,
        qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/,
        "It looks like a datetime.");
    ok($attrib{'logLevel'}->GetValue->DefinedI4, "Value for logLevel attribute is right type");
}

# read one
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_3';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('logLevel');

    my $res = $srv->on_iq($iq);

    ok($res, "Got a read result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");

    ok($qry->DefinedTimestamp, "Has a timestamp.");
    like($qry->GetTimestamp,
         qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/,
         "It looks like a timestamp.");

    my @attrib = $qry->GetAttribute();

    ok(@attrib, "Can get attributes.");

    my %attrib = map { ($_->GetName, $_) } @attrib;

    ok(exists $attrib{'logLevel'}, "Has the logLevel attribute.");
    ok(!exists $attrib{'time'}, "Has the default time attribute.");
    ok(!exists $attrib{'version'}, "Has the default version attribute.");
    ok($attrib{'logLevel'}->DefinedValue, "Has a value for logLevel attribute");
    ok($attrib{'logLevel'}->GetValue->DefinedI4, "Value for logLevel attribute is right type");
}

# read with a non-existent name
{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_read_4';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('logLevel');
    $read->SetName('a_nonexistent_attribute');

    my $res = $srv->on_iq($iq);

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
