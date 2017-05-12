#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server subclass logging

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
use MyServer;

$SRC = "User\@example.net/Client";
$DEST = "joap.example.com";
$DESTCLASS = "Person\@joap.example.com";
$LOGLEVEL = 42;

$GIVEN = 'Evan';
$FAMILY = 'Prodromou';
$BD = '1968-10-14T07:32:00-07:00';

my $con = new Net::Jabber::Client;
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

    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
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

    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
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

    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");

    $added = $res->GetQuery->GetNewAddress;
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

    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
}

# search class without defined attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_search_1';

    $iq->SetTo($DESTCLASS);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    my $res = $srv->on_joap($iq);

    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
}

# class method

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_rpc_1';

    $iq->SetTo($DESTCLASS);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $q =
      $con->RPCEncode(
	  type => 'methodCall',
	  methodName => 'get_family',
	  params => ['Prodromou']);

    $iq->AddQuery($q);

    my $res = $srv->on_joap($iq);
    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
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
    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
}

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

    my $res = $srv->on_joap($iq);
    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
}

# edit bad attribute

{
    my $iq = new Net::Jabber::IQ;
    my $ID = 'joap_edit_1';

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'not_an_attribute')->AddValue(i4 => $LOGLEVEL);

    my $res = $srv->on_joap($iq);
    my $log = $srv->log_entry($iq, $res);

    ok($log, "Got a log entry");
}
