#! perl

# Test auto-sense Latin encoding.

use strict;
use warnings;
use Test::More tests => 6;
use utf8;

use File::LoadLines;

-d "t" && chdir "t";

my @lengths = ( 24, 28, 18, 18 );

sub testlines {
    my ( $file, $options ) = @_;
    $options //= {};
    my @lines = loadlines( $file, $options );
    is( scalar(@lines), 4, "lines" );
    my $tally = 0;
    my $line = 0;
    foreach ( @lines ) {
	is( length($_), $lengths[$line], "line $line" );
	$line++;
	$tally++ if /¤urø/;
    }
    is( $tally, 4, "matches" );
    exit;
}

# test0.dat: ISO-8859.1 text
# Should auto-sense.
testlines( "test0.dat" );
