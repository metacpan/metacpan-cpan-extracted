#!/usr/bin/env perl

use strict;
use warnings;

use lib '../../lib';

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok( 'Gwybodaeth::Parsers::CSV' ); }

my $csv = new_ok ( 'Gwybodaeth::Parsers::CSV' );

my @data;
my $structure;

# Simple CSV test
@data = ( "first,surname,sex",
          "john,jones,male",
          "sali,williams,female"
        );

$structure = [ ['first', 'surname', 'sex'],
               ['john', 'jones', 'male'],
               ['sali', 'williams', 'female'] ];

is_deeply( $csv->parse(@data), $structure, 'simple data');

# Quoted CSV test
@data = ( 'name,home',
          'Iestyn Pryce,"Tit Hall, Cambridge"' );

$structure = [ ['name', 'home'],
               ['Iestyn Pryce', 'Tit Hall, Cambridge']
             ];

is_deeply( $csv->parse(@data), $structure, 'quoted fields' );

# Unicode text
@data = ( 'î Langollen,– ndash,— mdash' );

$structure = [ [ 'î Langollen', '– ndash', '— mdash'] ];

is_deeply( $csv->parse(@data), $structure, 'unicode fields');

# Set different variable separator
$csv->{sep_char} = ';';

@data = ( 'name;job;mbox' );
$structure = [ [ 'name', 'job', 'mbox' ] ];

is_deeply($csv->parse(@data), $structure, 'semicolon SV');

$csv->{sep_char} = ',';

# Set different quote character
$csv->{quote_char} = "'";

@data = ( "We,'like, to',quote" );
$structure = [ [ 'We', 'like, to', 'quote' ] ];

is_deeply($csv->parse(@data), $structure, 'single quote field quoting');
$csv->{quote_char} = '"';

# Test for cruft input

my $xml = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF>
<foaf:Person>
<foaf:name>Plato</foaf:name>
</foaf:Person>
</rdf:RDF>
EOF

my @xml = split /\n/, $xml;

throws_ok(sub { $csv->parse(@xml); }, 
        qr/unable to parse/, 
        'cruft test 1 (XML)');
