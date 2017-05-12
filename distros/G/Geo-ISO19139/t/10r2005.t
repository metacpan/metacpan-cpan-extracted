#!/usr/bin/perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 5;

#use Log::Report mode => 3;
use Geo::ISO19139::2005;
use Geo::ISO19139::Util ':2005';

my $gml = Geo::ISO19139::2005->new('RW');
isa_ok($gml, 'Geo::ISO19139::2005');
is($gml->version, '2005');
is($gml->gmlVersion, '3.2.1');

use XML::Compile::Util qw/pack_type/;
my $type = pack_type NS_GML_2005, 'RectifiedGridCoverage';

my $text = $gml->template(PERL => $type); 
ok(defined $text, 'template generated');
cmp_ok(length $text, '>', 100);

#warn $text;
#$gml->printIndex(\*STDERR);
