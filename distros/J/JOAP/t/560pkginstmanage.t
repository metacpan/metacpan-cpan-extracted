#!/usr/bin/perl -w

# tag: test for creating, searching, and deleting JOAP Proxy Class instances

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

use lib 't/lib';

use ProxyTest;
use JOAP::Proxy;
use JOAP::Proxy::Instance;
use MyPersonProxy;
use Error qw(:try);

use Test::More tests => 7;

@DATA = (
         ['Prodromou', 'Evan', '1968-10-14T07:32:00Z'],
         ['Prodromou', 'Andy', '1971-01-08T00:00:00Z'],
         ['Prodromou', 'Ted', '1973-07-07T00:00:00Z'],
         ['Prodromou', 'Nate', '1977-07-14T00:00:00Z'],
         ['Jenkins', 'Michele', '1976-08-09T00:00:00Z'],
         ['Washington', 'George', '1732-02-21T00:00:00Z'],
        );

SKIP: {

    my $address = ProxyTest->server();

    if (!$address) {
        skip("No server defined", 7);
    }

    my $person_addr = "Person\@$address";

    my $con = ProxyTest->connect();

    if (!$con) {
        skip("Can't connect to server", 7);
    }

    JOAP::Proxy->Connection($con);

    MyPersonProxy->Address($person_addr);
    MyPersonProxy->refresh;

    # first, we delete all the persons (!) The goal here is to clear
    # the db on the server so we don't get spurious clashes (and
    # errors) adding these standard persons.

    my @items;

    try {
        foreach my $item (MyPersonProxy->search) {
            my $p = JOAP::Proxy::Instance->get($item); # not testing us yet
            $p->delete;
        }
    } otherwise {
        skip("Trouble initializing", 7);
    };

    # Now, we add all our instances.

    my @instances;

    try {
        foreach $datum (@DATA) {
            my $p = MyPersonProxy->add(family_name => $datum->[0],
                                       given_name => $datum->[1],
                                       birthdate => $datum->[2]);

            push @instances, $p;
        }
        pass("Can add all our data.");
    } otherwise {
        fail("Can't add all our data.");
    };

    # Try to do some bogus adds.

    # Don't provide all required, writable attributes.

    try {
        my $p = MyPersonProxy->add(family_name => 'Prodromou'); # of course
        fail("Can add a person without all required, writable attributes.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't add a person without all required, writable attributes.");
    } otherwise {
        fail("Wrong error adding a person without all required, writable attributes.");
    };

    # Provide a read-only attribute.

    try {
        my $p = MyPersonProxy->add(family_name => 'Prodromou',
                                   given_name => 'Amity',
                                   birthdate => '1943-11-06T00:00:00Z',
                                   sign => 'virgo');
        fail("Can add a person with a read-only attribute.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't add a person with a read-only attribute.");
    } otherwise {
        fail("Wrong error adding a person with a read-only attribute.");
    };

    # Provide a non-existent attribute.

    try {
        my $p = MyPersonProxy->add(family_name => 'Prodromou',
                                   given_name => 'Amity',
                                   birthdate => '1943-11-06T00:00:00Z',
                                   non_existent_attribute => 'bogus');
        fail("Can add a person with a read-only attribute.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't add a person with a read-only attribute.");
    } otherwise {
        fail("Wrong error adding a person with a read-only attribute.");
    };

    # Provide a class attribute.

    try {
        my $p = MyPersonProxy->add(family_name => 'Prodromou',
                                   given_name => 'Amity',
                                   birthdate => '1943-11-06T00:00:00Z',
                                   population => 50);
        fail("Can add a person with a class attribute.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't add a person with a class attribute.");
    } otherwise {
        fail("Wrong error adding a person with a class attribute.");
    };

    # Add a person we just added. Note: remote error

    try {
        my $data = $DATA[0];
        my $p = MyPersonProxy->add(family_name => $data->[0],
                                   given_name => $data->[1],
                                   birthdate => $data->[2]);
        fail("Can add a duplicate person.");
    } catch JOAP::Proxy::Error::Remote with {
        pass("Can't add a duplicate person.");
    } otherwise {
        fail("Wrong error adding a duplicate person.");
    };

    try {
        foreach my $instance (@instances) {
            $instance->delete();
        }
        pass("Can delete all the items.");
    } otherwise {
        fail("Can't delete all the items.");
    };

    $con->Disconnect;
}
