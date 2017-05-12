#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8 encode_utf8);
use Map::Tube::Tbilisi;

# Object.
my $obj = Map::Tube::Tbilisi->new;

# Get route.
my $route = $obj->get_shortest_route(decode_utf8('სარაჯიშვილი'), decode_utf8('დელისი'));

# Print out type.
print "Route: ".encode_utf8($route)."\n";

# Output:
# Route: სარაჯიშვილი (ახმეტელი-ვარკეთილის ხაზი), გურამიშვილი (ახმეტელი-ვარკეთილის ხაზი), ღრმაღელე (ახმეტელი-ვარკეთილის ხაზი), დიდუბე (ახმეტელი-ვარკეთილის ხაზი), გოცირიძე (ახმეტელი-ვარკეთილის ხაზი), ნაძალადევი (ახმეტელი-ვარკეთილის ხაზი), სადგურის მოედანი (საბურთალოს ხაზი), წერეთელი (საბურთალოს ხაზი), ტექნიკური უნივერსიტეტი (საბურთალოს ხაზი), სამედიცინო უნივერსიტეტი (საბურთალოს ხაზი), დელისი (საბურთალოს ხაზი)