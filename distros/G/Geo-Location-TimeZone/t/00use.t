#!/usr/bin/env perl -w

# Check that the module can be 'use'd.

use strict;
use Test;
BEGIN { plan tests => 3 }

# Just try to use the module.
use Geo::Location::TimeZone; ok(1);

# Check that the object can be created.
my $gobj = Geo::Location::TimeZone->new();
if( defined( $gobj ) ){
	ok( 1 );
	my $vstr = $gobj->version();
	if( $vstr eq "0.1" ){
		ok( 1 );
	}else{
		ok( 0 );
		print "# Version string mismatch.  Bruce has not updated for this release\n";
	}
}else{
	ok( 0 );
	ok( 0 );	
	print "# No object, thus no version check\n";
}
exit;
__END__
