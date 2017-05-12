#!/usr/bin/perl
#
# $Id$
#
# Really simple smoke tests for Glib::Object wrappers.
#

use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'

#########################

use Test::More tests => 10;
BEGIN { use_ok('Glib'); Glib::Object->set_threadsafe (1); };

#########################

my $obj = Glib::Object->new;
isa_ok ($obj, 'Glib::Object');

$obj->freeze_notify;
$obj->thaw_notify;

undef $obj;
ok(1);


# portability tests -- we should be able to pass pointers through UVs
# with the get_data/set_data mechanism.  (gtk uses this in a few places.)
# we also test the new_from_pointer and get_pointer methods, and ensure
# that the magical hash wrappers work correctly, all in one convoluted
# test.

$obj = Glib::Object->new;
isa_ok ($obj, 'Glib::Object');
my $obj2 = Glib::Object->new;
isa_ok ($obj, 'Glib::Object');
$obj2->{key} = 'val';
$obj->set_data (obj2 => $obj2->get_pointer);
my $obj3_pointer = $obj->get_data ('obj2');
ok ($obj3_pointer);
my $obj3 = Glib::Object->new_from_pointer ($obj3_pointer);
isa_ok ($obj3, 'Glib::Object');
is ($obj3, $obj2);
is ($obj3->{key}, $obj2->{key});

# regression tests

# make sure calling a Glib::Object method on something invalid results in an
# error message, not in a segmentation fault
eval { Glib::Object->get (123); };
like ($@, qr/is not of type Glib::Object/);


__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
