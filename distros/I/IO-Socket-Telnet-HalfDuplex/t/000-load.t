#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

package Foo;
::use_ok('IO::Socket::Telnet::HalfDuplex')
    or ::BAIL_OUT("couldn't load IO::Socket::Telnet::HalfDuplex");
