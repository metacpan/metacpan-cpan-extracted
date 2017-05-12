#!/usr/bin/perl -w

use strict;
use Test::More tests => 5;

use_ok( 'ExtUtils::Typemaps::Excommunicated' );

my $map = ExtUtils::Typemaps::Excommunicated->new();
isa_ok($map, 'ExtUtils::Typemaps::Excommunicated');
isa_ok($map, 'ExtUtils::Typemaps');
ok($map->as_string =~ /^T_DATAUNIT/m);
ok($map->as_string =~ /^T_CALLBACK/m);

