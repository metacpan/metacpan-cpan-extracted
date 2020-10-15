# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use strict;
use warnings;

use Test::More tests => 20;
use Math::FFT;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $PI   = 4.0 * atan2( 1, 1 );
my $N    = 16;
my $NBIG = 32768;

#my $NBIG = 16;
my @subs = qw(cdft rdft ddct ddst dfct dfst);
foreach (@subs)
{
    my $start = $_ eq 'dfst' ? 1         : 0;
    my $end   = $_ eq 'dfct' ? $NBIG + 1 : $NBIG;
    my $orig  = make_random( $start, $end );
    my $fft   = Math::FFT->new($orig);
    my $coeff = $fft->$_();
    my $inv   = 'inv' . $_;
    my $calc  = $fft->$inv();

    # TEST*6
    check_error( $start, $end, $orig, $calc );
}

my $series = [];
my $coeff  = [];
my $start  = 0;
my $end    = $N + 1;
for ( my $k = $start ; $k < $end ; ++$k )
{
    $series->[$k] = cos( 3 * $k * $PI / $N );
}
my $fft = Math::FFT->new($series);
$coeff = $fft->dfct();
my $true = [ 0, 1, 0, 9, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 ];

# TEST
check_error( $start, $end, $coeff, $true );
my $calc = $fft->invdfct();

# TEST
check_error( $start, $end, $series, $calc );

$series = [];
$coeff  = [];
$calc   = [];
$start  = 1;
$end    = $N;
for ( my $k = $start ; $k < $end ; ++$k )
{
    $series->[$k] = sin( 3 * $k * $PI / $N );
}
$fft   = Math::FFT->new($series);
$coeff = $fft->dfst();
$true  = [ 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

# TEST
check_error( $start, $end, $coeff, $true );
$calc = $fft->invdfst();

# TEST
check_error( $start, $end, $series, $calc );

$calc   = [];
$series = [];
$coeff  = [];
$start  = 0;
$end    = $N;
for ( my $k = $start ; $k < $end ; ++$k )
{
    $series->[$k] = cos( 5 * ( $k + 0.5 ) * $PI / $N );
}
$fft   = Math::FFT->new($series);
$coeff = $fft->ddct();
$true  = [ 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

# TEST
check_error( $start, $end, $coeff, $true );
$calc = $fft->invddct();

# TEST
check_error( $start, $end, $series, $calc );

$calc   = [];
$series = [];
$coeff  = [];
$start  = 0;
$end    = $N;
for ( my $k = $start ; $k < $end ; ++$k )
{
    $series->[$k] = sin( 5 * ( $k + 0.5 ) * $PI / $N );
}
$fft   = Math::FFT->new($series);
$coeff = $fft->ddst();
$true  = [ 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

# TEST
check_error( $start, $end, $coeff, $true );
$calc = $fft->invddst();

# TEST
check_error( $start, $end, $series, $calc );

$calc   = [];
$series = [];
$coeff  = [];
$start  = 0;
$end    = $N;
for ( my $k = $start ; $k < $end ; ++$k )
{
    $series->[$k] = sin( 4 * $k * $PI / $N ) + cos( 6 * $k * $PI / $N );
}
$fft   = Math::FFT->new($series);
$coeff = $fft->rdft();
$true  = [ 0, 0, 0, 0, 0, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

# TEST
check_error( $start, $end, $coeff, $true );
$calc = $fft->invrdft();

# TEST
check_error( $start, $end, $series, $calc );

$calc   = [];
$series = [];
$coeff  = [];
$start  = 0;
$end    = $N;
for ( my $k = $start ; $k < $end / 2 ; ++$k )
{
    $series->[ 2 * $k ] = cos( 8 * $k * $PI / $N );
    $series->[ 2 * $k + 1 ] = sin( 8 * $k * $PI / $N );
}
$fft   = Math::FFT->new($series);
$coeff = $fft->cdft();
$true  = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0 ];

# TEST
check_error( $start, $end, $coeff, $true );
$calc = $fft->invcdft();

# TEST
check_error( $start, $end, $series, $calc );

my $orig = make_random( 0, $NBIG );
$fft   = Math::FFT->new($orig);
$coeff = $fft->cdft();
$calc  = $fft->invcdft();

# TEST
check_error( $start, $end, $orig, $calc );

$orig = make_random2( 0, $NBIG );
my $clone = $fft->clone($orig);
$coeff = $clone->cdft();
$calc  = $clone->invcdft();

# TEST
check_error( $start, $end, $orig, $calc );

sub make_random
{
    my ( $start, $end ) = @_;
    my $a = [];
    for ( my $k = $start ; $k < $end ; ++$k )
    {
        $a->[$k] = rand;
    }
    return $a;
}

sub make_random2
{
    my ( $start, $end ) = @_;
    my $a = [];
    for ( my $k = $start ; $k < $end ; ++$k )
    {
        $a->[$k] = 15 * rand;
    }
    return $a;
}

sub check_error
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ( $start, $end, $old, $new ) = @_;
    my $error = 0;
    for ( my $j = $start ; $j < $end ; ++$j )
    {
        $error += abs( $old->[$j] - $new->[$j] );
    }

    ok( scalar( $error < 1e-10 ), "Checking error (error of $error)" );
}
