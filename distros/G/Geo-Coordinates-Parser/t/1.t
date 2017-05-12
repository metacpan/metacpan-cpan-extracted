use strict;
use Test::More tests => 16;

BEGIN { use_ok('Geo::Coordinates::Parser') }


# Test the creation of the object with different decimal delimiters
my $coordinateparser;

$coordinateparser = Geo::Coordinates::Parser->new();
isa_ok($coordinateparser, 'Geo::Coordinates::Parser');
is($coordinateparser->decimal_delimiter, '.', 'Default (.) decimal delimiter');

$coordinateparser = Geo::Coordinates::Parser->new(',');
isa_ok($coordinateparser, 'Geo::Coordinates::Parser', 'new gets decimal delimiter as parameter');
is($coordinateparser->decimal_delimiter, ',', ', as decimal delimiter');


# Change delimiter
is($coordinateparser->decimal_delimiter('.'), '.', 'desimal_delimiter with parameter');


# Test parsing
is($coordinateparser->parse(), undef, "no string");
is($coordinateparser->parse(''), undef, "empty string");
is($coordinateparser->parse(' '), undef, "no value string");

my @formats = (q{E25°42'60"}, q{25,42,60}, q{E25'42'60}, q{E25.7166666666667}, q{E25, 43.000000000002, 0}, q{E25, 43.000000000002});
foreach my $format (@formats) {
	is($coordinateparser->parse($format), 25.7166666666667, $format);
}

$coordinateparser->decimal_delimiter(',');
my $format = $formats[3];
is($coordinateparser->parse($format), 119444444469.45, "$format with , as delimiter");



