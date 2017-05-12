#!/usr/bin/perl -w

# tag: test for creating JOAP server replies

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

use Test::More tests => 74;

use Net::Jabber qw(Client);
use JOAP;
use JOAP::Server::Object;

$SRC = "User\@example.net/Client";
$DEST = "Person\@joap.example.com/Prodromou,Evan";
$DESTCLASS = "Person\@joap.example.com";
$ID = 'joap_read_1';

# read

{
    my $iq = new Net::Jabber::IQ();

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('get');

    my $read = $iq->NewQuery($JOAP::NS, 'read');

    $read->SetName('age');

    ok($read->DefinedName, "Name field is defined.");

    my $reply = JOAP::Server::Object->reply($iq);

    ok($reply, "Can create a reply.");
    is($reply->GetType, "result", "Reply type is a result");
    is($reply->GetTo, $SRC, "Reply destination is correct");
    is($reply->GetFrom, $DEST, "Reply source is correct");
    is($reply->GetID, $ID, "Reply id is correct");

    my $replq = $reply->GetQuery();

    ok($replq, "Can get reply query");
    is($replq->GetXMLNS, $JOAP::NS, "Reply query is in the right NS");
    is($replq->GetTag, 'read', "Reply query is a <read>");
    ok(!$replq->DefinedName, "Name field was not passed through.");

    $reply->SetType('error');

    is($reply->GetType, 'error', 'Set the type to error correctly');

    $reply->SetErrorCode(406);
    $reply->SetError('Not acceptable');

    is($reply->GetErrorCode, 406, "Set error type correctly.");
    is($reply->GetError, 'Not acceptable', 'Set error text correctly.');
}

# edit

{
    my $iq = new Net::Jabber::IQ();

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $edit = $iq->NewQuery($JOAP::NS, 'edit');

    $edit->AddAttribute(name => 'age')->AddValue(i4 => 34);

    ok($edit->DefinedAttribute, "Name field is defined.");

    my $reply = JOAP::Server::Object->reply($iq);

    ok($reply, "Can create a reply.");
    is($reply->GetType, "result", "Reply type is a result");
    is($reply->GetTo, $SRC, "Reply destination is correct");
    is($reply->GetFrom, $DEST, "Reply source is correct");
    is($reply->GetID, $ID, "Reply id is correct");

    my $replq = $reply->GetQuery();

    ok($replq, "Can get reply query");
    is($replq->GetXMLNS, $JOAP::NS, "Reply query is in the right NS");
    is($replq->GetTag, 'edit', "Reply query is a <edit>");
    ok(!$replq->DefinedAttribute, "Attribute field was not passed through.");

    $reply->SetType('error');

    is($reply->GetType, 'error', 'Set the type to error correctly');

    $reply->SetErrorCode(406);
    $reply->SetError('Not acceptable');

    is($reply->GetErrorCode, 406, "Set error type correctly.");
    is($reply->GetError, 'Not acceptable', 'Set error text correctly.');
}

# add

{
    my $iq = new Net::Jabber::IQ();

    $iq->SetTo($DESTCLASS);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $add = $iq->NewQuery($JOAP::NS, 'add');

    $add->AddAttribute(name => 'age')->AddValue(i4 => 34);
    $add->AddAttribute(name => 'first')->AddValue(string => 'Evan');
    $add->AddAttribute(name => 'last')->AddValue(string => 'Prodromou');

    ok($add->DefinedAttribute, "Name field is defined.");

    my $reply = JOAP::Server::Object->reply($iq);

    ok($reply, "Can create a reply.");
    is($reply->GetType, "result", "Reply type is a result");
    is($reply->GetTo, $SRC, "Reply destination is correct");
    is($reply->GetFrom, $DESTCLASS, "Reply source is correct");
    is($reply->GetID, $ID, "Reply id is correct");

    my $replq = $reply->GetQuery();

    ok($replq, "Can get reply query");
    is($replq->GetXMLNS, $JOAP::NS, "Reply query is in the right NS");
    is($replq->GetTag, 'add', "Reply query is a <add>");
    ok(!$replq->DefinedAttribute, "Attribute field was not passed through.");

    $reply->SetType('error');

    is($reply->GetType, 'error', 'Set the type to error correctly');

    $reply->SetErrorCode(406);
    $reply->SetError('Not acceptable');

    is($reply->GetErrorCode, 406, "Set error type correctly.");
    is($reply->GetError, 'Not acceptable', 'Set error text correctly.');
}

