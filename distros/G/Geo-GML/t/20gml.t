#!/usr/bin/perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 4;

use Geo::GML;
use Geo::GML::Util qw/NS_GML_32/;

my $gml1 = Geo::GML->new('READER', version => '3.2.1');
isa_ok($gml1, 'Geo::GML');
is($gml1->version, '3.2.1');

my $gml2 = Geo::GML->new(WRITER => version => NS_GML_32);
isa_ok($gml2, 'Geo::GML');
is($gml2->version, '3.2.1');
