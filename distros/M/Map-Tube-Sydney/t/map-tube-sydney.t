#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::Map::Tube tests => 3;

use utf8;
use Map::Tube::Sydney;

my $map = Map::Tube::Sydney->new;

ok_map($map);
ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes($map, \@routes);

__DATA__
Route 1|Newtown|North Sydney|Newtown,Macdonaldtown,Redfern,Central,Town Hall,Wynyard,Milsons Point,North Sydney
Route 2|Rockdale|Mascot|Rockdale,Banksia,Arncliffe,Wolli Creek,International Airport,Domestic Airport,Mascot
Route 3|Waterfall|Cronulla|Waterfall,Heathcote,Engadine,Loftus,Sutherland,Kirrawee,Gymea,Miranda,Caringbah,Woolooware,Cronulla
Route 4|Ingleburn|Leppington|Ingleburn,Macquarie Fields,Glenfield,Edmondson Park,Leppington
Route 5|Leppington|Lidcombe|Leppington,Edmondson Park,Glenfield,Casula,Liverpool,Warwick Farm,Cabramatta,Carramar,Villawood,Leightonfield,Chester Hill,Sefton,Regents Park,Berala,Lidcombe
Route 6|Olympic Park|Bankstown|Olympic Park,Lidcombe,Berala,Regents Park,Birrong,Yagoona,Bankstown
Route 7|Parramatta|Clyde|Parramatta,Harris Park,Granville,Clyde
Route 8|Parramatta|Guildford|Parramatta,Harris Park,Merrylands,Guildford
Route 9|Clyde|Guildford|Clyde,Granville,Merrylands,Guildford
Route 10|Central|Macdonaldtown|Central,Redfern,Macdonaldtown
Route 11|Central|Burwood|Central,Redfern,Burwood
Route 12|Central|Strathfield|Central,Redfern,Strathfield
Route 13|North Sydney|Circular Quay|North Sydney,Milsons Point,Wynyard,Circular Quay
Route 14|UNSW High Street|UNSW Anzac Parade|UNSW High Street,Wansey Road,Royal Randwick,Moore Park,ES Marks,Kensington,UNSW Anzac Parade
Route 15|Paddy's Markets|Town Hall|Paddy's Markets,Capitol Square,Chinatown,Town Hall
Route 16|Harris Park|Westmead Hospital|Harris Park,Parramatta,Westmead,Westmead Hospital
Route 17|Rooty Hill|Quakers Hill|Rooty Hill,Doonside,Blacktown,Marayong,Quakers Hill
Route 18|Castle Hill|Berowra|Castle Hill,Cherrybrook,Epping,Cheltenham,Beecroft,Pennant Hills,Thornleigh,Normanhurst,Hornsby,Asquith,Mount Colah,Mount Kuring-gai,Berowra
Route 19|Kings Cross|Crows Nest|Kings Cross,Martin Place,Barangaroo,Victoria Cross,Crows Nest
Route 20|Gordon|Macquarie Park|Gordon,Killara,Lindfield,Roseville,Chatswood,North Ryde,Macquarie Park
Route 21|Turrella|Waterloo|Turrella,Sydenham,Waterloo
Route 22|East Hills|Villawood|East Hills,Holsworthy,Glenfield,Casula,Liverpool,Warwick Farm,Cabramatta,Carramar,Villawood
Route 23|Bankstown|Villawood|Bankstown,Yagoona,Birrong,Regents Park,Sefton,Chester Hill,Leightonfield,Villawood
Route 24|Town Hall|Museum|Town Hall,Central,Museum
Route 25|QVB|Haymarket|QVB,Town Hall,Chinatown,Haymarket
