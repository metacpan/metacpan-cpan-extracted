#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use utf8;
use Test::More 'no_plan';

use Map::Metro;

my $graph = Map::Metro->new('Berlin')->parse;
isa_ok $graph, 'Map::Metro::Graph', 'parsed Berlin graph';

if (1) { # S-Bahn example
    my $routing = $graph->routing_for('Alexanderplatz', 'Hauptbahnhof');
 
    is $routing->origin_station->name, 'Alexanderplatz';
    is $routing->destination_station->name, 'Hauptbahnhof';
 
    my($best_route) = $routing->ordered_routes;
    my $line_stations = $best_route->line_stations;
    is join(" ", map { $_->station->name } @$line_stations),
	'Alexanderplatz Hackescher Markt Friedrichstr. Hauptbahnhof';
    like $line_stations->[0]->line->name, qr{^S\d+$};
}

if (1) { # U-Bahn example
    {
	my $routing = $graph->routing_for('Platz der Luftbrücke', 'Gneisenaustr.');

	is $routing->origin_station->name, 'Platz der Luftbrücke';
	is $routing->destination_station->name, 'Gneisenaustr.';
 
	my($best_route) = $routing->ordered_routes;
	my $line_stations = $best_route->line_stations;
	is join(" ", map { $_->station->name } @$line_stations),
	    'Platz der Luftbrücke Mehringdamm Mehringdamm Gneisenaustr.';
	is $line_stations->[0]->line->name, 'U6';
	is $line_stations->[-1]->line->name, 'U7';
    }

    # may be mixed U/S-Bahn
    {
	my $routing = $graph->routing_for('Rathaus Spandau', 'Rudow');
	my($best_route) = $routing->ordered_routes;
	my $line_stations = $best_route->line_stations;
	like join(" ", map { $_->station->name } @$line_stations),
	    qr{^Rathaus Spandau .* (?:Wilmersdorfer Str. .* Kleistpark .* Hermannplatz|Halensee .* Tempelhof) .* Rudow$};
    }
}

if (1) { # new since 2017 (Ostkreuz, Suedringkurve)
    my $routing = $graph->routing_for('Treptower Park', 'Warschauer Str.');
    my($best_route) = $routing->ordered_routes;
    my $line_stations = $best_route->line_stations;
    is join(" ", map { $_->station->name } @$line_stations),
	'Treptower Park Warschauer Str.';
}

if (1) { # new since 2020, Museumsinsel new since 2021
    my $routing = $graph->routing_for('Stadtmitte', 'Rotes Rathaus');
    my($best_route) = $routing->ordered_routes;
    my $line_stations = $best_route->line_stations;
    is join(", ", map { $_->station->name } @$line_stations),
	'Stadtmitte, Unter den Linden, Unter den Linden, Museumsinsel, Rotes Rathaus';
}

__END__
