#!perl -Tw

use strict;
use integer;

use constant CAMEL_SKIPS => 8;

use Test::More tests=>(CAMEL_SKIPS * 2) + 7;
use File::Spec;

BEGIN {
    use_ok( 'MARC::File::USMARC' );
}

my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC', 'USMARC file' );

my $marc;
for ( 1..CAMEL_SKIPS ) { # Skip to the camel
    $marc = $file->next( sub { $_[0] == 245 } ); # Only want 245 in the record
    isa_ok( $marc, 'MARC::Record', 'Got a record' );

    is( scalar $marc->fields, 1, 'Should only have one tag' );
}

is( $marc->author,		'' );
is( $marc->title,		'Programming Perl / Larry Wall, Tom Christiansen & Jon Orwant.' );
is( $marc->title_proper,	'Programming Perl /' );
is( $marc->edition,		'' );
is( $marc->publication_date,	'' );

$file->close;

