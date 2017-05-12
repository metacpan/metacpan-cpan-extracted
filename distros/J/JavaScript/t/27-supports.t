#!perl

use Test::More tests => 6;
use Test::Exception;

use strict;
use warnings;

use JavaScript;

is(JavaScript->supports("threading"), int JavaScript->does_support_threading, "Checking support 'threading'");
is(JavaScript->supports("utf8"), int JavaScript->does_support_utf8, "Checking support 'utf8'");
is(JavaScript->supports("e4x"), int JavaScript->does_support_e4x, "Checking support 'e4x'");
is(JavaScript->supports("E4X"), int JavaScript->supports("E4X"), "Checking ignoring case");
is(JavaScript->supports("threading", "utf8", "e4x"),
    int JavaScript->does_support_threading && 
    int JavaScript->does_support_utf8 &&
    int JavaScript->does_support_e4x,
    "Checking support for multiple");

throws_ok {
    JavaScript->supports("non existent feature");
} qr/I don't know about/;