#!/usr/bin/env perl

use strict;
use warnings;

use Test::More qw{no_plan};
use Test::Output;
use Test::Exception;

use Gwybodaeth::Parsers::N3;
use Gwybodaeth::Parsers::GeoNamesXML;

BEGIN { use_ok( 'Gwybodaeth::Write::WriteFromUsgsXML' ); }

my $usgs = new_ok( 'Gwybodaeth::Write::WriteFromUsgsXML' );

my $xml_parse = Gwybodaeth::Parsers::GeoNamesXML->new();
my $map_parse = Gwybodaeth::Parsers::N3->new();

my $data_str = <<'EOF';
<feed>
<entry><title>Title</title></entry>
</feed>
EOF

my $map_str = <<'EOF';
@prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix eqd:    <http://example.com/earth_quake_data#> .
@prefix :       <#> .

[]  a rdf:Description ;
    eqd:title "Ex:$title^^string" .
EOF

my $expected = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF xmlns:eqd="http://example.com/earth_quake_data#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<rdf:Description>
<eqd:title rdf:datatype="http://www.w3.org/TR/xmlschema-2/#string">Title</eqd:title>
</rdf:Description>
</rdf:RDF>
EOF

my @map = split /\n/x, $map_str;
my @data = split /\n/x, $data_str;

sub write_test_1 {
    return $usgs->write_rdf($map_parse->parse(@map),$xml_parse->parse(@data));
}

stdout_is(\&write_test_1, $expected, 'simple feed');

# Tests with some dodgy input

my $csv = [ [ 'NAME', 'YEAR', 'COUNTRY'],
            [ 'Plato', '400 BC', 'Greece'],
            [ 'Nietzsche', '1889 AD', 'Switzerland' ],
          ];

$xml_parse = $usgs = undef;
$usgs = Gwybodaeth::Write::WriteFromXML->new();
$xml_parse = Gwybodaeth::Parsers::GeoNamesXML->new();

my $twig = $xml_parse->parse( @{ $csv } );

throws_ok { $usgs->write_rdf($map_parse->parse(@map), $twig) } 
          qr/expected XML::Twig in the second array ref/, 'csv test';

# Pass two scalars, not array refs;
my($string1,$string2) = (0,0);

throws_ok {$usgs->write_rdf($string1,$string2)}
        qr/expected array ref as first argument/,
        'scalar input (write_rdf args)';

# Set the first array ref as two scalars, not references to
# Gwybodaeth::Triple and a Hash

my $array_ref1 = [0,0];

throws_ok {$usgs->write_rdf($array_ref1,$string2)}
        qr/expected a Gwybodaeth::Triples object as first argument of array/,
        'dud array input 1 (write_rdf 1st arg)';

# Set the first array ref to a Gwybodaeth::Triples (correct)
# and a scalar (incorrect).
my$array_ref2 = [Gwybodaeth::Triples->new(),0];

throws_ok {$usgs->write_rdf($array_ref2, $string2)}
        qr/expected a hash ref as second argument of array/,
        'dud array intput 2 (write_rdf 1st arg)';

# Set the first array ref correctly and the second to a scalar.

my $array_ref3 = [Gwybodaeth::Triples->new(),{}];

throws_ok {$usgs->write_rdf($array_ref3, $string2)}
        qr/expected XML::Twig in the second array ref/,
        'dud array input 3 (write_rdf 2nd arg)';
