#!/usr/bin/perl -w

# tag: test for manipulating JOAP proxy instance objects

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
use JOAP::Proxy::Class;
use JOAP::Proxy::Instance;
use Error qw(:try);

use Test::More tests => 34;

my $FIRST = 'Evan';
my $LAST = 'Prodromou';
my $BD = '1968-10-14T07:32:00Z';

SKIP: {

    my $address = ProxyTest->server();

    if (!$address) {
        skip("No server defined", 34);
    }

    my $person_addr = "Person\@$address";

    my $con = ProxyTest->connect();

    if (!$con) {
        skip("Can't connect to server", 34);
    }

    JOAP::Proxy->Connection($con);

    my $pclass = JOAP::Proxy::Class->get($person_addr);

    # first, we delete all the persons (!) The goal here is to clear
    # the db on the server so we don't get spurious clashes (and
    # errors) adding the test person.

    my @items = $pclass->search;

    foreach my $item (@items) {
        my $p = $pclass->get($item);
        $p->delete();
    }

    # Now, we add the person we want to mess around with.

    my $p = $pclass->add(family_name => $LAST,
                               given_name => $FIRST,
                               birthdate => $BD);

    isa_ok($p, JOAP::Proxy::Instance, "We created a person.");

    # Check some can values

    # JOAP metadata

    can_ok($p, 'attributes');
    can_ok($p, 'methods');
    can_ok($p, 'superclasses');
    can_ok($p, 'timestamp');
    can_ok($p, 'description');
    can_ok($p, 'address');

    # Basic stuff

    can_ok($p, 'refresh');
    can_ok($p, 'save');
    can_ok($p, 'delete');

    # instance accessors

    can_ok($p, 'given_name');
    can_ok($p, 'family_name');
    can_ok($p, 'birthdate');
    can_ok($p, 'sign');

    # instance methods

    can_ok($p, 'walk');

    # Make sure we can't do some bogus stuff

    ok (!$p->can('not_a_method'), "Can't use non-existent method");
    ok (!$p->can('not_an_attribute'), "Can't use non-existent method");

    # class accessors

    ok(!$p->can('species'), "Can't access class attribute 'species'");
    ok(!$p->can('population'), "Can't access class attribute 'population'");

    # class methods

    ok(!$p->can('get_family'), "Can't access class method 'get_family'");

    # description

    ok(defined($p->description), "Description is defined.");
    ok(length($p->description) > 0, "Has a description.");

    # Check that the accessors work. instance accessors

    is($p->given_name, $FIRST, "given_name accessor works.");
    is($p->family_name, $LAST, "family_name accessor works.");
    is($p->birthdate, $BD, "birthdate accessor works.");

    # read-only attribute

    is($p->sign, 'libra', "sign accessor works.");

    # run an instance method.

    try {
        my $success = $p->walk(7);
        pass("Can do the walk method.");
        ok($success, "It actually worked.");
    } catch Error with {
        fail("Something bad happened with calling an instance method.");
        fail("So we can't check the return value, either.");
    };

    # run a class method

    try {
        my $family = $p->get_family('Prodromou');
        fail("Can do the get_family method.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Rightly prevented calling a class method.");
    };

    # some pathological examples

    # run an instance method without enough parameters

    try {
        my $success = $p->walk();
        fail("Can do the walk method without enough parameters.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't do the walk method without enough parameters.");
    } catch Error with {
        fail("Wrong error doing the walk method without enough parameters.");
    };

    # run an instance method with too many parameters

    try {
        my $success = $p->walk(1, 2, 3, 4, 5);
        fail("Can do the walk method with too many parameters.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't do the walk method with too many parameters.");
    } catch Error with {
        fail("Wrong error doing the walk method with too many parameters.");
    };

    # cause a fault

  SKIP: {
        try {
            $p->walk(-14);   # must be >= 0
            fail("No error thrown.");
            skip("Can't check error values", 2);
        } catch JOAP::Proxy::Error::Fault with {
            my $err = shift;
            pass("Successfully caused a fault.");
            is($err->text, "Never go back.", "Got expected fault string");
            is($err->value, 5440, "Got expected fault code");
        } otherwise {
            my $err = shift;
            diag(ref($err));
            fail("Wrong error setting the read-only time attribute.");
            skip("Can't check error values", 2);
        };
    }

    # delete it so we can run again

    $p->delete;

    $con->Disconnect;
}
