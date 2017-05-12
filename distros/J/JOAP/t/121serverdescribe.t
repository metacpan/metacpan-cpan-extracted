#!/usr/bin/perl -w -It/lib

# tag: test for JOAP Server subclass <describe> handling

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

use Test::More tests => 31;

use Net::Jabber qw(Client);
use JOAP;
use MyServer;

$SRC = "User\@example.net/Client";
$DEST = "joap.example.com";

my $srv = new MyServer;

# describe

my $iq = new Net::Jabber::IQ;
my $ID = 'joap_describe_1';

$iq->SetTo($DEST);
$iq->SetFrom($SRC);
$iq->SetID($ID);
$iq->SetType('get');

my $desc = $iq->NewQuery($JOAP::NS, 'describe');

my $res = $srv->on_iq($iq);

ok($res, "Got a describe result.");

is($res->GetType, "result", "It's a result result.");
is($res->GetID, $ID, "ID came back correct.");
is($res->GetFrom, $DEST, "from is right.");
is($res->GetTo, $SRC, "to is right.");

my $qry = $res->GetQuery;

ok($qry, "Can get the query.");

ok($qry->DefinedDesc, "Has a description.");
ok(length($qry->GetDesc), "Description has non-zero length.");

ok($qry->DefinedTimestamp, "Has a timestamp.");
like($qry->GetTimestamp, qr/^(-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/,
  "It looks like a timestamp.");

ok($qry->DefinedAttributeDescription, "Has attribute descriptions.");

my @attrs = $qry->GetAttributeDescription;
my %attrs = map {($_->GetName, $_)} @attrs;

ok($attrs{'time'}, "Has the default time attribute.");
ok(!$attrs{'time'}->GetWritable, "time attr correctly unwritable.");
is($attrs{'time'}->GetType, 'dateTime.iso8601', "Right type for time.");

ok($attrs{'version'}, "Has the default version attribute.");
ok(!$attrs{'version'}->GetWritable, "version attr correctly unwritable.");
is($attrs{'version'}->GetType, 'struct', "Right type for version.");

ok($attrs{'logLevel'}, "Has the logLevel attribute.");
ok($attrs{'logLevel'}->GetWritable, "logLevel attr writable.");
is($attrs{'logLevel'}->GetType, 'i4', "Right type for logLevel.");

ok($qry->DefinedMethodDescription, "Has method descriptions");

my @meths = $qry->GetMethodDescription;
my %meths = map {($_->GetName, $_)} @meths;

ok ($meths{'log'}, "Has the 'log' method.");
is ($meths{'log'}->GetReturnType, 'boolean', "The type is correct.");
ok ($meths{'log'}->DefinedDesc, "Has a description.");
ok ($meths{'log'}->DefinedParams, "Has params.");

my @params = $meths{'log'}->GetParams->GetParams; # blech

my %params = map {($_->GetName, $_)} @params;

ok ($params{message}, "Has the message param.");
ok ($params{message}->DefinedDesc, "Has a description.");
is ($params{message}->GetType, 'string', "Right type for message param.");

ok ($qry->DefinedClass, "Has classes.");

my @classes = $qry->GetClass;

is (scalar @classes, 1, "Returned the right number of classes");
is ($classes[0], 'Person@' . $DEST, 'Right address for classes');
