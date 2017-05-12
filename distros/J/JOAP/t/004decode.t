#!/usr/bin/perl -w

# tag: test for decoding

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

use Test::More tests => 8;

use Net::Jabber qw(Client);
use JOAP;

can_ok(JOAP, 'decode');

sub make_value {

    my $jval = new Net::Jabber::Query("value");
    $jval->SetXMLNS("__netjabber__:iq:rpc:value");

    return $jval;
}

{
    my $v = make_value();
    $v->SetI4(10);
    my $i = JOAP->decode($v);

    is($i, '10', "can decode an integer.");
}

{
    my $v = make_value();
    $v->SetBoolean(0);
    my $b = JOAP->decode($v);

    is($b, 0, "can decode a boolean.");
}

{
    my $v = make_value();
    $v->SetString("spock");
    my $s = JOAP->decode($v);

    is($s, 'spock', "can decode a string.");
}

{
    my $v = make_value();
    $v->SetDouble(3.14159);
    my $d = JOAP->decode($v);

    is($d, 3.14159, "can decode a double.");
}

{
    my $v = make_value();
    $v->SetDateTime('1968-10-14T07:32:00-07:00');
    my $dt = JOAP->decode($v);

    is($dt, '1968-10-14T07:32:00-07:00', "can decode a date");
}

{
    my $v = make_value();
    my $data = $v->AddArray()->AddData();
    my @arr = (1, 2, 3, 4, 5, 6);

    foreach my $i (@arr) {
        $data->AddValue(i4 => $i);
    }

    my $other = JOAP->decode($v);

    is_deeply(\@arr, $other, "can decode an array");
}

{
    my $v = make_value();
    my $str = $v->AddStruct();
    my %fields = (foo => 1, bar => 2);

    while (my($name, $value) = each %fields) {
        $str->AddMember(name => $name)->AddValue(i4 => $value);
    }

    my $other = JOAP->decode($v);

    is_deeply(\%fields, $other, "can decode a struct");
}
