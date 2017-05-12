#!/usr/bin/env perl -w

# Check that the module can be 'use'd.

use strict;
use Test;
BEGIN { plan tests => 3 }

# Just try to use the module.
use Jabber::Lite; ok(1);

# Check that the object can be created.
my $jobj = Jabber::Lite->new();
if( defined( $jobj ) ){
	ok( 1 );
	my $vstr = $jobj->version();
	if( $vstr eq "0.8" ){
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