# delete

{
    my $iq = new Net::Jabber::IQ();

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $delete = $iq->NewQuery($JOAP::NS, 'delete');

    my $reply = JOAP::Server::Object->reply($iq);

    ok($reply, "Can create a reply.");
    is($reply->GetType, "result", "Reply type is a result");
    is($reply->GetTo, $SRC, "Reply destination is correct");
    is($reply->GetFrom, $DEST, "Reply source is correct");
    is($reply->GetID, $ID, "Reply id is correct");

    my $replq = $reply->GetQuery();

    ok($replq, "Can get reply query");
    is($replq->GetXMLNS, $JOAP::NS, "Reply query is in the right NS");
    is($replq->GetTag, 'delete', "Reply query is a <delete>");

    $reply->SetType('error');

    is($reply->GetType, 'error', 'Set the type to error correctly');

    $reply->SetErrorCode(406);
    $reply->SetError('Not acceptable');

    is($reply->GetErrorCode, 406, "Set error type correctly.");
    is($reply->GetError, 'Not acceptable', 'Set error text correctly.');
}

# search

{
    my $iq = new Net::Jabber::IQ();

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $search = $iq->NewQuery($JOAP::NS, 'search');

    $search->AddAttribute(name => 'age')->AddValue(i4 => 34);

    ok($search->DefinedAttribute, "Name field is defined.");

    my $reply = JOAP::Server::Object->reply($iq);

    ok($reply, "Can create a reply.");
    is($reply->GetType, "result", "Reply type is a result");
    is($reply->GetTo, $SRC, "Reply destination is correct");
    is($reply->GetFrom, $DEST, "Reply source is correct");
    is($reply->GetID, $ID, "Reply id is correct");

    my $replq = $reply->GetQuery();

    ok($replq, "Can get reply query");
    is($replq->GetXMLNS, $JOAP::NS, "Reply query is in the right NS");
    is($replq->GetTag, 'search', "Reply query is a <search>");
    ok(!$replq->DefinedAttribute, "Attribute field was not passed through.");

    $reply->SetType('error');

    is($reply->GetType, 'error', 'Set the type to error correctly');

    $reply->SetErrorCode(406);
    $reply->SetError('Not acceptable');

    is($reply->GetErrorCode, 406, "Set error type correctly.");
    is($reply->GetError, 'Not acceptable', 'Set error text correctly.');
}

# describe

{
    my $iq = new Net::Jabber::IQ();

    $iq->SetTo($DEST);
    $iq->SetFrom($SRC);
    $iq->SetID($ID);
    $iq->SetType('set');

    my $describe = $iq->NewQuery($JOAP::NS, 'describe');

    my $reply = JOAP::Server::Object->reply($iq);

    ok($reply, "Can create a reply.");
    is($reply->GetType, "result", "Reply type is a result");
    is($reply->GetTo, $SRC, "Reply destination is correct");
    is($reply->GetFrom, $DEST, "Reply source is correct");
    is($reply->GetID, $ID, "Reply id is correct");

    my $replq = $reply->GetQuery();

    ok($replq, "Can get reply query");
    is($replq->GetXMLNS, $JOAP::NS, "Reply query is in the right NS");
    is($replq->GetTag, 'describe', "Reply query is a <describe>");

    $reply->SetType('error');

    is($reply->GetType, 'error', 'Set the type to error correctly');

    $reply->SetErrorCode(406);
    $reply->SetError('Not acceptable');

    is($reply->GetErrorCode, 406, "Set error type correctly.");
    is($reply->GetError, 'Not acceptable', 'Set error text correctly.');
}
