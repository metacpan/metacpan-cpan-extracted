#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/00_load.t'
BEGIN { $^W = 1 };
use Test::More tests => 1;
use_ok("Heap::Simple::Perl");
