#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server subclass method handling

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
use MyServer;

$SRC = "User\@example.net/Client";
$DEST = "joap.example.com";

my $con = new Net::Jabber::Client;

my $srv = new MyServer;

# call an existing method

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_rpc_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $q =
      $con->RPCEncode(
	  type => 'methodCall',
	  methodName => 'log',
	  params => ['Now is the time for all good men to come to the aid of their party.']);

    $iq->AddQuery($q);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a rpc result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");

    my $resp = $qry->GetMethodResponse;

    ok($resp, "Has a method response.");

    ok($resp->DefinedParams, "Has params.");

    my @p = $resp->GetParams->GetParams; # GetParams->GetParams->GetParams->GetParams...

    ok(@p, "Has params.");
    ok($p[0]->GetValue->DefinedBoolean, "Got the right response type");
    ok($p[0]->GetValue->GetBoolean, "Got the right response value");
}

# cause a fault

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_rpc_2';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $q =
      $con->RPCEncode(
	  type => 'methodCall',
	  methodName => 'logLine',
	  params => [-4]);      # line_no must be >= 0

    $iq->AddQuery($q);

    my $res = $srv->on_iq($iq);

    ok($res, "Got an rpc result.");

    is($res->GetType, "result", "It's a result result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");

    my $resp = $qry->GetMethodResponse;

    ok($resp, "Has a method response.");

    ok($resp->DefinedFault, "Has a fault.");
    ok($resp->GetFault->DefinedValue, "Has a value in the fault.");
    ok($resp->GetFault->GetValue->DefinedStruct, "Has a struct in the value in the fault.");

    my $str = $resp->GetFault->GetValue->GetStruct;

    ok($str, "Got a fault structure.");

    my %members = map {($_->GetName, $_->GetValue)} $str->GetMembers;

    ok($members{faultCode}, "Has a fault code");
    ok($members{faultCode}->DefinedI4, "Has an I4 for the fault code.");
    is($members{faultCode}->GetI4, 42, "Has the special fault code from MyServer.");

    ok($members{faultString}, "Has a fault string");
    ok($members{faultString}->DefinedString, "Has a string for the fault code.");
    is($members{faultString}->GetString, "No such line", "Has the special fault string from MyServer.");
}

# Call a non-existent method

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_rpc_3';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $q =
      $con->RPCEncode(
	  type => 'methodCall',
	  methodName => 'not_a_method',
	  params => [1, 2, 'foobar']);

    $iq->AddQuery($q);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a rpc result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
}

# Call a method with too many params

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_rpc_3';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $q =
      $con->RPCEncode(
	  type => 'methodCall',
	  methodName => 'log',
	  params => ['foobar', 'extra param']);

    $iq->AddQuery($q);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a rpc result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
}

# Call a method with too few params

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_rpc_4';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $q =
      $con->RPCEncode(
	  type => 'methodCall',
	  methodName => 'log',
	  params => []);

    $iq->AddQuery($q);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a rpc result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
}

# Call a method with params of wrong type

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_rpc_5';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $q =
      $con->RPCEncode(
	  type => 'methodCall',
	  methodName => 'log',
	  params => ['i4:25']);

    $iq->AddQuery($q);

    my $res = $srv->on_iq($iq);

    ok($res, "Got a rpc result.");

    is($res->GetType, "error", "It's an error result.");
    is($res->GetID, $ID, "ID came back correct.");
    is($res->GetFrom, $DEST, "from is right.");
    is($res->GetTo, $SRC, "to is right.");

    is($res->GetErrorCode, 406, "Error code is correct.");

    my $qry = $res->GetQuery;

    ok($qry, "Can get the query.");
}
