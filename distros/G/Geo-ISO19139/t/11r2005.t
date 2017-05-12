#!/usr/bin/perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 5;

#use Log::Report mode => 3;
use Geo::ISO19139;

my $gml = Geo::ISO19139->new('RW', version => 2005);
isa_ok($gml, 'Geo::ISO19139::2005');
is($gml->version, '2005');
is($gml->gmlVersion, '3.2.1');

my $mem = $gml->reader('gml:members');
ok(defined $mem, 'members structure');
isa_ok($mem, 'CODE');
