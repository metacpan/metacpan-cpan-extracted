#!/usr/bin/perl -w

# tag: test for JOAP Proxy errors

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

use Test::More tests => 35;
use Error qw(:try);

BEGIN {
    use Net::Jabber qw/Client/;
    use JOAP;
    # use base does this check, so we do it here, too.
    use_ok('JOAP::Proxy::Error');
    ok(%{JOAP::Proxy::Error::}, "There's something in the JOAP::Proxy::Error package.");
    ok(%{JOAP::Proxy::Error::Local::}, "There's something in the JOAP::Proxy::Error::Local package.");
    ok(%{JOAP::Proxy::Error::Remote::}, "There's something in the JOAP::Proxy::Error::Remote package.");
    ok(%{JOAP::Proxy::Error::Fault::}, "There's something in the JOAP::Proxy::Error::Fault package.");
}

# catch a JOAP proxy local error.

SKIP: {
    try {
        throw JOAP::Proxy::Error::Local("message 1", 1);
        fail("For some reason, didn't throw.");
        skip("Can't check if didn't throw", 4);
    } catch JOAP::Proxy::Error::Local with { # this is what we're lookin' for
        my $err = shift;
        pass("Threw the right type of error.");
        ok($err, "Error is there.");
        isa_ok($err, JOAP::Proxy::Error::Local, "Is a local error.");
        is($err->text, "message 1", "Got right message.");
        is($err->value, 1, "Got the right value.");
    } catch Error with {
        fail("Threw wrong type.");
        skip("Can't check wrong type", 4);
    }
}

# catch a JOAP proxy remote error

SKIP: {
    try {
        throw JOAP::Proxy::Error::Remote("message 2", 2);
        fail("For some reason, didn't throw.");
        skip("Can't check if didn't throw", 4);
    } catch JOAP::Proxy::Error::Remote with { # this is what we're lookin' for
        my $err = shift;
        pass("Threw the right type of error.");
        ok($err, "Error is there.");
        isa_ok($err, JOAP::Proxy::Error::Remote, "Is a remote error.");
        is($err->text, "message 2", "Got right message.");
        is($err->value, 2, "Got the right value.");
    } catch Error with {
        fail("Threw wrong type.");
        skip("Can't check wrong type", 4);
    }
}

# catch a JOAP proxy remote error

SKIP: {
    try {
        throw JOAP::Proxy::Error::Fault("message 3", 3);
        fail("For some reason, didn't throw.");
        skip("Can't check if didn't throw", 4);
    } catch JOAP::Proxy::Error::Fault with { # this is what we're lookin' for
        my $err = shift;
        pass("Threw the right type of error.");
        ok($err, "Error is there.");
        isa_ok($err, JOAP::Proxy::Error::Fault, "Is a fault error.");
        is($err->text, "message 3", "Got right message.");
        is($err->value, 3, "Got the right value.");
    } catch Error with {
        fail("Threw wrong type.");
        skip("Can't check wrong type", 4);
    }
}

# catch a JOAP proxy local error as a JOAP::Proxy::Error.

SKIP: {
    try {
        throw JOAP::Proxy::Error::Local("message 4", 4);
        fail("For some reason, didn't throw.");
        skip("Can't check if didn't throw", 4);
    } catch JOAP::Proxy::Error with { # this is what we're lookin' for
        my $err = shift;
        pass("Threw the right type of error.");
        ok($err, "Error is there.");
        isa_ok($err, JOAP::Proxy::Error::Local, "Is a local error.");
        is($err->text, "message 4", "Got right message.");
        is($err->value, 4, "Got the right value.");
    } catch Error with {
        fail("Threw wrong type.");
        skip("Can't check wrong type", 4);
    }
}

# catch a JOAP proxy remote error as a JOAP::Proxy::Error.

SKIP: {
    try {
        throw JOAP::Proxy::Error::Remote("message 5", 5);
        fail("For some reason, didn't throw.");
        skip("Can't check if didn't throw", 4);
    } catch JOAP::Proxy::Error with { # this is what we're lookin' for
        my $err = shift;
        pass("Threw the right type of error.");
        ok($err, "Error is there.");
        isa_ok($err, JOAP::Proxy::Error::Remote, "Is a remote error.");
        is($err->text, "message 5", "Got right message.");
        is($err->value, 5, "Got the right value.");
    } catch Error with {
        fail("Threw wrong type.");
        skip("Can't check wrong type", 4);
    }
}

# catch a JOAP proxy fault error as a JOAP::Proxy::Error.

SKIP: {
    try {
        throw JOAP::Proxy::Error::Fault("message 6", 6);
        fail("For some reason, didn't throw.");
        skip("Can't check if didn't throw", 4);
    } catch JOAP::Proxy::Error with { # this is what we're lookin' for
        my $err = shift;
        pass("Threw the right type of error.");
        ok($err, "Error is there.");
        isa_ok($err, JOAP::Proxy::Error::Fault, "Is a fault error.");
        is($err->text, "message 6", "Got right message.");
        is($err->value, 6, "Got the right value.");
    } catch Error with {
        fail("Threw wrong type.");
        skip("Can't check wrong type", 4);
    }
}

