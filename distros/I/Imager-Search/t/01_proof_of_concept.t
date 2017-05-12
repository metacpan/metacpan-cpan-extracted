#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Imager                ();






#####################################################################
# Regular expression code proof of concept

SCOPE: {
	my $big   = "#000000#123456#000000#123456#111111#123456#222222#333333#123456#FFFFFF#123456";
	my $small = "(?:#123456).{7}(?:#123456)";
	my @match = ();
	while ( scalar $big =~ /$small/gs ) {
		my $p = $-[0];
		push @match, $p / 7;
		pos $big = $p + 1;
	}
	is_deeply( \@match, [ 1, 3, 8 ], 'Proof of concept works' );
}





#####################################################################
# Imager BMP output support proof of concept

SCOPE: {
	my $read  = catfile( 't', 'data', 'basic', 'rgbw.bmp' );
        ok( -f $read, "Test file $read exists" );
	my $write = catfile( 't', 'data', 'write1.bmp'          );
	clear( $write );
	ok( ! -f $write, "Test file $write does not exist" );
	my $image = Imager->new;
	isa_ok( $image, 'Imager' );
	my $rv1 = $image->read( file => $read );
	ok( $rv1, '->read ok' );
	diag( $image->errstr ) unless $rv1;

	# Support for basic writing of BMP files
	my $rv2 = $image->write( file => $write );
	ok( $rv2, '->write ok' );
	diag( $image->errstr ) unless $rv2;
	ok( -f $write, "Test file $write created" );

	# Support for writing to memory
	my $data = '';
	my $rv3  = $image->write( data => \$data, type => 'bmp' );
	ok( $rv3, '->write(data) ok' );
	diag( $image->errstr ) unless $rv3;
	is( length($data), 70, 'Data is the expected length' );
}
