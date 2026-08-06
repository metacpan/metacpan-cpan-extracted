#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_PERLTIDY}) {
  plan(skip_all => 'Set TEST_PERLTIDY=1 to enable perltidy tests');
}

eval 'use Test::PerlTidy';
plan(skip_all => 'Test::PerlTidy required for checking code formatting') if $@;

run_tests();
