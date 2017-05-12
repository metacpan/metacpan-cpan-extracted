use strict;
use warnings;
use Test::More qw( no_plan );
use File::Temp qw( tempfile );


## recreate a MARC::SubjectMap object from its XML
## configuration, serialize as XML again, and compare
## the original XML against the generated XML 
## they should be identical

## pull in XML off disk as a single string
open( ORIGINAL, "t/test.xml" );
my $originalXML = join( '', <ORIGINAL> );
close( ORIGINAL );

## create MARC::SubjectMap object
use_ok( 'MARC::SubjectMap' );
my $map = MARC::SubjectMap->newFromConfig( 't/test.xml' );
isa_ok( $map, 'MARC::SubjectMap' );

## write out XML to disk
my ($xmlHandle,$xmlFile) = tempfile();
$map->writeConfig( $xmlFile );

## get generated XML
open( GENERATED, $xmlFile ); 
my $generatedXML = join( '', <GENERATED> );

## now compare
is( $generatedXML, $originalXML, "XML before and after matches" );

