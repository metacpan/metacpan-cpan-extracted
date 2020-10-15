use strict;
use warnings;

use Test::More tests => 7;
use Math::FFT;

{
    my $set  = [ 1, 2, 3, 4, 250 ];
    my $d    = Math::FFT->new($set);
    my $mean = $d->mean;

    # TEST
    check_value( 52, $mean );
    my $std = $d->stdev;

    # TEST
    check_value( 13 * sqrt(290) / 2, $std );
    my $rms = $d->rms;

    # TEST
    check_value( sqrt(12506), $rms );
    my ( $min, $max ) = $d->range;

    # TEST
    check_value( 1, $min );

    # TEST
    check_value( 250, $max );
    my $med = $d->median;

    # TEST
    check_value( 3, $med );
}

{
    my $set = [ 1, 2, 3, 4 ];
    my $d   = Math::FFT->new($set);
    my $med = $d->median;

    # TEST
    check_value( 2.5, $med );
}

sub check_value
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $true, $calc ) = @_;
    my $error = abs( $true - $calc );
    ok( scalar( $error < 1e-10 ), "Checking for Error (error of $error)\n" );
}
