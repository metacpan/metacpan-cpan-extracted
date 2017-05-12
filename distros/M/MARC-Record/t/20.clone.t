#!perl -Tw

use integer;
use strict;
use File::Spec;

use Test::More tests=>6;

BEGIN {
    use_ok( 'MARC::File::USMARC' );
}

my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC', 'USMARC input file object' );
my $marc = $file->next();
isa_ok( $marc, 'MARC::Record', 'Read from file' );
$file->close;

my $clone = $marc->clone;
isa_ok( $clone, 'MARC::Record', 'Cloned record' );

ok( $marc != $clone,		'Clone and original are different' );

ok( $marc->as_formatted eq $clone->as_formatted,
				'Clone and original match content' );
