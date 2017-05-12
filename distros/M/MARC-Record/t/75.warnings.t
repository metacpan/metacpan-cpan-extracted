#!perl -Tw

use Test::More tests=>21;
use strict;

use File::Spec;

BEGIN {
    use_ok( 'MARC::Batch' );
}

## when strict is on, errors cause next() to return undef

STRICT_ON: {

    my $filename = File::Spec->catfile( 't', 'badldr.usmarc' );
    my $batch = MARC::Batch->new( 'USMARC', $filename );
    isa_ok( $batch, 'MARC::Batch' );

    $batch->warnings_off(); # avoid clutter on STDERR
    $batch->strict_on(); # the default, but might as well test

    my $count = 0;
    while ( my $r = $batch->next() ) {
	isa_ok( $r, "MARC::Record" );
	$count++;
    }
    
    my @warnings = $batch->warnings();
    is( scalar(@warnings), 1, "warnings() w/ strict on" );
    is( $count, 2, "next() w/ strict on" );

}

## when strict is off you can keep on reading past errors

STRICT_OFF: {

    my $filename = File::Spec->catfile( 't', 'badldr.usmarc' );
    my $batch = MARC::Batch->new( 'USMARC', $filename );
    isa_ok( $batch, 'MARC::Batch' );

    $batch->warnings_off(); # avoid clutter on STDERR
    $batch->strict_off(); # turning off default behavior
    
    my $count = 0;
    while ( my $r = $batch->next() ) {
	isa_ok( $r, "MARC::Record" );
	$count++;
    }


    my @warnings = $batch->warnings();
    is( scalar(@warnings), 2, "warnings() w/ strict off" );
    is( $count, 8, "next() w/ strict off" );
}

WARNINGS_BUFFER_RESET: {

    my $filename = File::Spec->catfile( 't', 'badind.usmarc' );
    my $batch = MARC::Batch->new( 'USMARC', $filename );
    $batch->warnings_off();
    $batch->strict_off();
    my $r = $batch->next();

    ## check the warnings on the batch
    my @warnings = $batch->warnings();
    is( @warnings, 1, 'got expected amt of warnings off the batch' );
    like( $warnings[0], qr/^Invalid indicator/, 
        'got expected err msg off the batch' );

    ## same exact warning should be available on the record 
    @warnings = $r->warnings();
    is( @warnings, 1, 'got expected amt of warnings off the record' );
    like( $warnings[0], qr/^Invalid indicator/, 
        'got expected err msg off the record' );
}
