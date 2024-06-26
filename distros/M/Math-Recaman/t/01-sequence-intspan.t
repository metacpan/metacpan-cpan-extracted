#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Math::Recaman;

plan skip_all => "No Set::IntSpan installed" unless $Math::Recaman::USING_INTSPAN;
require 't/01-sequence-common.pl';
is($Math::Recaman::USING_INTSPAN, 1, "Used Set::IntSpan");