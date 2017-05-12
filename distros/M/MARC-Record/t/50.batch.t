#!perl -Tw

use strict;
use integer;
use File::Spec;

use Test::More tests=>267;

BEGIN: {
    use_ok( 'MARC::Batch' );
}

# Test the USMARC stuff
USMARC: {

    my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
    my $batch = new MARC::Batch( 'USMARC', $filename );
    isa_ok( $batch, 'MARC::Batch', 'MARC batch' );

    my $n = 0;
    while ( my $marc = $batch->next() ) {
	isa_ok( $marc, 'MARC::Record' );

	my $f245 = $marc->field( '245' );
	isa_ok( $f245, 'MARC::Field' );
	++$n;
    }
    is( $n, 10, 'Got 10 USMARC records' );
}

# Test MicroLIF batch

MicroLIF: {

    my @files = (
        File::Spec->catfile( 't', 'sample1.lif' ),
        File::Spec->catfile( 't', 'sample20.lif' ),
        File::Spec->catfile( 't', 'sample100.lif' )
    );

    my $batch = new MARC::Batch( 'MicroLIF', @files );
    isa_ok( $batch, 'MARC::Batch', 'MicroLIF batch' );

    my $n = 0;
    while ( my $marc = $batch->next() ) {
	isa_ok( $marc, 'MARC::Record' );

	my $f245 = $marc->field( '245' );
	isa_ok( $f245, 'MARC::Field' );
	++$n;
    }
    is( $n, 121, 'Got 120 LIF records' );
}
