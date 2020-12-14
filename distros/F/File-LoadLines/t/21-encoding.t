#! perl

# Test explicit encoding.

use strict;
use warnings;
use Test::More tests => 7;
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
	$tally++ if /€urø/;
    }
    is( $tally, 4, "matches" );
}

# test0.dat: ISO-8859.15 text
my $o = { encoding => "iso-8859-15" };
testlines( "test0.dat", $o );
is ( $o->{encoding}, "iso-8859-15", "returned encoding" );
