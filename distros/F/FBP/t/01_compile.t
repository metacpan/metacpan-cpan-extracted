#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

use_ok( 'FBP' );

# Test basic construction
my $fbp1 = FBP->new;
my $fbp2 = FBP->new;
isa_ok( $fbp1, 'FBP' );
isa_ok( $fbp2, 'FBP' );
