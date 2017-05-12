#!perl -Tw

use strict;
use integer;

use Test::More tests=>5;
use File::Spec;

BEGIN {
    use_ok( 'MARC::File::MicroLIF' );
}


MISSINGHEADER: {
    my $filename = File::Spec->catfile( 't', 'sample1.lif' );
    my $file = MARC::File::MicroLIF->in( $filename );
    isa_ok( $file, 'MARC::File::MicroLIF', 'got a MicroLIF file' );
    ok( !$file->header(), 'file contains no header' );
    $file->close();
}

MISSINGHEADER: {
    my $filename = File::Spec->catfile( 't', 'sample20.lif' );
    my $file = MARC::File::MicroLIF->in( $filename );
    isa_ok( $file, 'MARC::File::MicroLIF', 'got a MicroLIF file' );
    is( 
	$file->header(), 
	'header 20 rec MicroLIF file                                                     ', 
	'file header correct' 
    );
    $file->close();
}

