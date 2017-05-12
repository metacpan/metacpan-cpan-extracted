#!/usr/bin/perl -w

# tag: test for encoding

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

use Test::More tests => 25;

use Net::Jabber qw(Client);
use JOAP;

can_ok(JOAP, 'encode');

{
    my $v = JOAP->encode('i4', 10);
    ok($v, "Encoded an i4.");
    ok($v->DefinedI4, "The i4 is defined");
    is($v->GetI4, 10, "The value is what we set");
}

{
    my $v = JOAP->encode('boolean', 1);
    ok($v, "Encoded a boolean.");
    ok($v->DefinedBoolean, "The boolean is defined");
    is($v->GetBoolean, 1, "The value is what we set");
}

{
    my $v = JOAP->encode('double', 0.1);
    ok($v, "Encoded a double.");
    ok($v->DefinedDouble, "The double is defined");
    is($v->GetDouble, 0.1, "The value is what we set");
}

{
    my $v = JOAP->encode('int', 8);
    ok($v, "Encoded an int.");
    ok($v->DefinedI4, "The int is defined");
    is($v->GetI4, 8, "The value is what we set");
}

{
    my $v = JOAP->encode('string', 'Now is the time for all good men');
    ok($v, "Encoded a string.");
    ok($v->DefinedString, "The string is defined");
    is($v->GetString, 'Now is the time for all good men', "The value is what we set");
}

{
    my $v = JOAP->encode('dateTime.iso8601', '1968-10-14T07:32:00Z');
    ok($v, "Encoded a datetime.");
    ok($v->DefinedDateTime, "The datetime is defined");
    is($v->GetDateTime, '1968-10-14T07:32:00Z', "The value is what we set");
}

{
    my @arr = (1, 2, 'foo', 3, 4, 'bar', 5);

    my $v = JOAP->encode('array', \@arr);
    ok($v, "Encoded an array.");
    ok($v->DefinedArray, "The array is defined");
    my $arr;
    ok($arr = $v->GetArray, "Can get the array.");
}

{
    my %str = (foo => 1, bar => 'baz');

    my $v = JOAP->encode('struct', \%str);
    ok($v, "Encoded a struct.");
    ok($v->DefinedStruct, "The struct is defined");
    my $str;
    ok($str = $v->GetStruct, "Can get the struct.");
}
