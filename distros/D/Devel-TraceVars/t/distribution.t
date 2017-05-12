#!/usr/bin/perl

use Test::More;

eval q{use Test::Distribution not => "sig"};
plan(skip_all => 'Test::Distribution not installed') if $@;
