#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf;

throws_ok {
    neaf helper => foobar => \42;
} qr(helper.*must.*coderef)i, 'typecheck';

throws_ok {
    neaf helper => _private => sub { 42 };
} qr(helper.*name), 'private = no go';

throws_ok {
    neaf helper => do_stuff => sub { 42 };
} qr(helper.*name), 'do_* is reserved';

throws_ok {
    neaf helper => param => sub { 42 };
} qr(annot.*existing.*param), 'existing methods not avail';

done_testing;
