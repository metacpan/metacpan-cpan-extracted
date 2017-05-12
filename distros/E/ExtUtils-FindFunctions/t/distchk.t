#!/usr/bin/perl 
use strict;
use Test::More;
eval "use Test::Distribution not => 'podcover'";
plan skip_all => "Test::Distribution required for checking distribution" if $@;
