#!/usr/bin/env perl

use strict;
use warnings;

use lib '../../lib';

use Test::More qw{no_plan};
use Test::Output;
use Test::Exception;

use Gwybodaeth::Parsers::CSV;
use Gwybodaeth::Parsers::N3;

BEGIN { use_ok ( 'Gwybodaeth::Write::WriteFromCSV' ) };

my $csv_write = new_ok( 'Gwybodaeth::Write::WriteFromCSV' ); 

my $csv_parse = Gwybodaeth::Parsers::CSV->new();
my $map_parse = Gwybodaeth::Parsers::N3->new();

my @data;
my @map;

# Nested function test
@data = ( 'name', 'John' );

@map = ( '[] a foaf:Person ;',
          'foaf:office',
          '     [ a foaf:Place ;',
          '         foaf:addy "Ex:$1"',
          '     ] .' );

my $str = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF>
<foaf:Person>
<foaf:office>
<foaf:Place>
<foaf:addy>John</foaf:addy>
</foaf:Place>
</foaf:office>
</foaf:Person>
</rdf:RDF>
EOF

sub write_test_1 {
    return $csv_write->write_rdf($map_parse->parse(@map), 
                                 $csv_parse->parse(@data));
}

stdout_is(\&write_test_1, $str, 'nested function' );

@data = @map = undef;

# @If grammar test
@data = ('name,sex', 'John,male', 'Sarah,female');

@map = ( "[] a <Ex:foo+\@If(\$2='male';'Man';'Woman')> ;",
         'foaf:name "Ex:$1" .' );

$str = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF>
<foo:Man>
<foaf:name>John</foaf:name>
</foo:Man>
<foo:Woman>
<foaf:name>Sarah</foaf:name>
</foo:Woman>
</rdf:RDF>
EOF

$csv_write = $map_parse = $csv_parse = undef;
$csv_write = Gwybodaeth::Write::WriteFromCSV->new();
$map_parse = Gwybodaeth::Parsers::N3->new();
$csv_parse = Gwybodaeth::Parsers::CSV->new();


sub write_test_2 {
    return $csv_write->write_rdf($map_parse->parse(@map), 
                                 $csv_parse->parse(@data));
}

stdout_is(\&write_test_2, $str, '@If grammar');

# ^^ grammar test

@data = ( 'name,num', 'John,20391' );

@map = (  "[] a foaf:Person ;",
          'foaf:name "Ex:$1^^string" ;',
          'foo:id "Ex:$2^^int" .',
       );

$str = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF>
<foaf:Person>
<foaf:name rdf:datatype="http://www.w3.org/TR/xmlschema-2/#string">John</foaf:name>
<foo:id rdf:datatype="http://www.w3.org/TR/xmlschema-2/#int">20391</foo:id>
</foaf:Person>
</rdf:RDF>
EOF

$csv_write = $map_parse = $csv_parse = undef;
$csv_write = Gwybodaeth::Write::WriteFromCSV->new();
$map_parse = Gwybodaeth::Parsers::N3->new();
$csv_parse = Gwybodaeth::Parsers::CSV->new();

sub write_test_3 {
    return $csv_write->write_rdf($map_parse->parse(@map),
                                 $csv_parse->parse(@data));
}

stdout_is(\&write_test_3, $str, '^^ grammar');

# @lang test

@data = ( 'country,capital', 'Wales,Caerdydd');

@map  = ( '[] a foo:country ;',
          'foo:name "Ex:$1@en" ;',
          'foo:capital "Ex:$2@cy" .',
        );

$str = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF>
<foo:country>
<foo:name xml:lang="en">Wales</foo:name>
<foo:capital xml:lang="cy">Caerdydd</foo:capital>
</foo:country>
</rdf:RDF>
EOF

$csv_write = $map_parse = $csv_parse = undef;
$csv_write = Gwybodaeth::Write::WriteFromCSV->new();
$map_parse = Gwybodaeth::Parsers::N3->new();
$csv_parse = Gwybodaeth::Parsers::CSV->new();

sub write_test_4 {
    return $csv_write->write_rdf($map_parse->parse(@map),
                                 $csv_parse->parse(@data));
}

stdout_is(\&write_test_4, $str, '@lang grammar');


# Test 'start row' and 'end row' functionality
@data = ('some,cruft','start row, 5', 'end row, 6','name,sex', 
         'John,male', 'Sarah,female', 'some,end,cruft',);

@map = ( "[] a foo:Person ;",
         'foaf:name "Ex:$1" .' );

$str = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF>
<foo:Person>
<foaf:name>John</foaf:name>
</foo:Person>
<foo:Person>
<foaf:name>Sarah</foaf:name>
</foo:Person>
</rdf:RDF>
EOF

$csv_write = $map_parse = $csv_parse = undef;
$csv_write = Gwybodaeth::Write::WriteFromCSV->new();
$map_parse = Gwybodaeth::Parsers::N3->new();
$csv_parse = Gwybodaeth::Parsers::CSV->new();


sub write_test_5 {
    return $csv_write->write_rdf($map_parse->parse(@map), 
                                 $csv_parse->parse(@data));
}

stdout_is(\&write_test_5, $str, '[start|end] row');

# Test crufty input

$csv_write = $map_parse = $csv_parse = undef;
$csv_write = Gwybodaeth::Write::WriteFromCSV->new();
$csv_parse = Gwybodaeth::Parsers::CSV->new();

my $xml_block = <<'EOF';
<?xml version="1.0"?>
<rdf:RDF>
<foaf:Person>
<foaf:name>Plato</foaf:name>
</foaf:Person>
</rdf:RDF>
EOF

my @xml_array = split /\n/, $xml_block;

ok(sub { $csv_write->write_rdf($map_parse->parse(@map),
                                   $csv_parse->parse(@xml_array)); },
       'cruft test 1 (XML)' );

# Test for passing incorrect data structures to write_rdf
$csv_write = undef;
$csv_write = Gwybodaeth::Write::WriteFromCSV->new();

# Pass two strings, not two array refs;
my($string1,$string2) = (0,0);

throws_ok {$csv_write->write_rdf($string1, $string2)} 
        qr/expected array ref as first argument/, 
        'scalar input (write_rdf args)';

# Set the first array ref as two scalars, not references to
# Gwybodaeth::Triple and a HASH.
my $array_ref1 = [0,0];

throws_ok {$csv_write->write_rdf($array_ref1, $string2)}
        qr/expected a Gwybodaeth::Triples object as first argument of array/,
        'dud array input 1 (write_rdf 1st arg)';

# Set the first array ref to a Gwybodaeth::Triples (correct)
# and a scalar (incorrect).
my$array_ref2 = [Gwybodaeth::Triples->new(),0];

throws_ok {$csv_write->write_rdf($array_ref2, $string2)}
        qr/expected a hash ref as second argument of array/,
        'dud array intput 2 (write_rdf 1st arg)';

# Set the first array ref correctly and the second to a scalar.

my $array_ref3 = [Gwybodaeth::Triples->new(),{}];

throws_ok {$csv_write->write_rdf($array_ref3, $string2)}
        qr/expected ARRAY in the second array ref/,
        'dud array input 3 (write_rdf 2nd arg)';
