#!/usr/bin/perl -w

# tag: test for JOAP Proxy Class Objects

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
use JOAP::Proxy::Class;
use Error qw(:try);

use Test::More tests => 44;

SKIP: {

    my $address = ProxyTest->server();

    if (!$address) {
        skip("No server defined", 44);
    }

    my $person_addr = "Person\@$address";

    my $con = ProxyTest->connect();

    if (!$con) {
        skip("Can't connect to server", 44);
    }

    JOAP::Proxy->Connection($con);

    my $pclass = JOAP::Proxy::Class->get($person_addr);

    # JOAP metadata

    can_ok($pclass, 'attributes');
    can_ok($pclass, 'methods');
    can_ok($pclass, 'superclasses');
    can_ok($pclass, 'timestamp');
    can_ok($pclass, 'description');
    can_ok($pclass, 'address');

    # These are basic methods

    can_ok($pclass, 'get');
    can_ok($pclass, 'refresh');
    can_ok($pclass, 'save');
    can_ok($pclass, 'add');
    can_ok($pclass, 'search');

    # These are class attributes

    can_ok($pclass, 'species');
    can_ok($pclass, 'population');

    # This is a class method

    can_ok($pclass, 'get_family');

    # A couple of methods we don't have.

    ok (!$pclass->can('not_a_method'), "Can't use non-existent method");
    ok (!$pclass->can('not_an_attribute'), "Can't use non-existent method");

    ok(!$pclass->can('Classes'), "can() doesn't overreport.");
    ok(!$pclass->can('Methods'), "can() doesn't overreport.");
    ok(!$pclass->can('Attributes'), "can() doesn't overreport.");
    ok(!$pclass->can('Timestamp'), "can() doesn't overreport.");

    ok(!$pclass->can('sign'), "can() doesn't report instance accessors.");
    ok(!$pclass->can('family_name'), "can() doesn't report instance accessors.");
    ok(!$pclass->can('given_name'), "can() doesn't report instance accessors.");
    ok(!$pclass->can('birthdate'), "can() doesn't report instance accessors.");
    ok(!$pclass->can('age'), "can() doesn't report instance accessors.");

    ok(!$pclass->can('walk'), "can() doesn't report instance methods.");

    ok (length($pclass->description) > 0, "Has a description");
    is($pclass->address, $person_addr, "The address is what we set in the constructor.");

    # Read the species attribute

    try {
        my $species = $pclass->species;
        pass("Can get the species.");
        ok(defined($species), "It came back with, uh... something.");
    } otherwise {
        fail("Can't get the species.");
        fail("So we can't check the return value.");
    };

    # Read the population attribute

    my $pop = 0;

    try {
        $pop = $pclass->population;
        pass("Can get the population.");
        ok(defined($pop), "It came back with, uh... something.");
    } otherwise {
        fail("Can't get the population.");
        fail("So we can't check the return value.");
    };

    # Set the population attribute

    try {
        $pclass->population($pop + 1);
        $pclass->save;
        pass("Can set the population.");
        $pclass->refresh;
        is($pclass->population, $pop + 1, "It came back with the value we set.");
    } otherwise {
        my $err = shift;
        diag("Error #" . $err->value . ":" . $err->text);
        fail("Can't set the population.");
        fail("Can't check the return value, either.");
    };

    # run a class method

    try {
        my $family = $pclass->get_family('Prodromou');
        pass("Can do the get_family method.");
    } otherwise {
        fail("Something bad happened with calling a class method.");
    };

    # some pathological examples

    # Try to execute an instance method

    try {
        $pclass->walk;
        fail("Can execute instance method on class.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't execute instance method on class.");
    } otherwise {
        fail("Wrong error executing instance method on class.");
    };

    # Try to access an instance attribute

    try {
        my $bd = $pclass->birthdate;
        fail("Can use accessor for instance attribute 'birthdate'.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't use accessor for instance attribute 'birthdate'.");
    } otherwise {
        fail("Wrong error using accessor for instance attribute 'birthdate'.");
    };

    # Try to set an instance attribute

    try {
        $pclass->first_name("George");
        fail("Can use mutator for instance attribute 'first_name'.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't use mutator for instance attribute 'first_name'.");
    } otherwise {
        fail("Wrong error using mutator for instance attribute 'first_name'.");
    };

    # try to set a read-only attribute

    try {
        $pclass->species("canus canus");
        fail("Can set the species.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Properly prevent setting read-only attribute.");
    } otherwise {
        fail("Wrong error setting read-only attribute.");
    };

    # run an class method without enough parameters

    try {
        my $success = $pclass->get_family;
        fail("Can do the get_family method without enough parameters.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't do the get_family method without enough parameters.");
    } otherwise {
        fail("Wrong error doing get_family method without enough parameters.");
    };

    # run an class method with too many parameters

    try {
        my $success = $pclass->get_family('Prodromou', 1, 2, 3, 4, 5);
        fail("Can do the get_family method with too many parameters.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't do the get_family method with too many parameters.");
    } otherwise {
        fail("Wrong error doing the get_family method with too many parameters.");
    };

    # cause a fault

  SKIP: {
        try {
            $pclass->get_family('');   # must be >= 0 length
            fail("No error thrown.");
            skip("Can't check error values", 2);
        } catch JOAP::Proxy::Error::Fault with {
            my $err = shift;
            pass("Successfully caused a fault.");
            is($err->text, "Family name empty", "Got expected fault string");
            is($err->value, 23, "Got expected fault code");
        } otherwise {
            fail("Wrong error setting the read-only time attribute.");
            skip("Can't check error values", 2);
        };
    }

    $con->Disconnect;
}
