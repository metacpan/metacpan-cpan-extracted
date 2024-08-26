#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = '0.60';
eval "use Test::Map::Tube $min_ver tests => 4";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::London;
my $map = new_ok("Map::Tube::London");

SKIP: {
    ok_map($map) or skip "Skip map function and routes test.", 2;

    ok_map_functions($map);

    my @routes = <DATA>;
    ok_map_routes($map, \@routes);
}

__DATA__
Route 1|Wembley Central|Bond Street|Wembley Central,Stonebridge Park,Harlesden,Willesden Junction,Shepherd's Bush,Holland Park,Notting Hill Gate,Queensway,Lancaster Gate,Marble Arch,Bond Street
Route 2|Bond Street|Euston|Bond Street,Oxford Circus,Warren Street,Euston
Route 3|White City|Victoria|White City,Shepherd's Bush,Kensington (Olympia),Earl's Court,Gloucester Road,South Kensington,Sloane Square,Victoria
Route 4|Temple|Farringdon|Temple,Embankment,Waterloo,Bank,Moorgate,Barbican,Farringdon
Route 5|Turnham Green|Whitechapel|Turnham Green,Hammersmith,Barons Court,Earl's Court,Gloucester Road,South Kensington,Knightsbridge,Hyde Park Corner,Green Park,Westminster,Waterloo,Bank,Shadwell,Whitechapel
Route 6|Goldhawk Road|Wembley Central|Goldhawk Road,Shepherd's Bush Market,Wood Lane,White City,Shepherd's Bush,Willesden Junction,Harlesden,Stonebridge Park,Wembley Central
Route 7|Wembley Central|Marylebone|Wembley Central,Stonebridge Park,Harlesden,Willesden Junction,Shepherd's Bush,Holland Park,Notting Hill Gate,Bayswater,Paddington,Edgware Road,Marylebone
Route 8|Baker Street|Neasden|Baker Street,Finchley Road,Wembley Park,Neasden
Route 9|Baker Street|Preston Road|Baker Street,Finchley Road,Wembley Park,Preston Road
Route 10|Oval|Euston|Oval,Kennington,Waterloo,Westminster,Green Park,Oxford Circus,Warren Street,Euston
Route 11|South Ealing|Alperton|South Ealing,Acton Town,Ealing Common,North Ealing,Park Royal,Alperton
Route 12|Bank|Westminster|Bank,Waterloo,Westminster
Route 13|Hoxton|Gospel Oak|Hoxton,Haggerston,Dalston Junction,Dalston Kingsland,Canonbury,Highbury & Islington,Caledonian Road & Barnsbury,Camden Road,Kentish Town West,Gospel Oak
Route 14|Baker Street|North Harrow|Baker Street,Finchley Road,Harrow-on-the-Hill,North Harrow
Route 15|Baker Street|Croxley|Baker Street,Finchley Road,Harrow-on-the-Hill,Moor Park,Croxley
Route 16|Sloane Square|Westminster|Sloane Square,Victoria,St. James's Park,Westminster
Route 17|Westferry|Cannon Street|Westferry,Limehouse,Shadwell,Bank,Monument,Cannon Street
Route 18|Westferry|Cannon      Street|Westferry,Limehouse,Shadwell,Bank,Monument,Cannon Street
Route 19|   Westferry|Cannon      Street|Westferry,Limehouse,Shadwell,Bank,Monument,Cannon Street
Route 20|Westferry    |Cannon      Street|Westferry,Limehouse,Shadwell,Bank,Monument,Cannon Street
Route 21|Westferry    |   Cannon      Street    |Westferry,Limehouse,Shadwell,Bank,Monument,Cannon Street
Route 22|westferry    |   Cannon      Street    |Westferry,Limehouse,Shadwell,Bank,Monument,Cannon Street
Route 23|Tower Gateway|Aldgate|Tower Gateway,Tower Hill,Aldgate
Route 24|Liverpool Street|Monument|Liverpool Street,Bank,Monument
Route 25|Baker Street|Farringdon|Baker Street,Great Portland Street,Euston Square,King's Cross St. Pancras,Farringdon
Route 26|Bank|Monument|Bank,Monument
Route 27|Euston|King's Cross St. Pancras|Euston,King's Cross St. Pancras
