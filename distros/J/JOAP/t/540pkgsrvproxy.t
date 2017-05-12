#!/usr/bin/perl -w

# tag: test for JOAP Proxy Server

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
use MyServerProxy;
use Error qw(:try);

use Test::More tests => 48;

SKIP: {

    my $address = ProxyTest->server();

    if (!$address) {
        skip("No server defined", 48);
    }

    my $person_addr = "Person\@$address";

    my $con = ProxyTest->connect();

    if (!$con) {
        skip("Can't connect to server", 48);
    }

    JOAP::Proxy->Connection($con);

    can_ok(MyServerProxy, 'get');
    can_ok(MyServerProxy, 'Address');

    MyServerProxy->Address($address);

    my $server = MyServerProxy->get;

    ok($server, "Can instantiate a server.");
    isa_ok($server, MyServerProxy, "Hey! It's what we thought it was gonna be.");

    # class metadata

    can_ok($server, 'Attributes');
    can_ok($server, 'Methods');
    can_ok($server, 'Classes');
    can_ok($server, 'Timestamp');
    can_ok($server, 'Description');

    # instance metadata

    can_ok($server, 'attributes');
    can_ok($server, 'methods');
    can_ok($server, 'classes');
    can_ok($server, 'timestamp');
    can_ok($server, 'description');
    can_ok($server, 'address');

    # JOAP methods

    can_ok($server, 'refresh');
    can_ok($server, 'save');
    can_ok($server, 'logLevel');
    can_ok($server, 'log');
    can_ok($server, 'logLine');

    # inherited

    can_ok($server, 'version');
    can_ok($server, 'time');

    # non-existent

    # all right, technically there's no diff.

    ok(!$server->can('non_existent_method'), "can() doesn't overreport.");
    ok(!$server->can('non_existent_attribute'), "can() doesn't overreport.");

    is ($server->address, $address, "Address is what we set in constructor.");

    ok(length($server->Description) > 0, "Has a description.");
    is($server->description, $server->Description, "Description of class and object equal.");

    ok(length($server->Timestamp) > 0, "Has a timestamp.");
    is($server->timestamp, $server->Timestamp, "Timestamp of class and object equal.");

    my $classes = $server->classes;

    ok (@$classes, "server has classes");

    my $person = grep { /^$person_addr$/ } @$classes;

    ok ($person, "has person class.");

    my $person_class = $server->proxy_class($person_addr);

    ok ($person_class, "Can get proxy class for Person.");

    # Try to get some bogus addresses

    my $bogus_class = $server->proxy_class('ClassNameWithoutServerPart');

    ok (!defined($bogus_class), "Server properly returns undef for no server part.");

    $bogus_class = $server->proxy_class('Person@not.a.real.server');

    ok (!defined($bogus_class), "Server properly returns undef for different server.");

    $bogus_class = $server->proxy_class('NonExistentClass@' . $address);

    ok (!defined($bogus_class), "Server properly returns undef for non-existent class.");

    my $ll = 0;

    try {
        $ll = $server->logLevel;
        pass("Can retrieve the logLevel attribute.");
    } otherwise {
        fail("Can't retrieve the logLevel attribute.");
    };

    my $newll = $ll + 1;

    try {
        $server->logLevel($newll);
        pass("Can set the logLevel attribute.");
    } otherwise {
        my $err = shift;
        diag($err->text);
        fail("Can't set the logLevel attribute.");
    };

    try {
        $server->save();
        pass("Can save the server values.");
    } otherwise {
        my $err = shift;
        diag($err->text);
        fail("Can't save the server values.");
    };

    try {
        $server->refresh();
        pass("Can refresh the server object.");
    } otherwise {
        my $err = shift;
        diag($err->text);
        fail("Can't refresh the server object.");
    };

    is($server->logLevel, $newll, "The retrieved value is our new value.");

    try {
        my $res = $server->log("Now is the time for all good men");
        ok($res, "Can call the log method.");
        is($res, 1, "log method returned 1.");
    } otherwise {
        my $e = shift;
        diag($e->text);
        fail("Can't call log method.");
        fail("Results are wrong, too.");
    };

    # Try some pathological examples

    # try to set a read-only attribute

    try {
        $server->time('19700101T000000Z');
        fail("Set the read-only time attribute.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't set the read-only time attribute.");
    } otherwise {
        my $err = shift;
        diag($err->text);
        fail("Wrong error setting the read-only time attribute.");
    };

    # Call a method with too few arguments

    try {
        $server->log();
        fail("Can call a method with too few arguments.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't call a method with too few arguments.");
    } otherwise {
        my $err = shift;
        diag($err->text);
        fail("Wrong error calling a method with too few arguments.");
    };

    # Call a method with too many arguments

    try {
        $server->log('now is the time', 1, 2, 3, 4, 5, 6, 7, 8);
        fail("Can call a method with too many arguments.");
    } catch JOAP::Proxy::Error::Local with {
        pass("Can't call a method with too many arguments.");
    } otherwise {
        my $err = shift;
        diag($err->text);
        fail("Wrong error calling a method with too many arguments.");
    };

    # cause a fault

  SKIP: {
        try {
            $server->logLine(-4);   # must be >= 0
            fail("No error thrown.");
            skip("Can't check error values", 2);
        } catch JOAP::Proxy::Error::Fault with {
            my $err = shift;
            pass("Successfully caused a fault.");
            is($err->text, "No such line", "Got expected fault string");
            is($err->value, 42, "Got expected fault code");
        } otherwise {
            my $err = shift;
            diag($err->text);
            fail("Wrong error setting the read-only time attribute.");
            skip("Can't check error values", 2);
        };
    }

    $con->Disconnect();
}
