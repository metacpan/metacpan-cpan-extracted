#!perl

use Test::More tests => 6;
use Test::Exception;

use strict;
use warnings;

use JSPL;

is(JSPL->supports("threading"), JSPL->does_support_threading, "Checking support 'threading'");
is(JSPL->supports("utf8"), JSPL->does_support_utf8, "Checking support 'utf8'");
is(JSPL->supports("e4x"), JSPL->does_support_e4x, "Checking support 'e4x'");
is(JSPL->supports("E4X"), JSPL->supports("e4X"), "Checking ignoring case");
is(JSPL->supports("threading", "utf8", "e4x"),
    JSPL->does_support_threading && 
    JSPL->does_support_utf8 &&
    JSPL->does_support_e4x,
    "Checking support for multiple");

throws_ok {
    JSPL->supports("non existent feature");
} qr/I don't know about/;
